from flask import jsonify, request
from flask_jwt_extended import get_jwt_identity


def error_response(message, status_code):
    return jsonify({"error": message}), status_code


def success_response(data, status_code=200):
    return jsonify(data), status_code


def get_current_coordinator():
    from app.models import Coordinator
    coordinator_id = get_jwt_identity()
    if not coordinator_id:
        return None
    return Coordinator.query.get(coordinator_id)


def same_hub(coordinator, hub_id):
    if coordinator is None or hub_id is None:
        return False
    return str(coordinator.hub_id) == str(hub_id)


def forbidden(message="You do not have access to this resource"):
    return error_response(message, 403)


def validate_length(value, field_name, min_len=1, max_len=255):
    if not value:
        return f"{field_name} is required"
    if len(value) < min_len:
        return f"{field_name} must be at least {min_len} characters"
    if len(value) > max_len:
        return f"{field_name} must not exceed {max_len} characters"
    return None


def get_client_ip():
    """Get the real client IP, considering proxies."""
    if request.headers.get('X-Forwarded-For'):
        return request.headers.get('X-Forwarded-For').split(',')[0].strip()
    return request.remote_addr


def log_action(coordinator, action, resource_type, resource_id,
               details=None):
    try:
        from app.models import AuditLog
        from app.extensions import db
        entry = AuditLog(
            coordinator_id=coordinator.coordinator_id
                if coordinator else None,
            hub_id=coordinator.hub_id if coordinator else None,
            action=action,
            resource_type=resource_type,
            resource_id=str(resource_id) if resource_id else None,
            details=details or {},
            ip_address=get_client_ip(),
        )
        db.session.add(entry)
        db.session.commit()
    except Exception:
        try:
            from app.extensions import db
            db.session.rollback()
        except Exception:
            pass