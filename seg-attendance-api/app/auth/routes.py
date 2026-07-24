from flask import Blueprint, request, jsonify
from flask_jwt_extended import (
    create_access_token,
    jwt_required,
    get_jwt_identity,
)
from app.models import Coordinator, Hub
from app.extensions import db

auth_bp = Blueprint("auth", __name__)


@auth_bp.route("/register", methods=["POST"])
def register():
    data = request.get_json() or {}
    full_name = (data.get("full_name") or "").strip()
    phone = (data.get("phone") or "").strip()
    password = (data.get("password") or "").strip()
    hub_id = (data.get("hub_id") or "").strip()

    if not full_name or not phone or not password or not hub_id:
        return jsonify({
            "error": "Full name, phone, password and hub_id are required"
        }), 400

    if len(password) < 6:
        return jsonify({
            "error": "Password must be at least 6 characters"
        }), 400

    # Check phone not already taken
    existing = Coordinator.query.filter_by(phone=phone).first()
    if existing:
        return jsonify({
            "error": "A coordinator with this phone number already exists"
        }), 409

    # Verify hub exists
    try:
        hub = Hub.query.get(hub_id)
    except Exception:
        hub = None

    if not hub:
        return jsonify({"error": "Hub not found"}), 404

    # Create coordinator
    coordinator = Coordinator(
        full_name=full_name,
        phone=phone,
        hub_id=hub_id
    )
    coordinator.set_password(password)

    db.session.add(coordinator)
    db.session.commit()

    return jsonify({
        "message": "Account created successfully",
        "coordinator_id": str(coordinator.coordinator_id),
        "coordinator_name": coordinator.full_name,
        "hub_id": str(coordinator.hub_id),
        "hub_name": hub.name
    }), 201


@auth_bp.route("/login", methods=["POST"])
def login():
    data = request.get_json() or {}
    phone = (data.get("phone") or "").strip()
    password = (data.get("password") or "").strip()

    if not phone or not password:
        return jsonify({
            "error": "Phone number and password are required"
        }), 400

    coordinator = Coordinator.query.filter_by(phone=phone).first()

    if not coordinator or not coordinator.check_password(password):
        return jsonify({"error": "Invalid credentials"}), 401

    hub = Hub.query.get(coordinator.hub_id)
    hub_name = hub.name if hub else ""

    access_token = create_access_token(
        identity=str(coordinator.coordinator_id)
    )

    return jsonify({
        "access_token": access_token,
        "coordinator_name": coordinator.full_name,
        "coordinator_id": str(coordinator.coordinator_id),
        "hub_id": str(coordinator.hub_id),
        "hub_name": hub_name
    }), 200

from flask_jwt_extended import get_jwt_identity


@auth_bp.route("/me", methods=["GET"])
@jwt_required()
def get_me():
    coordinator_id = get_jwt_identity()
    coordinator = Coordinator.query.get(coordinator_id)
    if not coordinator:
        return jsonify({"error": "Coordinator not found"}), 404

    hub = Hub.query.get(coordinator.hub_id)
    result = coordinator.to_dict()
    result["hub_name"] = hub.name if hub else ""
    result["hub_location"] = hub.location if hub else ""
    return jsonify(result), 200


@auth_bp.route("/me", methods=["PATCH"])
@jwt_required()
def update_me():
    coordinator_id = get_jwt_identity()
    coordinator = Coordinator.query.get(coordinator_id)
    if not coordinator:
        return jsonify({"error": "Coordinator not found"}), 404

    data = request.get_json() or {}

    if "full_name" in data:
        name = (data.get("full_name") or "").strip()
        if len(name) < 3:
            return jsonify({
                "error": "Name must be at least 3 characters"
            }), 400
        coordinator.full_name = name

    db.session.commit()
    return jsonify(coordinator.to_dict()), 200


@auth_bp.route("/change-password", methods=["POST"])
@jwt_required()
def change_password():
    coordinator_id = get_jwt_identity()
    coordinator = Coordinator.query.get(coordinator_id)
    if not coordinator:
        return jsonify({"error": "Coordinator not found"}), 404

    data = request.get_json() or {}
    old_password = data.get("old_password") or ""
    new_password = data.get("new_password") or ""

    if not coordinator.check_password(old_password):
        return jsonify({
            "error": "Current password is incorrect"
        }), 401

    if len(new_password) < 6:
        return jsonify({
            "error": "New password must be at least 6 characters"
        }), 400

    coordinator.set_password(new_password)
    db.session.commit()
    return jsonify({"message": "Password updated"}), 200