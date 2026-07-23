from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required
from app.models import Hub

hubs_bp = Blueprint("hubs", __name__)

@hubs_bp.route("/<hub_id>", methods=["GET"])
@jwt_required()
def get_hub(hub_id):
    try:
        hub = Hub.query.get(hub_id)
    except Exception:
        hub = None
        
    if not hub:
        return jsonify({"error": "Hub not found"}), 404
    
    return jsonify(hub.to_dict()), 200
