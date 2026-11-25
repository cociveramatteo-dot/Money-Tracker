#!/usr/bin/env python3
"""Generate or verify the v1 interoperability fixture using the standard library.

AES-GCM values for `--generate --aes-results FILE` come from E2ECryptoTests.
FILE is a JSON object with envelope, wrapped_key_passphrase and wrapped_key_recovery.
Without FILE, generation keeps the AES-GCM values from the existing fixture.
"""

import argparse
import base64
import hashlib
import hmac
import json
from pathlib import Path
import re
import unicodedata


FIXTURE = Path(__file__).resolve().parents[3] / "MoneyTrackerTests/Fixtures/e2e-vectors-v1.json"
CROCKFORD = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
RECOVERY_INFO = b"bucktrail/e2e/v1/recovery"
KEY_ID_INFO = b"bucktrail/e2e/v1/key-id"


def b64url(data):
    return base64.urlsafe_b64encode(data).decode("ascii").rstrip("=")


def unb64url(value):
    if re.fullmatch(r"[A-Za-z0-9_-]*", value) is None:
        raise ValueError("invalid base64url alphabet")
    data = base64.b64decode(value + "=" * (-len(value) % 4), altchars=b"-_", validate=True)
    if b64url(data) != value:
        raise ValueError("noncanonical base64url")
    return data


def pbkdf2(phrase, salt, iterations):
    password = unicodedata.normalize("NFC", phrase).encode("utf-8")
    return hashlib.pbkdf2_hmac("sha256", password, salt, iterations, dklen=32)


def hkdf(ikm, salt, info, length):
    prk = hmac.digest(salt or bytes(32), ikm, "sha256")
    blocks = []
    previous = b""
    for counter in range(1, (length + 31) // 32 + 1):
        previous = hmac.digest(prk, previous + info + bytes([counter]), "sha256")
        blocks.append(previous)
    return b"".join(blocks)[:length]


def crockford_format(data):
    number = int.from_bytes(data, "big")
    symbols = "".join(CROCKFORD[(number >> shift) & 31] for shift in range(155, -1, -5))
    return "-".join(symbols[i:i + 4] for i in range(0, 32, 4))


def crockford_parse(text):
    ascii_text = text.encode("ascii").decode("ascii")
    symbols = ascii_text.upper().translate(str.maketrans("OIL", "011", "- \t\n\r\v\f"))
    if len(symbols) != 32 or any(symbol not in CROCKFORD for symbol in symbols):
        raise ValueError("invalid Crockford key")
    number = 0
    for symbol in symbols:
        number = (number << 5) | CROCKFORD.index(symbol)
    return number.to_bytes(20, "big")


def envelope_bytes(value, nonce_hex, cleartext_length):
    if not value.startswith("bt1."):
        raise ValueError("invalid v1 prefix")
    combined = unb64url(value[4:])
    if len(combined) != 12 + cleartext_length + 16 or combined[:12].hex() != nonce_hex:
        raise ValueError("envelope nonce or length does not match the vector")
    return combined


def vectors(sealed):
    # McGrew–Viega, GCM revised specification, test case 16.
    kat = {
        "key_hex": "feffe9928665731c6d6a8f9467308308" * 2,
        "nonce_hex": "cafebabefacedbaddecaf888",
        "aad_hex": "feedfacedeadbeeffeedfacedeadbeefabaddad2",
        "plaintext_hex": (
            "d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a72"
            "1c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39"
        ),
        "ciphertext_hex": (
            "522dc1f099567d07f47f37a32a84427d643a8cdcbfe5c0c97598a2bd2555d1aa"
            "8cb08e48590dbb3da7b08b1056828838c5f61e6393ba7a0abcc9f662"
        ),
        "tag_hex": "76fc6ece0f4e1768cddf8853bb2d551b",
    }
    kat["envelope"] = "bt1." + b64url(bytes.fromhex(kat["nonce_hex"] + kat["ciphertext_hex"] + kat["tag_hex"]))

    # RFC 5869, Appendix A.1.
    rfc = {
        "ikm_hex": "0b" * 22,
        "salt_hex": "000102030405060708090a0b0c",
        "info_hex": "f0f1f2f3f4f5f6f7f8f9",
        "length": 42,
        "okm_hex": "3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf34007208d5b887185865",
    }
    if hkdf(*(bytes.fromhex(rfc[field]) for field in ("ikm_hex", "salt_hex", "info_hex")), rfc["length"]).hex() != rfc["okm_hex"]:
        raise ValueError("RFC 5869 KAT failed")

    phrase = "Bucktrail test passphrase"
    unicode_phrase = unicodedata.normalize("NFD", "Pässwörd 日本 🔑 è")
    salt = bytes(range(16))
    rounds = 600_000
    pbkdf2_cases = [
        {
            "passphrase": password,
            "salt": b64url(salt),
            "iterations": iterations,
            "kek_hex": pbkdf2(password, salt, iterations).hex(),
        }
        for password, iterations in ((phrase, 1000), (phrase, rounds), (unicode_phrase, rounds))
    ]
    crockford_cases = []
    for raw, text in (
        (bytes(20), "oOoo - 0O00 " + "0000-" * 5 + "0000"),
        (bytes([8, 66, 16, 132, 33]) * 4, "l1iI-1111-" + "1111-" * 5 + "1111"),
        (bytes([255]) * 20, "zzzz-" * 7 + "zzzz"),
        (bytes(range(20)), None),
    ):
        formatted = crockford_format(raw)
        text = formatted if text is None else text
        if crockford_parse(text) != raw:
            raise ValueError("Crockford round trip failed")
        crockford_cases.append({"bytes_hex": raw.hex(), "formatted": formatted, "input": text})

    user = "abcdefab-cdef-4abc-8def-abcdefabcdef"
    row = "12345678-abcd-4ef0-8123-abcdef012345"
    dek = bytes(range(32))
    recovery = bytes(range(20))
    envelope = {
        "key_hex": dek.hex(),
        "nonce_hex": "00112233445566778899aabb",
        "kind": "transaction",
        "id": row,
        "user_id": user,
        "aad": f"bucktrail/e2e/v1/row/transaction/{row}/{user}",
        "plaintext": '{"amount":12.34,"memo":"caffè 日本 🔑"}',
        "sealed": sealed["envelope"],
    }
    combined = envelope_bytes(envelope["sealed"], envelope["nonce_hex"], len(envelope["plaintext"].encode("utf-8")))
    wrap = {
        "user_id": user,
        "passphrase": unicode_phrase,
        "salt": b64url(salt),
        "iterations": rounds,
        "dek_hex": dek.hex(),
        "recovery_key": crockford_format(recovery),
        "recovery_kek_hex": hkdf(recovery, b"", RECOVERY_INFO, 32).hex(),
        "passphrase_aad": f"bucktrail/e2e/v1/wrap/passphrase/{user}",
        "recovery_aad": f"bucktrail/e2e/v1/wrap/recovery/{user}",
        "passphrase_nonce_hex": "101112131415161718191a1b",
        "recovery_nonce_hex": "202122232425262728292a2b",
        "wrapped_key_passphrase": sealed["wrapped_key_passphrase"],
        "wrapped_key_recovery": sealed["wrapped_key_recovery"],
        "key_id": hmac.digest(dek, KEY_ID_INFO, "sha256")[:8].hex(),
    }
    envelope_bytes(wrap["wrapped_key_passphrase"], wrap["passphrase_nonce_hex"], len(dek))
    envelope_bytes(wrap["wrapped_key_recovery"], wrap["recovery_nonce_hex"], len(dek))

    changed_row = "12345679" + row[8:]
    changed_user = "abcdefac" + user[8:]
    return {
        "aes_gcm_kat": kat,
        "hkdf_rfc5869": rfc,
        "pbkdf2": pbkdf2_cases,
        "crockford": crockford_cases,
        "envelope": envelope,
        "wrap": wrap,
        "negative": {
            "tag_altered": "bt1." + b64url(combined[:-1] + bytes([combined[-1] ^ 1])),
            "unsupported_version": "bt2." + envelope["sealed"][4:],
            "invalid_base64": "bt1.%%%%",
            "wrong_id_aad": f"bucktrail/e2e/v1/row/transaction/{changed_row}/{user}",
            "wrong_kind_aad": f"bucktrail/e2e/v1/row/budget/{row}/{user}",
            "wrong_user_aad": f"bucktrail/e2e/v1/row/transaction/{row}/{changed_user}",
            "wrong_passphrase": "another test passphrase",
            "wrong_recovery_key": "1" + wrap["recovery_key"][1:],
        },
    }


def check_nonce_calls():
    root = FIXTURE.parents[2] / "MoneyTracker"
    for path in root.rglob("*.swift"):
        source = path.read_text(encoding="utf-8")
        if path == root / "Sync/E2E/VaultCrypto.swift":
            source = re.sub(r"\bfunc\s+sealForTest\b", "func", source)
        if re.search(r"\bsealForTest\b", source):
            raise ValueError(f"fixed nonce used by application code: {path}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--check", action="store_true")
    mode.add_argument("--generate", action="store_true")
    parser.add_argument("--aes-results", type=Path)
    parser.add_argument("fixture", nargs="?", type=Path, default=FIXTURE)
    args = parser.parse_args()
    if args.aes_results and not args.generate:
        parser.error("--aes-results requires --generate")
    try:
        current = json.loads(args.fixture.read_text(encoding="utf-8")) if args.fixture.exists() else {}
        if args.aes_results:
            sealed = json.loads(args.aes_results.read_text(encoding="utf-8"))
        else:
            sealed = {
                "envelope": current["envelope"]["sealed"],
                "wrapped_key_passphrase": current["wrap"]["wrapped_key_passphrase"],
                "wrapped_key_recovery": current["wrap"]["wrapped_key_recovery"],
            }
        expected = vectors(sealed)
        if args.check:
            for group, values in expected.items():
                if current.get(group) != values:
                    raise ValueError(f"vector group differs: {group}")
            check_nonce_calls()
            print(f"OK: {len(expected)} vector groups, independent KDF/codecs and production nonce check")
        else:
            current.update(expected)
            args.fixture.write_text(json.dumps(current, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    except (KeyError, OSError, ValueError) as error:
        parser.exit(1, f"{error}\n")


if __name__ == "__main__":
    main()
