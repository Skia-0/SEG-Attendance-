from datetime import datetime, date
from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required
from app.models import (
    Cohort,
    Learner,
    Session,
    AttendanceRecord,
    Coordinator,
)
from app.extensions import db
from app.utils import (
    get_current_coordinator,
    same_hub,
    forbidden,
    log_action,
)

cohorts_bp = Blueprint("cohorts", __name__)


def generate_cohort_code(name, hub_id):
    prefix = "".join(c for c in name.upper() if c.isalpha())[:3]
    if len(prefix) < 3:
        prefix = prefix.ljust(3, "X")

    existing_count = Cohort.query.filter(
        Cohort.hub_id == hub_id,
        Cohort.name.ilike(f"{name[:3]}%")
    ).count()

    return f"{prefix}-{str(existing_count + 1).zfill(3)}"


def parse_date(value):
    if not value:
        return None
    try:
        return datetime.fromisoformat(value).date()
    except Exception:
        try:
            return datetime.strptime(value, "%Y-%m-%d").date()
        except Exception:
            return None


def _has_active_session(cohort_id):
    """Check if cohort has any session with ended_at IS NULL."""
    return Session.query.filter_by(
        cohort_id=cohort_id,
        ended_at=None
    ).first() is not None


@cohorts_bp.route("", methods=["POST"])
@jwt_required()
def create_cohort():
    coordinator = get_current_coordinator()
    if not coordinator:
        return jsonify({"error": "Coordinator not found"}), 404

    data = request.get_json() or {}
    name = (data.get("name") or "").strip()
    start_date = parse_date(data.get("start_date"))
    end_date = parse_date(data.get("end_date"))
    min_attendance = data.get("min_attendance_percent", 80)

    if not name:
        return jsonify({"error": "Cohort name is required"}), 400

    if len(name) < 3:
        return jsonify({
            "error": "Cohort name must be at least 3 characters"
        }), 400

    try:
        min_attendance = int(min_attendance)
    except (ValueError, TypeError):
        min_attendance = 80

    if min_attendance < 1 or min_attendance > 100:
        return jsonify({
            "error": "Attendance percent must be between 1 and 100"
        }), 400

    code = generate_cohort_code(name, coordinator.hub_id)

    cohort = Cohort(
        name=name,
        hub_id=coordinator.hub_id,
        start_date=start_date or date.today(),
        end_date=end_date,
        min_attendance_percent=min_attendance
    )

    db.session.add(cohort)
    db.session.commit()

    log_action(coordinator, "cohort.created", "cohort",
               cohort.cohort_id, {"name": name, "code": code})

    result = cohort.to_dict()
    result["code"] = code
    result["learner_count"] = 0
    result["session_count"] = 0
    result["has_active_session"] = False

    return jsonify(result), 201


@cohorts_bp.route("", methods=["GET"])
@jwt_required()
def list_my_cohorts():
    coordinator = get_current_coordinator()
    if not coordinator:
        return jsonify({"error": "Coordinator not found"}), 404

    cohorts = Cohort.query.filter_by(
        hub_id=coordinator.hub_id,
        is_deleted=False 
    ).order_by(Cohort.created_at.desc()).all()

    results = []
    for c in cohorts:
        data = c.to_dict()
        data["learner_count"] = Learner.query.filter_by(
            cohort_id=c.cohort_id
        ).count()
        data["session_count"] = Session.query.filter_by(
            cohort_id=c.cohort_id
        ).count()
        data["has_active_session"] = _has_active_session(c.cohort_id)
        results.append(data)

    return jsonify(results), 200


@cohorts_bp.route("/<cohort_id>", methods=["GET"])
@jwt_required()
def get_cohort(cohort_id):
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
        return forbidden("Not authorized to access this cohort")

    learner_count = Learner.query.filter_by(
        cohort_id=cohort.cohort_id
    ).count()

    session_count = Session.query.filter_by(
        cohort_id=cohort.cohort_id
    ).count()

    # Calculate expected session count based on cohort duration (roughly)
    expected_sessions = None
    if cohort.start_date and cohort.end_date:
        days = (cohort.end_date - cohort.start_date).days
        # Assume ~1 session per week
        expected_sessions = max(1, days // 7)

    cohort_data = cohort.to_dict()
    cohort_data["learner_count"] = learner_count
    cohort_data["session_count"] = session_count
    cohort_data["expected_sessions"] = expected_sessions
    cohort_data["has_active_session"] = _has_active_session(cohort.cohort_id)

    return jsonify(cohort_data), 200


@cohorts_bp.route("/<cohort_id>/summary", methods=["GET"])
@jwt_required()
def get_cohort_summary(cohort_id):
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
        return forbidden("Not authorized to access this cohort")

    sessions = Session.query.filter_by(
        cohort_id=cohort.cohort_id
    ).all()
    session_ids = [str(s.session_id) for s in sessions]
    total_sessions = len(sessions)

    learners = Learner.query.filter_by(
        cohort_id=cohort.cohort_id
    ).order_by(Learner.full_name).all()

    summary_list = []
    for learner in learners:
        sessions_attended = 0
        if total_sessions > 0:
            sessions_attended = AttendanceRecord.query.filter(
                AttendanceRecord.learner_id == learner.learner_id,
                AttendanceRecord.session_id.in_(session_ids),
                AttendanceRecord.is_complete == True
            ).count()

        attendance_percent = (
            sessions_attended / total_sessions * 100.0
        ) if total_sessions > 0 else 100.0

        meets_threshold = attendance_percent >= cohort.min_attendance_percent

        summary_list.append({
            "learner_id": str(learner.learner_id),
            "seg_id": learner.seg_id,
            "full_name": learner.full_name,
            "sessions_attended": sessions_attended,
            "total_sessions": total_sessions,
            "attendance_percent": round(attendance_percent, 2),
            "meets_threshold": meets_threshold,
            "certified": meets_threshold
        })

    return jsonify(summary_list), 200


@cohorts_bp.route("/<cohort_id>/at-risk", methods=["GET"])
@jwt_required()
def get_at_risk_learners(cohort_id):
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
        return forbidden("Not authorized to access this cohort")

    sessions = Session.query.filter_by(
        cohort_id=cohort.cohort_id
    ).all()
    session_ids = [str(s.session_id) for s in sessions]
    total_sessions = len(sessions)

    learners = Learner.query.filter_by(
        cohort_id=cohort.cohort_id
    ).order_by(Learner.full_name).all()

    at_risk = []
    for learner in learners:
        sessions_attended = 0
        if total_sessions > 0:
            sessions_attended = AttendanceRecord.query.filter(
                AttendanceRecord.learner_id == learner.learner_id,
                AttendanceRecord.session_id.in_(session_ids),
                AttendanceRecord.is_complete == True
            ).count()

        attendance_percent = (
            sessions_attended / total_sessions * 100.0
        ) if total_sessions > 0 else 100.0

        if attendance_percent < cohort.min_attendance_percent:
            gap = cohort.min_attendance_percent - attendance_percent
            at_risk.append({
                "learner_id": str(learner.learner_id),
                "seg_id": learner.seg_id,
                "full_name": learner.full_name,
                "sessions_attended": sessions_attended,
                "total_sessions": total_sessions,
                "attendance_percent": round(attendance_percent, 2),
                "gap_to_threshold": round(gap, 2),
            })

    return jsonify({
        "cohort_id": str(cohort.cohort_id),
        "cohort_name": cohort.name,
        "min_attendance_percent": cohort.min_attendance_percent,
        "total_sessions_so_far": total_sessions,
        "at_risk_count": len(at_risk),
        "learners": at_risk,
    }), 200


@cohorts_bp.route("/<cohort_id>", methods=["DELETE"])
@jwt_required()
def delete_cohort(cohort_id):
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
        return forbidden("Not authorized to delete this cohort")

    cohort_name = cohort.name
    cohort.is_deleted = True
    cohort.deleted_at = datetime.utcnow
    db.session.commit()

    log_action(coordinator, "cohort.deleted", "cohort",
               cohort_id, {"name": cohort_name})

    return jsonify({"message": "Cohort deleted"}), 200