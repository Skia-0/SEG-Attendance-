from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token
from app.models import Coordinator
from app.extensions import db

auth_bp = Blueprint("auth", __name__)

@auth_bp.route("/login", methods=["POST"])
def login():
    data = request.get_json() or {}
    phone = data.get("phone")
    password = data.get("password")

    if not phone or not password:
        return jsonify({"error": "Phone number and password are required"}), 400

    coordinator = Coordinator.query.filter_by(phone=phone).first()

    if not coordinator or not coordinator.check_password(password):
        return jsonify({"error": "Invalid credentials"}), 401

    # Create JWT token. Use the coordinator_id as the identity (converted to string)
    access_token = create_access_token(identity=str(coordinator.coordinator_id))

    return jsonify({
        "access_token": access_token,
        "coordinator_name": coordinator.full_name,
        "coordinator_id": str(coordinator.coordinator_id),
        "hub_id": str(coordinator.hub_id)
    }), 200
