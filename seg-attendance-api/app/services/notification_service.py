from datetime import datetime
from app.extensions import db
from app.models import AdminNotification


class NotificationService:
    """
    Creates notifications when real events happen.
    Each call = one notification = one row in DB.
    Never duplicates. Never polls. Pure event-driven.
    """

    @staticmethod
    def notify(category, title, subtitle, icon, url,
               admin_id=None):
        try:
            notif = AdminNotification(
                admin_id=admin_id,
                category=category,
                title=title,
                subtitle=subtitle,
                icon=icon,
                url=url,
                is_read=False,
                created_at=datetime.utcnow(),
            )
            db.session.add(notif)
            db.session.commit()
            return notif
        except Exception:
            try:
                db.session.rollback()
            except Exception:
                pass
            return None

    @classmethod
    def report_submitted(cls, report_type, title, hub_name,
                         coordinator_name):
        label = "Session report" if report_type == "session" \
            else "Cohort final report"
        cls.notify(
            category="report",
            title=f"{label} submitted",
            subtitle=f"{title} — {hub_name} by {coordinator_name}",
            icon="📄",
            url="/admin/reports",
        )

    @classmethod
    def coordinator_registered(cls, coordinator_name, hub_name,
                               email):
        cls.notify(
            category="coordinator",
            title="New coordinator registered",
            subtitle=f"{coordinator_name} ({email}) — {hub_name}",
            icon="👤",
            url="/admin/coordinators",
        )

    @classmethod
    def coordinator_locked(cls, coordinator_name, hub_name):
        cls.notify(
            category="security",
            title="Account locked",
            subtitle=f"{coordinator_name} — {hub_name} (too many failed logins)",
            icon="🔒",
            url="/admin/coordinators",
        )

    @classmethod
    def coordinator_unlocked(cls, coordinator_name,
                             admin_name):
        cls.notify(
            category="security",
            title="Account unlocked",
            subtitle=f"{coordinator_name} unlocked by {admin_name}",
            icon="🔓",
            url="/admin/coordinators",
        )

    @classmethod
    def password_reset_requested(cls, coordinator_name):
        cls.notify(
            category="security",
            title="Password reset requested",
            subtitle=f"{coordinator_name} requested a password reset",
            icon="🔑",
            url="/admin/audit-log",
        )

    @classmethod
    def session_started(cls, session_title, cohort_name,
                        hub_name, coordinator_name):
        cls.notify(
            category="system",
            title="Session started",
            subtitle=f"{session_title} — {cohort_name} ({hub_name}) by {coordinator_name}",
            icon="▶️",
            url="/admin/hubs",
        )

    @classmethod
    def session_ended(cls, session_title, cohort_name,
                      hub_name, attended_count, total_count):
        cls.notify(
            category="system",
            title="Session ended",
            subtitle=f"{session_title} — {cohort_name} ({hub_name}) · {attended_count}/{total_count} attended",
            icon="⏹️",
            url="/admin/hubs",
        )

    @classmethod
    def failed_login_alert(cls, email):
        cls.notify(
            category="security",
            title="Failed login attempt",
            subtitle=f"Someone tried to log in as {email}",
            icon="⚠️",
            url="/admin/audit-log",
        )

    @classmethod
    def cohort_created(cls, cohort_name, hub_name,
                       coordinator_name):
        cls.notify(
            category="system",
            title="New cohort created",
            subtitle=f"{cohort_name} — {hub_name} by {coordinator_name}",
            icon="📚",
            url="/admin/hubs",
        )

    @classmethod
    def learner_registered(cls, learner_name, seg_id,
                           cohort_name, hub_name):
        cls.notify(
            category="system",
            title="New learner registered",
            subtitle=f"{learner_name} ({seg_id}) — {cohort_name}, {hub_name}",
            icon="🎓",
            url="/admin/hubs",
        )