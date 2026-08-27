import uuid
from datetime import datetime
from sqlalchemy.dialects.postgresql import UUID
from werkzeug.security import generate_password_hash, check_password_hash
from app.extensions import db


class Hub(db.Model):
    __tablename__ = "hubs"

    hub_id = db.Column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=db.text("gen_random_uuid()")
    )
    name = db.Column(db.String(255), nullable=False)
    location = db.Column(db.Text, nullable=True)
    created_at = db.Column(
        db.DateTime,
        default=datetime.utcnow,
        server_default=db.text("NOW()")
    )

    cohorts = db.relationship(
        "Cohort", back_populates="hub",
        cascade="all, delete-orphan"
    )
    coordinators = db.relationship(
        "Coordinator", back_populates="hub",
        cascade="all, delete-orphan"
    )

    def to_dict(self):
        return {
            "hub_id": str(self.hub_id),
            "name": self.name,
            "location": self.location,
            "created_at":
                self.created_at.isoformat()
                if self.created_at else None
        }


class Cohort(db.Model):
    __tablename__ = "cohorts"

    cohort_id = db.Column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=db.text("gen_random_uuid()")
    )
    name = db.Column(db.String(255), nullable=False)
    hub_id = db.Column(
        UUID(as_uuid=True),
        db.ForeignKey("hubs.hub_id", ondelete="CASCADE"),
        nullable=False
    )
    start_date = db.Column(db.Date, nullable=True)
    end_date = db.Column(db.Date, nullable=True)
    min_attendance_percent = db.Column(
        db.Integer, default=80, nullable=False
    )
    is_deleted = db.Column(
        db.Boolean, default=False, nullable=False,
        server_default="false"
    )
    deleted_at = db.Column(db.DateTime, nullable=True)
    created_at = db.Column(
        db.DateTime,
        default=datetime.utcnow,
        server_default=db.text("NOW()")
    )

    hub = db.relationship("Hub", back_populates="cohorts")
    learners = db.relationship(
        "Learner", back_populates="cohort",
        cascade="all, delete-orphan"
    )
    sessions = db.relationship(
        "Session", back_populates="cohort",
        cascade="all, delete-orphan"
    )
    nfc_cards = db.relationship("NFCCard", back_populates="cohort")

    def to_dict(self):
        return {
            "cohort_id": str(self.cohort_id),
            "name": self.name,
            "hub_id": str(self.hub_id),
            "start_date":
                self.start_date.isoformat()
                if self.start_date else None,
            "end_date":
                self.end_date.isoformat() if self.end_date else None,
            "min_attendance_percent": self.min_attendance_percent,
            "is_deleted": self.is_deleted,
            "created_at":
                self.created_at.isoformat()
                if self.created_at else None
        }


class Coordinator(db.Model):
    __tablename__ = "coordinators"

    coordinator_id = db.Column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=db.text("gen_random_uuid()")
    )
    full_name = db.Column(db.String(255), nullable=False)
    email = db.Column(
        db.String(255),
        unique=True,
        nullable=False,
        index=True
    )
    email_verified = db.Column(
        db.Boolean, default=False, nullable=False,
        server_default="false"
    )
    phone = db.Column(db.String(20), nullable=True)
    password_hash = db.Column(db.Text, nullable=False)
    role = db.Column(
        db.String(20),
        default="coordinator",
        nullable=False,
        server_default="coordinator"
    )
    hub_id = db.Column(
        UUID(as_uuid=True),
        db.ForeignKey("hubs.hub_id", ondelete="CASCADE"),
        nullable=False
    )
    created_at = db.Column(
        db.DateTime,
        default=datetime.utcnow,
        server_default=db.text("NOW()")
    )

    failed_login_attempts = db.Column(
        db.Integer, default=0, nullable=False,
        server_default="0"
    )
    locked_until = db.Column(db.DateTime, nullable=True)
    last_failed_login_at = db.Column(db.DateTime, nullable=True)

    hub = db.relationship("Hub", back_populates="coordinators")
    sessions = db.relationship(
        "Session", back_populates="coordinator",
        cascade="all, delete-orphan"
    )

    def set_password(self, password):
        self.password_hash = generate_password_hash(
            password, method="scrypt"
        )

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    def to_dict(self):
        return {
            "coordinator_id": str(self.coordinator_id),
            "full_name": self.full_name,
            "email": self.email,
            "email_verified": self.email_verified,
            "phone": self.phone,
            "role": self.role,
            "hub_id": str(self.hub_id),
            "created_at":
                self.created_at.isoformat()
                if self.created_at else None
        }


class Admin(db.Model):
    __tablename__ = "admins"

    admin_id = db.Column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=db.text("gen_random_uuid()")
    )
    full_name = db.Column(db.String(255), nullable=False)
    email = db.Column(
        db.String(255), unique=True, nullable=False, index=True
    )
    email_verified = db.Column(
        db.Boolean, default=False, nullable=False,
        server_default="false"
    )
    password_hash = db.Column(db.Text, nullable=False)
    role = db.Column(
        db.String(20),
        default="admin",
        nullable=False,
        server_default="admin"
    )
    created_at = db.Column(
        db.DateTime,
        default=datetime.utcnow,
        server_default=db.text("NOW()")
    )
    is_active = db.Column(
        db.Boolean, default=True, nullable=False,
        server_default="true"
    )

    def set_password(self, password):
        self.password_hash = generate_password_hash(
            password, method="scrypt"
        )

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    def to_dict(self):
        return {
            "admin_id": str(self.admin_id),
            "full_name": self.full_name,
            "email": self.email,
            "role": self.role,
            "is_active": self.is_active,
            "created_at":
                self.created_at.isoformat()
                if self.created_at else None
        }


class EmailVerification(db.Model):
    __tablename__ = "email_verifications"

    verification_id = db.Column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=db.text("gen_random_uuid()")
    )
    email = db.Column(db.String(255), nullable=False, index=True)
    otp_code = db.Column(db.String(6), nullable=False)
    purpose = db.Column(db.String(30), nullable=False)
    expires_at = db.Column(db.DateTime, nullable=False)
    used_at = db.Column(db.DateTime, nullable=True)
    attempts = db.Column(
        db.Integer, default=0, nullable=False,
        server_default="0"
    )
    created_at = db.Column(
        db.DateTime,
        default=datetime.utcnow,
        server_default=db.text("NOW()")
    )


class Learner(db.Model):
    __tablename__ = "learners"

    learner_id = db.Column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=db.text("gen_random_uuid()")
    )
    seg_id = db.Column(db.String(20), unique=True, nullable=False)
    full_name = db.Column(db.String(255), nullable=False)
    phone = db.Column(db.String(20), nullable=True)
    cohort_id = db.Column(
        UUID(as_uuid=True),
        db.ForeignKey("cohorts.cohort_id", ondelete="CASCADE"),
        nullable=False
    )
    nfc_uid = db.Column(db.String(100), nullable=True)
    fingerprint_enrolled = db.Column(
        db.Boolean, default=False, nullable=False,
        server_default="false"
    )
    photo_base64 = db.Column(db.Text, nullable=True)
    registered_at = db.Column(
        db.DateTime,
        default=datetime.utcnow,
        server_default=db.text("NOW()")
    )

    cohort = db.relationship("Cohort", back_populates="learners")
    attendance_records = db.relationship(
        "AttendanceRecord", back_populates="learner",
        cascade="all, delete-orphan"
    )
    nfc_cards = db.relationship("NFCCard", back_populates="learner")

    def to_dict(self):
        return {
            "learner_id": str(self.learner_id),
            "seg_id": self.seg_id,
            "full_name": self.full_name,
            "phone": self.phone,
            "cohort_id": str(self.cohort_id),
            "nfc_uid": self.nfc_uid,
            "fingerprint_enrolled": self.fingerprint_enrolled,
            "photo_base64": self.photo_base64,
            "registered_at":
                self.registered_at.isoformat()
                if self.registered_at else None
        }


class NFCCard(db.Model):
    __tablename__ = "nfc_cards"

    card_id = db.Column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=db.text("gen_random_uuid()")
    )
    uid = db.Column(db.String(100), unique=True, nullable=False)
    learner_id = db.Column(
        UUID(as_uuid=True),
        db.ForeignKey("learners.learner_id", ondelete="SET NULL"),
        nullable=True
    )
    cohort_id = db.Column(
        UUID(as_uuid=True),
        db.ForeignKey("cohorts.cohort_id", ondelete="SET NULL"),
        nullable=True
    )
    hub_id = db.Column(
        UUID(as_uuid=True),
        db.ForeignKey("hubs.hub_id", ondelete="SET NULL"),
        nullable=True
    )
    assigned_at = db.Column(db.DateTime, nullable=True)
    is_active = db.Column(
        db.Boolean, default=True, nullable=False,
        server_default="true"
    )

    learner = db.relationship("Learner", back_populates="nfc_cards")
    cohort = db.relationship("Cohort", back_populates="nfc_cards")

    def to_dict(self):
        return {
            "card_id": str(self.card_id),
            "uid": self.uid,
            "learner_id":
                str(self.learner_id) if self.learner_id else None,
            "cohort_id":
                str(self.cohort_id) if self.cohort_id else None,
            "hub_id":
                str(self.hub_id) if self.hub_id else None,
            "assigned_at":
                self.assigned_at.isoformat()
                if self.assigned_at else None,
            "is_active": self.is_active
        }


class Session(db.Model):
    __tablename__ = "sessions"

    session_id = db.Column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=db.text("gen_random_uuid()")
    )
    cohort_id = db.Column(
        UUID(as_uuid=True),
        db.ForeignKey("cohorts.cohort_id", ondelete="CASCADE"),
        nullable=False
    )
    coordinator_id = db.Column(
        UUID(as_uuid=True),
        db.ForeignKey(
            "coordinators.coordinator_id", ondelete="CASCADE"
        ),
        nullable=False
    )
    title = db.Column(db.String(255), nullable=True)
    started_at = db.Column(
        db.DateTime,
        default=datetime.utcnow,
        server_default=db.text("NOW()")
    )
    ended_at = db.Column(db.DateTime, nullable=True)
    end_reason = db.Column(db.Text, nullable=True)
    checkin_open = db.Column(
        db.Boolean, default=False, nullable=False,
        server_default="false"
    )
    checkout_open = db.Column(
        db.Boolean, default=False, nullable=False,
        server_default="false"
    )

    cohort = db.relationship("Cohort", back_populates="sessions")
    coordinator = db.relationship(
        "Coordinator", back_populates="sessions"
    )
    attendance_records = db.relationship(
        "AttendanceRecord", back_populates="session",
        cascade="all, delete-orphan"
    )

    def to_dict(self):
        return {
            "session_id": str(self.session_id),
            "cohort_id": str(self.cohort_id),
            "coordinator_id": str(self.coordinator_id),
            "title": self.title,
            "started_at":
                self.started_at.isoformat()
                if self.started_at else None,
            "ended_at":
                self.ended_at.isoformat() if self.ended_at else None,
            "end_reason": self.end_reason,
            "checkin_open": self.checkin_open,
            "checkout_open": self.checkout_open
        }


class AttendanceRecord(db.Model):
    __tablename__ = "attendance_records"

    record_id = db.Column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=db.text("gen_random_uuid()")
    )
    session_id = db.Column(
        UUID(as_uuid=True),
        db.ForeignKey("sessions.session_id", ondelete="CASCADE"),
        nullable=False
    )
    learner_id = db.Column(
        UUID(as_uuid=True),
        db.ForeignKey("learners.learner_id", ondelete="CASCADE"),
        nullable=False
    )
    checked_in_at = db.Column(db.DateTime, nullable=True)
    checked_out_at = db.Column(db.DateTime, nullable=True)
    verification_method = db.Column(db.String(20), nullable=False)
    override_reason = db.Column(db.Text, nullable=True)
    is_complete = db.Column(
        db.Boolean, default=False, nullable=False,
        server_default="false"
    )

    __table_args__ = (
        db.UniqueConstraint(
            "session_id", "learner_id", name="uq_session_learner"
        ),
        db.CheckConstraint(
            "verification_method IN ('fingerprint', 'nfc', 'manual')",
            name="check_verification_method"
        ),
    )

    session = db.relationship(
        "Session", back_populates="attendance_records"
    )
    learner = db.relationship(
        "Learner", back_populates="attendance_records"
    )

    def to_dict(self):
        return {
            "record_id": str(self.record_id),
            "session_id": str(self.session_id),
            "learner_id": str(self.learner_id),
            "checked_in_at":
                self.checked_in_at.isoformat()
                if self.checked_in_at else None,
            "checked_out_at":
                self.checked_out_at.isoformat()
                if self.checked_out_at else None,
            "verification_method": self.verification_method,
            "override_reason": self.override_reason,
            "is_complete": self.is_complete
        }


class Report(db.Model):
    __tablename__ = "reports"

    report_id = db.Column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=db.text("gen_random_uuid()")
    )
    cohort_id = db.Column(
        UUID(as_uuid=True),
        db.ForeignKey("cohorts.cohort_id", ondelete="CASCADE"),
        nullable=False
    )
    hub_id = db.Column(
        UUID(as_uuid=True),
        db.ForeignKey("hubs.hub_id", ondelete="CASCADE"),
        nullable=False
    )
    session_id = db.Column(
        UUID(as_uuid=True),
        db.ForeignKey("sessions.session_id", ondelete="SET NULL"),
        nullable=True
    )
    coordinator_id = db.Column(
        UUID(as_uuid=True),
        db.ForeignKey(
            "coordinators.coordinator_id", ondelete="SET NULL"
        ),
        nullable=True
    )
    report_type = db.Column(db.String(30), nullable=False)
    data = db.Column(db.JSON, nullable=False)
    status = db.Column(
        db.String(20),
        default="submitted",
        nullable=False,
        server_default="submitted"
    )
    submitted_at = db.Column(
        db.DateTime,
        default=datetime.utcnow,
        server_default=db.text("NOW()")
    )

    def to_dict(self):
        return {
            "report_id": str(self.report_id),
            "cohort_id": str(self.cohort_id),
            "hub_id": str(self.hub_id),
            "session_id":
                str(self.session_id) if self.session_id else None,
            "coordinator_id":
                str(self.coordinator_id)
                if self.coordinator_id else None,
            "report_type": self.report_type,
            "data": self.data,
            "status": self.status,
            "submitted_at":
                self.submitted_at.isoformat()
                if self.submitted_at else None,
        }


class AuditLog(db.Model):
    __tablename__ = "audit_logs"

    log_id = db.Column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=db.text("gen_random_uuid()")
    )
    coordinator_id = db.Column(
        UUID(as_uuid=True),
        db.ForeignKey(
            "coordinators.coordinator_id", ondelete="SET NULL"
        ),
        nullable=True
    )
    admin_id = db.Column(
        UUID(as_uuid=True),
        db.ForeignKey("admins.admin_id", ondelete="SET NULL"),
        nullable=True
    )
    hub_id = db.Column(
        UUID(as_uuid=True),
        db.ForeignKey("hubs.hub_id", ondelete="SET NULL"),
        nullable=True
    )
    action = db.Column(db.String(100), nullable=False)
    resource_type = db.Column(db.String(50), nullable=False)
    resource_id = db.Column(db.String(100), nullable=True)
    details = db.Column(db.JSON, nullable=True)
    ip_address = db.Column(db.String(45), nullable=True)
    created_at = db.Column(
        db.DateTime,
        default=datetime.utcnow,
        server_default=db.text("NOW()")
    )

    def to_dict(self):
        return {
            "log_id": str(self.log_id),
            "coordinator_id":
                str(self.coordinator_id)
                if self.coordinator_id else None,
            "admin_id":
                str(self.admin_id) if self.admin_id else None,
            "hub_id":
                str(self.hub_id) if self.hub_id else None,
            "action": self.action,
            "resource_type": self.resource_type,
            "resource_id": self.resource_id,
            "details": self.details,
            "ip_address": self.ip_address,
            "created_at":
                self.created_at.isoformat()
                if self.created_at else None,
        }


class AdminNotification(db.Model):
    __tablename__ = "admin_notifications"

    notification_id = db.Column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=db.text("gen_random_uuid()")
    )
    admin_id = db.Column(
        UUID(as_uuid=True),
        db.ForeignKey("admins.admin_id", ondelete="CASCADE"),
        nullable=True
    )
    category = db.Column(db.String(30), nullable=False)
    title = db.Column(db.String(255), nullable=False)
    subtitle = db.Column(db.String(255), nullable=True)
    icon = db.Column(db.String(10), nullable=True)
    url = db.Column(db.String(255), nullable=True)
    is_read = db.Column(
        db.Boolean, default=False, nullable=False,
        server_default="false"
    )
    created_at = db.Column(
        db.DateTime,
        default=datetime.utcnow,
        server_default=db.text("NOW()")
    )

    def to_dict(self):
        return {
            "notification_id": str(self.notification_id),
            "admin_id":
                str(self.admin_id) if self.admin_id else None,
            "category": self.category,
            "title": self.title,
            "subtitle": self.subtitle,
            "icon": self.icon,
            "url": self.url,
            "is_read": self.is_read,
            "created_at":
                self.created_at.isoformat()
                if self.created_at else None,
        }


class TokenBlocklist(db.Model):
    __tablename__ = "token_blocklist"

    id = db.Column(db.Integer, primary_key=True)
    jti = db.Column(db.String(36), nullable=False, index=True)
    token_type = db.Column(db.String(10), nullable=False)
    user_id = db.Column(db.String(100), nullable=True)
    revoked_at = db.Column(
        db.DateTime,
        default=datetime.utcnow,
        server_default=db.text("NOW()")
    )
    expires_at = db.Column(db.DateTime, nullable=False)