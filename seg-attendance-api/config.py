import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    SECRET_KEY = os.environ.get("SECRET_KEY", "default_secret_key")

    # Get raw database URL from environment
    _db_url = os.environ.get("DATABASE_URL", "")

    # Fix 1: Replace postgres:// with postgresql:// (Neon sometimes gives postgres://)
    # Fix 2: Replace postgresql:// with postgresql+psycopg:// (use psycopg v3 driver)
    if _db_url.startswith("postgres://"):
        _db_url = _db_url.replace("postgres://", "postgresql+psycopg://", 1)
    elif _db_url.startswith("postgresql://"):
        _db_url = _db_url.replace("postgresql://", "postgresql+psycopg://", 1)

    SQLALCHEMY_DATABASE_URI = _db_url
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    JWT_SECRET_KEY = os.environ.get("JWT_SECRET_KEY", "default_jwt_secret_key")
    JWT_ACCESS_TOKEN_EXPIRES = False  # Long-lived tokens for mobile usage