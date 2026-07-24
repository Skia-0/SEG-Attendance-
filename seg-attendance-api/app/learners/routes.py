from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from app.models import Learner, Cohort
from app.extensions import db

learners_bp = Blueprint("learners", __name__)

@learners_bp.route("", methods=["POST"])
@jwt_required()
def register_learner():
    data = request.get_json() or {}
    full_name = data.get("full_name")
    phone = data.get("phone")
    cohort_id = data.get("cohort_id")
    nfc_uid = data.get("nfc_uid")

    if not full_name or not cohort_id:
        return jsonify({"error": "Full name and cohort ID are required"}), 400

    try:
        cohort = Cohort.query.get(cohort_id)
    except Exception:
        cohort = None

    if not cohort:
        return jsonify({"error": "Cohort not found"}), 404

    # Generate SEG ID:
    # Prefix = first 3 letters of cohort name, uppercased (ignoring spaces, padded if needed)
    prefix_base = cohort.name.replace(" ", "")
    prefix = prefix_base[:3].upper().ljust(3, "X")

    # Increment number per cohort
    count = Learner.query.filter_by(cohort_id=cohort.cohort_id).count()
    num = count + 1
    while True:
        seg_id = f"SEG-{prefix}-{num:04d}"
        exists = Learner.query.filter_by(seg_id=seg_id).first()
        if not exists:
            break
        num += 1

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

    return jsonify(learner.to_dict()), 201

@learners_bp.route("", methods=["GET"])
@jwt_required()
def get_learners():
    cohort_id = request.args.get("cohort_id")
    if not cohort_id:
        return jsonify({"error": "cohort_id query parameter is required"}), 400

    try:
        learners = Learner.query.filter_by(cohort_id=cohort_id).order_by(Learner.full_name).all()
    except Exception:
        learners = []

    return jsonify([l.to_dict() for l in learners]), 200

@learners_bp.route("/nfc/<uid>", methods=["GET"])
@jwt_required()
def get_learner_by_nfc(uid):
    learner = Learner.query.filter_by(nfc_uid=uid).first()
    if not learner:
        return jsonify({"error": "Learner with this NFC UID not found"}), 404

    return jsonify(learner.to_dict()), 200

@learners_bp.route("/<learner_id>/fingerprint", methods=["PATCH"])
@jwt_required()
def update_fingerprint(learner_id):
    try:
        learner = Learner.query.get(learner_id)
    except Exception:
        learner = None

    if not learner:
        return jsonify({"error": "Learner not found"}), 404

    data = request.get_json() or {}
    fingerprint_enrolled = data.get("fingerprint_enrolled")

    if fingerprint_enrolled is None:
        return jsonify({"error": "fingerprint_enrolled field is required"}), 400

    learner.fingerprint_enrolled = bool(fingerprint_enrolled)
    db.session.commit()

    return jsonify(learner.to_dict()), 200

@learners_bp.route("/<learner_id>", methods=["DELETE"])
@jwt_required()
def delete_learner(learner_id):
    try:
        learner = Learner.query.get(learner_id)
    except Exception:
        learner = None

    if not learner:
        return jsonify({"error": "Learner not found"}), 404

    db.session.delete(learner)
    db.session.commit()
    return jsonify({"message": "Learner deleted"}), 200


@learners_bp.route("/<learner_id>", methods=["PATCH"])
@jwt_required()
def update_learner(learner_id):
    try:
        learner = Learner.query.get(learner_id)
    except Exception:
        learner = None

    if not learner:
        return jsonify({"error": "Learner not found"}), 404

    data = request.get_json() or {}

    if "full_name" in data:
        name = (data.get("full_name") or "").strip()
        if len(name) < 3:
            return jsonify({
                "error": "Name must be at least 3 characters"
            }), 400
        learner.full_name = name

    if "phone" in data:
        learner.phone = (data.get("phone") or "").strip() or None

    if "nfc_uid" in data:
        learner.nfc_uid = (data.get("nfc_uid") or "").strip() or None

    db.session.commit()
    return jsonify(learner.to_dict()), 200


@learners_bp.route("/<learner_id>", methods=["GET"])
@jwt_required()
def get_learner(learner_id):
    try:
        learner = Learner.query.get(learner_id)
    except Exception:
        learner = None

    if not learner:
        return jsonify({"error": "Learner not found"}), 404

    return jsonify(learner.to_dict()), 200