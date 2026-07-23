from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required
from app.models import Cohort, Learner, Session, AttendanceRecord
from app.extensions import db

cohorts_bp = Blueprint("cohorts", __name__)

@cohorts_bp.route("/<cohort_id>", methods=["GET"])
@jwt_required()
def get_cohort(cohort_id):
    try:
        cohort = Cohort.query.get(cohort_id)
    except Exception:
        cohort = None

    if not cohort:
        return jsonify({"error": "Cohort not found"}), 404

    learner_count = Learner.query.filter_by(cohort_id=cohort.cohort_id).count()

    cohort_data = cohort.to_dict()
    cohort_data["learner_count"] = learner_count

    return jsonify(cohort_data), 200

@cohorts_bp.route("/<cohort_id>/summary", methods=["GET"])
@jwt_required()
def get_cohort_summary(cohort_id):
    try:
        cohort = Cohort.query.get(cohort_id)
    except Exception:
        cohort = None

    if not cohort:
        return jsonify({"error": "Cohort not found"}), 404

    # Get total sessions in this cohort
    sessions = Session.query.filter_by(cohort_id=cohort.cohort_id).all()
    session_ids = [str(s.session_id) for s in sessions]
    total_sessions = len(sessions)

    # Get all learners in this cohort
    learners = Learner.query.filter_by(cohort_id=cohort.cohort_id).order_by(Learner.full_name).all()

    summary_list = []
    for learner in learners:
        sessions_attended = 0
        if total_sessions > 0:
            # Count complete attendance records for this learner on the cohort's sessions
            sessions_attended = AttendanceRecord.query.filter(
                AttendanceRecord.learner_id == learner.learner_id,
                AttendanceRecord.session_id.in_(session_ids),
                AttendanceRecord.is_complete == True
            ).count()

        # Business Logic Rules:
        # attendance_percent = (sessions where is_complete=True) / total_sessions * 100
        # meets_threshold = attendance_percent >= min_attendance_percent
        attendance_percent = (sessions_attended / total_sessions * 100.0) if total_sessions > 0 else 100.0
        meets_threshold = attendance_percent >= cohort.min_attendance_percent

        summary_list.append({
            "learner_id": str(learner.learner_id),
            "seg_id": learner.seg_id,
            "full_name": learner.full_name,
            "sessions_attended": sessions_attended,
            "total_sessions": total_sessions,
            "attendance_percent": round(attendance_percent, 2),
            "meets_threshold": meets_threshold,
            "certified": meets_threshold  # Added for clear map to "Certified (Yes/No)" in mobile/dashboard
        })

    return jsonify(summary_list), 200
