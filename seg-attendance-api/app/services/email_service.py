import os
import random
from datetime import datetime, timedelta
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail
from app.extensions import db
from app.models import EmailVerification


class EmailService:
    """Handles email sending and OTP verification."""

    OTP_EXPIRY_MINUTES = 10
    MAX_OTP_ATTEMPTS = 5

    @staticmethod
    def _get_client():
        api_key = os.environ.get("SENDGRID_API_KEY")
        if not api_key:
            raise RuntimeError("SENDGRID_API_KEY not configured")
        return SendGridAPIClient(api_key)

    @staticmethod
    def _get_from_email():
        email = os.environ.get("SENDGRID_FROM_EMAIL")
        if not email:
            raise RuntimeError("SENDGRID_FROM_EMAIL not configured")
        return email

    @classmethod
    def send_email(cls, to_email, subject, html_body):
        try:
            message = Mail(
                from_email=cls._get_from_email(),
                to_emails=to_email,
                subject=subject,
                html_content=html_body,
            )
            client = cls._get_client()
            response = client.send(message)
            return response.status_code in [200, 201, 202]
        except Exception as e:
            print(f"Email send failed: {e}")
            return False

    @classmethod
    def generate_otp(cls, email, purpose):
        EmailVerification.query.filter_by(
            email=email,
            purpose=purpose,
            used_at=None
        ).update({"used_at": datetime.utcnow()})

        code = str(random.randint(100000, 999999))
        expires = datetime.utcnow() + timedelta(
            minutes=cls.OTP_EXPIRY_MINUTES
        )

        verification = EmailVerification(
            email=email,
            otp_code=code,
            purpose=purpose,
            expires_at=expires,
        )
        db.session.add(verification)
        db.session.commit()
        return code

    @classmethod
    def verify_otp(cls, email, code, purpose):
        now = datetime.utcnow()

        verification = EmailVerification.query.filter_by(
            email=email,
            purpose=purpose,
            used_at=None
        ).order_by(
            EmailVerification.created_at.desc()
        ).first()

        if not verification:
            return False, "No pending verification for this email"

        if verification.expires_at < now:
            return False, "Verification code has expired"

        if verification.attempts >= cls.MAX_OTP_ATTEMPTS:
            return False, "Too many attempts. Request a new code."

        verification.attempts += 1

        if verification.otp_code != code:
            db.session.commit()
            remaining = cls.MAX_OTP_ATTEMPTS - verification.attempts
            return False, f"Invalid code. {remaining} attempts remaining."

        verification.used_at = now
        db.session.commit()
        return True, None

    @classmethod
    def send_registration_otp(cls, email, full_name, otp_code):
        subject = "SEG Attendance — Verify Your Email"
        html = f"""
        <div style="font-family:Arial,sans-serif;max-width:500px;margin:0 auto;padding:20px;">
          <div style="background:#1A1A1A;padding:20px;text-align:center;">
            <h1 style="color:#FF6B00;margin:0;">SEG ATTENDANCE</h1>
          </div>
          <div style="padding:30px 20px;background:#f9f9f9;">
            <h2 style="color:#1A1A1A;">Welcome, {full_name}!</h2>
            <p style="color:#444;font-size:14px;">
              Use this code to verify your email address and complete your registration:
            </p>
            <div style="background:#fff;border:2px solid #FF6B00;padding:20px;text-align:center;margin:20px 0;border-radius:8px;">
              <span style="font-size:32px;font-weight:bold;color:#FF6B00;letter-spacing:8px;">{otp_code}</span>
            </div>
            <p style="color:#666;font-size:12px;">
              This code expires in {cls.OTP_EXPIRY_MINUTES} minutes.
              If you didn't request this, please ignore this email.
            </p>
          </div>
          <div style="text-align:center;padding:15px;color:#888;font-size:11px;">
            Social Enterprise Ghana — Internal Use Only
          </div>
        </div>
        """
        return cls.send_email(email, subject, html)

    @classmethod
    def send_password_reset_otp(cls, email, full_name, otp_code):
        subject = "SEG Attendance — Password Reset Code"
        html = f"""
        <div style="font-family:Arial,sans-serif;max-width:500px;margin:0 auto;padding:20px;">
          <div style="background:#1A1A1A;padding:20px;text-align:center;">
            <h1 style="color:#FF6B00;margin:0;">SEG ATTENDANCE</h1>
          </div>
          <div style="padding:30px 20px;background:#f9f9f9;">
            <h2 style="color:#1A1A1A;">Password Reset Request</h2>
            <p style="color:#444;font-size:14px;">
              Hello {full_name}, use this code to reset your password:
            </p>
            <div style="background:#fff;border:2px solid #FF6B00;padding:20px;text-align:center;margin:20px 0;border-radius:8px;">
              <span style="font-size:32px;font-weight:bold;color:#FF6B00;letter-spacing:8px;">{otp_code}</span>
            </div>
            <p style="color:#666;font-size:12px;">
              This code expires in {cls.OTP_EXPIRY_MINUTES} minutes.
              If you didn't request a password reset, please contact your administrator immediately.
            </p>
          </div>
          <div style="text-align:center;padding:15px;color:#888;font-size:11px;">
            Social Enterprise Ghana — Internal Use Only
          </div>
        </div>
        """
        return cls.send_email(email, subject, html)