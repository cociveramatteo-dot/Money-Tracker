#!/usr/bin/env python3
"""Supabase FINTO per provare l'app Android sull'emulatore senza toccare il cloud reale.

Uso:  python3 scripts/fake-supabase.py [porta=54321]
App:  ./gradlew installDebug -PsupabaseUrl=http://10.0.2.2:54321 -PsupabaseKey=chiave-finta
Utenti di prova (password «password1»): demo@test.it (normale), unconfirmed@test.it («Email not confirmed»), limit@test.it (429).
Altri indirizzi: registrazione normale (mail di conferma finta); auto@test.it si registra e accede subito.
Variabili: FAKE_LATENCY=secondi (ritardo di ogni risposta), FAKE_DOWN=1 (risponde 503 a tutto).
FAKE_NO_E2E=1 nasconde le tabelle E2E. FAKE_FAIL_AFTER=N risponde 503 dopo N scritture REST riuscite.
Stato solo in memoria: riavviando il server si riparte da zero. Non fa nessuna chiamata verso l'esterno.
"""
import json, os, sys, time, uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from threading import Lock
from urllib.parse import urlparse, parse_qs

USERS = {"demo@test.it": "password1", "unconfirmed@test.it": "password1", "limit@test.it": "password1"}
IDS = {e: str(uuid.uuid5(uuid.NAMESPACE_DNS, e)) for e in USERS}
TABLES = {}     # tabella -> {chiave primaria: riga}
TOKENS = {}     # access token -> email
LOG = []
E2E_TABLES = {"mt_e2e", "mt_vault"}
PLAIN_TABLES = {"mt_accounts", "mt_transactions", "mt_budgets", "mt_goals", "mt_recurring_rules"}
UNAVAILABLE = 503, {"message": "service unavailable"}


class FakeServer(ThreadingHTTPServer):
    def __init__(self, address, handler):
        super().__init__(address, handler)
        self.data_lock = Lock()
        fail_after = os.environ.get("FAKE_FAIL_AFTER")
        self.fail_after = int(fail_after) if fail_after else None
        self.writes = 0

    def writes_exhausted(self):
        return self.fail_after is not None and self.writes >= self.fail_after


def eq_filter(query, column):
    value = query.get(column, [""])[0]
    return value[3:] if value.startswith("eq.") else None


def e2e_state(row):
    return TABLES.get("mt_e2e", {}).get(row.get("user_id", "").lower(), {}).get("state")


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

    def table_request(self, table, method, query, uid, body):
        if self.server.writes_exhausted():
            return UNAVAILABLE
        if table in E2E_TABLES and os.environ.get("FAKE_NO_E2E") == "1":
            return 404, {"code": "PGRST205", "message": "Could not find the table"}

        pk = "user_id" if table == "mt_e2e" else "id"
        rows = TABLES.setdefault(table, {})
        user_filter = eq_filter(query, "user_id")
        kind_filter = eq_filter(query, "kind")
        metadata_filters = {column: eq_filter(query, column) for column in ("key_id", "state", "updated_at")
                            if table == "mt_e2e" and column in query}
        preferences = {value.strip() for value in self.headers.get("Prefer", "").split(",")}

        def matches(row):
            return (
                (user_filter is None or row["user_id"].lower() == user_filter.lower())
                and (kind_filter is None or row.get("kind") == kind_filter)
                and all(value is not None and row.get(column) == value
                        for column, value in metadata_filters.items())
            )

        def mutation_response(changed):
            if table != "mt_e2e" or "return=representation" not in preferences:
                return 204, b""
            columns = query.get("select", ["*"])[0]
            if columns != "*":
                changed = [{column: row.get(column) for column in columns.split(",")} for row in changed]
            return 200, changed

        if method == "GET":
            mine = [
                row for _, row in sorted(rows.items())
                if row["user_id"].lower() == uid and matches(row)
            ]
            a, b = (int(x) for x in self.headers.get("Range", "0-999").split("-"))
            page = [
                {
                    key: value.lower() if key in ("id", "user_id", "account_id") and isinstance(value, str) else value
                    for key, value in row.items()
                }
                for row in mine[a:b + 1]
            ]
            if "select" in query and query["select"][0] != "*":
                cols = query["select"][0].split(",")
                page = [{c: r.get(c) for c in cols} for r in page]
            return (206 if len(mine) > b + 1 else 200), page
        if method == "POST":
            incoming = body if isinstance(body, list) else [body]
            if table in PLAIN_TABLES and any(e2e_state(row) in {"migrating", "active"} for row in incoming):
                return 400, {"code": "P0001", "message": "bt_e2e_active"}
            updates = {row[pk].lower(): row for row in incoming}
            if table == "mt_e2e":
                duplicate = rows.keys() & updates.keys() or len(updates) != len(incoming)
                if duplicate and "resolution=merge-duplicates" not in preferences:
                    return 409, {"code": "23505", "message": "duplicate key value violates unique constraint"}
            rows.update(updates)
            return 201, b""
        if method == "PATCH" and table == "mt_e2e" and user_filter is not None:
            row = rows.get(uid)
            if row is not None and matches(row):
                rows[uid] = {**row, **body, pk: row[pk]}
                return mutation_response([rows[uid]])
            return mutation_response([])
        if method == "DELETE":
            id_filter = query.get("id", [""])[0]
            if (
                ("user_id" in query and user_filter is None)
                or ("kind" in query and kind_filter is None)
                or (id_filter and pk != "id")
            ):
                return 204, b""
            ids = None
            if id_filter.startswith("in.(") and id_filter.endswith(")"):
                ids = {value.lower() for value in id_filter[4:-1].split(",")}
            elif id_filter.startswith("eq."):
                ids = {id_filter[3:].lower()}
            candidates = []
            if ids is not None or (not id_filter and (user_filter is not None or kind_filter is not None)):
                # Le DELETE per soli id già esistenti conservano il comportamento del server finto.
                legacy_ids = table not in E2E_TABLES and user_filter is None and kind_filter is None
                candidates = [
                    key for key, row in rows.items()
                    if (ids is None or key in ids) and matches(row)
                    and (legacy_ids or row["user_id"].lower() == uid)
                ]
            if table in PLAIN_TABLES and any(e2e_state(rows[key]) == "migrating" for key in candidates):
                return 400, {"code": "P0001", "message": "bt_e2e_migrating"}
            return mutation_response([rows.pop(key) for key in candidates])
        return 404, {"message": "not found " + urlparse(self.path).path}

    def route(self, method):
        if os.environ.get("FAKE_DOWN") or self.server.writes_exhausted():
            return self.send(*UNAVAILABLE)
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
            with self.server.data_lock:
                if self.server.writes_exhausted():
                    result = UNAVAILABLE
                else:
                    for t in TABLES.values():
                        for k in [k for k, r in t.items() if r.get("user_id", "").lower() == IDS.get(email, "").lower()]:
                            del t[k]
                    USERS.pop(email, None)
                    self.server.writes += 1
                    result = 204, b""
            return self.send(*result)
        if u.path.startswith("/rest/v1/mt_"):
            table = u.path.rsplit("/", 1)[1]
            email = self.user_email()
            if not email:
                return self.send(401, {"message": "JWT expired"})
            uid = IDS.get(email, "").lower()
            body = self.body() if method in {"POST", "PATCH"} else None
            with self.server.data_lock:
                result = self.table_request(table, method, q, uid, body)
                if method != "GET" and 200 <= result[0] < 300:
                    self.server.writes += 1
            return self.send(*result)
        return self.send(404, {"message": "not found " + u.path})

    def do_GET(self): self.route("GET")
    def do_POST(self): self.route("POST")
    def do_PATCH(self): self.route("PATCH")
    def do_DELETE(self): self.route("DELETE")


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 54321
    with FakeServer(("127.0.0.1", port), H) as server:
        port = server.server_port
        print(f"Supabase FINTO su http://127.0.0.1:{port} (emulatore: http://10.0.2.2:{port})", file=sys.stderr)
        server.serve_forever()
