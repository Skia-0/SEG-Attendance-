from flask import Flask, jsonify
from app.extensions import db, migrate, jwt, cors
from config import Config

def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)

    # Initialize extensions
    db.init_app(app)
    migrate.init_app(app, db)
    jwt.init_app(app)
    cors.init_app(app, resources={r"/*": {"origins": "*"}})

    # Global error handlers
    @app.errorhandler(400)
    def bad_request(error):
        return jsonify({"error": error.description or "Bad request"}), 400

    @app.errorhandler(401)
    def unauthorized(error):
        return jsonify({"error": error.description or "Unauthorized"}), 401

    @app.errorhandler(403)
    def forbidden(error):
        return jsonify({"error": error.description or "Forbidden"}), 403

    @app.errorhandler(404)
    def not_found(error):
        return jsonify({"error": error.description or "Not found"}), 404

    @app.errorhandler(409)
    def conflict(error):
        return jsonify({"error": error.description or "Conflict"}), 409

    @app.errorhandler(500)
    def server_error(error):
        return jsonify({"error": "An internal server error occurred"}), 500

    @jwt.unauthorized_loader
    def unauthorized_jwt(callback):
        return jsonify({"error": "Missing or invalid authorization header"}), 401

    @jwt.expired_token_loader
    def expired_jwt(jwt_header, jwt_payload):
        return jsonify({"error": "Token has expired"}), 401

    @jwt.invalid_token_loader
    def invalid_jwt(callback):
        return jsonify({"error": "Invalid token"}), 401

    # Register Blueprints
    from app.auth.routes import auth_bp
    from app.hubs.routes import hubs_bp
    from app.cohorts.routes import cohorts_bp
    from app.learners.routes import learners_bp
    from app.nfc_cards.routes import nfc_cards_bp
    from app.sessions.routes import sessions_bp
    from app.attendance.routes import attendance_bp
    from app.dashboard.routes import dashboard_bp
    from app.reports.routes import reports_bp

    app.register_blueprint(auth_bp, url_prefix="/api/auth")
    app.register_blueprint(hubs_bp, url_prefix="/api/hubs")
    app.register_blueprint(cohorts_bp, url_prefix="/api/cohorts")
    app.register_blueprint(learners_bp, url_prefix="/api/learners")
    app.register_blueprint(nfc_cards_bp, url_prefix="/api/nfc-cards")
    app.register_blueprint(sessions_bp, url_prefix="/api/sessions")
    app.register_blueprint(attendance_bp, url_prefix="/api/attendance")
    app.register_blueprint(dashboard_bp, url_prefix="/dashboard")
    app.register_blueprint(reports_bp, url_prefix="/api/reports")

    return app
