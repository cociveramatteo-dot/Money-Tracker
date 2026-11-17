#!/usr/bin/env python3
"""Tiene allineato il notebook NotebookLM (il bibliotecario) con il magazzino del cantiere.

Uso:
  python3 .cantiere/strumenti/biblioteca.py              → cosa aggiungere / ricaricare, con istruzioni per Matteo
  python3 .cantiere/strumenti/biblioteca.py --segna F…   → registra in FONTI.md che F (percorsi nel magazzino) è nel notebook
  python3 .cantiere/strumenti/biblioteca.py --escludi F… → F non va nel notebook: non viene più proposto
  python3 .cantiere/strumenti/biblioteca.py --dal-mac NOME… → fonte caricata dal Mac (fuori dal magazzino): solo annotata
  python3 .cantiere/strumenti/biblioteca.py --json       → stesso controllo in JSON

NotebookLM non ha un accesso automatico: le fonti le carica Matteo. Questo strumento gli dice ESATTAMENTE cosa fare.
- Google Documenti, Fogli e Presentazioni presi da Drive si aggiornano da soli nel notebook (sincronizzazione Drive).
- PDF, Word, testi caricati sono copie ferme: se il file cambia nel magazzino va ricaricato (lo segnala qui).
Impronta = dimensione + data di modifica: nessun file viene scaricato da Drive. Solo libreria standard.
"""
from __future__ import annotations

import datetime as dt
import json
import re
import sys
from pathlib import Path

RADICE = Path.cwd()
FONTI = RADICE / ".cantiere" / "bibliotecario" / "FONTI.md"
DOCUMENTI = {".pdf", ".docx", ".doc", ".odt", ".txt", ".md", ".rtf", ".pptx", ".xlsx", ".csv",
             ".gdoc", ".gsheet", ".gslides"}
GOOGLE = {".gdoc", ".gsheet", ".gslides"}
CARTELLE = ("00_CLIENTE", "02_RISORSE")
SALTA = re.compile(r"(^|/)(backup|sito[-_ ]?attuale|sito[-_ ]?vecchio|export|wp[-_]|wordpress|lavorate)", re.I)
MIN_BYTE = 3_000          # sotto questa soglia l'IA legge il file direttamente: non serve il bibliotecario
MAX_BYTE = 200_000_000    # limite pratico di NotebookLM per fonte


def magazzino() -> Path | None:
    try:
        c = json.loads((RADICE / ".cantiere" / "cantiere.json").read_text())
        return Path(c["magazzino"]).expanduser()
    except (OSError, ValueError, KeyError):
        return None


def impronta(p: Path) -> str:
    st = p.stat()
    return f"{st.st_size}-{int(st.st_mtime)}"


def leggi_fonti() -> dict[str, dict[str, str]]:
    voci: dict[str, dict[str, str]] = {}
    if not FONTI.is_file():
        return voci
    for riga in FONTI.read_text(encoding="utf-8").splitlines():
        m = re.match(r"^\| `([^`]+)` \| ([^|]+) \| ([^|]+) \| `?([^|`]+)`? \|$", riga.strip())
        if m:
            voci[m.group(1)] = {"tipo": m.group(2).strip(), "data": m.group(3).strip(), "impronta": m.group(4).strip()}
    return voci


def scrivi_fonti(voci: dict[str, dict[str, str]]) -> None:
    testa = FONTI.read_text(encoding="utf-8").split("| Fonte (percorso nel magazzino)")[0] if FONTI.is_file() else "# FONTI DEL NOTEBOOK\n\n"
    righe = ["| Fonte (percorso nel magazzino) | Tipo | Aggiunta il | Impronta |", "|---|---|---|---|"]
    for k in sorted(voci):
        v = voci[k]
        righe.append(f"| `{k}` | {v['tipo']} | {v['data']} | `{v['impronta']}` |")
    FONTI.parent.mkdir(parents=True, exist_ok=True)
    FONTI.write_text(testa + "\n".join(righe) + "\n", encoding="utf-8")


def candidati(mag: Path) -> dict[str, Path]:
    trovati: dict[str, Path] = {}
    for base in CARTELLE:
        d = mag / base
        if not d.is_dir():
            continue
        for p in sorted(d.rglob("*")):
            if not p.is_file() or p.name.startswith((".", "~$")):
                continue
            rel = p.relative_to(mag).as_posix()
            if SALTA.search(rel) or p.suffix.lower() not in DOCUMENTI:
                continue
            try:
                n = p.stat().st_size
            except OSError:
                continue
            if p.suffix.lower() not in GOOGLE and not (MIN_BYTE <= n <= MAX_BYTE):
                continue
            trovati[rel] = p
    return trovati


def main() -> int:
    mag = magazzino()
    if not mag or not mag.is_dir():
        print("🔴 Magazzino non raggiungibile (Google Drive è aperto? .cantiere/cantiere.json → magazzino)")
        return 2
    voci = leggi_fonti()

    if "--escludi" in sys.argv or "--dal-mac" in sys.argv:
        tipo = "esclusa" if "--escludi" in sys.argv else "caricata dal Mac (ricaricare se cambia)"
        oggi = dt.date.today().isoformat()
        for rel in [a for a in sys.argv[1:] if not a.startswith("--")]:
            voci[rel] = {"tipo": tipo, "data": oggi, "impronta": "-"}
            print(f"✅ {rel}: {tipo}")
        scrivi_fonti(voci)
        return 0

    if "--segna" in sys.argv:
        file = [a for a in sys.argv[1:] if not a.startswith("--")]
        oggi = dt.date.today().isoformat()
        for rel in file:
            p = mag / rel
            if not p.is_file():
                print(f"⚠️  {rel}: non trovato nel magazzino")
                continue
            tipo = "si aggiorna da sola" if p.suffix.lower() in GOOGLE else "copia ferma"
            voci[rel] = {"tipo": tipo, "data": oggi, "impronta": impronta(p)}
            print(f"✅ {rel} registrata ({tipo})")
        scrivi_fonti(voci)
        return 0

    tutti = candidati(mag)
    nuovi = [r for r in tutti if r not in voci]
    fissi = ("si aggiorna da sola", "esclusa", "caricata dal Mac (ricaricare se cambia)")
    cambiati = [r for r, v in voci.items() if r in tutti and v["tipo"] not in fissi
                and impronta(tutti[r]) != v["impronta"]]
    spariti = [r for r, v in voci.items() if v["tipo"] in ("copia ferma", "si aggiorna da sola") and not (mag / r).exists()]

    if "--json" in sys.argv:
        print(json.dumps({"nuovi": nuovi, "da_ricaricare": cambiati, "spariti": spariti,
                          "in_notebook": sum(1 for v in voci.values() if v["tipo"] != "esclusa")}, ensure_ascii=False))
        return 1 if (nuovi or cambiati or spariti) else 0

    cartella = mag.as_posix().split("/Il mio Drive/")[-1] if "/Il mio Drive/" in mag.as_posix() else mag.name
    nel = sum(1 for v in voci.values() if v["tipo"] != "esclusa")
    print(f"## Bibliotecario — {nel} fonti nel notebook\n")
    if not (nuovi or cambiati or spariti):
        print("✅ Il notebook è allineato al magazzino: niente da fare.")
        return 0
    print("Istruzioni per Matteo (📍 notebooklm.google.com → notebook del cantiere, link in AGENTS.md §1):\n")
    if nuovi:
        print(f"🆕 **Da aggiungere** ({len(nuovi)}): «Aggiungi fonte» → «Google Drive» → `{cartella}/` →")
        for r in nuovi:
            print(f"   - `{r}`")
    if cambiati:
        print(f"\n♻️ **Da ricaricare** ({len(cambiati)}, cambiati nel magazzino): sulla fonte ⋮ → «Rimuovi fonte», poi «Aggiungi fonte» → stesso file")
        for r in cambiati:
            print(f"   - `{r}`")
    if spariti:
        print(f"\n🗑️ **Da togliere dal notebook** ({len(spariti)}, non ci sono più nel magazzino): ⋮ → «Rimuovi fonte»")
        for r in spariti:
            print(f"   - `{r}`")
    print("\n↩️ Quando hai fatto, scrivilo: l'IA lancia `biblioteca.py --segna <file>` (e toglie da FONTI.md quelli rimossi).")
    print("💡 Le note che scrivi tu (riunioni, appunti) creale come **Google Documento** nel magazzino: nel notebook si aggiornano da sole.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
