from flask import Flask, jsonify, request
from prometheus_flask_exporter import PrometheusMetrics
import os
os.environ.get("API_KEY")
app = Flask(__name__)

# This single line adds /metrics endpoint automatically
# Prometheus will scrape this endpoint every 15 seconds
metrics = PrometheusMetrics(app)

@app.route("/", methods=["GET"])
def home():
    return jsonify({
        "message": "DevSecOps Pipeline Demo API",
        "version": "1.0.0",
        "status": "running"
    })

@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "healthy"}), 200


@app.route("/secret-test")
def secret_test():
    api_key = os.environ.get("API_KEY")
    return jsonify({
        "api_key_loaded": bool(api_key)
    })

@app.route("/greet", methods=["GET"])
def greet():
    name = request.args.get("name", "World")
    if not name or not name.isalpha():
        return jsonify({"error": "Invalid name parameter"}), 400
    return jsonify({"message": f"Hello, {name}!"}), 200

@app.route("/add", methods=["POST"])
def add():
    data = request.get_json()
    if not data or "a" not in data or "b" not in data:
        return jsonify({"error": "Missing fields 'a' and 'b'"}), 400
    try:
        result = float(data["a"]) + float(data["b"])
        return jsonify({"result": result}), 200
    except (TypeError, ValueError):
        return jsonify({"error": "Fields must be numbers"}), 400

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    app.run(host="0.0.0.0", port=port, debug=False)