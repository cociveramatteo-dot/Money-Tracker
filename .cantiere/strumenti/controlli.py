#!/usr/bin/env python3
"""Controlli statici del collaudatore (solo libreria standard, Python >= 3.8).

Uso: python3 .cantiere/strumenti/controlli.py [cartella_codice] [--json]

Controlla: JSON validi, marcatori di conflitto git, possibili segreti, debug dimenticato,
TODO/FIXME, file pesanti e, per i siti statici, link locali rotti, alt mancanti, title/viewport,
link WhatsApp malformati.
Stampa un rapporto Markdown (o JSON con --json, usato da pagella.py).
Exit code: 0 = ok, 1 = avvisi, 2 = errori.
"""
from __future__ import annotations

import json
import re
import sys
from dataclasses import dataclass, field
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlparse

IGNORA_DIR = {".git", "node_modules", "graphify-out", ".venv", "venv", "__pycache__",
              "dist", "build", ".next", ".netlify", ".cache", ".cantiere", ".claude"}
TESTO_EXT = {".html", ".htm", ".css", ".js", ".mjs", ".cjs", ".ts", ".tsx", ".jsx", ".json",
             ".py", ".md", ".toml", ".yml", ".yaml", ".txt", ".svg", ".vue", ".svelte", ".php"}
CODICE_EXT = {".js", ".mjs", ".cjs", ".ts", ".tsx", ".jsx", ".py", ".vue", ".svelte", ".php"}
MAX_TESTO_BYTE = 2_000_000
SOGLIA_PESANTE_BYTE = 1_000_000  # immagini/asset oltre 1 MB nel codice: da ottimizzare

SEGRETI = [
    ("chiave privata", re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----")),
    ("chiave AWS", re.compile(r"\bAKIA[0-9A-Z]{16}\b")),
    ("token Anthropic/OpenAI", re.compile(r"\bsk-(?:ant-)?[A-Za-z0-9_\-]{20,}\b")),
    ("token GitHub", re.compile(r"\bgh[pousr]_[A-Za-z0-9]{30,}\b")),
    ("chiave Google API", re.compile(r"\bAIza[0-9A-Za-z_\-]{35}\b")),
    ("chiave Stripe live", re.compile(r"\b[sr]k_live_[0-9A-Za-z]{20,}\b")),
    ("password in chiaro", re.compile(r"""(?i)\b(?:password|passwd|pwd|secret|api_?key)\s*[:=]\s*["'][^"'\s]{6,}["']""")),
]
CONFLITTO = re.compile(r"^(?:<{7}|>{7}|={7})(?:\s|$)", re.M)
DEBUG = re.compile(r"\bconsole\.(?:log|debug)\s*\(|\bdebugger\s*;|^\s*print\(|\bbreakpoint\(\)", re.M)
DEBUG_HTML = re.compile(r"\bconsole\.(?:log|debug)\s*\(|\bdebugger\s*;")
TODO = re.compile(r"\b(?:TODO|FIXME|XXX|HACK)\b")
DA_COMPLETARE = re.compile(r"\[DA[ _]COMPLETARE\]|DA_CHIEDERE")
HTTP_RISORSA = re.compile(r"""(?:src|href)\s*=\s*["']http://""", re.I)
WA = re.compile(r"https?://(?:wa\.me|api\.whatsapp\.com)/[^\s\"'<>)]*")
WA_OK = re.compile(r"^https://wa\.me/\d{8,15}(?:\?text=[^\s]*)?$|^https://api\.whatsapp\.com/send\?phone=\d{8,15}")


@dataclass
class Rapporto:
    errori: list[str] = field(default_factory=list)
    avvisi: list[str] = field(default_factory=list)
    info: list[str] = field(default_factory=list)
    conteggi: dict[str, int] = field(default_factory=dict)

    def conta(self, chiave: str, n: int = 1) -> None:
        self.conteggi[chiave] = self.conteggi.get(chiave, 0) + n

    def stampa(self) -> int:
        print("## Controlli statici\n")
        for titolo, voci, icona in (("Errori", self.errori, "🔴"), ("Avvisi", self.avvisi, "🟡"), ("Info", self.info, "ℹ️")):
            print(f"### {icona} {titolo} ({len(voci)})")
            for v in voci[:60]:
                print(f"- {v}")
            if len(voci) > 60:
                print(f"- … e altri {len(voci) - 60}")
            print()
        return 2 if self.errori else (1 if self.avvisi else 0)


class AnalizzatoreHTML(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.riferimenti: list[tuple[str, str, int]] = []  # (tag, url, riga)
        self.img_senza_alt: list[int] = []
        self.ha_title = False
        self.ha_viewport = False
        self.ha_lang = False
        self.ids: set[str] = set()

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        a = {k: (v or "") for k, v in attrs}
        riga = self.getpos()[0]
        if "id" in a:
            self.ids.add(a["id"])
        if tag == "html" and a.get("lang"):
            self.ha_lang = True
        if tag == "title":
            self.ha_title = True
        if tag == "meta" and a.get("name", "").lower() == "viewport":
            self.ha_viewport = True
        if tag == "img" and "alt" not in a:
            self.img_senza_alt.append(riga)
        for attr in ("href", "src"):
            if a.get(attr):
                self.riferimenti.append((tag, a[attr], riga))
        if a.get("srcset"):
            for parte in a["srcset"].split(","):
                url = parte.strip().split(" ")[0]
                if url:
                    self.riferimenti.append((tag, url, riga))


def file_del_progetto(radice: Path):
    for p in radice.rglob("*"):
        if any(parte in IGNORA_DIR for parte in p.relative_to(radice).parts):
            continue
        if p.is_file():
            yield p


def leggi_testo(p: Path) -> str | None:
    try:
        if p.stat().st_size > MAX_TESTO_BYTE:
            return None
        return p.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError):
        return None


def radice_web(radice: Path) -> Path:
    """Cartella servita come "/" del sito: quella con index.html più vicina alla radice (es. public/)."""
    if (radice / "index.html").is_file():
        return radice
    candidati = sorted((p.parent for p in radice.rglob("index.html")
                        if not any(x in IGNORA_DIR for x in p.relative_to(radice).parts)),
                       key=lambda d: len(d.relative_to(radice).parts))
    return candidati[0] if candidati else radice


def controlla_html(p: Path, testo: str, radice: Path, r: Rapporto, web: Path | None = None) -> None:
    an = AnalizzatoreHTML()
    try:
        an.feed(testo)
    except Exception as e:  # HTMLParser è tollerante, ma per sicurezza
        r.errori.append(f"`{p.relative_to(radice)}`: HTML non analizzabile ({e})")
        r.conta("html_rotto")
        return
    rel = p.relative_to(radice)
    if not an.ha_title:
        r.avvisi.append(f"`{rel}`: manca <title>"); r.conta("html_meta")
    if not an.ha_viewport:
        r.avvisi.append(f"`{rel}`: manca <meta name=viewport> (il sito non sarà responsive)"); r.conta("html_meta")
    if not an.ha_lang:
        r.avvisi.append(f"`{rel}`: manca l'attributo lang su <html>"); r.conta("html_meta")
    for riga in an.img_senza_alt:
        r.avvisi.append(f"`{rel}:{riga}`: <img> senza alt"); r.conta("alt_mancanti")
    for tag, url, riga in an.riferimenti:
        u = urlparse(url)
        if u.scheme in ("http", "https", "mailto", "tel", "data", "javascript", "sms") or url.startswith("//"):
            continue
        if url.startswith("#"):
            if len(url) > 1 and url[1:] not in an.ids:
                r.avvisi.append(f"`{rel}:{riga}`: ancora `{url}` senza elemento con quell'id"); r.conta("ancore_rotte")
            continue
        if "{{" in url or "${" in url:
            continue  # template
        percorso = unquote(u.path)
        if not percorso:
            continue
        base = web if (web is not None and web in p.parents) else radice
        bersaglio = (base / percorso.lstrip("/")) if percorso.startswith("/") else (p.parent / percorso)
        if percorso.endswith("/"):
            bersaglio = bersaglio / "index.html"
        if not bersaglio.exists() and not bersaglio.with_suffix(".html").exists():
            r.errori.append(f"`{rel}:{riga}`: <{tag}> punta a `{url}` che non esiste"); r.conta("link_rotti")


def analizza(radice: Path) -> Rapporto:
    r = Rapporto()
    web = radice_web(radice)
    n_file = n_todo = n_debug = 0

    for p in file_del_progetto(radice):
        n_file += 1
        rel = p.relative_to(radice)
        ext = p.suffix.lower()
        try:
            dim = p.stat().st_size
        except OSError:
            continue
        if ext not in TESTO_EXT and dim > SOGLIA_PESANTE_BYTE:
            r.avvisi.append(f"`{rel}`: {dim / 1_000_000:.1f} MB, da ottimizzare (WebP/AVIF, compressione)"); r.conta("file_pesanti")
        if ext not in TESTO_EXT:
            continue
        testo = leggi_testo(p)
        if testo is None:
            continue
        if CONFLITTO.search(testo):
            r.errori.append(f"`{rel}`: marcatori di conflitto git (<<<<<<< / >>>>>>>)"); r.conta("conflitti")
        for nome, rx in SEGRETI:
            if rx.search(testo):
                r.errori.append(f"`{rel}`: possibile {nome} nel codice"); r.conta("segreti")
        if ext in (".html", ".htm", ".css") and HTTP_RISORSA.search(testo):
            r.avvisi.append(f"`{rel}`: risorse caricate in http:// (non sicuro)"); r.conta("http_non_sicuro")
        dc = len(DA_COMPLETARE.findall(testo))
        if dc:
            r.conta("da_completare", dc)
        if ext == ".json":
            try:
                json.loads(testo)
            except json.JSONDecodeError as e:
                r.errori.append(f"`{rel}:{e.lineno}`: JSON non valido ({e.msg})"); r.conta("json_rotti")
        script_di_servizio = "scripts" in rel.parts or "tools" in rel.parts or rel.stem in ("build", "gulpfile", "vite.config")
        if (ext in CODICE_EXT or ext in (".html", ".htm")) and not script_di_servizio:  # nei programmi da terminale console.log è normale
            d = len((DEBUG_HTML if ext in (".html", ".htm") else DEBUG).findall(testo))
            if d:
                n_debug += d
                r.avvisi.append(f"`{rel}`: {d} istruzioni di debug (console.log/print/debugger)")
        n_todo += len(TODO.findall(testo))
        for url in WA.findall(testo):
            if url.rstrip("/") in ("https://wa.me", "http://wa.me") or url.endswith("phone="):
                continue  # prefisso a cui il codice aggiunge il numero
            if not WA_OK.match(url):
                r.avvisi.append(f"`{rel}`: link WhatsApp sospetto `{url[:80]}` (formato: https://wa.me/39XXXXXXXXXX)"); r.conta("whatsapp_sospetti")
        if ext in (".html", ".htm"):
            controlla_html(p, testo, radice, r, web)

    r.info.append(f"File controllati: {n_file}")
    r.info.append(f"TODO/FIXME presenti: {n_todo}")
    r.info.append(f"Istruzioni di debug: {n_debug}")
    r.info.append(f"Segnaposto [DA COMPLETARE]: {r.conteggi.get('da_completare', 0)}")
    r.conta("file", n_file); r.conta("todo", n_todo); r.conta("debug", n_debug)
    return r


def main() -> int:
    argomenti = [a for a in sys.argv[1:] if not a.startswith("--")]
    radice = Path(argomenti[0] if argomenti else ".").resolve()
    if not radice.is_dir():
        print(f"Cartella non trovata: {radice}", file=sys.stderr)
        return 2
    r = analizza(radice)
    if "--json" in sys.argv:
        print(json.dumps({"errori": r.errori, "avvisi": r.avvisi, "conteggi": r.conteggi}, ensure_ascii=False))
        return 2 if r.errori else (1 if r.avvisi else 0)
    return r.stampa()


if __name__ == "__main__":
    sys.exit(main())
