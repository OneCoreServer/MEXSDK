"""
Google Login Proxy Server for Virtual Blackbox SDK
BGMI / PUBG Mobile ke liye

Usage:
1. Run this server on your local machine or VPS
2. Open browser: http://localhost:8080/auth/google
3. Complete Google login in external browser
4. Copy the auth token
5. Use token in your Virtual SDK
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import urllib.parse
import urllib.request
import json
import ssl
import time
import base64
import secrets
import hashlib

# ========== CONFIGURATION ==========
HOST = "0.0.0.0"
PORT = 8080
CLIENT_ID = "YOUR_GOOGLE_OAUTH_CLIENT_ID"  # Replace with your OAuth client ID
CLIENT_SECRET = "YOUR_GOOGLE_OAUTH_CLIENT_SECRET"  # Replace with your secret
REDIRECT_URI = f"http://localhost:{PORT}/auth/google/callback"

# Token storage (in production use Redis/DB)
auth_tokens = {}
active_sessions = {}


def generate_pkce():
    """Generate PKCE code verifier and challenge"""
    verifier = secrets.token_urlsafe(64)
    challenge = hashlib.sha256(verifier.encode()).digest()
    challenge_b64 = base64.urlsafe_b64encode(challenge).rstrip(b'=').decode()
    return verifier, challenge_b64


class GoogleAuthProxy(BaseHTTPRequestHandler):
    """HTTP Request Handler for Google OAuth Proxy"""

    def log_message(self, format, *args):
        print(f"[PROXY] {self.address_string()} - {format % args}")

    def do_GET(self):
        parsed_path = urllib.parse.urlparse(self.path)
        path = parsed_path.path
        query = urllib.parse.parse_qs(parsed_path.query)

        if path == "/auth/google":
            self._handle_google_auth_init()
        elif path == "/auth/google/callback":
            self._handle_google_callback(query)
        elif path == "/auth/token":
            self._handle_get_token(query)
        elif path == "/auth/verify":
            self._handle_verify_token(query)
        elif path == "/auth/status":
            self._handle_status_check(query)
        elif path == "/":
            self._handle_home()
        else:
            self._send_error(404, "Not Found")

    def do_POST(self):
        parsed_path = urllib.parse.urlparse(self.path)
        path = parsed_path.path

        content_length = int(self.headers.get("Content-Length", 0))
        post_data = self.rfile.read(content_length).decode("utf-8")
        data = urllib.parse.parse_qs(post_data)

        if path == "/sdk/auth":
            self._handle_sdk_auth_request(data)
        elif path == "/sdk/refresh":
            self._handle_token_refresh(data)
        else:
            self._send_error(404, "Not Found")

    def _handle_google_auth_init(self):
        session_id = self._generate_session_id()
        verifier, challenge = generate_pkce()

        auth_url = (
            "https://accounts.google.com/o/oauth2/v2/auth?"
            f"client_id={CLIENT_ID}&"
            f"redirect_uri={urllib.parse.quote(REDIRECT_URI)}&"
            "response_type=code&"
            "scope=openid%20email%20profile&"
            "access_type=offline&"
            f"state={session_id}&"
            f"code_challenge={challenge}&"
            "code_challenge_method=S256"
        )

        active_sessions[session_id] = {
            "status": "pending",
            "created_at": time.time(),
            "token": None,
            "pkce_verifier": verifier,
        }

        html = f"""
        <!DOCTYPE html><html><body>
        <h1>BGMI Google Login Proxy</h1>
        <p>Session ID: <code>{session_id}</code></p>
        <a href=\"{auth_url}\">Login with Google</a>
        </body></html>
        """
        self._send_html(html)

    def _handle_google_callback(self, query):
        code = query.get("code", [None])[0]
        state = query.get("state", [None])[0]
        error = query.get("error", [None])[0]

        if error:
            self._send_html(self._get_error_page(f"Google Error: {error}"))
            return

        if not code or not state:
            self._send_html(self._get_error_page("Missing code or state"))
            return

        pkce_verifier = active_sessions.get(state, {}).get("pkce_verifier")
        token_data = self._exchange_code_for_token(code, pkce_verifier)
        if not token_data:
            self._send_html(self._get_error_page("Token exchange failed"))
            return

        if state not in active_sessions:
            active_sessions[state] = {"created_at": time.time()}

        active_sessions[state]["status"] = "success"
        active_sessions[state]["token"] = token_data
        active_sessions[state]["completed_at"] = time.time()

        auth_tokens[token_data.get("access_token", "")[:20]] = token_data

        self._send_html(self._get_success_page(token_data, state))

    def _handle_get_token(self, query):
        session_id = query.get("session", [None])[0]
        if not session_id or session_id not in active_sessions:
            self._send_json({"error": "Invalid session"}, 400)
            return

        session = active_sessions[session_id]
        if session.get("status") != "success":
            self._send_json(
                {"status": session.get("status", "pending"), "message": "Login pending or failed"},
                202,
            )
            return

        self._send_json({"status": "success", "token": session["token"], "session_id": session_id})

    def _handle_verify_token(self, query):
        token = query.get("token", [None])[0]
        if not token:
            self._send_json({"error": "No token provided"}, 400)
            return

        is_valid = self._verify_google_token(token)
        self._send_json({"valid": is_valid, "token_prefix": token[:20] + "..."})

    def _handle_status_check(self, query):
        session_id = query.get("session", [None])[0]
        if not session_id or session_id not in active_sessions:
            self._send_json({"error": "Session not found"}, 404)
            return

        session = active_sessions[session_id]
        self._send_json(
            {
                "session_id": session_id,
                "status": session.get("status"),
                "created_at": session.get("created_at"),
                "completed_at": session.get("completed_at"),
                "has_token": session.get("token") is not None,
            }
        )

    def _handle_sdk_auth_request(self, data):
        device_id = data.get("device_id", [None])[0]
        package_name = data.get("package", ["com.pubg.imobile"])[0]

        session_id = self._generate_session_id()
        active_sessions[session_id] = {
            "status": "pending",
            "device_id": device_id,
            "package": package_name,
            "created_at": time.time(),
            "token": None,
        }

        auth_url = f"http://{self.headers.get('Host', f'{HOST}:{PORT}')}/auth/google?session={session_id}"
        self._send_json(
            {
                "session_id": session_id,
                "auth_url": auth_url,
                "status": "pending",
                "message": "Open auth_url in external browser and complete login",
            }
        )

    def _handle_token_refresh(self, data):
        refresh_token = data.get("refresh_token", [None])[0]
        if not refresh_token:
            self._send_json({"error": "No refresh token"}, 400)
            return

        new_token = self._refresh_access_token(refresh_token)
        if new_token:
            self._send_json({"status": "success", "token": new_token})
        else:
            self._send_json({"error": "Refresh failed"}, 401)

    def _handle_home(self):
        self._send_html("<html><body><h1>BGMI Virtual Login Proxy</h1><a href='/auth/google'>Start Google Login</a></body></html>")

    def _exchange_code_for_token(self, code, code_verifier=None):
        try:
            data = urllib.parse.urlencode(
                {
                    "code": code,
                    "client_id": CLIENT_ID,
                    "client_secret": CLIENT_SECRET,
                    "redirect_uri": REDIRECT_URI,
                    "grant_type": "authorization_code",
                    "code_verifier": code_verifier or "",
                }
            ).encode()
            req = urllib.request.Request(
                "https://oauth2.googleapis.com/token",
                data=data,
                headers={"Content-Type": "application/x-www-form-urlencoded"},
                method="POST",
            )
            context = ssl.create_default_context()
            with urllib.request.urlopen(req, context=context, timeout=30) as response:
                return json.loads(response.read().decode())
        except Exception as e:
            print(f"[ERROR] Token exchange failed: {e}")
            return None

    def _verify_google_token(self, token):
        try:
            req = urllib.request.Request(
                f"https://oauth2.googleapis.com/tokeninfo?access_token={token}", method="GET"
            )
            with urllib.request.urlopen(req, timeout=10) as response:
                data = json.loads(response.read().decode())
                return "error" not in data
        except Exception:
            return False

    def _refresh_access_token(self, refresh_token):
        try:
            data = urllib.parse.urlencode(
                {
                    "refresh_token": refresh_token,
                    "client_id": CLIENT_ID,
                    "client_secret": CLIENT_SECRET,
                    "grant_type": "refresh_token",
                }
            ).encode()
            req = urllib.request.Request(
                "https://oauth2.googleapis.com/token",
                data=data,
                headers={"Content-Type": "application/x-www-form-urlencoded"},
                method="POST",
            )
            with urllib.request.urlopen(req, timeout=30) as response:
                return json.loads(response.read().decode())
        except Exception as e:
            print(f"[ERROR] Token refresh failed: {e}")
            return None

    def _generate_session_id(self):
        import uuid

        return str(uuid.uuid4())[:16]

    def _get_success_page(self, token_data, session_id):
        access_token = token_data.get("access_token", "")
        return f"<html><body><h1>Login Successful</h1><p>Session: {session_id}</p><pre>{access_token}</pre></body></html>"

    def _get_error_page(self, message):
        return f"<html><body><h1>Login Failed</h1><p>{message}</p></body></html>"

    def _send_html(self, html, status=200):
        self.send_response(status)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(html.encode())

    def _send_json(self, data, status=200):
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(json.dumps(data, indent=2).encode())

    def _send_error(self, status, message):
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps({"error": message}).encode())


def run_server():
    server = HTTPServer((HOST, PORT), GoogleAuthProxy)
    print("=" * 60)
    print("BGMI Google Login Proxy Server")
    print("=" * 60)
    print(f"Server running on http://{HOST}:{PORT}")
    print(f"Open browser and go to: http://localhost:{PORT}")
    print("=" * 60)
    print("IMPORTANT: Update CLIENT_ID and CLIENT_SECRET in code!")
    print("=" * 60)

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped")
        server.shutdown()


if __name__ == "__main__":
    run_server()
