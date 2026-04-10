from flask import Flask, render_template, request
import socket
import requests
import os
import datetime
import socket



app = Flask(__name__)

logs = []

def get_public_ip():
    try:
        return requests.get("https://api.ipify.org").text
    except:
        return "No Internet Access ❌"

def get_metadata():
    metadata_url = os.environ.get("ECS_CONTAINER_METADATA_URI_V4")
    if metadata_url:
        try:
            return requests.get(metadata_url).json()
        except:
            return {"error": "Failed to fetch metadata"}
    return {"info": "Not running in ECS or metadata unavailable"}

@app.route("/")
def index():
    try:
        log_entry = f"{datetime.datetime.now()} - {request.remote_addr} accessed /"
        logs.append(log_entry)

        data = {
            "hostname": socket.gethostname(),
            "local_ip": get_local_ip(),
            "public_ip": get_public_ip(),
            "env_vars": dict(list(os.environ.items())[:10]),
            "metadata": str(get_metadata())[:500],
            "logs": logs[-10:],
            "network": network_diagnostics()
        }

        return render_template("index.html", data=data)

    except Exception as e:
        return f"Error: {str(e)}", 500

def get_local_ip():
    try:
        return socket.gethostbyname(socket.gethostname())
    except:
        return "Unavailable ❌"
    
@app.route("/health")
def health():
    return {"status": "healthy"}, 200

@app.route("/test-internet")
def test_internet():
    try:
        r = requests.get("https://www.google.com", timeout=3)
        return {"internet": "Working ✅", "status_code": r.status_code}
    except:
        return {"internet": "Not Working ❌"}


def network_diagnostics():
    result = {}

    # 1️⃣ DNS Resolution Test
    try:
        ip = socket.gethostbyname("google.com")
        result["dns"] = f"Working ✅ (google.com -> {ip})"
    except Exception as e:
        result["dns"] = f"Failed ❌ ({str(e)})"

    # 2️⃣ TCP Connection Test (Port 80)
    try:
        s = socket.create_connection(("google.com", 80), timeout=3)
        s.close()
        result["tcp_connection"] = "Working ✅ (Port 80 reachable)"
    except Exception as e:
        result["tcp_connection"] = f"Failed ❌ ({str(e)})"

    # 3️⃣ HTTP Request Test
    try:
        r = requests.get("https://www.google.com", timeout=3)
        result["http"] = f"Working ✅ (Status: {r.status_code})"
    except Exception as e:
        result["http"] = f"Failed ❌ ({str(e)})"

    return result


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)