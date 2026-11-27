#!/usr/bin/env python3
"""Prova ripetibile E2E su APK Android release minificato con R8 (S-50w / S-50z).

Avvia fake-supabase.py su una porta libera, costruisce assembleRelease su una copia
temporanea con HTTP verso 10.0.2.2, firma col keystore di debug, avvia un AVD
isolato temporaneo ed esegue il giro completo: login, attivazione Protezione avanzata,
seconda spesa cifrata nel vault (bt1.), sblocco dopo pm clear, disattivazione con PIN
e controllo logcat. Non tocca mai Supabase reale ne' lascia file nel repository.
"""

import json
import os
import re
import shlex
import shutil
import signal
import socket
import subprocess
import sys
import tempfile
import time
import xml.etree.ElementTree as ET
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import ProxyHandler, Request, build_opener

ANDROID = Path(__file__).resolve().parents[1]
SERVER = Path(__file__).with_name("fake-supabase.py")
PACKAGE = "com.bucktrail.android"
ACTIVITY = f"{PACKAGE}/.MainActivity"
FAKE_KEY = "chiave-finta"
EMAIL = "demo@test.it"
PASSWORD = "password1"
PIN = "2468"
PHRASE = "correct horse battery staple"
WRONG_PHRASE = "wrong security phrase test"
ACCOUNT_NAME = "Conto Prova"
ACCOUNT_BALANCE = "100"
FIRST_EXPENSE = ("12.50", "Spesa iniziale")
SECOND_EXPENSE = ("7.25", "Spesa cifrata")
AVD_NAME = "Bucktrail_S50z"
SYSTEM_IMAGE = "system-images;android-36;default;arm64-v8a"


class ProbeError(Exception):
    pass


def checked(command, label, *, timeout=300, input_text=None, cwd=ANDROID, env=None):
    result = subprocess.run(
        command,
        cwd=cwd,
        env=env,
        input=input_text,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        timeout=timeout,
    )
    if result.returncode:
        for line in result.stdout.splitlines():
            if re.search(r"error:|failed:|AssertionError:|FAILURE:|^Error:|^adb:", line, re.I):
                print(line[:400], flush=True)
        raise ProbeError(label)
    return result.stdout


def free_emulator_port():
    for port in range(5554, 5584, 2):
        try:
            with socket.socket() as console, socket.socket() as adb:
                console.bind(("127.0.0.1", port))
                adb.bind(("127.0.0.1", port + 1))
                return port
        except OSError:
            continue
    raise ProbeError("Nessuna porta libera per l'emulatore Android")


def find_apksigner(sdk):
    preferred = sdk / "build-tools/35.0.0/apksigner"
    if preferred.is_file():
        return preferred
    candidates = sorted((sdk / "build-tools").glob("*/apksigner"))
    if not candidates:
        raise ProbeError("apksigner non trovato in ANDROID_HOME/build-tools")
    return candidates[-1]


def start_fake_server(work):
    env = {k: v for k, v in os.environ.items() if not k.startswith("FAKE_")}
    env["FAKE_LATENCY"] = "0.05"
    log_path = work / "fake-supabase.log"
    log_handle = log_path.open("wb")
    server = subprocess.Popen(
        [sys.executable, "-u", str(SERVER), "0"],
        env=env,
        stderr=log_handle,
    )
    deadline = time.monotonic() + 10
    while time.monotonic() < deadline and server.poll() is None:
        text = log_path.read_text(errors="replace")
        match = re.search(r"Supabase FINTO su http://127\.0\.0\.1:(\d+)", text)
        if match:
            return server, int(match[1]), log_path, log_handle
        time.sleep(0.05)
    log_handle.close()
    stop_process(server)
    raise ProbeError("Avvio di fake-supabase.py fallito")


def stop_process(proc, timeout=10):
    if proc is None or proc.poll() is not None:
        return
    proc.terminate()
    try:
        proc.wait(timeout=timeout)
    except subprocess.TimeoutExpired:
        proc.kill()
        proc.wait()


class FakeApi:
    def __init__(self, url, key):
        self.url = url.rstrip("/")
        self.key = key
        self.opener = build_opener(ProxyHandler({}))
        self.token = self._login()

    def _request(self, method, path, body=None, *, auth=True):
        headers = {"apikey": self.key, "Content-Type": "application/json"}
        if auth and self.token:
            headers["Authorization"] = f"Bearer {self.token}"
        req = Request(
            self.url + path,
            data=None if body is None else json.dumps(body).encode(),
            method=method,
            headers=headers,
        )
        try:
            resp = self.opener.open(req, timeout=10)
        except HTTPError as err:
            resp = err
        with resp:
            raw = resp.read()
            return resp.status, json.loads(raw) if raw else None

    def _login(self):
        status, body = self._request(
            "POST",
            "/auth/v1/token?grant_type=password",
            {"email": EMAIL, "password": PASSWORD},
            auth=False,
        )
        if status != 200 or not body or "access_token" not in body:
            raise ProbeError(f"Login HTTP su fake-supabase fallito ({status})")
        return body["access_token"]

    def table(self, name):
        status, body = self._request("GET", f"/rest/v1/{name}?select=*")
        if status not in (200, 206) or body is None:
            raise ProbeError(f"Lettura {name} fallita ({status})")
        return body

    def snapshot(self):
        return {
            name: self.table(name)
            for name in ("mt_e2e", "mt_vault", "mt_accounts", "mt_transactions")
        }


def build_and_sign_apk(work, port, sdk, java_home):
    url = f"http://10.0.2.2:{port}"
    assert url.startswith("http://10.0.2.2:"), "URL non locale non ammesso"
    repo_copy = work / "bucktrail-android"
    shutil.copytree(
        ANDROID,
        repo_copy,
        ignore=shutil.ignore_patterns(".gradle", "build", ".idea", "__pycache__"),
    )
    release_manifest = repo_copy / "app/src/release/AndroidManifest.xml"
    release_manifest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(repo_copy / "app/src/debug/AndroidManifest.xml", release_manifest)
    release_netsec = repo_copy / "app/src/release/res/xml/network_security_config.xml"
    release_netsec.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(repo_copy / "app/src/debug/res/xml/network_security_config.xml", release_netsec)

    env = dict(os.environ, ANDROID_HOME=str(sdk), JAVA_HOME=java_home)
    print(f"Build assembleRelease R8 verso {url}", flush=True)
    checked(
        [
            "./gradlew",
            "--max-workers=2",
            "assembleRelease",
            f"-PsupabaseUrl={url}",
            f"-PsupabaseKey={FAKE_KEY}",
        ],
        "Build assembleRelease fallita",
        cwd=repo_copy,
        env=env,
        timeout=900,
    )

    mapping = repo_copy / "app/build/outputs/mapping/release/mapping.txt"
    if not mapping.is_file():
        raise ProbeError("mapping.txt assente: R8 non eseguito")

    unsigned_apk = repo_copy / "app/build/outputs/apk/release/app-release-unsigned.apk"
    if not unsigned_apk.is_file():
        raise ProbeError("APK release unsigned assente")

    keystore = Path.home() / ".android/debug.keystore"
    if not keystore.is_file():
        raise ProbeError(f"Keystore di debug assente: {keystore}")

    signed_apk = work / "bucktrail-r8.apk"
    apksigner = str(find_apksigner(sdk))
    checked(
        [
            apksigner,
            "sign",
            "--ks",
            str(keystore),
            "--ks-pass",
            "pass:android",
            "--key-pass",
            "pass:android",
            "--out",
            str(signed_apk),
            str(unsigned_apk),
        ],
        "Firma APK fallita",
        cwd=repo_copy,
        env=env,
        timeout=120,
    )
    checked([apksigner, "verify", str(signed_apk)], "Verifica firma APK fallita", cwd=repo_copy, env=env)
    return signed_apk


class Emulator:
    def __init__(self, work, sdk, java_home):
        self.work = work
        self.sdk = sdk
        self.adb = str(sdk / "platform-tools/adb")
        self.port = free_emulator_port()
        self.serial = f"emulator-{self.port}"
        self.avd_home = work / "avd"
        self.avd_home.mkdir()
        self.env = dict(
            os.environ,
            ANDROID_HOME=str(sdk),
            ANDROID_SERIAL=self.serial,
            ANDROID_AVD_HOME=str(self.avd_home),
            JAVA_HOME=java_home,
        )
        self.proc = None

    def start(self):
        checked(
            [
                str(self.sdk / "cmdline-tools/latest/bin/avdmanager"),
                "create",
                "avd",
                "--name",
                AVD_NAME,
                "--package",
                SYSTEM_IMAGE,
                "-d",
                "pixel_7",
            ],
            "Creazione AVD temporaneo fallita",
            input_text="no\n",
            env=self.env,
        )
        config = self.avd_home / f"{AVD_NAME}.avd/config.ini"
        lines = [line for line in config.read_text().splitlines() if not line.startswith("disk.dataPartition.size=")]
        lines.append("disk.dataPartition.size=2048M")
        config.write_text("\n".join(lines) + "\n")

        print(f"Avvio AVD temporaneo {AVD_NAME} ({self.serial})", flush=True)
        log = self.work / "emulator.log"
        self.log_handle = log.open("w")
        self.proc = subprocess.Popen(
            [
                str(self.sdk / "emulator/emulator"),
                "-avd",
                AVD_NAME,
                "-port",
                str(self.port),
                "-no-window",
                "-no-audio",
                "-no-snapshot",
                "-no-boot-anim",
                "-gpu",
                "host",
                "-cores",
                "2",
            ],
            env=self.env,
            stdout=self.log_handle,
            stderr=subprocess.STDOUT,
        )
        deadline = time.monotonic() + 420
        while time.monotonic() < deadline:
            if self.proc.poll() is not None:
                raise ProbeError("L'emulatore Android si e' arrestato all'avvio")
            boot = subprocess.run(
                [self.adb, "-s", self.serial, "shell", "getprop", "sys.boot_completed"],
                capture_output=True,
                text=True,
                timeout=10,
            )
            if boot.stdout.strip() == "1":
                pm = subprocess.run(
                    [self.adb, "-s", self.serial, "shell", "pm", "path", "android"],
                    capture_output=True,
                    text=True,
                    timeout=10,
                )
                if pm.returncode == 0 and "package:" in pm.stdout:
                    break
            time.sleep(2)
        else:
            raise ProbeError("Avvio emulatore scaduto")

        for setting in ("window_animation_scale", "transition_animation_scale", "animator_duration_scale"):
            self.adb_shell("settings", "put", "global", setting, "0")
        self.adb_shell("settings", "put", "system", "screen_off_timeout", "1800000")
        self.adb_shell("svc", "power", "stayon", "true")
        self.adb_shell("locksettings", "set-pin", PIN)
        self.adb_shell("input", "keyevent", "KEYCODE_WAKEUP")
        time.sleep(0.4)
        self.adb_shell("wm", "dismiss-keyguard")

    def adb_cmd(self, *args, timeout=60, check=True):
        result = subprocess.run(
            [self.adb, "-s", self.serial, *args],
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        if check and result.returncode:
            raise ProbeError(f"adb {' '.join(args)} fallito: {result.stderr.strip() or result.stdout.strip()}")
        return result.stdout

    def adb_shell(self, *args, timeout=60, check=True):
        return self.adb_cmd("shell", *args, timeout=timeout, check=check)

    def close(self):
        if self.proc is not None and self.proc.poll() is None:
            subprocess.run(
                [self.adb, "-s", self.serial, "emu", "kill"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                timeout=15,
            )
            stop_process(self.proc, timeout=20)
        if hasattr(self, "log_handle"):
            self.log_handle.close()


class UiDriver:
    def __init__(self, emu):
        self.emu = emu

    @staticmethod
    def _bounds(node):
        match = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", node.attrib.get("bounds", ""))
        if not match:
            return None
        x1, y1, x2, y2 = (int(g) for g in match.groups())
        return (x1, y1, x2, y2) if x2 > x1 and y2 > y1 else None

    @classmethod
    def _center(cls, node):
        b = cls._bounds(node)
        return ((b[0] + b[2]) // 2, (b[1] + b[3]) // 2) if b else None

    @staticmethod
    def _text(node):
        return (node.attrib.get("text") or "").strip()

    @staticmethod
    def _desc(node):
        return (node.attrib.get("content-desc") or "").strip()

    def dump(self):
        last_err = None
        for _ in range(5):
            try:
                out = self.emu.adb_shell("uiautomator", "dump", "/sdcard/uidump.xml", timeout=20, check=False)
                if "UI hierchary dumped to" in out or "UI hierarchy dumped to" in out:
                    xml_text = self.emu.adb_cmd("exec-out", "cat", "/sdcard/uidump.xml", timeout=15)
                    start = xml_text.find("<?xml")
                    if start >= 0:
                        return ET.fromstring(xml_text[start:])
            except (ProbeError, ET.ParseError, subprocess.TimeoutExpired) as err:
                last_err = err
            time.sleep(0.5)
        raise ProbeError(f"Dump UiAutomator fallito ({last_err})")

    def _dismiss_permission_if_shown(self, root):
        for node in root.iter("node"):
            pkg = node.attrib.get("package", "")
            rid = node.attrib.get("resource-id", "")
            text = self._text(node).lower()
            if "permissioncontroller" in pkg and (
                rid.endswith("permission_allow_button")
                or text in {"allow", "consenti", "while using the app"}
            ):
                c = self._center(node)
                if c:
                    self.emu.adb_shell("input", "tap", str(c[0]), str(c[1]))
                    time.sleep(0.5)
                    return True
            if pkg == "android" and rid.endswith("aerr_wait"):
                c = self._center(node)
                if c:
                    self.emu.adb_shell("input", "tap", str(c[0]), str(c[1]))
                    time.sleep(0.5)
                    return True
        sys_nodes = [n for n in root.iter("node") if "systemui" in n.attrib.get("package", "")]
        if any(
            self._desc(n) in {"Device locked", "PIN area"}
            or "Unlock for all" in self._text(n)
            or self._text(n) == "Enter PIN"
            for n in sys_nodes
        ):
            if enter_system_pin(self, self.emu, root):
                time.sleep(0.7)
                return True
        return False

    @classmethod
    def _summarize(cls, root):
        items = []
        for node in root.iter("node"):
            if not cls._bounds(node):
                continue
            t = cls._text(node)
            d = cls._desc(node)
            if t or d:
                items.append(f"{node.attrib.get('package', '')}: text={t!r} desc={d!r}")
        return "; ".join(items[:20])

    def wait_for(self, pred, desc, timeout=35):
        deadline = time.monotonic() + timeout
        last_root = None
        while time.monotonic() < deadline:
            root = self.dump()
            last_root = root
            if self._dismiss_permission_if_shown(root):
                continue
            for node in root.iter("node"):
                if self._bounds(node) and pred(node):
                    return root, node
            time.sleep(0.6)
        summary = self._summarize(last_root) if last_root is not None else "vuoto"
        raise ProbeError(f"Timeout attesa elemento UI: {desc} | Visibile: {summary}")

    def wait_gone(self, pred, desc, timeout=35):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            root = self.dump()
            if not any(self._bounds(node) and pred(node) for node in root.iter("node")):
                return
            time.sleep(0.6)
        raise ProbeError(f"Elemento UI ancora presente: {desc}")

    def tap_node(self, node):
        c = self._center(node)
        if not c:
            raise ProbeError("Elemento senza coordinate valide")
        self.emu.adb_shell("input", "tap", str(c[0]), str(c[1]))
        time.sleep(0.4)

    def tap(self, labels, desc=None, *, timeout=25, scroll=False, match_desc=True, pick_last=False):
        label_set = set(labels)
        def matches(n):
            return self._text(n) in label_set or (match_desc and self._desc(n) in label_set)

        if not scroll:
            deadline = time.monotonic() + timeout
            last_root = None
            while time.monotonic() < deadline:
                root = self.dump()
                last_root = root
                if self._dismiss_permission_if_shown(root):
                    continue
                found = [node for node in root.iter("node") if self._bounds(node) and matches(node)]
                if found:
                    self.tap_node(found[-1] if pick_last else found[0])
                    return
                time.sleep(0.6)
            summary = self._summarize(last_root) if last_root is not None else "vuoto"
            raise ProbeError(f"Timeout attesa elemento UI: {desc or '/'.join(labels)} | Visibile: {summary}")

        last_root = None
        for attempt in range(7):
            root = self.dump()
            last_root = root
            if self._dismiss_permission_if_shown(root):
                continue
            found = []
            for node in root.iter("node"):
                b = self._bounds(node)
                if b and matches(node) and (80 <= (b[1] + b[3]) // 2 <= 2280 or attempt == 6):
                    found.append(node)
            if found:
                self.tap_node(found[-1] if pick_last else found[0])
                return
            if attempt < 6:
                self.emu.adb_shell("input", "swipe", "540", "1650", "540", "750", "300")
                time.sleep(0.4)
        summary = self._summarize(last_root) if last_root is not None else "vuoto"
        raise ProbeError(f"Elemento non trovato dopo scroll: {desc or '/'.join(labels)} | Visibile: {summary}")

    def hide_keyboard_if_open(self):
        ime = self.emu.adb_shell("dumpsys", "input_method", check=False)
        if "mInputShown=true" in ime:
            self.emu.adb_shell("input", "keyevent", "KEYCODE_BACK")
            time.sleep(0.35)

    def enter_edit_text(self, index, value, desc, *, timeout=20):
        if index > 0:
            self.hide_keyboard_if_open()
        deadline = time.monotonic() + timeout
        target = None
        last_root = None
        while time.monotonic() < deadline:
            root = self.dump()
            last_root = root
            if self._dismiss_permission_if_shown(root):
                continue
            edits = []
            for node in root.iter("node"):
                b = self._bounds(node)
                if b and node.attrib.get("class") == "android.widget.EditText":
                    edits.append((b[1], b[0], node))
            edits.sort(key=lambda item: (item[0], item[1]))
            if len(edits) > index:
                target = edits[index][2]
                break
            self.hide_keyboard_if_open()
            time.sleep(0.5)
        if target is None:
            summary = self._summarize(last_root) if last_root is not None else "vuoto"
            raise ProbeError(f"Campo testo #{index} non trovato ({desc}) | Visibile: {summary}")
        self.tap_node(target)
        encoded = shlex.quote(value.replace(" ", "%s"))
        self.emu.adb_shell("input", "text", encoded)
        time.sleep(0.3)
        self.hide_keyboard_if_open()

    def read_recovery_key(self):
        root = self.dump()
        for node in root.iter("node"):
            text = self._text(node)
            normalized = re.sub(r"\s+", "-", text.strip()).upper()
            if re.fullmatch(r"[A-Z0-9]{4}(?:-[A-Z0-9]{4}){7}", normalized):
                return normalized
            desc = self._desc(node)
            compact = re.sub(r"\s+", "", desc).upper()
            if re.fullmatch(r"[A-Z0-9]{4}(?:-[A-Z0-9]{4}){7}", compact):
                return compact
        raise ProbeError("Chiave di recupero non trovata nella UI")


def wait_until(predicate, desc, timeout=30, interval=0.6):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        value = predicate()
        if value:
            return value
        time.sleep(interval)
    raise ProbeError(f"Condizione non soddisfatta entro {timeout}s: {desc}")


def wait_snapshot(api, pred, desc, timeout=30):
    def check():
        snap = api.snapshot()
        return snap if pred(snap) else None

    return wait_until(check, desc, timeout=timeout)


def sign_in(ui, *, verify_email=True):
    ui.tap(("Settings", "Impostazioni"), "Impostazioni")
    ui.tap(("Sign in or create an account", "Accedi o crea un account"), "Accedi o crea un account", scroll=True)
    ui.wait_for(lambda n: UiDriver._text(n) in {"Sign in", "Accedi"}, "Schermata login")
    ui.enter_edit_text(0, EMAIL, "Email")
    ui.enter_edit_text(1, PASSWORD, "Password")
    ui.hide_keyboard_if_open()
    ui.tap(("Sign in", "Accedi"), "Pulsante accedi")
    ui.wait_gone(lambda n: UiDriver._text(n) in {"Sign in", "Accedi"}, "Chiusura login", timeout=35)
    if verify_email:
        ui.emu.adb_shell("input", "swipe", "540", "1650", "540", "750", "300")
        ui.wait_for(lambda n: UiDriver._text(n) == EMAIL, "Email utente autenticato", timeout=20)


def enter_system_pin(ui, emu, root):
    nodes = list(root.iter("node"))
    sys_nodes = [n for n in nodes if "systemui" in n.attrib.get("package", "") or "settings" in n.attrib.get("package", "")]
    if any(UiDriver._desc(n) == "Device locked" or "Unlock for all" in UiDriver._text(n) for n in sys_nodes):
        emu.adb_shell("input", "keyevent", "KEYCODE_WAKEUP")
        emu.adb_shell("input", "swipe", "540", "1900", "540", "500", "250")
        time.sleep(0.6)
        root = ui.dump()
        nodes = list(root.iter("node"))
        sys_nodes = [n for n in nodes if "systemui" in n.attrib.get("package", "") or "settings" in n.attrib.get("package", "")]

    edit = next((n for n in sys_nodes if n.attrib.get("class") == "android.widget.EditText" and UiDriver._bounds(n)), None)
    if edit is not None:
        ui.tap_node(edit)
        emu.adb_shell("input", "text", PIN)
        emu.adb_shell("input", "keyevent", "KEYCODE_ENTER")
        return True

    digit_nodes = {}
    enter_node = None
    for n in sys_nodes:
        if not UiDriver._bounds(n):
            continue
        d = UiDriver._desc(n)
        t = UiDriver._text(n)
        rid = n.attrib.get("resource-id", "")
        if d in set("0123456789") or t in set("0123456789"):
            key = d if d in set("0123456789") else t
            digit_nodes.setdefault(key, n)
        if rid.endswith(("key_enter", "enter", "btn_enter")) or d.lower() in {"enter", "ok", "confirm", "invio", "conferma"} or t.lower() in {"enter", "ok", "confirm", "invio", "conferma"}:
            enter_node = n
    if all(ch in digit_nodes for ch in PIN):
        for ch in PIN:
            ui.tap_node(digit_nodes[ch])
            time.sleep(0.15)
        if enter_node is not None:
            ui.tap_node(enter_node)
        else:
            emu.adb_shell("input", "keyevent", "KEYCODE_ENTER")
        return True

    if any("PIN" in UiDriver._text(n).upper() or "PIN" in UiDriver._desc(n).upper() for n in sys_nodes):
        emu.adb_shell("input", "text", PIN)
        emu.adb_shell("input", "keyevent", "KEYCODE_ENTER")
        return True
    return False


def ensure_device_unlocked(ui, emu):
    for _ in range(5):
        root = ui.dump()
        sys_nodes = [n for n in root.iter("node") if "systemui" in n.attrib.get("package", "")]
        locked = any(
            UiDriver._desc(n) in {"Device locked", "PIN area"}
            or "PIN" in UiDriver._text(n).upper()
            or "Unlock for all" in UiDriver._text(n)
            for n in sys_nodes
        )
        if not locked:
            return
        enter_system_pin(ui, emu, root)
        time.sleep(0.8)


def handle_pin_if_shown(ui, emu):
    deadline = time.monotonic() + 90
    last_pin_at = 0.0
    last_root = None
    while time.monotonic() < deadline:
        root = ui.dump()
        last_root = root
        nodes = list(root.iter("node"))
        if any(UiDriver._text(n) in {"Turn on Advanced Protection", "Attiva Protezione avanzata"} for n in nodes):
            return
        turning_off = any("Turning off" in UiDriver._text(n) or "Disattivazione in corso" in UiDriver._text(n) for n in nodes)
        if not turning_off and time.monotonic() - last_pin_at >= 5.0 and enter_system_pin(ui, emu, root):
            last_pin_at = time.monotonic()
        time.sleep(1.5 if turning_off else 0.7)
    summary = ui._summarize(last_root) if last_root is not None else "vuoto"
    raise ProbeError(f"Disattivazione Protezione avanzata non completata dopo PIN | Visibile: {summary}")


def run_e2e_flow(emu, api, server_log):
    ui = UiDriver(emu)
    emu.adb_shell("logcat", "-c")
    emu.adb_shell("am", "start", "-W", "-n", ACTIVITY)
    ensure_device_unlocked(ui, emu)

    # 1. Login demo@test.it e chiusura impostazioni
    sign_in(ui)
    ui.tap(("Close", "Chiudi"), "Chiudi impostazioni")

    # 2. Conto iniziale + prima spesa
    ui.tap(("New transaction", "New account", "Nuovo movimento", "Nuovo conto"), "FAB nuovo conto")
    ui.wait_for(lambda n: UiDriver._text(n) in {"New account", "Nuovo conto"}, "Modulo nuovo conto")
    ui.enter_edit_text(0, ACCOUNT_NAME, "Nome conto")
    ui.enter_edit_text(1, ACCOUNT_BALANCE, "Saldo conto")
    ui.hide_keyboard_if_open()
    ui.tap(("Add", "Aggiungi"), "Aggiungi conto", scroll=True)
    ui.wait_for(lambda n: UiDriver._desc(n) in {"Settings", "Impostazioni"}, "Home dopo creazione conto")

    ui.tap(("New transaction", "Nuovo movimento"), "FAB nuovo movimento")
    ui.tap(("Expense / Income", "Spesa / Entrata"), "Voce Spesa / Entrata")
    ui.wait_for(lambda n: UiDriver._text(n).lower() in {"amount", "importo"}, "Modulo movimento")
    ui.enter_edit_text(0, FIRST_EXPENSE[0], "Importo prima spesa")
    ui.enter_edit_text(1, FIRST_EXPENSE[1], "Descrizione prima spesa")
    ui.hide_keyboard_if_open()
    ui.tap(("Save", "Salva"), "Salva prima spesa", scroll=True)

    snap = wait_snapshot(
        api,
        lambda s: len(s["mt_accounts"]) == 1 and len(s["mt_transactions"]) == 1,
        "Sync iniziale conto e prima spesa in chiaro",
    )
    print(f"OK  Sync iniziale in chiaro: {len(snap['mt_accounts'])} conto, {len(snap['mt_transactions'])} spesa")

    # 3. Attivazione Protezione avanzata
    ui.tap(("Settings", "Impostazioni"), "Impostazioni per attivazione E2E")
    ui.tap(("Advanced Protection", "Protezione avanzata"), "Protezione avanzata", scroll=True)
    ui.tap(("Turn on Advanced Protection", "Attiva Protezione avanzata"), "Attiva Protezione avanzata", scroll=True)
    ui.enter_edit_text(0, PHRASE, "Frase di sicurezza")
    ui.enter_edit_text(1, PHRASE, "Ripeti frase")
    ui.hide_keyboard_if_open()
    ui.tap(("Continue", "Continua"), "Continua frase", scroll=True)

    ui.wait_for(lambda n: UiDriver._text(n) in {"Your recovery key", "La tua chiave di recupero"}, "Schermata chiave di recupero")
    recovery_key = ui.read_recovery_key()
    last_group = recovery_key.split("-")[-1]
    ui.emu.adb_shell("input", "swipe", "540", "1650", "540", "750", "300")
    time.sleep(0.3)
    ui.enter_edit_text(0, last_group, "Conferma ultimo gruppo chiave")
    ui.hide_keyboard_if_open()
    ui.tap(("I've saved the key", "Ho salvato la chiave"), "Ho salvato la chiave", scroll=True)
    ui.wait_for(lambda n: UiDriver._text(n) in {"Advanced Protection is on", "Protezione avanzata attiva"}, "Attivazione completata", timeout=45)

    snap = api.snapshot()
    if len(snap["mt_e2e"]) != 1 or snap["mt_e2e"][0].get("state") != "active":
        raise ProbeError(f"mt_e2e non active dopo attivazione: {snap['mt_e2e']}")
    live_key_id = snap["mt_e2e"][0].get("key_id")
    if not live_key_id:
        raise ProbeError("key_id mancante in mt_e2e")
    if len(snap["mt_vault"]) != 2 or snap["mt_accounts"] or snap["mt_transactions"]:
        raise ProbeError("Stato tabelle errato dopo attivazione")
    for row in snap["mt_vault"]:
        if row.get("key_id") != live_key_id or not str(row.get("payload", "")).startswith("bt1."):
            raise ProbeError(f"Riga vault non valida dopo attivazione: {row}")
    log_text = server_log.read_text(errors="replace")
    if '"POST /rest/v1/rpc/mt_e2e_activate HTTP/1.1" 204' not in log_text:
        raise ProbeError("RPC mt_e2e_activate 204 assente nei log del server finto")
    print("OK  Attivazione Protezione avanzata (mt_e2e_activate 204, vault bt1.)")

    ui.tap(("Close", "Chiudi"), "Chiudi Protezione avanzata")
    ui.tap(("Close", "Chiudi"), "Chiudi Impostazioni")

    # 4. Seconda spesa nel vault
    ui.tap(("New transaction", "Nuovo movimento"), "FAB seconda spesa")
    ui.tap(("Expense / Income", "Spesa / Entrata"), "Voce Spesa / Entrata")
    ui.wait_for(lambda n: UiDriver._text(n).lower() in {"amount", "importo"}, "Modulo seconda spesa")
    ui.enter_edit_text(0, SECOND_EXPENSE[0], "Importo seconda spesa")
    ui.enter_edit_text(1, SECOND_EXPENSE[1], "Descrizione seconda spesa")
    ui.hide_keyboard_if_open()
    ui.tap(("Save", "Salva"), "Salva seconda spesa", scroll=True)

    snap = wait_snapshot(
        api,
        lambda s: len(s["mt_vault"]) == 3,
        "Seconda spesa nel vault",
    )
    if snap["mt_accounts"] or snap["mt_transactions"]:
        raise ProbeError("Tabelle in chiaro non vuote dopo la seconda spesa")
    tx_vault = [row for row in snap["mt_vault"] if row.get("kind") == "transaction"]
    if len(tx_vault) != 2 or any(
        row.get("key_id") != live_key_id or not str(row.get("payload", "")).startswith("bt1.")
        for row in snap["mt_vault"]
    ):
        raise ProbeError("Seconda spesa non cifrata correttamente con bt1. e chiave viva")
    log_text = server_log.read_text(errors="replace")
    if f"key_id=neq.{live_key_id}" not in log_text and "key_id=neq." not in log_text:
        raise ProbeError("GET di pulizia mt_vault con key_id=neq. assente nei log")
    print("OK  Seconda spesa nel vault (2 movimenti bt1., tabelle in chiaro vuote, pulizia neq)")

    # 5. Pulizia dati locali + sblocco con frase errata poi corretta
    emu.adb_shell("pm", "clear", PACKAGE)
    emu.adb_shell("am", "start", "-W", "-n", ACTIVITY)
    sign_in(ui, verify_email=False)
    try:
        ui.wait_for(lambda n: UiDriver._text(n) in {"Unlock sync", "Sblocca la sincronizzazione"}, "Foglio sblocco automatico", timeout=20)
    except ProbeError:
        ui.tap(("Advanced Protection", "Protezione avanzata"), "Protezione avanzata per sblocco", scroll=True)
        ui.tap(("Unlock", "Sblocca"), "Apri sblocco", scroll=True)
        ui.wait_for(lambda n: UiDriver._text(n) in {"Unlock sync", "Sblocca la sincronizzazione"}, "Foglio sblocco")

    ui.enter_edit_text(0, WRONG_PHRASE, "Frase errata")
    ui.hide_keyboard_if_open()
    ui.tap(("Unlock", "Sblocca"), "Tenta sblocco errato", scroll=True)
    ui.wait_for(lambda n: UiDriver._text(n) in {"Incorrect phrase or key.", "Frase o chiave non corretta."}, "Rifiuto frase errata")

    ui.tap(("Use recovery key", "Usa la chiave di recupero"), "Passa a chiave per azzerare campo", scroll=True)
    ui.tap(("Use security phrase", "Usa la frase di sicurezza"), "Torna a frase di sicurezza", scroll=True)
    ui.enter_edit_text(0, PHRASE, "Frase corretta")
    ui.hide_keyboard_if_open()
    ui.tap(("Unlock", "Sblocca"), "Sblocca con frase corretta", scroll=True)
    ui.wait_gone(lambda n: UiDriver._text(n) in {"Unlock sync", "Sblocca la sincronizzazione"}, "Chiusura sblocco", timeout=35)
    for _ in range(3):
        root = ui.dump()
        if any(UiDriver._text(n) in {"Transactions", "Movimenti"} for n in root.iter("node")):
            break
        close = [n for n in root.iter("node") if UiDriver._bounds(n) and UiDriver._text(n) in {"Close", "Chiudi"}]
        if close:
            ui.tap_node(close[0])
    ui.tap(("Transactions", "Movimenti"), "Scheda Movimenti")
    ui.wait_for(lambda n: UiDriver._text(n) == FIRST_EXPENSE[1], "Prima spesa ricomparsa dopo sblocco")
    ui.wait_for(lambda n: UiDriver._text(n) == SECOND_EXPENSE[1], "Seconda spesa ricomparsa dopo sblocco")
    print("OK  Sblocco dopo pm clear (frase errata rifiutata, corretta accettata, 2 spese presenti)")

    # 6. Disattivazione con PIN e controllo stato finale
    ui.tap(("Settings", "Impostazioni"), "Impostazioni per disattivazione")
    ui.tap(("Advanced Protection", "Protezione avanzata"), "Protezione avanzata per disattivazione", scroll=True)
    ui.wait_for(lambda n: UiDriver._text(n) in {"Advanced Protection is on", "Protezione avanzata attiva"}, "Conferma stato attivo")
    ui.tap(("Turn off Advanced Protection", "Disattiva Protezione avanzata"), "Disattiva Protezione avanzata", scroll=True)
    ui.wait_for(lambda n: UiDriver._text(n) in {"Turn off Advanced Protection?", "Disattivare la Protezione avanzata?"}, "Dialogo disattivazione")
    ui.tap(("Turn off Advanced Protection", "Disattiva Protezione avanzata"), "Conferma disattivazione", pick_last=True)
    handle_pin_if_shown(ui, emu)

    snap = wait_snapshot(
        api,
        lambda s: not s["mt_e2e"] and not s["mt_vault"] and len(s["mt_accounts"]) == 1 and len(s["mt_transactions"]) == 2,
        "Ripristino in chiaro dopo disattivazione",
    )
    print(f"OK  Disattivazione completata: {len(snap['mt_accounts'])} conto, {len(snap['mt_transactions'])} spese in chiaro, vault vuoto")

    # 7. Controllo logcat (nessun crash dell'app)
    logcat = emu.adb_cmd("logcat", "-d", timeout=20)
    crash_lines = [
        line for line in logcat.splitlines()
        if ("FATAL EXCEPTION" in line or "Fatal signal" in line) and PACKAGE in logcat[max(0, logcat.find(line) - 200):logcat.find(line) + 400]
    ]
    if re.search(rf"(FATAL EXCEPTION.*\n.*{re.escape(PACKAGE)}|Process: {re.escape(PACKAGE)}, PID:.*|Fatal signal.*{re.escape(PACKAGE)})", logcat):
        for line in crash_lines[:10]:
            print(line[:300], flush=True)
        raise ProbeError("Rilevato crash di Bucktrail nel logcat")
    print("OK  Nessun crash di com.bucktrail.android nel logcat")


def main():
    sdk = Path(os.environ.get("ANDROID_HOME", str(Path.home() / "Library/Android/sdk")))
    java_home = checked(["/usr/libexec/java_home", "-v", "17"], "Java 17 non trovato").strip()

    with tempfile.TemporaryDirectory(prefix="bucktrail-r8-") as tmp:
        work = Path(tmp)
        server = None
        log_handle = None
        emu = None
        try:
            server, port, server_log, log_handle = start_fake_server(work)
            print(f"Server finto avviato su http://127.0.0.1:{port} (emulatore http://10.0.2.2:{port})", flush=True)
            api = FakeApi(f"http://127.0.0.1:{port}", FAKE_KEY)

            apk = build_and_sign_apk(work, port, sdk, java_home)
            emu = Emulator(work, sdk, java_home)
            emu.start()
            print("Installazione APK release R8 sull'emulatore", flush=True)
            emu.adb_cmd("install", "-r", str(apk), timeout=120)

            run_e2e_flow(emu, api, server_log)
            print("PROVA R8 S-50z VERDE", flush=True)
            return 0
        finally:
            if emu is not None:
                emu.close()
            if server is not None:
                stop_process(server)
            if log_handle is not None:
                log_handle.close()


if __name__ == "__main__":
    def abort(_signal, _frame):
        raise KeyboardInterrupt

    signal.signal(signal.SIGTERM, abort)
    try:
        raise SystemExit(main())
    except (ProbeError, subprocess.TimeoutExpired, KeyboardInterrupt, OSError, ValueError) as error:
        detail = str(error) if isinstance(error, ProbeError) else f"{type(error).__name__}: {error}"
        raise SystemExit(f"KO  {detail}") from None
