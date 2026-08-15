from flask import (
    Blueprint, render_template, request, redirect,
    url_for, session, flash, current_app
)
from app.models import Admin
from flask_jwt_extended import create_access_token

admin_portal_bp = Blueprint(
    "admin_portal",
    __name__,
    template_folder="templates",
    static_folder="static",
    static_url_path="/admin/static",
)


def admin_logged_in():
    return session.get("admin_id") is not None


@admin_portal_bp.route("/login", methods=["GET", "POST"])
def login():
    if admin_logged_in():
        return redirect(url_for("admin_portal.dashboard"))

    if request.method == "POST":
        email = (request.form.get("email") or "").strip().lower()
        password = (request.form.get("password") or "").strip()

        if not email or not password:
            flash("Email and password are required", "danger")
            return render_template("admin_login.html")

        admin = Admin.query.filter_by(email=email).first()

        if not admin or not admin.check_password(password):
            flash("Invalid credentials", "danger")
            return render_template("admin_login.html")

        if not admin.is_active:
            flash("Admin account deactivated", "danger")
            return render_template("admin_login.html")

        identity = str(admin.admin_id)
        access_token = create_access_token(
            identity=identity,
            additional_claims={"role": "admin"},
        )

        session["admin_id"] = identity
        session["admin_name"] = admin.full_name
        session["admin_role"] = admin.role
        session["admin_email"] = admin.email
        session["admin_token"] = access_token

        return redirect(url_for("admin_portal.dashboard"))

    return render_template("admin_login.html")


@admin_portal_bp.route("/forgot-password")
def forgot_password():
    return render_template("admin_forgot_password.html")


@admin_portal_bp.route("/logout")
def logout():
    session.clear()
    return redirect(url_for("admin_portal.login"))


def _require_admin():
    if not admin_logged_in():
        return redirect(url_for("admin_portal.login"))
    return None


@admin_portal_bp.route("/")
@admin_portal_bp.route("/dashboard")
def dashboard():
    redir = _require_admin()
    if redir:
        return redir
    return render_template("admin_dashboard.html")


@admin_portal_bp.route("/hubs")
def hubs():
    redir = _require_admin()
    if redir:
        return redir
    return render_template("admin_hubs.html")


@admin_portal_bp.route("/hubs/<hub_id>")
def hub_detail(hub_id):
    redir = _require_admin()
    if redir:
        return redir
    return render_template("admin_hub_detail.html")


@admin_portal_bp.route("/coordinators")
def coordinators():
    redir = _require_admin()
    if redir:
        return redir
    return render_template("admin_coordinators.html")

@admin_portal_bp.route("/coordinators/<coordinator_id>")
def coordinator_detail(coordinator_id):
    redir = _require_admin()
    if redir:
        return redir
    return render_template("admin_coordinator_detail.html")

@admin_portal_bp.route("/reports")
def reports():
    redir = _require_admin()
    if redir:
        return redir
    return render_template("admin_reports.html")


@admin_portal_bp.route("/audit-log")
def audit_log():
    redir = _require_admin()
    if redir:
        return redir
    return render_template("admin_audit_log.html")


@admin_portal_bp.route("/settings")
def settings():
    redir = _require_admin()
    if redir:
        return redir
    return render_template("admin_settings.html")


@admin_portal_bp.context_processor
def inject_admin_token():
    return {
        "admin_token": session.get("admin_token", ""),
        "admin_email": session.get("admin_email", ""),
    }