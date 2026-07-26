from flask import jsonify
from flask_jwt_extended import get_jwt_identity


def error_response(message, status_code):
    """Returns a consistent JSON error response."""
    return jsonify({"error": message}), status_code


def success_response(data, status_code=200):
    """Returns a consistent JSON success response."""
    return jsonify(data), status_code


def get_current_coordinator():
    """
    Fetch the Coordinator row for the current JWT identity.
    Returns None if there's no valid identity or no matching row.
    Import is local to avoid a circular import with app.models.
    """
    from app.models import Coordinator
    coordinator_id = get_jwt_identity()
    if not coordinator_id:
        return None
    return Coordinator.query.get(coordinator_id)


def same_hub(coordinator, hub_id):
    """
    True only if coordinator belongs to the hub identified by hub_id.
    This is the single choke point for "does this coordinator own 
    this resource" - every route that loads a Cohort/Session/
    Learner/NFCCard by id must resolve that resource's owning 
    hub_id and check it here before mutating or returning it.
    """
    if coordinator is None or hub_id is None:
        return False
    return str(coordinator.hub_id) == str(hub_id)


def forbidden(message="You do not have access to this resource"):
    return error_response(message, 403)


def log_action(coordinator, action, resource_type, resource_id,
               details=None):
    """
    Write an audit log entry. Never raise if audit fails - 
    audit failure must not block the actual action.
    """
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
        )
        db.session.add(entry)
        db.session.commit()
    except Exception:
        # Never let audit failure break the main action
        try:
            from app.extensions import db
            db.session.rollback()
        except Exception:
            pass