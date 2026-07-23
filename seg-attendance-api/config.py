import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    SECRET_KEY = os.environ.get("SECRET_KEY", "default_secret_key")
    
    # Neon serverless postgres URLs can start with postgres://, SQLAlchemy requires postgresql://
    db_url = os.environ.get("DATABASE_URL")
    if db_url and db_url.startswith("postgres://"):
        db_url = db_url.replace("postgres://", "postgresql://", 1)
    
    SQLALCHEMY_DATABASE_URI = db_url
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    
    JWT_SECRET_KEY = os.environ.get("JWT_SECRET_KEY", "default_jwt_secret_key")
    JWT_ACCESS_TOKEN_EXPIRES = False  # Long-lived tokens for easy testing/mobile usage
