from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from app.models import AttendanceRecord, Session, Learner
from app.extensions import db
from datetime import datetime

attendance_bp = Blueprint("attendance", __name__)

@attendance_bp.route("/checkin", methods=["POST"])
@jwt_required()
def checkin():
    data = request.get_json() or {}
    session_id = data.get("session_id")
    learner_id = data.get("learner_id")
    verification_method = data.get("verification_method")

    if not session_id or not learner_id or not verification_method:
        return jsonify({"error": "session_id, learner_id, and verification_method are required"}), 400

    if verification_method not in ["fingerprint", "nfc"]:
        return jsonify({"error": "verification_method must be either 'fingerprint' or 'nfc'"}), 400

    # Validate session
    try:
        session = Session.query.get(session_id)
    except Exception:
        session = None

    if not session:
        return jsonify({"error": "Session not found"}), 404

    if session.ended_at is not None:
        return jsonify({"error": "Session has already ended"}), 400

    if not session.checkin_open:
        return jsonify({"error": "Check-in is not open for this session"}), 400

    # Validate learner
    try:
        learner = Learner.query.get(learner_id)
    except Exception:
        learner = None

    if not learner:
        return jsonify({"error": "Learner not found"}), 404

    # Check duplicate
    record = AttendanceRecord.query.filter_by(session_id=session.session_id, learner_id=learner.learner_id).first()
    if record and record.checked_in_at is not None:
        return jsonify({"error": "Learner has already checked in for this session"}), 409

    if not record:
        record = AttendanceRecord(
            session_id=session.session_id,
            learner_id=learner.learner_id,
            checked_in_at=datetime.utcnow(),
            verification_method=verification_method,
            is_complete=False
        )
        db.session.add(record)
    else:
        record.checked_in_at = datetime.utcnow()
        record.verification_method = verification_method

    db.session.commit()

    return jsonify(record.to_dict()), 200

@attendance_bp.route("/checkout", methods=["POST"])
@jwt_required()
def checkout():
    data = request.get_json() or {}
    session_id = data.get("session_id")
    learner_id = data.get("learner_id")
    verification_method = data.get("verification_method")

    if not session_id or not learner_id or not verification_method:
        return jsonify({"error": "session_id, learner_id, and verification_method are required"}), 400

    if verification_method not in ["fingerprint", "nfc"]:
        return jsonify({"error": "verification_method must be either 'fingerprint' or 'nfc'"}), 400

    # Validate session
    try:
        session = Session.query.get(session_id)
    except Exception:
        session = None

    if not session:
        return jsonify({"error": "Session not found"}), 404

    if session.ended_at is not None:
        return jsonify({"error": "Session has already ended"}), 400

    if not session.checkout_open:
        return jsonify({"error": "Check-out is not open for this session"}), 400

    # Validate learner
    try:
        learner = Learner.query.get(learner_id)
    except Exception:
        learner = None

    if not learner:
        return jsonify({"error": "Learner not found"}), 404

    # Check record
    record = AttendanceRecord.query.filter_by(session_id=session.session_id, learner_id=learner.learner_id).first()
    if not record or record.checked_in_at is None:
        return jsonify({"error": "Learner must check in first before checking out"}), 400

    if record.checked_out_at is not None:
        return jsonify({"error": "Learner has already checked out for this session"}), 409

    record.checked_out_at = datetime.utcnow()
    record.verification_method = verification_method
    record.is_complete = True

    db.session.commit()

    return jsonify(record.to_dict()), 200

@attendance_bp.route("/<session_id>", methods=["GET"])
@jwt_required()
def get_attendance_records(session_id):
    try:
        session = Session.query.get(session_id)
    except Exception:
        session = None

    if not session:
        return jsonify({"error": "Session not found"}), 404

    records = AttendanceRecord.query.filter_by(session_id=session.session_id).all()
    results = []
    for r in records:
        results.append({
            "record_id": str(r.record_id),
            "session_id": str(r.session_id),
            "learner_id": str(r.learner_id),
            "seg_id": r.learner.seg_id,
            "full_name": r.learner.full_name,
            "checked_in_at": r.checked_in_at.isoformat() if r.checked_in_at else None,
            "checked_out_at": r.checked_out_at.isoformat() if r.checked_out_at else None,
            "verification_method": r.verification_method,
            "is_complete": r.is_complete
        })

    return jsonify(results), 200
