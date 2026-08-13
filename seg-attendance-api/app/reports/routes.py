from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from app.extensions import db
from app.models import (
    Report,
    Session,
    Cohort,
    Learner,
    AttendanceRecord,
    AuditLog,
)
from app.utils import (
    get_current_coordinator,
    same_hub,
    forbidden,
    log_action,
)

reports_bp = Blueprint("reports", __name__)


def _build_session_report_data(session, cohort):
    learners = Learner.query.filter_by(
        cohort_id=session.cohort_id
    ).order_by(Learner.full_name).all()

    records = AttendanceRecord.query.filter_by(
        session_id=session.session_id
    ).all()
    records_by_learner = {str(r.learner_id): r for r in records}

    attendance = []
    for learner in learners:
        record = records_by_learner.get(str(learner.learner_id))
        attendance.append({
            "learner_id": str(learner.learner_id),
            "seg_id": learner.seg_id,
            "full_name": learner.full_name,
            "checked_in_at":
                record.checked_in_at.isoformat()
                if record and record.checked_in_at else None,
            "checked_out_at":
                record.checked_out_at.isoformat()
                if record and record.checked_out_at else None,
            "verification_method":
                record.verification_method if record else None,
            "is_complete":
                record.is_complete if record else False,
        })

    return {
        "session_id": str(session.session_id),
        "session_title": session.title,
        "cohort_id": str(cohort.cohort_id),
        "cohort_name": cohort.name,
        "started_at":
            session.started_at.isoformat()
            if session.started_at else None,
        "ended_at":
            session.ended_at.isoformat()
            if session.ended_at else None,
        "total_learners": len(learners),
        "attended_count":
            sum(1 for a in attendance if a["is_complete"]),
        "attendance": attendance,
    }


def _build_cohort_final_data(cohort):
    sessions = Session.query.filter_by(
        cohort_id=cohort.cohort_id
    ).all()
    session_ids = [str(s.session_id) for s in sessions]
    total_sessions = len(sessions)

    learners = Learner.query.filter_by(
        cohort_id=cohort.cohort_id
    ).order_by(Learner.full_name).all()

    results = []
    for learner in learners:
        attended = 0
        if total_sessions > 0:
            attended = AttendanceRecord.query.filter(
                AttendanceRecord.learner_id == learner.learner_id,
                AttendanceRecord.session_id.in_(session_ids),
                AttendanceRecord.is_complete == True
            ).count()

        percent = (
            attended / total_sessions * 100.0
        ) if total_sessions > 0 else 0.0
        meets = percent >= cohort.min_attendance_percent

        results.append({
            "learner_id": str(learner.learner_id),
            "seg_id": learner.seg_id,
            "full_name": learner.full_name,
            "sessions_attended": attended,
            "total_sessions": total_sessions,
            "attendance_percent": round(percent, 2),
            "certified": meets,
        })

    return {
        "cohort_id": str(cohort.cohort_id),
        "cohort_name": cohort.name,
        "hub_id": str(cohort.hub_id),
        "min_attendance_percent": cohort.min_attendance_percent,
        "total_sessions": total_sessions,
        "total_learners": len(learners),
        "certified_count":
            sum(1 for r in results if r["certified"]),
        "learners": results,
    }


@reports_bp.route("/session/<session_id>", methods=["POST"])
@jwt_required()
def submit_session_report(session_id):
    coordinator = get_current_coordinator()
    if not coordinator:
        return jsonify({"error": "Coordinator not found"}), 404

    try:
        session = Session.query.get(session_id)
    except Exception:
        session = None

    if not session:
        return jsonify({"error": "Session not found"}), 404

    cohort = Cohort.query.get(session.cohort_id)
    if not cohort or not same_hub(coordinator, cohort.hub_id):
        return forbidden("Not authorized to submit this session")

    if session.ended_at is None:
        return jsonify({
            "error": "Session must be ended before submitting"
        }), 400

    # Warn if 0 attendance and no confirmation
   

    existing = Report.query.filter_by(
        session_id=session.session_id,
        report_type="session"
    ).first()
    if existing:
        return jsonify({
            "error": "Session report already submitted",
            "report_id": str(existing.report_id)
        }), 409

    report_data = _build_session_report_data(session, cohort)

    report = Report(
        cohort_id=cohort.cohort_id,
        hub_id=cohort.hub_id,
        session_id=session.session_id,
        coordinator_id=coordinator.coordinator_id,
        report_type="session",
        data=report_data,
        status="submitted",
    )
    db.session.add(report)
    db.session.commit()

    log_action(coordinator, "report.session_submitted", "report",
               report.report_id, {"session_id": str(session_id)})

    return jsonify(report.to_dict()), 201


@reports_bp.route("/cohort/<cohort_id>/final", methods=["POST"])
@jwt_required()
def submit_cohort_final_report(cohort_id):
    coordinator = get_current_coordinator()
    if not coordinator:
        return jsonify({"error": "Coordinator not found"}), 404

    try:
        cohort = Cohort.query.get(cohort_id)
    except Exception:
        cohort = None

    if not cohort:
        return jsonify({"error": "Cohort not found"}), 404

    if not same_hub(coordinator, cohort.hub_id):
        return forbidden("Not authorized to submit this cohort")

    existing = Report.query.filter_by(
        cohort_id=cohort.cohort_id,
        report_type="cohort_final"
    ).first()
    if existing:
        return jsonify({
            "error": "Final report already submitted",
            "report_id": str(existing.report_id)
        }), 409

    data = _build_cohort_final_data(cohort)

    report = Report(
        cohort_id=cohort.cohort_id,
        hub_id=cohort.hub_id,
        session_id=None,
        coordinator_id=coordinator.coordinator_id,
        report_type="cohort_final",
        data=data,
        status="submitted",
    )
    db.session.add(report)
    db.session.commit()

    log_action(coordinator, "report.cohort_final_submitted",
               "report", report.report_id,
               {"cohort_id": str(cohort_id)})

    return jsonify(report.to_dict()), 201


@reports_bp.route("", methods=["GET"])
@jwt_required()
def list_reports():
    coordinator = get_current_coordinator()
    if not coordinator:
        return jsonify({"error": "Coordinator not found"}), 404

    report_type = request.args.get("type")

    query = Report.query.filter_by(hub_id=coordinator.hub_id)

    if report_type:
        query = query.filter_by(report_type=report_type)

    reports = query.order_by(Report.submitted_at.desc()).all()
    return jsonify([r.to_dict() for r in reports]), 200


@reports_bp.route("/<report_id>", methods=["GET"])
@jwt_required()
def get_report(report_id):
    coordinator = get_current_coordinator()
    if not coordinator:
        return jsonify({"error": "Coordinator not found"}), 404

    try:
        report = Report.query.get(report_id)
    except Exception:
        report = None

    if not report:
        return jsonify({"error": "Report not found"}), 404

    if not same_hub(coordinator, report.hub_id):
        return forbidden("Not authorized to access this report")

    return jsonify(report.to_dict()), 200


@reports_bp.route("/audit-log", methods=["GET"])
@jwt_required()
def get_audit_log():
    coordinator = get_current_coordinator()
    if not coordinator:
        return jsonify({"error": "Coordinator not found"}), 404

    limit = min(int(request.args.get("limit", 100)), 500)

    logs = AuditLog.query.filter_by(
        coordinator_id=coordinator.coordinator_id
    ).order_by(
        AuditLog.created_at.desc()
    ).limit(limit).all()

    return jsonify([log.to_dict() for log in logs]), 200