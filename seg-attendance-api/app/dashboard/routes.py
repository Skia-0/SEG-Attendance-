from flask import Blueprint, render_template, request, redirect, url_for, session, flash, jsonify
from app.models import Coordinator, Hub, Cohort, Session as HubSession, Learner, AttendanceRecord
from app.extensions import db
from datetime import datetime

dashboard_bp = Blueprint(
    "dashboard",
    __name__,
    template_folder="templates"
)

def get_current_coordinator():
    coordinator_id = session.get("coordinator_id")
    if not coordinator_id:
        return None
    return Coordinator.query.get(coordinator_id)

@dashboard_bp.route("/login", methods=["GET", "POST"])
def login():
    if get_current_coordinator():
        return redirect(url_for("dashboard.home"))

    if request.method == "POST":
        phone = request.form.get("phone")
        password = request.form.get("password")

        if not phone or not password:
            flash("Phone number and password are required", "danger")
            return render_template("login.html")

        coordinator = Coordinator.query.filter_by(phone=phone).first()

        if not coordinator or not coordinator.check_password(password):
            flash("Invalid credentials", "danger")
            return render_template("login.html")

        session["coordinator_id"] = str(coordinator.coordinator_id)
        return redirect(url_for("dashboard.home"))

    return render_template("login.html")

@dashboard_bp.route("/logout", methods=["GET"])
def logout():
    session.pop("coordinator_id", None)
    return redirect(url_for("dashboard.login"))

@dashboard_bp.route("/home", methods=["GET"])
def home():
    coordinator = get_current_coordinator()
    if not coordinator:
        return redirect(url_for("dashboard.login"))

    hub = Hub.query.get(coordinator.hub_id)
    cohorts = Cohort.query.filter_by(hub_id=hub.hub_id).all()
    
    cohort_ids = [c.cohort_id for c in cohorts]
    sessions = []
    if cohort_ids:
        sessions = HubSession.query.filter(HubSession.cohort_id.in_(cohort_ids)).order_by(HubSession.started_at.desc()).all()

    return render_template(
        "dashboard.html",
        coordinator=coordinator,
        hub=hub,
        cohorts=cohorts,
        sessions=sessions
    )

@dashboard_bp.route("/session/<session_id>", methods=["GET"])
def session_detail(session_id):
    coordinator = get_current_coordinator()
    if not coordinator:
        return redirect(url_for("dashboard.login"))

    try:
        hub_session = HubSession.query.get(session_id)
    except Exception:
        hub_session = None

    if not hub_session:
        return "Session not found", 404

    cohort = Cohort.query.get(hub_session.cohort_id)
    learners = Learner.query.filter_by(cohort_id=cohort.cohort_id).order_by(Learner.full_name).all()
    records = AttendanceRecord.query.filter_by(session_id=hub_session.session_id).all()

    records_map = {str(r.learner_id): r for r in records}

    # Prepare learner attendance status
    learner_statuses = []
    for l in learners:
        record = records_map.get(str(l.learner_id))
        status = "Pending"
        checked_in_at = None
        checked_out_at = None
        method = "N/A"

        if record:
            checked_in_at = record.checked_in_at
            checked_out_at = record.checked_out_at
            method = record.verification_method
            if record.is_complete:
                status = "Complete"
            elif record.checked_in_at:
                status = "Checked In"

        learner_statuses.append({
            "seg_id": l.seg_id,
            "full_name": l.full_name,
            "status": status,
            "checked_in_at": checked_in_at.strftime("%H:%M:%S") if checked_in_at else "—",
            "checked_out_at": checked_out_at.strftime("%H:%M:%S") if checked_out_at else "—",
            "method": method
        })

    return render_template(
        "session.html",
        session=hub_session,
        cohort=cohort,
        learner_statuses=learner_statuses
    )

# Dashboard actions to manage state
@dashboard_bp.route("/session/<session_id>/checkin/<action>", methods=["POST"])
def toggle_checkin(session_id, action):
    coordinator = get_current_coordinator()
    if not coordinator:
        return jsonify({"error": "Unauthorized"}), 401

    hub_session = HubSession.query.get(session_id)
    if not hub_session:
        return jsonify({"error": "Session not found"}), 404

    if action == "open":
        hub_session.checkin_open = True
        hub_session.checkout_open = False
    else:
        hub_session.checkin_open = False

    db.session.commit()
    return redirect(url_for("dashboard.session_detail", session_id=session_id))

@dashboard_bp.route("/session/<session_id>/checkout/<action>", methods=["POST"])
def toggle_checkout(session_id, action):
    coordinator = get_current_coordinator()
    if not coordinator:
        return jsonify({"error": "Unauthorized"}), 401

    hub_session = HubSession.query.get(session_id)
    if not hub_session:
        return jsonify({"error": "Session not found"}), 404

    if action == "open":
        hub_session.checkout_open = True
        hub_session.checkin_open = False
    else:
        hub_session.checkout_open = False

    db.session.commit()
    return redirect(url_for("dashboard.session_detail", session_id=session_id))

@dashboard_bp.route("/session/<session_id>/end", methods=["POST"])
def end_session(session_id):
    coordinator = get_current_coordinator()
    if not coordinator:
        return jsonify({"error": "Unauthorized"}), 401

    hub_session = HubSession.query.get(session_id)
    if not hub_session:
        return jsonify({"error": "Session not found"}), 404

    hub_session.ended_at = datetime.utcnow()
    hub_session.checkin_open = False
    hub_session.checkout_open = False

    db.session.commit()
    return redirect(url_for("dashboard.session_detail", session_id=session_id))

@dashboard_bp.route("/cohort/<cohort_id>/summary", methods=["GET"])
def cohort_summary(cohort_id):
    coordinator = get_current_coordinator()
    if not coordinator:
        return redirect(url_for("dashboard.login"))

    try:
        cohort = Cohort.query.get(cohort_id)
    except Exception:
        cohort = None

    if not cohort:
        return "Cohort not found", 404

    # Calculate same as API
    sessions = HubSession.query.filter_by(cohort_id=cohort.cohort_id).all()
    session_ids = [str(s.session_id) for s in sessions]
    total_sessions = len(sessions)

    learners = Learner.query.filter_by(cohort_id=cohort.cohort_id).order_by(Learner.full_name).all()

    summary_list = []
    for learner in learners:
        sessions_attended = 0
        if total_sessions > 0:
            sessions_attended = AttendanceRecord.query.filter(
                AttendanceRecord.learner_id == learner.learner_id,
                AttendanceRecord.session_id.in_(session_ids),
                AttendanceRecord.is_complete == True
            ).count()

        attendance_percent = (sessions_attended / total_sessions * 100.0) if total_sessions > 0 else 100.0
        meets_threshold = attendance_percent >= cohort.min_attendance_percent

        summary_list.append({
            "seg_id": learner.seg_id,
            "full_name": learner.full_name,
            "sessions_attended": sessions_attended,
            "total_sessions": total_sessions,
            "attendance_percent": round(attendance_percent, 1),
            "meets_threshold": meets_threshold
        })

    return render_template(
        "cohort_summary.html",
        cohort=cohort,
        summary_list=summary_list
    )
