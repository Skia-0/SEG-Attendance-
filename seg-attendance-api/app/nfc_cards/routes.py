from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from app.models import NFCCard, Learner
from app.extensions import db
from datetime import datetime

nfc_cards_bp = Blueprint("nfc_cards", __name__)

@nfc_cards_bp.route("/assign", methods=["POST"])
@jwt_required()
def assign_card():
    data = request.get_json() or {}
    uid = data.get("uid")
    learner_id = data.get("learner_id")
    cohort_id = data.get("cohort_id")

    if not uid or not learner_id or not cohort_id:
        return jsonify({"error": "uid, learner_id, and cohort_id are required"}), 400

    # Ensure learner exists
    try:
        learner = Learner.query.get(learner_id)
    except Exception:
        learner = None

    if not learner:
        return jsonify({"error": "Learner not found"}), 404

    # If this card was assigned to another learner, we can clear that learner's nfc_uid
    existing_card = NFCCard.query.filter_by(uid=uid).first()
    if existing_card and existing_card.learner_id:
        old_learner = Learner.query.get(existing_card.learner_id)
        if old_learner and str(old_learner.learner_id) != str(learner_id):
            old_learner.nfc_uid = None

    # If this learner had another card assigned, we can deactivate/clear those cards
    if learner.nfc_uid and learner.nfc_uid != uid:
        old_cards = NFCCard.query.filter_by(learner_id=learner.learner_id).all()
        for oc in old_cards:
            if oc.uid != uid:
                oc.learner_id = None
                oc.is_active = False

    # Create or update card
    if not existing_card:
        card = NFCCard(uid=uid)
        db.session.add(card)
    else:
        card = existing_card

    card.learner_id = learner.learner_id
    card.cohort_id = cohort_id
    card.is_active = True
    card.assigned_at = datetime.utcnow()

    # Update learner
    learner.nfc_uid = uid

    db.session.commit()

    return jsonify(card.to_dict()), 200

@nfc_cards_bp.route("/clear/<cohort_id>", methods=["POST"])
@jwt_required()
def clear_cohort_cards(cohort_id):
    # Action: Set is_active=False and learner_id=None for all cards in cohort
    # Set nfc_uid=None on all learners in cohort
    try:
        # Get all learners in the cohort
        learners = Learner.query.filter_by(cohort_id=cohort_id).all()
        for learner in learners:
            learner.nfc_uid = None

        # Get all cards in the cohort
        cards = NFCCard.query.filter_by(cohort_id=cohort_id).all()
        cleared_count = len(cards)
        for card in cards:
            card.is_active = False
            card.learner_id = None

        db.session.commit()
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": f"Failed to clear cards: {str(e)}"}), 500

    return jsonify({"cleared_count": cleared_count}), 200
