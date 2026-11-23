#!/usr/bin/env python3
"""Supabase FINTO per provare l'app Android sull'emulatore senza toccare il cloud reale.

Uso:  python3 scripts/fake-supabase.py [porta=54321]
App:  ./gradlew installDebug -PsupabaseUrl=http://10.0.2.2:54321 -PsupabaseKey=chiave-finta
Utenti di prova (password «password1»): demo@test.it (normale), unconfirmed@test.it («Email not confirmed»), limit@test.it (429).
Altri indirizzi: registrazione normale (mail di conferma finta); auto@test.it si registra e accede subito.
Variabili: FAKE_LATENCY=secondi (ritardo di ogni risposta), FAKE_DOWN=1 (risponde 503 a tutto).
Stato solo in memoria: riavviando il server si riparte da zero. Non fa nessuna chiamata verso l'esterno.
"""
import json, os, sys, time, uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs

USERS = {"demo@test.it": "password1", "unconfirmed@test.it": "password1", "limit@test.it": "password1"}
IDS = {e: str(uuid.uuid5(uuid.NAMESPACE_DNS, e)) for e in USERS}
TABLES = {}     # tabella -> {id: riga}
TOKENS = {}     # access token -> email
LOG = []


def session(email):
    uid = IDS.setdefault(email, str(uuid.uuid5(uuid.NAMESPACE_DNS, email)))
    token = "at-" + uuid.uuid4().hex
    TOKENS[token] = email
    return {"access_token": token, "token_type": "bearer", "expires_in": 3600, "refresh_token": "rt-" + email,
            "user": {"id": uid, "email": email}}


class H(BaseHTTPRequestHandler):
    def log_message(self, fmt, *a):
        sys.stderr.write("[fake-supabase] " + fmt % a + "\n")

    def send(self, status, body=b"", extra=None):
        if isinstance(body, (dict, list)):
            body = json.dumps(body).encode()
        if os.environ.get("FAKE_LATENCY"):
            time.sleep(float(os.environ["FAKE_LATENCY"]))
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        for k, v in (extra or {}).items():
            self.send_header(k, v)
        self.end_headers()
        self.wfile.write(body)

    def body(self):
        n = int(self.headers.get("Content-Length") or 0)
        return json.loads(self.rfile.read(n) or b"{}") if n else {}

    def user_email(self):
        auth = self.headers.get("Authorization", "")
        return TOKENS.get(auth.replace("Bearer ", ""))

    def route(self, method):
        if os.environ.get("FAKE_DOWN"):
            return self.send(503, {"message": "service unavailable"})
        u = urlparse(self.path); q = parse_qs(u.query)
        if u.path == "/auth/v1/token":
            b = self.body()
            if q.get("grant_type") == ["refresh_token"]:
                email = b.get("refresh_token", "")[3:]
                return self.send(200, session(email)) if email else self.send(400, {"msg": "Invalid Refresh Token"})
            email, pw = b.get("email", ""), b.get("password", "")
            if email == "limit@test.it":
                return self.send(429, {"code": 429, "error_code": "over_request_rate_limit", "msg": "Request rate limit reached"})
            if email == "unconfirmed@test.it":
                return self.send(400, {"code": 400, "error_code": "email_not_confirmed", "msg": "Email not confirmed"})
            if USERS.get(email) != pw:
                return self.send(400, {"code": 400, "error_code": "invalid_credentials", "msg": "Invalid login credentials"})
            return self.send(200, session(email))
        if u.path == "/auth/v1/signup":
            b = self.body(); email, pw = b.get("email", ""), b.get("password", "")
            if "@" not in email:
                return self.send(400, {"code": 400, "error_code": "email_address_invalid", "msg": "Unable to validate email address: invalid format"})
            if email in USERS:
                return self.send(422, {"code": 422, "error_code": "user_already_exists", "msg": "User already registered"})
            if len(pw) < 6:
                return self.send(422, {"code": 422, "error_code": "weak_password", "msg": "Password should be at least 6 characters."})
            USERS[email] = pw
            if email == "auto@test.it":
                return self.send(200, session(email))
            return self.send(200, {"id": str(uuid.uuid4()), "email": email, "confirmation_sent_at": "2026-11-23T10:00:00Z"})
        if u.path == "/auth/v1/recover":
            return self.send(200, {})
        if u.path == "/auth/v1/logout":
            return self.send(204)
        if u.path == "/rest/v1/rpc/delete_own_account":
            email = self.user_email()
            for t in TABLES.values():
                for k in [k for k, r in t.items() if r.get("user_id", "").lower() == IDS.get(email, "").lower()]:
                    del t[k]
            USERS.pop(email, None)
            return self.send(204)
        if u.path.startswith("/rest/v1/mt_"):
            table = u.path.rsplit("/", 1)[1]
            email = self.user_email()
            if not email:
                return self.send(401, {"message": "JWT expired"})
            rows = TABLES.setdefault(table, {})
            uid = IDS.get(email, "").lower()
            if method == "GET":
                mine = sorted((r for r in rows.values() if r["user_id"].lower() == uid), key=lambda r: r["id"].lower())
                a, b = (int(x) for x in self.headers.get("Range", "0-999").split("-"))
                page = [{k: (v.lower() if k in ("id", "user_id", "account_id") and isinstance(v, str) else v) for k, v in r.items()} for r in mine[a:b + 1]]
                if "select" in q and q["select"][0] != "*":
                    cols = q["select"][0].split(","); page = [{c: r.get(c) for c in cols} for r in page]
                return self.send(206 if len(mine) > b + 1 else 200, page)
            if method == "POST":
                for r in self.body():
                    rows[r["id"].lower()] = r
                return self.send(201)
            if method == "DELETE":
                ids = q["id"][0][4:-1].split(",") if "id" in q else []
                for i in ids:
                    rows.pop(i.lower(), None)
                return self.send(204)
        return self.send(404, {"message": "not found " + u.path})

    def do_GET(self): self.route("GET")
    def do_POST(self): self.route("POST")
    def do_DELETE(self): self.route("DELETE")


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 54321
    print(f"Supabase FINTO su http://127.0.0.1:{port} (emulatore: http://10.0.2.2:{port})", file=sys.stderr)
    ThreadingHTTPServer(("127.0.0.1", port), H).serve_forever()
