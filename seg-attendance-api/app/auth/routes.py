import os
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
from app.services.email_service import EmailService

auth_bp = Blueprint("auth", __name__)

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


def _validate_email(email):
    email = email.strip().lower()
    if not email or "@" not in email:
        return None, "Please enter a valid email address"

    # Enforce domain restriction if configured
    allowed_domain = os.environ.get("ALLOWED_EMAIL_DOMAIN")
    if allowed_domain:
        if not email.endswith(f"@{allowed_domain.lower()}"):
            return None, f"Only @{allowed_domain} email addresses are allowed"

    return email, None


def _log_failed_login(email, reason):
    try:
        from app.models import AuditLog
        entry = AuditLog(
            coordinator_id=None,
            hub_id=None,
            action="coordinator.login_failed",
            resource_type="coordinator",
            resource_id=email,
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
    """
    Step 1 of registration — creates unverified account, sends OTP.
    Coordinator must then call /verify-email with OTP to activate.
    """
    data = request.get_json() or {}
    full_name = (data.get("full_name") or "").strip()
    email_raw = (data.get("email") or "").strip().lower()
    password = (data.get("password") or "").strip()
    hub_id = (data.get("hub_id") or "").strip()

    if not full_name or not email_raw or not password or not hub_id:
        return jsonify({
            "error": "Full name, email, password and hub_id are required"
        }), 400

    from app.utils import validate_length

    name_err = validate_length(full_name, "Full name", 3, 100)
    if name_err:
        return jsonify({"error": name_err}), 400

    email, email_error = _validate_email(email_raw)
    if email_error:
        return jsonify({"error": email_error}), 400

    pw_error = _validate_password(password)
    if pw_error:
        return jsonify({"error": pw_error}), 400

    # Check email not already registered
    existing = Coordinator.query.filter_by(email=email).first()
    if existing:
        # Generic error — avoid enumeration
        return jsonify({
            "error": "Registration failed. Please contact your administrator if you need help."
        }), 409

    try:
        hub = Hub.query.get(hub_id)
    except Exception:
        hub = None

    if not hub:
        return jsonify({"error": "Hub not found"}), 404

    coordinator = Coordinator(
        full_name=full_name,
        email=email,
        email_verified=False,
        hub_id=hub_id,
        role="coordinator"
    )
    coordinator.set_password(password)

    db.session.add(coordinator)
    db.session.commit()

    # Generate and send OTP
    otp = EmailService.generate_otp(email, purpose="register")
    sent = EmailService.send_registration_otp(email, full_name, otp)

    log_action(coordinator, "coordinator.registered_pending_verification",
               "coordinator", coordinator.coordinator_id,
               {"email": email, "hub_id": str(hub_id)})

    return jsonify({
        "message": "Account created. Check your email for verification code.",
        "email": email,
        "requires_verification": True,
        "email_sent": sent
    }), 201


@auth_bp.route("/verify-email", methods=["POST"])
@limiter.limit("10 per hour")
def verify_email():
    data = request.get_json() or {}
    email = (data.get("email") or "").strip().lower()
    code = (data.get("code") or "").strip()

    if not email or not code:
        return jsonify({
            "error": "Email and code are required"
        }), 400

    valid, error = EmailService.verify_otp(email, code, "register")
    if not valid:
        return jsonify({"error": error}), 400

    coordinator = Coordinator.query.filter_by(email=email).first()
    if not coordinator:
        return jsonify({"error": "Account not found"}), 404

    coordinator.email_verified = True
    db.session.commit()

    hub = Hub.query.get(coordinator.hub_id)

    identity = str(coordinator.coordinator_id)
    access_token = create_access_token(identity=identity)
    refresh_token = create_refresh_token(identity=identity)

    log_action(coordinator, "coordinator.email_verified",
               "coordinator", coordinator.coordinator_id)

    return jsonify({
        "message": "Email verified successfully",
        "access_token": access_token,
        "refresh_token": refresh_token,
        "coordinator_name": coordinator.full_name,
        "coordinator_id": str(coordinator.coordinator_id),
        "hub_id": str(coordinator.hub_id),
        "hub_name": hub.name if hub else "",
        "email": coordinator.email
    }), 200

@auth_bp.route("/verify-otp", methods=["POST"])
@limiter.limit("10 per hour")
def verify_otp_only():
    """
    Verify OTP without marking it as used.
    Used for password reset flow — client checks OTP validity 
    before showing reset password screen.
    """
    data = request.get_json() or {}
    email = (data.get("email") or "").strip().lower()
    code = (data.get("code") or "").strip()
    purpose = (data.get("purpose") or "password_reset").strip()

    if not email or not code:
        return jsonify({
            "error": "Email and code are required"
        }), 400

    # Peek — don't consume the OTP yet
    from app.models import EmailVerification
    from datetime import datetime

    verification = EmailVerification.query.filter_by(
        email=email,
        purpose=purpose,
        used_at=None
    ).order_by(
        EmailVerification.created_at.desc()
    ).first()

    if not verification:
        return jsonify({
            "error": "No pending verification for this email"
        }), 400

    if verification.expires_at < datetime.utcnow():
        return jsonify({
            "error": "Verification code has expired"
        }), 400

    if verification.attempts >= EmailService.MAX_OTP_ATTEMPTS:
        return jsonify({
            "error": "Too many attempts. Request a new code."
        }), 400

    if verification.otp_code != code:
        verification.attempts += 1
        db.session.commit()
        remaining = EmailService.MAX_OTP_ATTEMPTS - verification.attempts
        return jsonify({
            "error": f"Invalid code. {remaining} attempts remaining."
        }), 400

    # Valid — but don't mark as used (reset endpoint will do that)
    return jsonify({"message": "Code is valid"}), 200


@auth_bp.route("/resend-otp", methods=["POST"])
@limiter.limit("3 per hour")
def resend_otp():
    data = request.get_json() or {}
    email = (data.get("email") or "").strip().lower()
    purpose = (data.get("purpose") or "register").strip()

    if not email:
        return jsonify({"error": "Email is required"}), 400

    if purpose not in ["register", "password_reset"]:
        return jsonify({"error": "Invalid purpose"}), 400

    coordinator = Coordinator.query.filter_by(email=email).first()
    if not coordinator:
        # Silent success to avoid enumeration
        return jsonify({
            "message": "If the email exists, a code has been sent."
        }), 200

    otp = EmailService.generate_otp(email, purpose=purpose)

    if purpose == "register":
        EmailService.send_registration_otp(
            email, coordinator.full_name, otp
        )
    else:
        EmailService.send_password_reset_otp(
            email, coordinator.full_name, otp
        )

    return jsonify({"message": "Code sent"}), 200


@auth_bp.route("/login", methods=["POST"])
@limiter.limit("5 per minute")
def login():
    data = request.get_json() or {}
    email = (data.get("email") or "").strip().lower()
    password = (data.get("password") or "").strip()

    if not email or not password:
        return jsonify({
            "error": "Email and password are required"
        }), 400

    coordinator = Coordinator.query.filter_by(email=email).first()

    if not coordinator:
        _log_failed_login(email, "unknown_email")
        return jsonify({"error": "Invalid credentials"}), 401

    now = datetime.utcnow()
    if coordinator.locked_until and coordinator.locked_until > now:
        minutes_left = int(
            (coordinator.locked_until - now).total_seconds() // 60
        ) + 1
        _log_failed_login(email, "account_locked")
        return jsonify({
            "error": f"Account locked. Try again in {minutes_left} minute(s)."
        }), 423

    if not coordinator.check_password(password):
        coordinator.failed_login_attempts = (
            (coordinator.failed_login_attempts or 0) + 1
        )
        coordinator.last_failed_login_at = now

        if coordinator.failed_login_attempts >= MAX_FAILED_ATTEMPTS:
            coordinator.locked_until = now + timedelta(
                minutes=LOCKOUT_DURATION_MINUTES
            )
            db.session.commit()

            _log_failed_login(email,
                              f"locked_after_{coordinator.failed_login_attempts}_attempts")

            log_action(coordinator, "coordinator.account_locked",
                       "coordinator", coordinator.coordinator_id,
                       {"failed_attempts": coordinator.failed_login_attempts})

            return jsonify({
                "error": f"Too many failed attempts. Account locked for {LOCKOUT_DURATION_MINUTES} minutes."
            }), 423

        remaining = MAX_FAILED_ATTEMPTS - coordinator.failed_login_attempts
        db.session.commit()
        _log_failed_login(email, "wrong_password")

        return jsonify({
            "error": f"Invalid credentials. {remaining} attempt(s) remaining."
        }), 401

    if not coordinator.email_verified:
        return jsonify({
            "error": "Email not verified. Check your inbox for the verification code.",
            "requires_verification": True,
            "email": coordinator.email
        }), 403

    # Success
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
        "hub_name": hub_name,
        "email": coordinator.email
    }), 200


@auth_bp.route("/forgot-password", methods=["POST"])
@limiter.limit("3 per hour")
def forgot_password():
    data = request.get_json() or {}
    email = (data.get("email") or "").strip().lower()

    if not email:
        return jsonify({"error": "Email is required"}), 400

    coordinator = Coordinator.query.filter_by(email=email).first()

    # Silent success to avoid enumeration
    if not coordinator:
        return jsonify({
            "message": "If the email exists, a reset code has been sent."
        }), 200

    otp = EmailService.generate_otp(email, purpose="password_reset")
    EmailService.send_password_reset_otp(
        email, coordinator.full_name, otp
    )

    log_action(coordinator, "coordinator.password_reset_requested",
               "coordinator", coordinator.coordinator_id)

    return jsonify({
        "message": "If the email exists, a reset code has been sent."
    }), 200


@auth_bp.route("/reset-password", methods=["POST"])
@limiter.limit("5 per hour")
def reset_password():
    data = request.get_json() or {}
    email = (data.get("email") or "").strip().lower()
    code = (data.get("code") or "").strip()
    new_password = (data.get("new_password") or "").strip()

    if not email or not code or not new_password:
        return jsonify({
            "error": "Email, code and new password are required"
        }), 400

    pw_error = _validate_password(new_password)
    if pw_error:
        return jsonify({"error": pw_error}), 400

    valid, error = EmailService.verify_otp(email, code, "password_reset")
    if not valid:
        return jsonify({"error": error}), 400

    coordinator = Coordinator.query.filter_by(email=email).first()
    if not coordinator:
        return jsonify({"error": "Account not found"}), 404

    coordinator.set_password(new_password)
    coordinator.failed_login_attempts = 0
    coordinator.locked_until = None
    db.session.commit()

    log_action(coordinator, "coordinator.password_reset_completed",
               "coordinator", coordinator.coordinator_id)

    return jsonify({
        "message": "Password reset successfully. Please log in."
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

    if "phone" in data:
     raw_phone = (data.get("phone") or "").strip()
     if raw_phone:
        from app.utils import validate_phone
        cleaned, phone_err = validate_phone(raw_phone)
        if phone_err:
            return jsonify({"error": phone_err}), 400
        coordinator.phone = cleaned
    else:
        coordinator.phone = None

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