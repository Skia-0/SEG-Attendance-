from flask import jsonify

def error_response(message, status_code):
    """
    Returns a consistent JSON error response.
    """
    return jsonify({"error": message}), status_code

def success_response(data, status_code=200):
    """
    Returns a consistent JSON success response.
    """
    return jsonify(data), status_code
