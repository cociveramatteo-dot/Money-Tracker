#!/usr/bin/env python3
"""Ispezione del magazzino: controlla che ogni file sia al posto giusto col nome giusto.

Uso: python3 .cantiere/strumenti/magazzino.py [--json]
Legge le regole da .cantiere/magazzino.json. NON sposta né cancella niente: fa solo il rapporto,
poi il magazziniere (e l'addetto alle pulizie) agiscono.
Exit code: 0 = in ordine, 1 = c'è da sistemare.
"""
from __future__ import annotations

import fnmatch
import json
import re
import sys
import unicodedata
from pathlib import Path

NOME_OK = re.compile(r"^[a-z0-9][a-z0-9._-]*$")
CARTELLA_STD_OK = re.compile(r"^(?:\d{2}_[A-Z_]+|[a-z0-9][a-z0-9._-]*)$")
DATA_SBAGLIATA = re.compile(r"(?<!\d)(\d{1,2})[-_.](\d{1,2})[-_.](\d{2,4})(?!\d)")


def radice_progetto() -> Path:
    p = Path.cwd().resolve()
    for c in (p, *p.parents):
        if (c / ".cantiere").is_dir():
            return c
    return p


def suggerisci(nome: str) -> str:
    stem, punto, ext = nome.rpartition(".") if "." in nome[1:] else (nome, "", "")
    s = unicodedata.normalize("NFKD", stem).encode("ascii", "ignore").decode()
    s = re.sub(r"[^A-Za-z0-9]+", "-", s).strip("-").lower()
    s = re.sub(r"-{2,}", "-", s) or "file"
    return f"{s}.{ext.lower()}" if punto else s


def main() -> int:
    radice = radice_progetto()
    cfg_path = radice / ".cantiere" / "magazzino.json"
    try:
        cfg = json.loads(cfg_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as e:
        print(f"Impossibile leggere {cfg_path}: {e}", file=sys.stderr)
        return 1

    dir_ammesse = set(cfg["cartelle_ammesse_in_radice"])
    file_ammessi = set(cfg["file_ammessi_in_radice"])
    nomi_liberi = set(cfg["cartelle_con_nomi_liberi"])
    ignora = set(cfg["cartelle_da_ignorare"])
    spazzatura = cfg["spazzatura"]
    vietate = [w.lower() for w in cfg["parole_vietate_nei_nomi"]]
    soglia = float(cfg.get("file_grande_mb", 5)) * 1_000_000

    fuori_posto: list[str] = []
    nomi: list[str] = []
    nomi_codice: list[str] = []
    rifiuti: list[str] = []
    pesanti: list[str] = []
    da_smistare: list[str] = []
    vuote: list[str] = []

    for voce in sorted(radice.iterdir()):
        if voce.is_dir() and voce.name not in dir_ammesse:
            fuori_posto.append(f"`{voce.name}/` — cartella non prevista in radice")
        elif voce.is_file() and voce.name not in file_ammessi and not any(fnmatch.fnmatch(voce.name, s) for s in spazzatura):
            fuori_posto.append(f"`{voce.name}` — file non previsto in radice → `99_DA_SMISTARE/` o cartella giusta")

    for p in sorted(radice.rglob("*")):
        rel = p.relative_to(radice)
        parti = rel.parts
        if any(x in ignora for x in parti):
            continue
        if parti[0] in (".cantiere", ".claude", ".agent", ".agents", ".github", ".vscode"):
            continue
        nome = p.name
        if nome == ".gitkeep":
            continue
        if p.is_file() and any(fnmatch.fnmatch(nome, s) for s in spazzatura):
            rifiuti.append(f"`{rel}`")
            continue
        if parti[0] == "99_DA_SMISTARE" and p.is_file():
            da_smistare.append(f"`{rel}`")
        if p.is_dir() and not any(p.iterdir()):
            vuote.append(f"`{rel}/`")
        if p.is_file():
            try:
                if p.stat().st_size > soglia:
                    pesanti.append(f"`{rel}` ({p.stat().st_size / 1_000_000:.1f} MB)")
            except OSError:
                pass

        if len(parti) == 1 or nome in (".gitkeep", ".gitignore", ".htaccess", "_redirects", "_headers"):
            continue  # radice già controllata sopra; file tecnici con nome obbligato
        problemi = []
        if p.is_dir():
            if not CARTELLA_STD_OK.match(nome):
                problemi.append("nome cartella non conforme")
        else:
            if not NOME_OK.match(nome):
                problemi.append("maiuscole, spazi, accenti o simboli")
        low = nome.lower()
        trovate = [w for w in vietate if re.search(rf"(?:^|[^a-z]){re.escape(w)}(?:[^a-z]|$)", low)]
        if trovate:
            problemi.append(f"parole vietate: {', '.join(trovate)} (usa -v1, -v2…)")
        if DATA_SBAGLIATA.search(nome):
            problemi.append("data non in formato AAAA-MM-GG")
        if not problemi:
            continue
        riga = f"`{rel}` — {'; '.join(problemi)}"
        if p.is_file() and not NOME_OK.match(nome):
            riga += f" → suggerito `{suggerisci(nome)}`"
        if parti[0] in nomi_liberi:
            nomi_codice.append(riga)  # in 03_CODICE solo segnalazione
        elif parti[0] == "02_RISORSE" and len(parti) > 1 and parti[1] == "originali":
            continue  # gli originali tengono il nome del cliente
        else:
            nomi.append(riga)

    sezioni = [
        ("🔴 Fuori posto in radice", fuori_posto),
        ("🟡 Nomi da correggere", nomi),
        ("ℹ️ Nomi non conformi nel codice (solo segnalazione, non rinominare)", nomi_codice),
        ("🗑️ Spazzatura (le pulizie possono cancellare)", rifiuti),
        ("📦 Da smistare (99_DA_SMISTARE)", da_smistare),
        ("📭 Cartelle vuote", vuote),
        ("🐘 File pesanti", pesanti),
    ]
    if "--json" in sys.argv:
        print(json.dumps({t: v for t, v in sezioni}, ensure_ascii=False, indent=2))
    else:
        print(f"# Ispezione magazzino — {radice.name}\n")
        for titolo, voci in sezioni:
            if voci:
                print(f"## {titolo} ({len(voci)})")
                print("\n".join(f"- {v}" for v in voci[:80]))
                if len(voci) > 80:
                    print(f"- … e altri {len(voci) - 80}")
                print()
    da_fare = fuori_posto or nomi or rifiuti or da_smistare
    print("Esito: " + ("🟡 c'è da sistemare" if da_fare else "🟢 magazzino in ordine"))
    return 1 if da_fare else 0


if __name__ == "__main__":
    sys.exit(main())
