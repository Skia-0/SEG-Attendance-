from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from app.models import NFCCard, Learner, Cohort
from app.extensions import db
from app.utils import (
    get_current_coordinator,
    same_hub,
    forbidden,
    log_action,
)
from datetime import datetime

nfc_cards_bp = Blueprint("nfc_cards", __name__)


@nfc_cards_bp.route("/assign", methods=["POST"])
@jwt_required()
def assign_card():
    coordinator = get_current_coordinator()
    if not coordinator:
        return jsonify({"error": "Coordinator not found"}), 404

    data = request.get_json() or {}
    uid = data.get("uid")
    learner_id = data.get("learner_id")
    cohort_id = data.get("cohort_id")

    if not uid or not learner_id or not cohort_id:
        return jsonify({
            "error": "uid, learner_id, and cohort_id are required"
        }), 400

    try:
        learner = Learner.query.get(learner_id)
    except Exception:
        learner = None

    if not learner:
        return jsonify({"error": "Learner not found"}), 404

    learner_cohort = Cohort.query.get(learner.cohort_id)
    if not learner_cohort or not same_hub(coordinator, learner_cohort.hub_id):
        return forbidden(
            "Not authorized to assign a card to this learner"
        )

    try:
        target_cohort = Cohort.query.get(cohort_id)
    except Exception:
        target_cohort = None

    if not target_cohort or not same_hub(coordinator, target_cohort.hub_id):
        return forbidden(
            "Not authorized to assign cards in this cohort"
        )

    if str(target_cohort.cohort_id) != str(learner.cohort_id):
        return jsonify({
            "error": "cohort_id does not match the learner's cohort"
        }), 400

    try:
        existing_card = NFCCard.query.filter_by(uid=uid).first()

        # If this card was previously assigned, verify it belonged to
        # this coordinator's hub before clearing it.
        if existing_card and existing_card.learner_id:
            if existing_card.hub_id and not same_hub(
                coordinator, existing_card.hub_id
            ):
                return jsonify({
                    "error": "This card is assigned to a learner in another hub"
                }), 409

            old_learner = Learner.query.get(existing_card.learner_id)
            if old_learner:
                old_learner.nfc_uid = None

        # If learner already had a different card, deactivate it
        if learner.nfc_uid and learner.nfc_uid != uid:
            old_cards = NFCCard.query.filter_by(
                uid=learner.nfc_uid
            ).all()
            for oc in old_cards:
                oc.learner_id = None
                oc.is_active = False

        if not existing_card:
            card = NFCCard(uid=uid)
            db.session.add(card)
        else:
            card = existing_card

        card.learner_id = learner.learner_id
        card.cohort_id = cohort_id
        card.hub_id = coordinator.hub_id
        card.is_active = True
        card.assigned_at = datetime.utcnow()

        learner.nfc_uid = uid

        db.session.commit()

    except Exception as e:
        db.session.rollback()
        return jsonify({
            "error": f"Failed to assign card: {str(e)}"
        }), 500

    log_action(coordinator, "nfc_card.assigned", "nfc_card",
               card.card_id,
               {"uid": uid, "learner_id": str(learner.learner_id)})

    return jsonify(card.to_dict()), 200


@nfc_cards_bp.route("/clear/<cohort_id>", methods=["POST"])
@jwt_required()
def clear_cohort_cards(cohort_id):
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
        return forbidden(
            "Not authorized to clear cards for this cohort"
        )

    try:
        cards = NFCCard.query.filter_by(cohort_id=cohort_id).all()
        cleared_count = len(cards)

        for card in cards:
            card.is_active = False
            card.learner_id = None

        learners = Learner.query.filter_by(cohort_id=cohort_id).all()
        for learner in learners:
            learner.nfc_uid = None

        db.session.commit()

    except Exception as e:
        db.session.rollback()
        return jsonify({
            "error": f"Failed to clear cards: {str(e)}"
        }), 500

    log_action(coordinator, "nfc_card.cleared_cohort", "cohort",
               cohort_id, {"cleared_count": cleared_count})

    return jsonify({"cleared_count": cleared_count}), 200