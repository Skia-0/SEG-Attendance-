import os
import sys
from datetime import timedelta
from dotenv import load_dotenv

load_dotenv()


def _get_required(key):
    """
    Get required env var. Exit if missing in production.
    Only allow fallbacks when explicitly in development mode.
    """
    value = os.environ.get(key)
    if value:
        return value

    is_dev = os.environ.get("FLASK_ENV") == "development"
    if is_dev:
        print(f"⚠️  WARNING: {key} not set. Using dev fallback.")
        return f"dev-{key.lower()}-not-for-production"

    print(
        f"❌ FATAL: Required environment variable {key} is missing. "
        f"Set it in Render dashboard or .env file.",
        file=sys.stderr,
    )
    sys.exit(1)


class Config:
    SECRET_KEY = _get_required("SECRET_KEY")
    JWT_SECRET_KEY = _get_required("JWT_SECRET_KEY")

    _db_url = os.environ.get("DATABASE_URL", "")

    if _db_url.startswith("postgres://"):
        _db_url = _db_url.replace(
            "postgres://", "postgresql+psycopg://", 1
        )
    elif _db_url.startswith("postgresql://"):
        _db_url = _db_url.replace(
            "postgresql://", "postgresql+psycopg://", 1
        )

    if not _db_url:
        print(
            "❌ FATAL: DATABASE_URL is required.",
            file=sys.stderr,
        )
        sys.exit(1)

    SQLALCHEMY_DATABASE_URI = _db_url
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # JWT — access tokens expire in 7 days, refresh tokens in 30 days
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(days=7)
    JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=30)

    # CORS — restrict in production, allow all in dev
    _cors_origins = os.environ.get("CORS_ORIGINS", "*")
    CORS_ORIGINS = (
        _cors_origins.split(",") if _cors_origins != "*" else "*"
    )