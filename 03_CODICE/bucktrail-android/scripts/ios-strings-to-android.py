#!/usr/bin/env python3
"""Genera le risorse stringa Android dai cataloghi iOS (deterministico, rieseguibile).

Uso (dalla cartella bucktrail-android):  python3 scripts/ios-strings-to-android.py
Sorgente: ../../MoneyTracker/<lang>.lproj/Localizable.strings + .stringsdict
          scripts/android-extra-strings.json (stringhe che esistono solo su Android)
Uscita:   app/src/main/res/values*/strings.xml, scripts/strings-map.json (chiave iOS -> nome risorsa)
Esce con codice != 0 se un segnaposto differisce tra lingue.
"""
import json, plistlib, re, sys, unicodedata, zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
IOS = ROOT.parent.parent / "MoneyTracker"
RES = ROOT / "app/src/main/res"
LANGS = {"it": "values", "en": "values-en", "de": "values-de", "es": "values-es",
         "fr": "values-fr", "ja": "values-ja", "zh-Hans": "values-b+zh+Hans"}
PAIR = re.compile(r'^"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;\s*$')
SPEC = re.compile(r'%(?:(\d+)\$)?(@|lld|ld|d|\.\d+f|f|s)')


def unescape(s):
    return (s.replace('\\n', '\n').replace('\\"', '"').replace('\\\\', '\\'))


def parse_strings(path):
    out = {}
    if not path.exists():
        return out
    for line in path.read_text(encoding="utf-8").splitlines():
        m = PAIR.match(line.strip())
        if m:
            out[unescape(m.group(1))] = unescape(m.group(2))
    return out


def slug(key):
    s = unicodedata.normalize("NFKD", key).encode("ascii", "ignore").decode()
    s = re.sub(r"[^a-z0-9]+", "_", s.lower()).strip("_")[:40].strip("_")
    s = s or "s"
    return "s_" + s if s[0].isdigit() else s


def specs(s):
    return [m.group(2) for m in SPEC.finditer(s)]


def esc(seg):
    return seg.replace("%%", "\0").replace("%", "%%").replace("\0", "%%")


def to_android(s):
    """Converte i segnaposto iOS e fa l'escape per strings.xml. Ritorna (testo, ha_segnaposto)."""
    found = list(SPEC.finditer(s))
    out, last, idx = [], 0, 0
    positional = len(found) > 1
    for m in found:
        out.append(esc(s[last:m.start()]))
        idx += 1
        n = m.group(1) or (str(idx) if positional else None)
        kind = m.group(2)
        conv = {"@": "s", "s": "s", "lld": "d", "ld": "d", "d": "d", "f": "f"}.get(kind, kind)
        out.append("%" + (n + "$" if n else "") + conv)
        last = m.end()
    out.append(esc(s[last:]) if found else s[last:])
    text = "".join(out)
    return text, bool(found)


def xml_escape(s):
    s = s.replace("\\", "\\\\").replace("'", "\\'").replace('"', '\\"').replace("\n", "\\n")
    s = s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    s = s.replace("@", "\\@") if s.startswith("@") else s
    s = s.replace("?", "\\?") if s.startswith("?") else s
    return s


def main():
    cat = {lang: parse_strings(IOS / f"{lang}.lproj/Localizable.strings") for lang in LANGS}
    plist = plistlib.loads((IOS / "en.lproj/Localizable.stringsdict").read_bytes())
    keys = sorted(k for k in cat["en"].keys() if k not in plist)
    names, used = {}, {}
    for k in keys:
        base = slug(k)
        name = base
        if name in used and used[name] != k:
            name = f"{base}_{zlib.crc32(k.encode()) & 0xFFFFFF:06x}"
        used[name] = k
        names[k] = name
    extra = json.loads((ROOT / "scripts/android-extra-strings.json").read_text(encoding="utf-8"))
    for n in extra:
        if n in used:
            sys.exit(f"nome extra duplicato: {n}")

    errors = []
    for lang, folder in LANGS.items():
        lines = ['<?xml version="1.0" encoding="utf-8"?>',
                 "<!-- GENERATO da scripts/ios-strings-to-android.py: non modificare a mano -->",
                 "<resources>"]
        if lang == "it":
            lines.append('    <string name="app_name" translatable="false">Bucktrail</string>')
        for k in keys:
            value = cat[lang].get(k) or (k if lang == "it" and not k.startswith("demo.") else cat["it"].get(k) or k)
            if lang != "it":
                ref = cat["en"][k]
                if sorted(specs(value)) != sorted(specs(ref)) and cat[lang].get(k):
                    errors.append(f"{lang}: segnaposto diversi per «{k}»")
            text, has = to_android(value)
            attr = "" if has else ' formatted="false"'
            if not has:
                text = text.replace("%%", "%")
            lines.append(f'    <string name="{names[k]}"{attr}>{xml_escape(text)}</string>')
        for n, tr in sorted(extra.items()):
            value = tr.get(lang) or tr["it"]
            text, has = to_android(value)
            attr = "" if has else ' formatted="false"'
            if not has:
                text = text.replace("%%", "%")
            lines.append(f'    <string name="{n}"{attr}>{xml_escape(text)}</string>')
        # plurals (unica voce iOS: giorni mancanti)
        for pk, pv in sorted(plist.items()):
            lp = plistlib.loads((IOS / f"{lang}.lproj/Localizable.stringsdict").read_bytes()) if (IOS / f"{lang}.lproj/Localizable.stringsdict").exists() else plist
            forms = lp.get(pk, pv)["days"] if pk in lp else pv["days"]
            pname = "plurale_" + slug(pk)
            lines.append(f'    <plurals name="{pname}">')
            order = ["other"] if lang in ("ja", "zh-Hans") else ["one", "other"]
            for q in order:
                t, _ = to_android(forms.get(q, forms["other"]))
                lines.append(f'        <item quantity="{q}">{xml_escape(t)}</item>')
            lines.append("    </plurals>")
        lines.append("</resources>\n")
        d = RES / folder
        d.mkdir(parents=True, exist_ok=True)
        (d / "strings.xml").write_text("\n".join(lines), encoding="utf-8")
    (ROOT / "scripts/strings-map.json").write_text(json.dumps(names, ensure_ascii=False, indent=1, sort_keys=True) + "\n", encoding="utf-8")
    (RES / "xml").mkdir(parents=True, exist_ok=True)
    (RES / "xml/locales_config.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n<locale-config xmlns:android="http://schemas.android.com/apk/res/android">\n'
        + "".join(f'    <locale android:name="{t}"/>\n' for t in ["it", "en", "de", "es", "fr", "ja", "zh-Hans"])
        + "</locale-config>\n", encoding="utf-8")
    if errors:
        print("\n".join(errors)); sys.exit(1)
    print(f"ok: {len(keys)} chiavi, {len(extra)} extra, {len(LANGS)} lingue")


if __name__ == "__main__":
    main()
