from flask import Flask, jsonify, request
from flask_cors import CORS

app = Flask(__name__)
CORS(app)


@app.route("/explain_risk", methods=["GET"])
def explain_risk():
    coord = request.args.get("coord")

    if not coord:
        return jsonify({"success": False, "error": "coord missing"}), 400

    try:
        lat_str, lon_str = coord.split(",")
        lat = float(lat_str)
        lon = float(lon_str)
    except Exception:
        return jsonify({"success": False, "error": "invalid coordinates"}), 400

    if 49.017 < lat < 49.020:
        message = "Warning. High pedestrian accident zone. Please proceed carefully."
    else:
        message = "This route appears relatively safe based on available accident data."

    return jsonify({
        "success": True,
        "risk_explanation": message
    })


# ✅ OUTSIDE the above function
@app.route("/is_dangerous_road_nearby", methods=["GET"])
def is_dangerous_road_nearby():
    coord = request.args.get("coord")

    if not coord:
        return jsonify({"success": False, "message": "coord missing"}), 400

    try:
        lat_str, lon_str = coord.split(",")
        lat = float(lat_str)
        lon = float(lon_str)
    except Exception:
        return jsonify({"success": False, "message": "invalid coordinates"}), 400

    if 49.017 < lat < 49.020:
        return jsonify({
            "success": True,
            "dangerous_roads_nearby": True
        })

    return jsonify({
        "success": True,
        "dangerous_roads_nearby": False
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001, debug=True)