#!/usr/bin/env python3
"""Prova S-51b su simulatori isolati e account Supabase dedicato."""

import json
import os
import plistlib
import re
import secrets
import shlex
import signal
import socket
import subprocess
import tempfile
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ANDROID = Path(__file__).resolve().parents[1]
ROOT = ANDROID.parents[1]
ACCOUNT = Path.home() / ".config/moneytracker/test-account.env"
BUNDLE = "com.matteo.moneytracker.MoneyTracker"
ANDROID_PACKAGE = "com.bucktrail.android"
ANDROID_RUNNER = f"{ANDROID_PACKAGE}.test/androidx.test.runner.AndroidJUnitRunner"
ANDROID_TEST = f"{ANDROID_PACKAGE}.sync.TwoDeviceLiveSyncTest"
IOS_TEST = "MoneyTrackerTests/TwoDeviceLiveSyncTests/testLiveSync"
IOS_UI_TEST = "MoneyTrackerUITests/TwoDeviceLiveReopenUITests/testReopenedAppShowsBothMovements"
PHASES = ("prima", "protetta", "dopo")
TABLES = ("mt_accounts", "mt_transactions", "mt_budgets", "mt_goals", "mt_recurring_rules")


class ProbeError(Exception):
    pass


def checked(command, label, *, timeout=300, input_text=None, cwd=ROOT, env=None):
    result = subprocess.run(command, cwd=cwd, env=env, input=input_text, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=timeout)
    if result.returncode:
        # Only build and test diagnostics. The account file is never part of any command.
        for line in result.stdout.splitlines():
            if re.search(r"error:|failed:|AssertionError:|FAILURE:|^Error:|^adb:", line):
                print(line[:400], flush=True)
        raise ProbeError(label)
    return result.stdout


def account_values():
    if not ACCOUNT.is_file():
        raise ProbeError(f"File account assente. Creare {ACCOUNT} con MT_TEST_EMAIL e MT_TEST_PASSWORD.")
    values = {}
    for line in ACCOUNT.read_text().splitlines():
        line = line.strip().removeprefix("export ")
        if re.match(r"MT_TEST_(EMAIL|PASSWORD|PHRASE)=", line):
            parts = shlex.split(line, comments=True)
            if len(parts) != 1:
                raise ProbeError("Riga dell’account non valida. Racchiudere il valore tra apici.")
            key, value = parts[0].split("=", 1)
            values[key] = value
    if not values.get("MT_TEST_EMAIL") or not values.get("MT_TEST_PASSWORD"):
        raise ProbeError("MT_TEST_EMAIL e MT_TEST_PASSWORD sono obbligatori nel file locale.")
    return values


def supabase_config():
    source = (ROOT / "MoneyTracker/Auth/SupabaseConfig.swift").read_text()
    return [re.search(rf'static let {key}\s*=\s*(?:URL\(string:\s*)?"([^"]+)"', source)[1]
            for key in ("url", "anonKey")]


class Cloud:
    def __init__(self, url, key, account):
        self.url = url.rstrip("/")
        self.key = key
        self.token = None
        session = self.request("/auth/v1/token?grant_type=password", {
            "email": account["MT_TEST_EMAIL"], "password": account["MT_TEST_PASSWORD"]
        })
        self.token = session["access_token"]
        self.user = session["user"]["id"]

    def request(self, path, payload=None):
        # macOS curl uses the system trust store. Request secrets enter over stdin.
        headers = {"apikey": self.key}
        if self.token:
            headers["Authorization"] = f"Bearer {self.token}"
        if payload is not None:
            headers["Content-Type"] = "application/json"
        lines = [f"header = {json.dumps(f'{key}: {value}')}" for key, value in headers.items()]
        if payload is not None:
            lines.append(f"data-binary = {json.dumps(json.dumps(payload))}")
        result = subprocess.run(
            ["/usr/bin/curl", "-fsS", "--max-time", "30", "--config", "-", self.url + path],
            input="\n".join(lines), stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True,
            timeout=35,
        )
        if result.returncode:
            raise ProbeError("Accesso o verifica in sola lettura su Supabase falliti")
        return json.loads(result.stdout)

    def protection(self):
        return [row["state"] for row in self.request("/rest/v1/mt_e2e?select=state")]

    def ids(self):
        result = {}
        for table in TABLES:
            offset = 0
            ids = set()
            while True:
                page = self.request(f"/rest/v1/{table}?select=id&order=id&limit=500&offset={offset}")
                ids.update(row["id"] for row in page)
                if len(page) < 500:
                    break
                offset += len(page)
            result[table] = ids
        return result


def simulator_runtime():
    listing = json.loads(checked(["xcrun", "simctl", "list", "devices", "available", "-j"],
                                 "Lettura simulatori iOS"))
    for runtime, devices in listing["devices"].items():
        if any(device["name"] == "iPhone 18 Pro" for device in devices):
            return runtime
    raise ProbeError("Manca un simulatore iPhone 18 Pro in Xcode")


def free_emulator_port():
    for port in range(5554, 5584, 2):
        try:
            with socket.socket() as console, socket.socket() as adb:
                console.bind(("127.0.0.1", port))
                adb.bind(("127.0.0.1", port + 1))
                return port
        except OSError:
            continue
    raise ProbeError("Nessuna porta libera per l’emulatore Android")


class Devices:
    def __init__(self, work, run):
        self.work = work
        self.run = run
        self.ios = None
        self.emulator = None
        self.keep_ios = False

    def prepare(self, url, key):
        runtime = simulator_runtime()
        sdk = Path(os.environ.get("ANDROID_HOME", str(Path.home() / "Library/Android/sdk")))
        self.adb = str(sdk / "platform-tools/adb")
        port = free_emulator_port()
        self.serial = f"emulator-{port}"
        self.android_env = dict(os.environ, ANDROID_HOME=str(sdk), ANDROID_SERIAL=self.serial,
                                ANDROID_AVD_HOME=str(self.work / "avd"),
                                JAVA_HOME=checked(["/usr/libexec/java_home", "-v", "17"], "Java 17").strip())
        (self.work / "avd").mkdir()
        image = "system-images;android-36;default;arm64-v8a"
        checked([str(sdk / "cmdline-tools/latest/bin/avdmanager"), "create", "avd",
                 "--name", "S51b", "--package", image], "Creazione AVD API 36", input_text="no\n",
                env=self.android_env)
        print("Avvio emulatore Android", flush=True)
        emulator_log = self.work / "emulator.log"
        with emulator_log.open("w") as output:
            self.emulator = subprocess.Popen([
                str(sdk / "emulator/emulator"), "-avd", "S51b", "-port", str(port),
                "-gpu", "host", "-cores", "2", "-no-audio", "-no-snapshot", "-no-boot-anim",
            ], env=self.android_env, stdout=output, stderr=subprocess.STDOUT)
        deadline = time.monotonic() + 420
        while time.monotonic() < deadline:
            result = subprocess.run([self.adb, "-s", self.serial, "shell", "getprop", "sys.boot_completed"],
                                    capture_output=True, text=True, timeout=10)
            if result.stdout.strip() == "1":
                break
            if self.emulator.poll() is not None:
                raise ProbeError("L’emulatore Android si è arrestato all’avvio")
            time.sleep(2)
        else:
            for line in emulator_log.read_text(errors="replace").splitlines()[-12:]:
                print(line[:250], flush=True)
            raise ProbeError("Avvio Android scaduto")

        print("Build e installazione Android Debug", flush=True)
        checked(["./gradlew", "--max-workers=2", "installDebug", "installDebugAndroidTest", "-Pe2e=true",
                 f"-PsupabaseUrl={url}", f"-PsupabaseKey={key}",
                 f"-Pandroid.injected.device.serial={self.serial}"], "Build o installazione Android fallita",
                cwd=ANDROID, env=self.android_env, timeout=900)
        self.ios = checked(["xcrun", "simctl", "create", f"S51b-{self.run}",
                            "com.apple.CoreSimulator.SimDeviceType.iPhone-18-Pro", runtime],
                           "Creazione iPhone 18 Pro").strip()
        checked(["xcrun", "simctl", "boot", self.ios], "Avvio iPhone 18 Pro")
        self.destination = f"platform=iOS Simulator,id={self.ios}"
        print("Build XCTest e XCUITest per iPhone 18 Pro", flush=True)
        ios_build = Path(os.environ.get("MT_LIVE_DERIVED_DATA", str(self.work / "ios")))
        checked(["xcodebuild", "-scheme", "MoneyTracker", "-configuration", "Debug", "-jobs", "3", "-destination",
                 self.destination, "-derivedDataPath", str(ios_build), "-only-testing:" + IOS_TEST,
                 "-only-testing:" + IOS_UI_TEST, "build-for-testing"], "Build XCTest iOS fallita", timeout=900)
        files = list((ios_build / "Build/Products").glob("MoneyTracker_*.xctestrun"))
        if not files:
            raise ProbeError("File xctestrun della build Debug assente")
        self.test_run = max(files, key=lambda file: file.stat().st_mtime)

    def ios_test(self, bridge, phase, reopen=False):
        if reopen:
            subprocess.run(["xcrun", "simctl", "terminate", self.ios, BUNDLE],
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=30)
        configuration = plistlib.loads(self.test_run.read_bytes())
        targets = {target["BlueprintName"]: target for test in configuration["TestConfigurations"]
                   for target in test["TestTargets"]}
        test = targets["MoneyTrackerTests"]
        test.setdefault("CommandLineArguments", []).extend(["-E2EEnabled", "YES"])
        test.setdefault("EnvironmentVariables", {}).update({
            "MT_LIVE_BRIDGE": bridge,
            "MT_LIVE_RUN": self.run,
            "MT_LIVE_PHASE": phase,
            "MT_LIVE_REOPEN": "YES" if reopen else "NO",
        })
        selected = [IOS_TEST]
        if reopen:
            selected.append(IOS_UI_TEST)
            targets["MoneyTrackerUITests"].setdefault("EnvironmentVariables", {}).update({
                "MT_LIVE_RUN": self.run, "MT_LIVE_PHASE": phase,
            })
        run_file = self.test_run.with_name(f"S51b-{self.run}.xctestrun")
        self.generated_test_run = run_file
        run_file.write_bytes(plistlib.dumps(configuration))
        label = f"iOS {phase}" + (" riapertura" if reopen else "")
        result = checked(["xcodebuild", "-xctestrun", str(run_file), "-destination", self.destination,
                          "-parallel-testing-enabled", "NO", *["-only-testing:" + test for test in selected],
                          "test-without-building"], label, timeout=360)
        for test in selected:
            if f"{test.split('/')[-1]}]' passed" not in result:
                raise ProbeError(f"{label}: test {test.split('/')[-1]} non superato")

    def android_exchange(self, bridge, phase):
        result = checked([self.adb, "-s", self.serial, "shell", "am", "instrument", "-w", "-r",
                          "-e", "class", ANDROID_TEST, "-e", "mtBridge", bridge, "-e", "mtRun", self.run,
                          "-e", "mtPhase", phase, ANDROID_RUNNER],
                         f"Avvio strumentazione Android {phase}", timeout=130)
        if not re.search(r"^OK \(1 test\)", result, re.MULTILINE):
            message = next((line for line in result.splitlines()
                            if "AssertionError:" in line or line.startswith("INSTRUMENTATION_FAILED")), "")
            raise ProbeError(f"Android {phase} {message[:240]}")

    def stop_android_app(self):
        subprocess.run([self.adb, "-s", self.serial, "shell", "am", "force-stop", ANDROID_PACKAGE],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=20)

    def close(self):
        if hasattr(self, "generated_test_run"):
            self.generated_test_run.unlink(missing_ok=True)
        if self.emulator is not None:
            self.emulator.terminate()
            try:
                self.emulator.wait(timeout=15)
            except subprocess.TimeoutExpired:
                self.emulator.kill()
                self.emulator.wait()
        if self.ios is not None and self.keep_ios:
            print(f"Simulatore iOS conservato per il ripristino: {self.ios}", flush=True)
        elif self.ios is not None:
            for action in ("shutdown", "delete"):
                subprocess.run(["xcrun", "simctl", action, self.ios],
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=30)


def run_probe(devices, account, cloud, baseline):
    marker = secrets.token_urlsafe(24)
    passed = set()
    errors = []

    class Bridge(BaseHTTPRequestHandler):
        def log_message(self, *args):
            pass

        def do_GET(self):
            prefix, _, action = self.path.lstrip("/").partition("/")
            if not secrets.compare_digest(prefix, marker):
                self.send_error(404)
                return
            try:
                if action == "login":
                    body = {"email": account["MT_TEST_EMAIL"], "password": account["MT_TEST_PASSWORD"],
                            "user": cloud.user}
                elif action == "phrase":
                    body = account["MT_TEST_PHRASE"]
                elif action == "android-phrase":
                    body = {"phrase": account["MT_TEST_PHRASE"]}
                elif action in {"android-unlocked", "android-received"} or action.startswith("protection-"):
                    passed.add(action if action != "android-received" else f"{self.server.phase}:A")
                    body = True
                elif action == f"android-{self.server.phase}":
                    devices.android_exchange(f"http://10.0.2.2:{self.server.server_port}/{marker}", self.server.phase)
                    body = True
                else:
                    self.send_error(404)
                    return
            except (ProbeError, subprocess.TimeoutExpired) as error:
                errors.append(str(error) if isinstance(error, ProbeError) else "Strumentazione Android scaduta")
                self.send_error(502)
                return
            data = json.dumps(body).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Cache-Control", "no-store")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

    with ThreadingHTTPServer(("127.0.0.1", 0), Bridge) as server:
        bridge = f"http://127.0.0.1:{server.server_port}/{marker}"
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            for phase in PHASES:
                print(f"Fase {phase} in corso", flush=True)
                server.phase = phase
                try:
                    devices.ios_test(bridge, phase)
                    passed.add(f"{phase}:B")
                except (ProbeError, subprocess.TimeoutExpired) as error:
                    errors.append(str(error) if isinstance(error, ProbeError) else f"Scambio {phase} scaduto")
                    if f"protection-{phase}" not in passed:
                        break
                try:
                    devices.ios_test(bridge, phase, reopen=True)
                    passed.add(f"{phase}:reopen")
                except (ProbeError, subprocess.TimeoutExpired) as error:
                    errors.append(str(error) if isinstance(error, ProbeError) else f"Riapertura {phase} scaduta")
        except (ProbeError, subprocess.TimeoutExpired, KeyboardInterrupt) as error:
            errors.append(str(error) if isinstance(error, ProbeError) else type(error).__name__)
        finally:
            # Keep the only device with the migration marker until the server confirms OFF.
            devices.keep_ios = "protection-protetta" in passed or getattr(server, "phase", None) in {"protetta", "dopo"}
            try:
                if cloud.protection():
                    devices.stop_android_app()
                    devices.ios_test(bridge, "ripristino")
                if cloud.protection():
                    raise ProbeError("Protezione finale ancora attiva")
                devices.keep_ios = False
                final = cloud.ids()
                if any(not baseline[table] <= final[table] for table in TABLES):
                    raise ProbeError("Verifica finale: mancano record preesistenti")
                print("Protezione finale disattivata · record preesistenti presenti", flush=True)
            except (ProbeError, subprocess.TimeoutExpired) as error:
                errors.append(f"Ripristino finale KO ({type(error).__name__}: {error})")
            server.shutdown()
            thread.join()

    outcomes = [("prima:A", "1 · iOS → Android"),
                ("prima:B", "2 · Android → iOS"),
                ("prima:reopen", "3 · Riapertura iOS senza doppioni"),
                ("protection-protetta", "4 · Attivazione su iOS"),
                ("android-unlocked", "4 · Sblocco su Android"),
                ("protetta:A", "4 · iOS → Android"),
                ("protetta:B", "4 · Android → iOS"),
                ("protetta:reopen", "4 · Riapertura iOS senza doppioni"),
                ("protection-dopo", "5 · Disattivazione su iOS"),
                ("dopo:A", "5 · iOS → Android"),
                ("dopo:B", "5 · Android → iOS"),
                ("dopo:reopen", "5 · Riapertura iOS senza doppioni")]
    for key, label in outcomes:
        print(f"{'OK' if key in passed else 'KO / non completato'}  {label}")
    for error in errors:
        print(f"KO  {error}")
    return not errors and all(key in passed for key, _ in outcomes)


def main():
    account = account_values()
    url, key = supabase_config()
    cloud = Cloud(url, key, account)
    if cloud.protection():
        raise ProbeError("Prima della prova l’account dedicato deve avere la Protezione avanzata disattivata.")
    baseline = cloud.ids()
    if not account.get("MT_TEST_PHRASE"):
        phrase = secrets.token_hex(24)
        ACCOUNT.chmod(0o600)
        with ACCOUNT.open("a") as handle:
            handle.write(f"\nMT_TEST_PHRASE={phrase}\n")
        account["MT_TEST_PHRASE"] = phrase

    with tempfile.TemporaryDirectory(prefix="s51b-") as directory:
        devices = Devices(Path(directory), secrets.token_hex(6))
        try:
            print("Preparazione dispositivi virtuali e build Debug", flush=True)
            devices.prepare(url, key)
            return 0 if run_probe(devices, account, cloud, baseline) else 1
        finally:
            devices.close()


if __name__ == "__main__":
    def abort(_signal, _frame):
        raise KeyboardInterrupt

    signal.signal(signal.SIGTERM, abort)
    try:
        raise SystemExit(main())
    except (ProbeError, subprocess.TimeoutExpired, KeyboardInterrupt, OSError, KeyError, ValueError) as error:
        detail = str(error) if isinstance(error, ProbeError) else type(error).__name__
        raise SystemExit(f"KO  {detail}") from None
