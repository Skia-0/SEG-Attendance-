import re
from datetime import datetime, timedelta
from flask import Blueprint, request, jsonify
from flask_jwt_extended import (
    create_access_token,
    create_refresh_token,
    jwt_required,
    get_jwt_identity,
    get_jwt,
)
from app.models import (
    Admin, Hub, Cohort, Coordinator, Learner,
    Session as HubSession, AttendanceRecord, Report, AuditLog,
    EmailVerification, AdminNotification,
)
from app.extensions import db, limiter
from app.services.email_service import EmailService

admin_api_bp = Blueprint("admin_api", __name__)


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


def get_current_admin():
    identity = get_jwt_identity()
    if not identity:
        return None
    claims = get_jwt()
    if claims.get("role") != "admin":
        return None
    return Admin.query.get(identity)


def admin_required(fn):
    from functools import wraps

    @wraps(fn)
    @jwt_required()
    def wrapper(*args, **kwargs):
        admin = get_current_admin()
        if not admin:
            return jsonify({"error": "Admin access required"}), 403
        if not admin.is_active:
            return jsonify({"error": "Admin account deactivated"}), 403
        return fn(*args, **kwargs)

    return wrapper


# ─── AUTH ─────────────────────────────────────────────
@admin_api_bp.route("/login", methods=["POST"])
@limiter.limit("5 per minute")
def admin_login():
    data = request.get_json() or {}
    email = (data.get("email") or "").strip().lower()
    password = (data.get("password") or "").strip()

    if not email or not password:
        return jsonify({"error": "Email and password are required"}), 400

    admin = Admin.query.filter_by(email=email).first()

    if not admin or not admin.check_password(password):
        return jsonify({"error": "Invalid credentials"}), 401

    if not admin.is_active:
        return jsonify({"error": "Admin account deactivated"}), 403

    identity = str(admin.admin_id)
    additional_claims = {"role": "admin"}
    access_token = create_access_token(
        identity=identity, additional_claims=additional_claims
    )
    refresh_token = create_refresh_token(
        identity=identity, additional_claims=additional_claims
    )

    return jsonify({
        "access_token": access_token,
        "refresh_token": refresh_token,
        "admin_id": str(admin.admin_id),
        "full_name": admin.full_name,
        "email": admin.email,
        "role": admin.role,
    }), 200


@admin_api_bp.route("/forgot-password", methods=["POST"])
@limiter.limit("3 per hour")
def admin_forgot_password():
    data = request.get_json() or {}
    email = (data.get("email") or "").strip().lower()

    if not email:
        return jsonify({"error": "Email is required"}), 400

    admin = Admin.query.filter_by(email=email).first()

    if not admin:
        return jsonify({
            "message": "If the email exists, a reset code has been sent."
        }), 200

    otp = EmailService.generate_otp(email, purpose="admin_password_reset")
    EmailService.send_password_reset_otp(email, admin.full_name, otp)

    return jsonify({
        "message": "If the email exists, a reset code has been sent."
    }), 200


@admin_api_bp.route("/verify-reset-otp", methods=["POST"])
@limiter.limit("10 per hour")
def admin_verify_reset_otp():
    data = request.get_json() or {}
    email = (data.get("email") or "").strip().lower()
    code = (data.get("code") or "").strip()

    if not email or not code:
        return jsonify({"error": "Email and code required"}), 400

    now = datetime.utcnow()
    verification = EmailVerification.query.filter_by(
        email=email,
        purpose="admin_password_reset",
        used_at=None,
    ).order_by(EmailVerification.created_at.desc()).first()

    if not verification:
        return jsonify({"error": "No pending verification"}), 400

    if verification.expires_at < now:
        return jsonify({"error": "Code has expired"}), 400

    if verification.attempts >= EmailService.MAX_OTP_ATTEMPTS:
        return jsonify({"error": "Too many attempts"}), 400

    if verification.otp_code != code:
        verification.attempts += 1
        db.session.commit()
        remaining = EmailService.MAX_OTP_ATTEMPTS - verification.attempts
        return jsonify({
            "error": f"Invalid code. {remaining} attempts remaining."
        }), 400

    return jsonify({"message": "Code valid"}), 200


@admin_api_bp.route("/reset-password", methods=["POST"])
@limiter.limit("5 per hour")
def admin_reset_password():
    data = request.get_json() or {}
    email = (data.get("email") or "").strip().lower()
    code = (data.get("code") or "").strip()
    new_password = (data.get("new_password") or "").strip()

    if not email or not code or not new_password:
        return jsonify({"error": "All fields required"}), 400

    pw_error = _validate_password(new_password)
    if pw_error:
        return jsonify({"error": pw_error}), 400

    valid, error = EmailService.verify_otp(
        email, code, "admin_password_reset"
    )
    if not valid:
        return jsonify({"error": error}), 400

    admin = Admin.query.filter_by(email=email).first()
    if not admin:
        return jsonify({"error": "Admin not found"}), 404

    admin.set_password(new_password)
    db.session.commit()

    return jsonify({
        "message": "Password reset. Please log in."
    }), 200


@admin_api_bp.route("/me", methods=["GET"])
@admin_required
def admin_me():
    admin = get_current_admin()
    return jsonify(admin.to_dict()), 200


@admin_api_bp.route("/change-password", methods=["POST"])
@admin_required
@limiter.limit("5 per hour")
def admin_change_password():
    admin = get_current_admin()
    data = request.get_json() or {}
    old_password = data.get("old_password") or ""
    new_password = data.get("new_password") or ""

    if not admin.check_password(old_password):
        return jsonify({"error": "Current password incorrect"}), 401

    pw_error = _validate_password(new_password)
    if pw_error:
        return jsonify({"error": pw_error}), 400

    admin.set_password(new_password)
    db.session.commit()

    entry = AuditLog(
        admin_id=admin.admin_id,
        action="admin.password_changed",
        resource_type="admin",
        resource_id=str(admin.admin_id),
    )
    db.session.add(entry)
    db.session.commit()

    return jsonify({"message": "Password updated"}), 200


# ─── NOTIFICATIONS ───────────────────────────────────
@admin_api_bp.route("/notifications", methods=["GET"])
@admin_required
def get_notifications():
    admin = get_current_admin()

    # Clean old read notifications (older than 30 days)
    thirty_days_ago = datetime.utcnow() - timedelta(days=30)
    AdminNotification.query.filter(
        AdminNotification.created_at < thirty_days_ago,
        AdminNotification.is_read == True,
    ).delete(synchronize_session=False)
    db.session.commit()

    category = request.args.get("category")

    query = AdminNotification.query.filter(
        db.or_(
            AdminNotification.admin_id == admin.admin_id,
            AdminNotification.admin_id.is_(None),
        )
    )

    if category:
        query = query.filter_by(category=category)

    notifications = query.order_by(
        AdminNotification.created_at.desc(),
    ).limit(100).all()

    unread_count = AdminNotification.query.filter(
        db.or_(
            AdminNotification.admin_id == admin.admin_id,
            AdminNotification.admin_id.is_(None),
        ),
        AdminNotification.is_read == False,
    ).count()

    return jsonify({
        "count": unread_count,
        "notifications": [n.to_dict() for n in notifications],
    }), 200


@admin_api_bp.route(
    "/notifications/<notification_id>/read", methods=["POST"]
)
@admin_required
def mark_notification_read(notification_id):
    notif = AdminNotification.query.get(notification_id)
    if not notif:
        return jsonify({"error": "Not found"}), 404

    notif.is_read = True
    db.session.commit()

    return jsonify({"message": "Marked as read"}), 200


@admin_api_bp.route("/notifications/read-all", methods=["POST"])
@admin_required
def mark_all_notifications_read():
    admin = get_current_admin()
    AdminNotification.query.filter(
        db.or_(
            AdminNotification.admin_id == admin.admin_id,
            AdminNotification.admin_id.is_(None),
        ),
        AdminNotification.is_read == False,
    ).update({"is_read": True}, synchronize_session=False)
    db.session.commit()

    return jsonify({"message": "All marked as read"}), 200


# ─── OVERVIEW ─────────────────────────────────────────
@admin_api_bp.route("/overview", methods=["GET"])
@admin_required
def overview():
    total_hubs = Hub.query.count()
    total_coordinators = Coordinator.query.count()
    total_cohorts = Cohort.query.count()
    total_learners = Learner.query.count()
    total_sessions = HubSession.query.count()
    total_reports = Report.query.count()

    active_sessions = HubSession.query.filter_by(
        ended_at=None
    ).count()

    week_ago = datetime.utcnow() - timedelta(days=7)
    reports_this_week = Report.query.filter(
        Report.submitted_at >= week_ago
    ).count()

    return jsonify({
        "total_hubs": total_hubs,
        "total_coordinators": total_coordinators,
        "total_cohorts": total_cohorts,
        "total_learners": total_learners,
        "total_sessions": total_sessions,
        "total_reports": total_reports,
        "active_sessions": active_sessions,
        "reports_this_week": reports_this_week,
    }), 200


# ─── HUBS ─────────────────────────────────────────────
@admin_api_bp.route("/hubs", methods=["GET"])
@admin_required
def list_hubs():
    hubs = Hub.query.order_by(Hub.name).all()
    results = []
    for h in hubs:
        data = h.to_dict()
        data["coordinator_count"] = Coordinator.query.filter_by(
            hub_id=h.hub_id
        ).count()
        data["cohort_count"] = Cohort.query.filter_by(
            hub_id=h.hub_id
        ).count()
        data["learner_count"] = Learner.query.join(Cohort).filter(
            Cohort.hub_id == h.hub_id
        ).count()
        results.append(data)
    return jsonify(results), 200


@admin_api_bp.route("/hubs/<hub_id>", methods=["GET"])
@admin_required
def get_hub_detail(hub_id):
    hub = Hub.query.get(hub_id)
    if not hub:
        return jsonify({"error": "Hub not found"}), 404

    data = hub.to_dict()

    coords_data = []
    for c in Coordinator.query.filter_by(hub_id=hub_id).order_by(
        Coordinator.full_name
    ).all():
        cd = c.to_dict()
        cd["is_locked"] = (
            c.locked_until is not None
            and c.locked_until > datetime.utcnow()
        )
        coords_data.append(cd)
    data["coordinators"] = coords_data

    cohorts_data = []
    for c in Cohort.query.filter_by(hub_id=hub_id).order_by(
        Cohort.created_at.desc()
    ).all():
        cd = c.to_dict()
        cd["learner_count"] = Learner.query.filter_by(
            cohort_id=c.cohort_id
        ).count()
        cd["session_count"] = HubSession.query.filter_by(
            cohort_id=c.cohort_id
        ).count()
        cd["active_session"] = HubSession.query.filter_by(
            cohort_id=c.cohort_id,
            ended_at=None
        ).first() is not None
        cohorts_data.append(cd)
    data["cohorts"] = cohorts_data

    recent_logs = AuditLog.query.filter_by(
        hub_id=hub_id
    ).order_by(
        AuditLog.created_at.desc()
    ).limit(15).all()

    logs_data = []
    for log in recent_logs:
        ld = log.to_dict()
        if log.coordinator_id:
            coord = Coordinator.query.get(log.coordinator_id)
            ld["actor_name"] = coord.full_name if coord else "Unknown"
            ld["actor_type"] = "coordinator"
        elif log.admin_id:
            admin_user = Admin.query.get(log.admin_id)
            ld["actor_name"] = admin_user.full_name if admin_user else "Unknown"
            ld["actor_type"] = "admin"
        else:
            ld["actor_name"] = "System"
            ld["actor_type"] = "system"
        logs_data.append(ld)
    data["recent_activity"] = logs_data

    data["total_learners"] = Learner.query.join(Cohort).filter(
        Cohort.hub_id == hub_id
    ).count()
    data["total_sessions"] = HubSession.query.join(Cohort).filter(
        Cohort.hub_id == hub_id
    ).count()
    data["active_sessions"] = HubSession.query.join(Cohort).filter(
        Cohort.hub_id == hub_id,
        HubSession.ended_at.is_(None)
    ).count()
    data["total_reports"] = Report.query.filter_by(
        hub_id=hub_id
    ).count()

    return jsonify(data), 200


# ─── COORDINATORS ─────────────────────────────────────
@admin_api_bp.route("/coordinators", methods=["GET"])
@admin_required
def list_coordinators():
    hub_id = request.args.get("hub_id")

    query = Coordinator.query
    if hub_id:
        query = query.filter_by(hub_id=hub_id)

    coordinators = query.order_by(Coordinator.full_name).all()

    results = []
    for c in coordinators:
        data = c.to_dict()
        hub = Hub.query.get(c.hub_id)
        data["hub_name"] = hub.name if hub else ""
        data["is_locked"] = (
            c.locked_until is not None
            and c.locked_until > datetime.utcnow()
        )
        results.append(data)

    return jsonify(results), 200


@admin_api_bp.route(
    "/coordinators/<coordinator_id>/unlock", methods=["POST"]
)
@admin_required
def unlock_coordinator(coordinator_id):
    admin = get_current_admin()
    coord = Coordinator.query.get(coordinator_id)
    if not coord:
        return jsonify({"error": "Coordinator not found"}), 404

    coord.locked_until = None
    coord.failed_login_attempts = 0
    db.session.commit()

    entry = AuditLog(
        admin_id=admin.admin_id,
        hub_id=coord.hub_id,
        action="admin.coordinator_unlocked",
        resource_type="coordinator",
        resource_id=str(coord.coordinator_id),
        details={"admin_email": admin.email},
    )
    db.session.add(entry)
    db.session.commit()

    return jsonify({"message": "Coordinator unlocked"}), 200


@admin_api_bp.route(
    "/coordinators/<coordinator_id>/reset-password",
    methods=["POST"]
)
@admin_required
def admin_reset_coordinator_password(coordinator_id):
    admin = get_current_admin()
    coord = Coordinator.query.get(coordinator_id)
    if not coord:
        return jsonify({"error": "Coordinator not found"}), 404

    otp = EmailService.generate_otp(
        coord.email, purpose="password_reset"
    )
    EmailService.send_password_reset_otp(
        coord.email, coord.full_name, otp
    )

    entry = AuditLog(
        admin_id=admin.admin_id,
        hub_id=coord.hub_id,
        action="admin.coordinator_password_reset_sent",
        resource_type="coordinator",
        resource_id=str(coord.coordinator_id),
        details={"admin_email": admin.email},
    )
    db.session.add(entry)
    db.session.commit()

    return jsonify({
        "message": f"Password reset code sent to {coord.email}"
    }), 200


# ─── REPORTS ──────────────────────────────────────────
@admin_api_bp.route("/reports", methods=["GET"])
@admin_required
def list_all_reports():
    hub_id = request.args.get("hub_id")
    report_type = request.args.get("type")

    query = Report.query
    if hub_id:
        query = query.filter_by(hub_id=hub_id)
    if report_type:
        query = query.filter_by(report_type=report_type)

    reports = query.order_by(Report.submitted_at.desc()).all()

    results = []
    for r in reports:
        data = r.to_dict()
        hub = Hub.query.get(r.hub_id)
        cohort = Cohort.query.get(r.cohort_id)
        data["hub_name"] = hub.name if hub else ""
        data["cohort_name"] = cohort.name if cohort else ""
        results.append(data)

    return jsonify(results), 200


@admin_api_bp.route("/reports/<report_id>", methods=["GET"])
@admin_required
def get_report_detail(report_id):
    report = Report.query.get(report_id)
    if not report:
        return jsonify({"error": "Report not found"}), 404

    data = report.to_dict()
    hub = Hub.query.get(report.hub_id)
    cohort = Cohort.query.get(report.cohort_id)
    data["hub_name"] = hub.name if hub else ""
    data["cohort_name"] = cohort.name if cohort else ""
    return jsonify(data), 200


@admin_api_bp.route("/reports/<report_id>/pdf", methods=["GET"])
@admin_required
def download_report_pdf(report_id):
    from flask import Response
    from app.services.report_export import ReportExporter

    report = Report.query.get(report_id)
    if not report:
        return jsonify({"error": "Report not found"}), 404

    hub = Hub.query.get(report.hub_id)
    cohort = Cohort.query.get(report.cohort_id)
    hub_name = hub.name if hub else "Unknown Hub"
    cohort_name = cohort.name if cohort else "Unknown Cohort"

    pdf_bytes = ReportExporter.to_pdf(report, hub_name, cohort_name)

    filename_parts = [
        report.report_type,
        cohort_name.replace(" ", "_"),
        report.submitted_at.strftime("%Y%m%d")
        if report.submitted_at else "report"
    ]
    filename = "_".join(filename_parts) + ".pdf"

    return Response(
        pdf_bytes,
        mimetype="application/pdf",
        headers={
            "Content-Disposition":
                f'attachment; filename="{filename}"'
        }
    )


@admin_api_bp.route("/reports/<report_id>/csv", methods=["GET"])
@admin_required
def download_report_csv(report_id):
    from flask import Response
    from app.services.report_export import ReportExporter

    report = Report.query.get(report_id)
    if not report:
        return jsonify({"error": "Report not found"}), 404

    hub = Hub.query.get(report.hub_id)
    cohort = Cohort.query.get(report.cohort_id)
    hub_name = hub.name if hub else "Unknown Hub"
    cohort_name = cohort.name if cohort else "Unknown Cohort"

    csv_string = ReportExporter.to_csv(report, hub_name, cohort_name)

    filename_parts = [
        report.report_type,
        cohort_name.replace(" ", "_"),
        report.submitted_at.strftime("%Y%m%d")
        if report.submitted_at else "report"
    ]
    filename = "_".join(filename_parts) + ".csv"

    return Response(
        csv_string,
        mimetype="text/csv",
        headers={
            "Content-Disposition":
                f'attachment; filename="{filename}"'
        }
    )


@admin_api_bp.route("/reports/<report_id>/json", methods=["GET"])
@admin_required
def download_report_json(report_id):
    from flask import Response
    import json

    report = Report.query.get(report_id)
    if not report:
        return jsonify({"error": "Report not found"}), 404

    hub = Hub.query.get(report.hub_id)
    cohort = Cohort.query.get(report.cohort_id)

    full_data = report.to_dict()
    full_data["hub_name"] = hub.name if hub else ""
    full_data["cohort_name"] = cohort.name if cohort else ""

    filename_parts = [
        report.report_type,
        (cohort.name if cohort else "report").replace(" ", "_"),
        report.submitted_at.strftime("%Y%m%d")
        if report.submitted_at else "report"
    ]
    filename = "_".join(filename_parts) + ".json"

    return Response(
        json.dumps(full_data, indent=2),
        mimetype="application/json",
        headers={
            "Content-Disposition":
                f'attachment; filename="{filename}"'
        }
    )


# ─── AUDIT LOG ────────────────────────────────────────
@admin_api_bp.route("/audit-log", methods=["GET"])
@admin_required
def hub_wide_audit_log():
    hub_id = request.args.get("hub_id")
    limit = min(int(request.args.get("limit", 200)), 1000)

    query = AuditLog.query
    if hub_id:
        query = query.filter_by(hub_id=hub_id)

    logs = query.order_by(
        AuditLog.created_at.desc()
    ).limit(limit).all()

    results = []
    for log in logs:
        data = log.to_dict()
        if log.coordinator_id:
            coord = Coordinator.query.get(log.coordinator_id)
            data["actor_name"] = coord.full_name if coord else "Unknown"
            data["actor_type"] = "coordinator"
        elif log.admin_id:
            admin_user = Admin.query.get(log.admin_id)
            data["actor_name"] = admin_user.full_name if admin_user else "Unknown"
            data["actor_type"] = "admin"
        else:
            data["actor_name"] = "System"
            data["actor_type"] = "system"
        results.append(data)

    return jsonify(results), 200