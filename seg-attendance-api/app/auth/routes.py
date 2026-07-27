import re
from datetime import datetime, timedelta
from flask import Blueprint, request, jsonify
from flask_jwt_extended import (
    create_access_token,
    create_refresh_token,
    jwt_required,
    get_jwt_identity,
)
from app.models import Coordinator, Hub
from app.extensions import db, limiter
from app.utils import log_action

auth_bp = Blueprint("auth", __name__)

# Lockout configuration
MAX_FAILED_ATTEMPTS = 5
LOCKOUT_DURATION_MINUTES = 30


def _validate_password(password):
    if not password or len(password) < 8:
        return "Password must be at least 8 characters"
    if len(password) > 32:
        return "Password must not exceed 32 characters"
    if not re.search(r"[A-Za-z]", password):
        return "Password must contain at least one letter"
    if not re.search(r"\d", password):
        return "Password must contain at least one number"
    return None


def _log_failed_login(phone, reason):
    """
    Log failed login attempt without user context (coordinator may not exist).
    Uses direct DB insert to avoid circular deps.
    """
    try:
        from app.models import AuditLog
        entry = AuditLog(
            coordinator_id=None,
            hub_id=None,
            action="coordinator.login_failed",
            resource_type="coordinator",
            resource_id=phone,
            details={"reason": reason},
        )
        db.session.add(entry)
        db.session.commit()
    except Exception:
        try:
            db.session.rollback()
        except Exception:
            pass


@auth_bp.route("/register", methods=["POST"])
@limiter.limit("5 per hour")
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

    pw_error = _validate_password(password)
    if pw_error:
        return jsonify({"error": pw_error}), 400

    existing = Coordinator.query.filter_by(phone=phone).first()
    if existing:
        return jsonify({
            "error": "A coordinator with this phone number already exists"
        }), 409

    try:
        hub = Hub.query.get(hub_id)
    except Exception:
        hub = None

    if not hub:
        return jsonify({"error": "Hub not found"}), 404

    coordinator = Coordinator(
        full_name=full_name,
        phone=phone,
        hub_id=hub_id
    )
    coordinator.set_password(password)

    db.session.add(coordinator)
    db.session.commit()

    log_action(coordinator, "coordinator.registered",
               "coordinator", coordinator.coordinator_id,
               {"phone": phone, "hub_id": str(hub_id)})

    return jsonify({
        "message": "Account created successfully",
        "coordinator_id": str(coordinator.coordinator_id),
        "coordinator_name": coordinator.full_name,
        "hub_id": str(coordinator.hub_id),
        "hub_name": hub.name
    }), 201


@auth_bp.route("/login", methods=["POST"])
@limiter.limit("5 per minute")
def login():
    data = request.get_json() or {}
    phone = (data.get("phone") or "").strip()
    password = (data.get("password") or "").strip()

    if not phone or not password:
        return jsonify({
            "error": "Phone number and password are required"
        }), 400

    coordinator = Coordinator.query.filter_by(phone=phone).first()

    # Non-existent account — return generic error but log for monitoring
    if not coordinator:
        _log_failed_login(phone, "unknown_phone")
        return jsonify({"error": "Invalid credentials"}), 401

    # Check if account is locked
    now = datetime.utcnow()
    if coordinator.locked_until and coordinator.locked_until > now:
        minutes_left = int(
            (coordinator.locked_until - now).total_seconds() // 60
        ) + 1
        _log_failed_login(phone, "account_locked")
        return jsonify({
            "error": f"Account locked due to too many failed attempts. "
                     f"Try again in {minutes_left} minute(s)."
        }), 423  # 423 Locked

    # Check password
    if not coordinator.check_password(password):
        coordinator.failed_login_attempts = (
            (coordinator.failed_login_attempts or 0) + 1
        )
        coordinator.last_failed_login_at = now

        # Lock account if too many failures
        if coordinator.failed_login_attempts >= MAX_FAILED_ATTEMPTS:
            coordinator.locked_until = now + timedelta(
                minutes=LOCKOUT_DURATION_MINUTES
            )
            db.session.commit()

            _log_failed_login(phone,
                              f"account_locked_after_{coordinator.failed_login_attempts}_attempts")

            log_action(coordinator, "coordinator.account_locked",
                       "coordinator", coordinator.coordinator_id,
                       {"failed_attempts": coordinator.failed_login_attempts,
                        "locked_for_minutes": LOCKOUT_DURATION_MINUTES})

            return jsonify({
                "error": f"Too many failed attempts. "
                         f"Account locked for {LOCKOUT_DURATION_MINUTES} minutes."
            }), 423

        remaining = MAX_FAILED_ATTEMPTS - coordinator.failed_login_attempts
        db.session.commit()

        _log_failed_login(phone, "wrong_password")

        return jsonify({
            "error": f"Invalid credentials. {remaining} attempt(s) remaining."
        }), 401

    # Success — reset counters
    coordinator.failed_login_attempts = 0
    coordinator.locked_until = None
    coordinator.last_failed_login_at = None

    hub = Hub.query.get(coordinator.hub_id)
    hub_name = hub.name if hub else ""

    identity = str(coordinator.coordinator_id)
    access_token = create_access_token(identity=identity)
    refresh_token = create_refresh_token(identity=identity)

    db.session.commit()

    log_action(coordinator, "coordinator.login",
               "coordinator", coordinator.coordinator_id)

    return jsonify({
        "access_token": access_token,
        "refresh_token": refresh_token,
        "coordinator_name": coordinator.full_name,
        "coordinator_id": str(coordinator.coordinator_id),
        "hub_id": str(coordinator.hub_id),
        "hub_name": hub_name
    }), 200


@auth_bp.route("/refresh", methods=["POST"])
@jwt_required(refresh=True)
@limiter.limit("60 per hour")
def refresh():
    identity = get_jwt_identity()
    coordinator = Coordinator.query.get(identity)
    if not coordinator:
        return jsonify({"error": "Coordinator not found"}), 404

    access_token = create_access_token(identity=identity)
    return jsonify({"access_token": access_token}), 200


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

    log_action(coordinator, "coordinator.profile_updated",
               "coordinator", coordinator.coordinator_id)

    return jsonify(coordinator.to_dict()), 200


@auth_bp.route("/change-password", methods=["POST"])
@jwt_required()
@limiter.limit("5 per hour")
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

    pw_error = _validate_password(new_password)
    if pw_error:
        return jsonify({"error": pw_error}), 400

    coordinator.set_password(new_password)
    db.session.commit()

    log_action(coordinator, "coordinator.password_changed",
               "coordinator", coordinator.coordinator_id)

    return jsonify({"message": "Password updated"}), 200