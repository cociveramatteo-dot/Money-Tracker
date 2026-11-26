#!/usr/bin/env python3
"""Prove HTTP del fake Supabase E2E. Richiede solo la libreria standard."""

from concurrent.futures import ThreadPoolExecutor
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
from threading import Barrier
import time
import unittest
from urllib.error import HTTPError
from urllib.request import ProxyHandler, Request, build_opener


SERVER = Path(__file__).with_name("fake-supabase.py")
E2E = "/rest/v1/mt_e2e"
VAULT = "/rest/v1/mt_vault"
ACTIVATE = "/rest/v1/rpc/mt_e2e_activate"
ROLLBACK = "/rest/v1/rpc/mt_e2e_rollback"
KEY = "0123456789abcdef"
NEXT_KEY = "fedcba9876543210"
START = "2026-11-26T10:00:00.123456Z"
FINISH = "2026-11-26T10:00:01.123456Z"
PLAIN = [
    f"/rest/v1/mt_{name}"
    for name in ("accounts", "transactions", "budgets", "goals", "recurring_rules")
]
ACTIVE = {"code": "P0001", "message": "bt_e2e_active"}
MIGRATING = {"code": "P0001", "message": "bt_e2e_migrating"}
STATE_CHANGED = {"code": "P0001", "message": "bt_e2e_state_changed"}
DUPLICATE = {"code": "23505", "message": "duplicate key value violates unique constraint"}
UNAVAILABLE = {"message": "service unavailable"}


class FakeSupabaseE2ETests(unittest.TestCase):
    def start_server(self, **settings):
        env = {key: value for key, value in os.environ.items() if not key.startswith("FAKE_")}
        env.update(settings)
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        log = Path(directory.name) / "server.log"
        with log.open("wb") as output:
            server = subprocess.Popen(
                [sys.executable, "-I", str(SERVER), "0"],
                env=env,
                stderr=output,
            )
        self.addCleanup(self.stop_server, server)
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline and server.poll() is None:
            match = re.search(r"Supabase FINTO su (http://127\.0\.0\.1:\d+)", log.read_text())
            if match:
                self.url = match[1]
                return
            time.sleep(0.02)
        self.fail(f"Avvio del server fallito: {log.read_text()}")

    @staticmethod
    def stop_server(server):
        if server.poll() is None:
            server.terminate()
        try:
            server.wait(timeout=3)
        except subprocess.TimeoutExpired:
            server.kill()
            server.wait()

    def request(self, method, path, body=None, *, token=None, headers=None):
        request = Request(
            self.url + path,
            data=None if body is None else json.dumps(body).encode(),
            method=method,
            headers={"Content-Type": "application/json", **(headers or {})},
        )
        if token:
            request.add_header("Authorization", f"Bearer {token}")
        try:
            response = build_opener(ProxyHandler({})).open(request, timeout=3)
        except HTTPError as error:
            response = error
        with response:
            raw = response.read()
            return response.status, json.loads(raw) if raw else None

    def login(self, *, second_user=False):
        path = "/auth/v1/signup" if second_user else "/auth/v1/token?grant_type=password"
        email = "auto@test.it" if second_user else "demo@test.it"
        status, body = self.request("POST", path, {"email": email, "password": "password1"})
        self.assertEqual(status, 200)
        return body["user"]["id"], body["access_token"]

    def seed_metadata(self, uid, token, *, state="migrating", key_id=KEY):
        row = {"user_id": uid, "state": state, "key_id": key_id, "updated_at": START}
        self.assertEqual(self.request("POST", E2E, row, token=token), (201, None))
        return row

    def activate(self, token, *, key_id=KEY, before=START, counts=None):
        return self.request("POST", ACTIVATE, {
            "p_key_id": key_id, "p_from_generation": before, "p_to_generation": FINISH,
            "p_counts": counts or {},
        }, token=token)

    def rollback(self, token, *, key_id=KEY, generation=START):
        return self.request("POST", ROLLBACK, {
            "p_key_id": key_id, "p_generation": generation,
        }, token=token)

    def test_primary_keys_and_on_conflict(self):
        self.start_server()
        uid, token = self.login()
        row = {"user_id": uid.upper(), "state": "active", "key_id": KEY}
        self.assertEqual(self.request("POST", E2E, [row], token=token), (201, None))
        updated = {"user_id": uid, "state": "active", "key_id": KEY, "salt": "changed"}
        self.assertEqual(
            self.request("POST", E2E + "?on_conflict=id", updated, token=token,
                         headers={"Prefer": "resolution=merge-duplicates, return=minimal"}),
            (201, None),
        )
        self.assertEqual(self.request("GET", E2E, token=token), (200, [updated]))
        row = {"id": "AB", "user_id": uid, "kind": "goal", "key_id": KEY, "payload": "bt1.Old"}
        self.assertEqual(self.request("POST", VAULT, [row], token=token), (201, None))
        row = {**row, "id": "ab", "payload": "bt1.New"}
        self.assertEqual(self.request("POST", VAULT + "?on_conflict=user_id", [row], token=token), (201, None))
        self.assertEqual(self.request("GET", VAULT, token=token), (200, [row]))

    def test_get_filters_projection_and_range(self):
        self.start_server()
        uid, token = self.login()
        other_uid, other_token = self.login(second_user=True)
        self.seed_metadata(uid, token, state="active")
        self.seed_metadata(other_uid, other_token, state="active")
        rows = [
            {"id": "B", "user_id": uid, "kind": "goal", "key_id": KEY, "payload": "bt1.B"},
            {"id": "A", "user_id": uid, "kind": "goal", "key_id": KEY, "payload": "bt1.A"},
            {"id": "C", "user_id": uid, "kind": "account", "key_id": KEY, "payload": "bt1.C"},
        ]
        self.assertEqual(self.request("POST", VAULT, rows, token=token), (201, None))
        other = {"id": "D", "user_id": other_uid, "kind": "goal", "key_id": KEY, "payload": "bt1.D"}
        self.assertEqual(self.request("POST", VAULT, [other], token=other_token), (201, None))
        query = f"?kind=eq.goal&user_id=eq.{uid.upper()}&select=id,payload"
        self.assertEqual(
            self.request("GET", VAULT + query, token=token, headers={"Range": "0-0"}),
            (206, [{"id": "a", "payload": "bt1.A"}]),
        )
        self.assertEqual(
            self.request("GET", VAULT + f"?user_id=eq.{other_uid}", token=token), (200, []),
        )

    def test_delete_filters_and_legacy_ids(self):
        self.start_server()
        uid, token = self.login()
        other_uid, other_token = self.login(second_user=True)
        self.seed_metadata(uid, token, state="active")
        self.seed_metadata(other_uid, other_token, state="active")
        rows = [
            {"id": "A", "user_id": uid, "kind": "goal", "key_id": KEY, "payload": "bt1.A"},
            {"id": "B", "user_id": uid, "kind": "goal", "key_id": KEY, "payload": "bt1.B"},
            {"id": "C", "user_id": uid, "kind": "account", "key_id": KEY, "payload": "bt1.C"},
        ]
        other = {"id": "d", "user_id": other_uid, "kind": "goal", "key_id": KEY, "payload": "bt1.D"}
        self.assertEqual(self.request("POST", VAULT, rows, token=token), (201, None))
        self.assertEqual(self.request("POST", VAULT, [other], token=other_token), (201, None))
        self.assertEqual(self.request("DELETE", VAULT + f"?kind=eq.goal&key_id=eq.{KEY}", token=token), (204, None))
        remaining = {**rows[2], "id": "c"}
        self.assertEqual(self.request("GET", VAULT, token=token), (200, [remaining]))
        self.assertEqual(self.request("GET", VAULT, token=other_token), (200, [other]))
        delete = VAULT + f"?user_id=eq.{uid}&kind=eq.account&key_id=eq.{KEY}"
        self.assertEqual(self.request("DELETE", delete, token=token), (204, None))
        self.assertEqual(self.request("GET", VAULT, token=token), (200, []))
        self.assertEqual(self.request("DELETE", E2E + f"?user_id=eq.{uid}", token=token), (204, None))
        self.assertEqual(self.request("POST", PLAIN[0], [{"id": "ABC", "user_id": uid}], token=token), (201, None))
        self.assertEqual(self.request("DELETE", PLAIN[0] + "?id=in.(ABC)", token=token), (204, None))
        self.assertEqual(self.request("GET", PLAIN[0], token=token), (200, []))

    def test_duplicate_conflict_is_atomic(self):
        self.start_server()
        uid, token = self.login()
        other_uid, other_token = self.login(second_user=True)
        row = {"user_id": uid, "state": "migrating"}
        self.assertEqual(self.request("POST", E2E, row, token=token), (201, None))
        self.assertEqual(self.request(
            "POST", E2E, [{"user_id": other_uid, "state": "active"}, {**row, "state": "active"}], token=token,
        ), (409, DUPLICATE))
        self.assertEqual(self.request("GET", E2E, token=token), (200, [row]))
        self.assertEqual(self.request("GET", E2E, token=other_token), (200, []))

    def test_patch_updates_only_selected_row_and_fields(self):
        self.start_server()
        uid, token = self.login()
        other_uid, other_token = self.login(second_user=True)
        row = {"user_id": uid, "state": "migrating", "salt": "Unchanged"}
        other = {"user_id": other_uid, "state": "migrating"}
        self.assertEqual(self.request("POST", E2E, row, token=token), (201, None))
        self.assertEqual(self.request("POST", E2E, other, token=other_token), (201, None))
        patch = {"state": "disabling", "wrapped_key_passphrase": "bt1.UpdatedKey"}
        self.assertEqual(self.request("PATCH", E2E + f"?user_id=eq.{uid.upper()}", patch, token=token), (204, None))
        self.assertEqual(self.request("GET", E2E, token=token), (200, [{**row, **patch}]))
        self.assertEqual(self.request("GET", E2E, token=other_token), (200, [other]))

    def test_guard_blocks_plain_writes_and_migrating_deletes(self):
        self.start_server()
        uid, token = self.login()
        other_uid, other_token = self.login(second_user=True)
        existing = {"id": "existing", "user_id": uid}
        new = {"id": "new", "user_id": uid}
        other = {"id": "other", "user_id": other_uid}
        for path in PLAIN:
            self.assertEqual(self.request("POST", path, [existing], token=token), (201, None))
        self.seed_metadata(uid, token)
        for state in ("migrating", "active", "disabling"):
            if state == "active":
                self.assertEqual(self.activate(token), (204, None))
            elif state == "disabling":
                filter_path = E2E + f"?user_id=eq.{uid}"
                self.assertEqual(self.request("PATCH", filter_path, {"state": state}, token=token), (204, None))
            for path in PLAIN:
                with self.subTest(state=state, table=path):
                    self.assertEqual(self.request("POST", path, [other], token=other_token), (201, None))
                    expected = (201, None) if state == "disabling" else (400, ACTIVE)
                    self.assertEqual(self.request("POST", path, [new], token=token), expected)
                    self.assertEqual(self.request("POST", path, [{**existing, "changed": True}], token=token), expected)
                    delete = path + "?id=in.(existing,other)"
                    if state == "migrating":
                        self.assertEqual(self.request("DELETE", delete, token=token), (400, MIGRATING))
                        self.assertEqual(self.request("GET", path, token=token), (200, [existing]))
                        self.assertEqual(self.request("GET", path, token=other_token), (200, [other]))
                    else:
                        self.assertEqual(self.request("DELETE", delete, token=token), (204, None))

    def test_delete_own_account_bypasses_guard(self):
        self.start_server()
        uid, token = self.login()
        original = {"id": "original", "user_id": uid}
        vault = {**original, "kind": "account", "key_id": KEY, "payload": "bt1.Payload"}
        self.assertEqual(self.request("POST", PLAIN[0], [original], token=token), (201, None))
        self.seed_metadata(uid, token)
        self.assertEqual(self.request("POST", VAULT, [vault], token=token), (201, None))
        self.assertEqual(self.request("POST", "/rest/v1/rpc/delete_own_account", token=token), (204, None))
        for path in (PLAIN[0], VAULT, E2E):
            self.assertEqual(self.request("GET", path, token=token), (200, []))

    def test_delayed_d7_cannot_delete_row_from_new_activation(self):
        self.start_server()
        uid, token = self.login()
        self.seed_metadata(uid, token, key_id=NEXT_KEY)
        row = {"id": "same-id", "user_id": uid, "kind": "goal", "key_id": NEXT_KEY, "payload": "bt1.New"}
        self.assertEqual(self.request("POST", VAULT, [row], token=token), (201, None))
        self.assertEqual(self.activate(token, key_id=NEXT_KEY, counts={"goal": 1}), (204, None))
        delayed = VAULT + f"?id=eq.same-id&user_id=eq.{uid}&kind=eq.goal&key_id=eq.{KEY}"
        self.assertEqual(self.request("DELETE", delayed, token=token), (204, None))
        self.assertEqual(self.request("GET", VAULT, token=token), (200, [row]))

    def test_orphan_delete_after_a5_leaves_counts_mismatch_at_a6(self):
        self.start_server()
        uid, token = self.login()
        metadata = self.seed_metadata(uid, token)
        row = {"id": "original", "user_id": uid, "kind": "account", "key_id": KEY, "payload": "bt1.Payload"}
        self.assertEqual(self.request("POST", VAULT, [row], token=token), (201, None))
        self.assertEqual(self.request("DELETE", VAULT + f"?id=eq.original&key_id=eq.{KEY}", token=token), (204, None))
        self.assertEqual(self.activate(token, counts={"account": 1}),
                         (400, {"code": "P0001", "message": "bt_e2e_counts"}))
        self.assertEqual(self.request("GET", E2E, token=token), (200, [metadata]))
        self.assertEqual(self.activate(token, before=FINISH),
                         (400, {"code": "P0001", "message": "bt_e2e_state_changed"}))

    def seed_activation_race(self):
        self.start_server()
        uid, token = self.login()
        metadata = self.seed_metadata(uid, token)
        row = {"id": "original", "user_id": uid, "kind": "account", "key_id": KEY, "payload": "bt1.Payload"}
        self.assertEqual(self.request("POST", VAULT, [row], token=token), (201, None))
        return token, metadata, row

    def test_a6_wins_before_rollback(self):
        token, metadata, row = self.seed_activation_race()
        self.assertEqual(self.activate(token, counts={"account": 1}), (204, None))
        self.assertEqual(self.rollback(token), (400, STATE_CHANGED))
        self.assertEqual(self.request("GET", E2E, token=token),
                         (200, [{**metadata, "state": "active", "updated_at": FINISH}]))
        self.assertEqual(self.request("GET", VAULT, token=token), (200, [row]))

    def test_rollback_wins_before_a6_and_preserves_other_keys_and_users(self):
        token, metadata, _ = self.seed_activation_race()
        uid = metadata["user_id"]
        other_uid, other_token = self.login(second_user=True)
        other_metadata = self.seed_metadata(other_uid, other_token)
        other = {"id": "other", "user_id": other_uid, "kind": "goal", "key_id": KEY}
        self.assertEqual(self.request("POST", VAULT, [other], token=other_token), (201, None))

        # Simula una riga orfana di una generazione precedente.
        orphan = {"id": "orphan", "user_id": uid, "kind": "goal", "key_id": NEXT_KEY}
        path = E2E + f"?user_id=eq.{uid}"
        self.assertEqual(self.request("PATCH", path, {"key_id": NEXT_KEY}, token=token), (204, None))
        self.assertEqual(self.request("POST", VAULT, [orphan], token=token), (201, None))
        self.assertEqual(self.request("PATCH", path, {"key_id": KEY}, token=token), (204, None))

        self.assertEqual(self.rollback(token, generation=START.replace("Z", "+00:00")), (204, None))
        self.assertEqual(self.activate(token, counts={"account": 1}), (400, STATE_CHANGED))
        self.assertEqual(self.request("GET", E2E, token=token), (200, []))
        self.assertEqual(self.request("GET", VAULT, token=token), (200, [orphan]))
        self.assertEqual(self.request("GET", E2E, token=other_token), (200, [other_metadata]))
        self.assertEqual(self.request("GET", VAULT, token=other_token), (200, [other]))

    def test_concurrent_a6_and_rollback_have_one_winner(self):
        token, metadata, row = self.seed_activation_race()
        ready = Barrier(2, timeout=3)

        def race(operation):
            ready.wait()
            return operation()

        with ThreadPoolExecutor(max_workers=2) as pool:
            a6 = pool.submit(race, lambda: self.activate(token, counts={"account": 1}))
            rollback = pool.submit(race, lambda: self.rollback(token))
            a6_result, rollback_result = a6.result(), rollback.result()

        if a6_result == (204, None):
            self.assertEqual(rollback_result, (400, STATE_CHANGED))
            expected_metadata = [{**metadata, "state": "active", "updated_at": FINISH}]
            expected_vault = [row]
        else:
            self.assertEqual(a6_result, (400, STATE_CHANGED))
            self.assertEqual(rollback_result, (204, None))
            expected_metadata = []
            expected_vault = []
        self.assertEqual(self.request("GET", E2E, token=token), (200, expected_metadata))
        self.assertEqual(self.request("GET", VAULT, token=token), (200, expected_vault))

    def test_direct_migrating_delete_and_stale_rollback_leave_data_intact(self):
        token, metadata, row = self.seed_activation_race()
        path = E2E + f"?user_id=eq.{metadata['user_id']}&state=eq.migrating&key_id=eq.{KEY}"
        self.assertEqual(self.request("DELETE", path, token=token),
                         (400, {"code": "P0001", "message": "bt_e2e_use_rollback"}))
        self.assertEqual(self.rollback(token, generation=FINISH), (400, STATE_CHANGED))
        self.assertEqual(self.rollback(token, key_id=NEXT_KEY), (400, STATE_CHANGED))
        self.assertEqual(self.request("GET", E2E, token=token), (200, [metadata]))
        self.assertEqual(self.request("GET", VAULT, token=token), (200, [row]))

    def test_direct_activation_patch_cannot_bypass_rpc(self):
        self.start_server()
        uid, token = self.login()
        metadata = self.seed_metadata(uid, token)
        path = E2E + f"?user_id=eq.{uid}&state=eq.migrating&key_id=eq.{KEY}"
        self.assertEqual(self.request("PATCH", path, {"state": "active"}, token=token),
                         (400, {"code": "P0001", "message": "bt_e2e_use_activate"}))
        self.assertEqual(self.request("GET", E2E, token=token), (200, [metadata]))
        self.assertEqual(self.activate(token, before=START.replace("Z", "+00:00")), (204, None))

    def test_vault_guard_rejects_wrong_key_and_locks_live_rows_during_disable(self):
        self.start_server()
        uid, token = self.login()
        self.seed_metadata(uid, token, state="active")
        row = {"id": "row", "user_id": uid, "kind": "goal", "key_id": KEY, "payload": "bt1.Payload"}
        self.assertEqual(self.request("POST", VAULT, [{**row, "key_id": NEXT_KEY}], token=token),
                         (400, {"code": "P0001", "message": "bt_e2e_key_mismatch"}))
        self.assertEqual(self.request("POST", VAULT, [row], token=token), (201, None))
        self.assertEqual(self.request("PATCH", E2E + f"?user_id=eq.{uid}", {"state": "disabling"}, token=token), (204, None))
        self.assertEqual(self.request("DELETE", VAULT + f"?id=eq.row&key_id=eq.{KEY}", token=token),
                         (400, {"code": "P0001", "message": "bt_e2e_vault_locked"}))
        self.assertEqual(self.request("GET", VAULT + f"?key_id=eq.{NEXT_KEY}", token=token), (200, []))
        self.assertEqual(self.request("GET", VAULT + f"?key_id=eq.{KEY}", token=token), (200, [row]))

    def test_no_e2e_tables(self):
        self.start_server(FAKE_NO_E2E="1")
        uid, token = self.login()
        missing = {"code": "PGRST205", "message": "Could not find the table"}
        for path in (E2E, VAULT):
            for method in ("GET", "POST"):
                with self.subTest(path=path, method=method):
                    body = {} if method == "POST" else None
                    self.assertEqual(self.request(method, path, body, token=token), (404, missing))
        self.assertEqual(self.request("POST", PLAIN[0], [{"id": "a", "user_id": uid}], token=token), (201, None))
        self.assertEqual(self.request("DELETE", PLAIN[0] + "?id=in.(a)", token=token), (204, None))

    def test_fail_after_counts_successful_writes_only(self):
        self.start_server(FAKE_FAIL_AFTER="3")
        uid, token = self.login()
        row = self.seed_metadata(uid, token)
        self.assertEqual(self.request("POST", E2E, row, token=token), (409, DUPLICATE))
        self.assertEqual(self.request("GET", E2E, token=token), (200, [row]))
        self.assertEqual(self.request("POST", PLAIN[0], [{"id": "a", "user_id": uid}], token=token), (400, ACTIVE))
        path = E2E + f"?user_id=eq.{uid}"
        self.assertEqual(self.activate(token), (204, None))
        self.assertEqual(self.request("DELETE", path, token=token), (204, None))
        for method in ("GET", "POST", "PATCH", "DELETE"):
            with self.subTest(method=method):
                self.assertEqual(self.request(method, path, token=token), (503, UNAVAILABLE))

    def test_fail_after_enforces_limit_with_concurrent_writes(self):
        self.start_server(FAKE_FAIL_AFTER="1")
        uid, token = self.login()

        def insert(id_value):
            return self.request("POST", PLAIN[0], [{"id": id_value, "user_id": uid}], token=token)

        with ThreadPoolExecutor(max_workers=2) as pool:
            self.assertCountEqual(pool.map(insert, ("a", "b")), [(201, None), (503, UNAVAILABLE)])

    def test_payload_round_trips_unchanged(self):
        self.start_server()
        uid, token = self.login()
        self.seed_metadata(uid, token)
        payload = "bt1.AzZ_09-É" + "Aa" * 4096
        row = {"id": "AB", "user_id": uid, "kind": "transaction", "key_id": KEY, "payload": payload}
        self.assertEqual(self.request("POST", VAULT, [row], token=token), (201, None))
        self.assertEqual(
            self.request("GET", VAULT + "?select=id,payload", token=token),
            (200, [{"id": "ab", "payload": payload}]),
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
