from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token
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