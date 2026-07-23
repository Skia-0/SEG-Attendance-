from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required
from app.models import Hub
from app.extensions import db

hubs_bp = Blueprint("hubs", __name__)


@hubs_bp.route("", methods=["POST"])
def create_hub():
    """
    Create a new hub — no JWT required because this is used
    during initial account setup before any user exists.
    """
    data = request.get_json() or {}
    name = (data.get("name") or "").strip()
    location = (data.get("location") or "").strip()

    if not name:
        return jsonify({"error": "Hub name is required"}), 400

    if not location:
        return jsonify({"error": "Hub location is required"}), 400

    # Check if hub with same name exists
    existing = Hub.query.filter_by(name=name).first()
    if existing:
        return jsonify({
            "error": "A hub with this name already exists"
        }), 409

    hub = Hub(name=name, location=location)
    db.session.add(hub)
    db.session.commit()

    return jsonify(hub.to_dict()), 201


@hubs_bp.route("/<hub_id>", methods=["GET"])
@jwt_required()
def get_hub(hub_id):
    try:
        hub = Hub.query.get(hub_id)
    except Exception:
        hub = None

    if not hub:
        return jsonify({"error": "Hub not found"}), 404

    return jsonify(hub.to_dict()), 200


@hubs_bp.route("", methods=["GET"])
@jwt_required()
def list_hubs():
    hubs = Hub.query.all()
    return jsonify([h.to_dict() for h in hubs]), 200