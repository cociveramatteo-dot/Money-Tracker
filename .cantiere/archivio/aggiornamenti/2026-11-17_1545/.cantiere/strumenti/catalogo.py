#!/usr/bin/env python3
"""Catalogo del magazzino: l'inventario che permette alle IA di sapere DOVE sta una cosa
senza aprire le cartelle.

Uso: python3 .cantiere/strumenti/catalogo.py [--stampa]

Legge la cartella del cantiere nel magazzino (da .cantiere/cantiere.json, campo "magazzino",
oppure dal collegamento 00_CLIENTE) e riscrive <magazzino>/CATALOGO.md con una riga per file:
percorso, tipo, dimensione, data, descrizione, parole chiave.
Le cartelle "blocco" (backup, siti vecchi, export: più di 40 file, o nome che inizia con backup/sito-attuale/
export/wp-) diventano UNA riga sola (`cartella/`, tipo "cartella · N file"): si descrivono una volta, non file per file.
Le descrizioni e le parole chiave già scritte vengono CONSERVATE (chiave = percorso).
Non apre il contenuto dei file (con Drive in streaming non li scarica). Solo libreria standard.
"""
from __future__ import annotations

import datetime as dt
import json
import re
import sys
from pathlib import Path

IGNORA = {".DS_Store", "Thumbs.db", "desktop.ini", ".gitkeep", "CATALOGO.md"}
IGNORA_DIR = {".tmp.drivedownload", ".tmp.driveupload", "__MACOSX"}
TIPI = {
    "immagine": {".jpg", ".jpeg", ".png", ".webp", ".avif", ".gif", ".svg", ".heic", ".tif", ".tiff"},
    "video": {".mp4", ".mov", ".m4v", ".webm", ".avi"},
    "documento": {".pdf", ".doc", ".docx", ".odt", ".rtf", ".pages", ".txt", ".md"},
    "foglio": {".xls", ".xlsx", ".csv", ".ods", ".numbers"},
    "presentazione": {".ppt", ".pptx", ".key", ".odp"},
    "archivio": {".zip", ".rar", ".7z", ".tar", ".gz", ".tgz"},
    "grafica": {".ai", ".psd", ".fig", ".sketch", ".eps", ".indd"},
    "dati": {".json", ".xml", ".yml", ".yaml", ".sql"},
    "audio": {".mp3", ".wav", ".m4a", ".aac", ".ogg"},
    "font": {".ttf", ".otf", ".woff", ".woff2"},
}
RIGA = re.compile(r"^\|\s*`([^`]+)`\s*\|[^|]*\|[^|]*\|[^|]*\|\s*(.*?)\s*\|\s*(.*?)\s*\|\s*$")
MAX_VOCI = 5000
SOGLIA_BLOCCO = 40  # una cartella con più file di così si cataloga come un blocco unico
CONTENITORI = {"00_CLIENTE", "02_RISORSE", "04_CONSEGNE", "originali", "lavorate", "CANTIERI"}
NOMI_BLOCCO = re.compile(r"^(backup|sito[-_ ]?attuale|sito[-_ ]?vecchio|export|wp[-_]|wordpress)", re.I)


def trova_magazzino(radice: Path) -> Path | None:
    conf = radice / ".cantiere" / "cantiere.json"
    if conf.is_file():
        try:
            m = json.loads(conf.read_text(encoding="utf-8")).get("magazzino", "")
            if m and Path(m).expanduser().is_dir():
                return Path(m).expanduser()
        except (json.JSONDecodeError, OSError):
            pass
    cliente = radice / "00_CLIENTE"
    if cliente.is_symlink() and cliente.resolve().is_dir():
        return cliente.resolve().parent
    return None


def tipo_di(p: Path) -> str:
    ext = p.suffix.lower()
    return next((t for t, exts in TIPI.items() if ext in exts), ext.lstrip(".") or "file")


def dimensione(n: int) -> str:
    for unita in ("B", "KB", "MB", "GB"):
        if n < 1024 or unita == "GB":
            return f"{n:.0f} {unita}" if unita == "B" else f"{n:.1f} {unita}"
        n /= 1024
    return f"{n:.1f} GB"


def main() -> int:
    radice = Path.cwd()
    for c in (radice, *radice.parents):
        if (c / ".cantiere").is_dir():
            radice = c
            break
    mag = trova_magazzino(radice)
    if mag is None:
        print("🔴 Magazzino non trovato: controlla .cantiere/cantiere.json (campo \"magazzino\") e che Google Drive sia aperto.")
        return 2

    cat = mag / "CATALOGO.md"
    vecchie: dict[str, tuple[str, str]] = {}
    if cat.is_file():
        for riga in cat.read_text(encoding="utf-8").splitlines():
            m = RIGA.match(riga)
            if m:
                vecchie[m.group(1)] = (m.group(2), m.group(3))

    voci = []

    def conta(cartella: Path) -> tuple[int, int, float]:
        n = b = 0
        ultimo = 0.0
        for f in cartella.rglob("*"):
            if f.is_file() and f.name not in IGNORA:
                try:
                    st = f.stat()
                except OSError:
                    continue
                n += 1
                b += st.st_size
                ultimo = max(ultimo, st.st_mtime)
        return n, b, ultimo

    def visita(cartella: Path) -> None:
        try:
            figli = sorted(cartella.iterdir())
        except OSError:
            return
        for p in figli:
            if len(voci) >= MAX_VOCI:
                return
            rel = p.relative_to(mag)
            if p.name in IGNORA or p.name.startswith("~$") or p.name in IGNORA_DIR:
                continue
            if p.is_dir():
                if p.name not in CONTENITORI and len(rel.parts) >= 2:
                    n, b, ultimo = conta(p)
                    if n > SOGLIA_BLOCCO or NOMI_BLOCCO.match(p.name):
                        data = dt.datetime.fromtimestamp(ultimo).strftime("%Y-%m-%d") if ultimo else "—"
                        voci.append((rel.as_posix() + "/", f"cartella · {n} file", dimensione(b), data))
                        continue
                visita(p)
                continue
            try:
                st = p.stat()
            except OSError:
                continue
            voci.append((rel.as_posix(), tipo_di(p), dimensione(st.st_size),
                         dt.datetime.fromtimestamp(st.st_mtime).strftime("%Y-%m-%d")))

    visita(mag)

    senza = 0
    righe = []
    cartella_corrente = None
    for rel, tipo, dim, data in voci:
        cartella = rel.split("/")[0] if "/" in rel else "(radice)"
        if cartella != cartella_corrente:
            righe += ["", f"## {cartella}", "", "| File | Tipo | Dim. | Data | Descrizione | Parole chiave |",
                      "|---|---|---|---|---|---|"]
            cartella_corrente = cartella
        desc, chiavi = vecchie.get(rel, ("", ""))
        if not desc or desc == "—":
            senza += 1
            desc = "—"
        righe.append(f"| `{rel}` | {tipo} | {dim} | {data} | {desc} | {chiavi or '—'} |")

    testa = [
        f"# CATALOGO — {mag.name}",
        "",
        "> Inventario del magazzino del cantiere. Le IA leggono QUESTO per sapere dove sta una cosa,",
        "> poi aprono solo il file che serve. Rigenerato da `catalogo.py`: descrizioni e parole chiave si conservano.",
        "> Descrizione = una riga su cosa contiene il file. Si scrive a mano (magazziniere) nella colonna Descrizione.",
        "",
        f"Aggiornato: {dt.datetime.now():%Y-%m-%d %H:%M} · File: {len(voci)} · Senza descrizione: {senza}",
    ]
    if len(voci) >= MAX_VOCI:
        testa.append(f"⚠️ Catalogo troncato a {MAX_VOCI} file.")
    testo = "\n".join(testa + righe) + "\n"
    try:
        cat.write_text(testo, encoding="utf-8")
    except OSError as e:
        print(f"🔴 Impossibile scrivere {cat}: {e}")
        return 2
    if "--stampa" in sys.argv:
        print(testo)
    print(f"Catalogo aggiornato: {len(voci)} file, {senza} senza descrizione → {cat}")
    return 1 if senza else 0


if __name__ == "__main__":
    sys.exit(main())
