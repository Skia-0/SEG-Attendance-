from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from app.models import Session, Cohort, AttendanceRecord
from app.extensions import db
from app.utils import (
    get_current_coordinator,
    same_hub,
    forbidden,
    log_action,
)
from datetime import datetime

sessions_bp = Blueprint("sessions", __name__)


def _get_owned_session_or_response(session_id, coordinator):
    """
    Shared lookup: resolves session, then checks coordinator's hub
    against session's cohort's hub. Returns (session, None) on
    success, or (None, response) on failure.
    """
    try:
        session = Session.query.get(session_id)
    except Exception:
        session = None

    if not session:
        return None, (jsonify({"error": "Session not found"}), 404)

    cohort = Cohort.query.get(session.cohort_id)
    if not cohort or not same_hub(coordinator, cohort.hub_id):
        return None, forbidden("Not authorized to access this session")

    return session, None


@sessions_bp.route("", methods=["POST"])
@jwt_required()
def create_session():
    coordinator = get_current_coordinator()
    if not coordinator:
        return jsonify({"error": "Coordinator not found"}), 404

    data = request.get_json() or {}
    cohort_id = data.get("cohort_id")
    title = (data.get("title") or "").strip()

    if not cohort_id or not title:
        return jsonify({
            "error": "cohort_id and title are required"
        }), 400

    try:
        cohort = Cohort.query.get(cohort_id)
    except Exception:
        cohort = None

    if not cohort:
        return jsonify({"error": "Cohort not found"}), 404

    if not same_hub(coordinator, cohort.hub_id):
        return forbidden(
            "Not authorized to create a session for this cohort"
        )

    session = Session(
        cohort_id=cohort.cohort_id,
        coordinator_id=coordinator.coordinator_id,
        title=title,
        started_at=datetime.utcnow(),
        ended_at=None,
        checkin_open=False,
        checkout_open=False
    )

    db.session.add(session)
    db.session.commit()

    log_action(coordinator, "session.created", "session",
               session.session_id, {"title": title})

    return jsonify(session.to_dict()), 201


@sessions_bp.route("", methods=["GET"])
@jwt_required()
def list_sessions():
    coordinator = get_current_coordinator()
    if not coordinator:
        return jsonify({"error": "Coordinator not found"}), 404

    cohort_id = request.args.get("cohort_id")

    if not cohort_id:
        return jsonify({
            "error": "cohort_id query parameter required"
        }), 400

    try:
        cohort = Cohort.query.get(cohort_id)
    except Exception:
        cohort = None

    if not cohort:
        return jsonify({"error": "Cohort not found"}), 404

    if not same_hub(coordinator, cohort.hub_id):
        return forbidden(
            "Not authorized to view sessions for this cohort"
        )

    sessions = Session.query.filter_by(
        cohort_id=cohort_id
    ).order_by(Session.started_at.desc()).all()

    results = []
    for s in sessions:
        data = s.to_dict()
        data["attendance_count"] = AttendanceRecord.query.filter_by(
            session_id=s.session_id,
            is_complete=True
        ).count()
        results.append(data)

    return jsonify(results), 200


@sessions_bp.route("/<session_id>", methods=["GET"])
@jwt_required()
def get_session(session_id):
    coordinator = get_current_coordinator()
    if not coordinator:
        return jsonify({"error": "Coordinator not found"}), 404

    session, err = _get_owned_session_or_response(session_id, coordinator)
    if err:
        return err

    return jsonify(session.to_dict()), 200


@sessions_bp.route("/<session_id>/checkin", methods=["PATCH"])
@jwt_required()
def update_checkin_state(session_id):
    coordinator = get_current_coordinator()
    if not coordinator:
        return jsonify({"error": "Coordinator not found"}), 404

    session, err = _get_owned_session_or_response(session_id, coordinator)
    if err:
        return err

    if session.ended_at is not None:
        return jsonify({
            "error": "Cannot change check-in state on an ended session"
        }), 400

    data = request.get_json() or {}
    open_state = data.get("open")

    if open_state is None:
        return jsonify({"error": "open field is required"}), 400

    is_open = bool(open_state)
    session.checkin_open = is_open

    if is_open:
        session.checkout_open = False

    db.session.commit()

    log_action(coordinator,
               "session.checkin_opened" if is_open
               else "session.checkin_closed",
               "session", session.session_id)

    return jsonify(session.to_dict()), 200


@sessions_bp.route("/<session_id>/checkout", methods=["PATCH"])
@jwt_required()
def update_checkout_state(session_id):
    coordinator = get_current_coordinator()
    if not coordinator:
        return jsonify({"error": "Coordinator not found"}), 404

    session, err = _get_owned_session_or_response(session_id, coordinator)
    if err:
        return err

    if session.ended_at is not None:
        return jsonify({
            "error": "Cannot change check-out state on an ended session"
        }), 400

    data = request.get_json() or {}
    open_state = data.get("open")

    if open_state is None:
        return jsonify({"error": "open field is required"}), 400

    is_open = bool(open_state)
    session.checkout_open = is_open

    if is_open:
        session.checkin_open = False

    db.session.commit()

    log_action(coordinator,
               "session.checkout_opened" if is_open
               else "session.checkout_closed",
               "session", session.session_id)

    return jsonify(session.to_dict()), 200


@sessions_bp.route("/<session_id>/end", methods=["PATCH"])
@jwt_required()
def end_session(session_id):
    coordinator = get_current_coordinator()
    if not coordinator:
        return jsonify({"error": "Coordinator not found"}), 404

    session, err = _get_owned_session_or_response(session_id, coordinator)
    if err:
        return err

    session.ended_at = datetime.utcnow()
    session.checkin_open = False
    session.checkout_open = False

    db.session.commit()

    log_action(coordinator, "session.ended", "session",
               session.session_id)

    return jsonify(session.to_dict()), 200