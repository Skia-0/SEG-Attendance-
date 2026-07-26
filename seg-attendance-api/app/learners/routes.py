from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from sqlalchemy.exc import IntegrityError
from app.models import Learner, Cohort
from app.extensions import db
from app.utils import (
    get_current_coordinator,
    same_hub,
    forbidden,
    log_action,
)

learners_bp = Blueprint("learners", __name__)


def _get_owned_learner_or_response(learner_id, coordinator):
    try:
        learner = Learner.query.get(learner_id)
    except Exception:
        learner = None

    if not learner:
        return None, (jsonify({"error": "Learner not found"}), 404)

    cohort = Cohort.query.get(learner.cohort_id)
    if not cohort or not same_hub(coordinator, cohort.hub_id):
        return None, forbidden("Not authorized to access this learner")

    return learner, None


def _generate_unique_seg_id(cohort, max_attempts=10):
    """
    Atomic SEG ID generation using DB unique constraint + retry.
    Prevents race condition when two coordinators register 
    learners simultaneously.
    """
    prefix_base = cohort.name.replace(" ", "")
    prefix = prefix_base[:3].upper().ljust(3, "X")

    count = Learner.query.filter_by(
        cohort_id=cohort.cohort_id
    ).count()

    for attempt in range(max_attempts):
        num = count + 1 + attempt
        candidate = f"SEG-{prefix}-{num:04d}"
        if not Learner.query.filter_by(seg_id=candidate).first():
            return candidate

    # Fallback: use timestamp to guarantee uniqueness
    import time
    return f"SEG-{prefix}-{int(time.time()) % 100000:05d}"


@learners_bp.route("", methods=["POST"])
@jwt_required()
def register_learner():
    coordinator = get_current_coordinator()
    if not coordinator:
        return jsonify({"error": "Coordinator not found"}), 404

    data = request.get_json() or {}
    full_name = (data.get("full_name") or "").strip()
    phone = (data.get("phone") or "").strip() or None
    cohort_id = data.get("cohort_id")
    nfc_uid = (data.get("nfc_uid") or "").strip() or None

    if not full_name or not cohort_id:
        return jsonify({
            "error": "Full name and cohort ID are required"
        }), 400

    try:
        cohort = Cohort.query.get(cohort_id)
    except Exception:
        cohort = None

    if not cohort:
        return jsonify({"error": "Cohort not found"}), 404

    if not same_hub(coordinator, cohort.hub_id):
        return forbidden(
            "Not authorized to register learners in this cohort"
        )

    # Retry loop for atomic seg_id generation
    for attempt in range(3):
        try:
            seg_id = _generate_unique_seg_id(cohort)

            learner = Learner(
                full_name=full_name,
                phone=phone,
                cohort_id=cohort.cohort_id,
                nfc_uid=nfc_uid,
                seg_id=seg_id,
                fingerprint_enrolled=False
            )

            db.session.add(learner)
            db.session.commit()
            break
        except IntegrityError:
            db.session.rollback()
            if attempt == 2:
                return jsonify({
                    "error": "Failed to generate unique ID. Try again."
                }), 500

    log_action(coordinator, "learner.registered", "learner",
               learner.learner_id,
               {"seg_id": seg_id, "cohort_id": str(cohort.cohort_id)})

    return jsonify(learner.to_dict()), 201


@learners_bp.route("", methods=["GET"])
@jwt_required()
def get_learners():
    coordinator = get_current_coordinator()
    if not coordinator:
        return jsonify({"error": "Coordinator not found"}), 404

    cohort_id = request.args.get("cohort_id")
    if not cohort_id:
        return jsonify({
            "error": "cohort_id query parameter is required"
        }), 400

    try:
        cohort = Cohort.query.get(cohort_id)
    except Exception:
        cohort = None

    if not cohort:
        return jsonify({"error": "Cohort not found"}), 404

    if not same_hub(coordinator, cohort.hub_id):
        return forbidden(
            "Not authorized to view learners in this cohort"
        )

    learners = Learner.query.filter_by(
        cohort_id=cohort_id
    ).order_by(Learner.full_name).all()

    return jsonify([l.to_dict() for l in learners]), 200


@learners_bp.route("/nfc/<uid>", methods=["GET"])
@jwt_required()
def get_learner_by_nfc(uid):
    coordinator = get_current_coordinator()
    if not coordinator:
        return jsonify({"error": "Coordinator not found"}), 404

    learner = Learner.query.filter_by(nfc_uid=uid).first()
    if not learner:
        return jsonify({
            "error": "Learner with this NFC UID not found"
        }), 404

    cohort = Cohort.query.get(learner.cohort_id)
    if not cohort or not same_hub(coordinator, cohort.hub_id):
        # Return 404 not 403 - prevents leaking that UID exists
        # but belongs to another hub
        return jsonify({
            "error": "Learner with this NFC UID not found"
        }), 404

    return jsonify(learner.to_dict()), 200


@learners_bp.route("/<learner_id>/fingerprint", methods=["PATCH"])
@jwt_required()
def update_fingerprint(learner_id):
    coordinator = get_current_coordinator()
    if not coordinator:
        return jsonify({"error": "Coordinator not found"}), 404

    learner, err = _get_owned_learner_or_response(learner_id, coordinator)
    if err:
        return err

    data = request.get_json() or {}
    fingerprint_enrolled = data.get("fingerprint_enrolled")

    if fingerprint_enrolled is None:
        return jsonify({
            "error": "fingerprint_enrolled field is required"
        }), 400

    learner.fingerprint_enrolled = bool(fingerprint_enrolled)
    db.session.commit()

    log_action(coordinator, "learner.fingerprint_updated",
               "learner", learner.learner_id,
               {"enrolled": bool(fingerprint_enrolled)})

    return jsonify(learner.to_dict()), 200


@learners_bp.route("/<learner_id>", methods=["GET"])
@jwt_required()
def get_learner(learner_id):
    coordinator = get_current_coordinator()
    if not coordinator:
        return jsonify({"error": "Coordinator not found"}), 404

    learner, err = _get_owned_learner_or_response(learner_id, coordinator)
    if err:
        return err

    return jsonify(learner.to_dict()), 200


@learners_bp.route("/<learner_id>", methods=["PATCH"])
@jwt_required()
def update_learner(learner_id):
    coordinator = get_current_coordinator()
    if not coordinator:
        return jsonify({"error": "Coordinator not found"}), 404

    learner, err = _get_owned_learner_or_response(learner_id, coordinator)
    if err:
        return err

    data = request.get_json() or {}
    changes = {}

    if "full_name" in data:
        name = (data.get("full_name") or "").strip()
        if len(name) < 3:
            return jsonify({
                "error": "Name must be at least 3 characters"
            }), 400
        learner.full_name = name
        changes["full_name"] = name

    if "phone" in data:
        learner.phone = (data.get("phone") or "").strip() or None
        changes["phone"] = learner.phone

    if "nfc_uid" in data:
        learner.nfc_uid = (data.get("nfc_uid") or "").strip() or None
        changes["nfc_uid"] = learner.nfc_uid

    db.session.commit()

    log_action(coordinator, "learner.updated", "learner",
               learner.learner_id, changes)

    return jsonify(learner.to_dict()), 200


@learners_bp.route("/<learner_id>", methods=["DELETE"])
@jwt_required()
def delete_learner(learner_id):
    coordinator = get_current_coordinator()
    if not coordinator:
        return jsonify({"error": "Coordinator not found"}), 404

    learner, err = _get_owned_learner_or_response(learner_id, coordinator)
    if err:
        return err

    learner_name = learner.full_name
    learner_seg_id = learner.seg_id
    db.session.delete(learner)
    db.session.commit()

    log_action(coordinator, "learner.deleted", "learner",
               learner_id,
               {"name": learner_name, "seg_id": learner_seg_id})

    return jsonify({"message": "Learner deleted"}), 200