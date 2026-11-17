#!/usr/bin/env python3
"""Pagella del cantiere: voti 0–100 per categoria, totale pesato e verdetto di consegna.

Uso:
  python3 .cantiere/strumenti/pagella.py --misurata   # solo voti misurati (checkpoint): 0 crediti di giudizio
  python3 .cantiere/strumenti/pagella.py              # misurati + giudici (.cantiere/tmp/giudice-*.md)
  opzioni: --json (stampa il risultato in JSON) · --non-salvare (non scrive storico e archivio)

Fonti (nessuna IA): rapporto del guardiano (Lighthouse, giro su 8 dispositivi), controlli.py (codice,
sicurezza, segnaposto), bilingue.py (lingue), APPROVAZIONI.md (consegnabilità). Pesi e soglie in
.cantiere/pagella.json. Scrive una riga in .cantiere/PAGELLE.md e il dettaglio in
.cantiere/archivio/pagelle/. Solo libreria standard.
"""
from __future__ import annotations

import datetime as dt
import json
import re
import subprocess
import sys
from pathlib import Path

CATEGORIE = [
    ("prestazioni", "Prestazioni"), ("accessibilita", "Accessib."), ("seo", "SEO"),
    ("buone_pratiche", "Buone pratiche"), ("peso", "Peso"), ("velocita", "Velocità"),
    ("robustezza", "Robustezza"), ("codice", "Codice"), ("sicurezza", "Sicurezza"),
    ("lingue", "Lingue"), ("completezza", "Completezza"),
    ("grafica", "Grafica"), ("uso", "Uso"), ("testi", "Testi"),
]
GIUDICATE = {"grafica", "uso", "testi"}
PESI_DEFAULT = {"prestazioni": 10, "accessibilita": 10, "seo": 7, "buone_pratiche": 5, "peso": 6,
                "velocita": 8, "robustezza": 12, "codice": 8, "sicurezza": 8, "lingue": 5,
                "completezza": 5, "grafica": 9, "uso": 5, "testi": 2}
SOGLIE_DEFAULT = {"totale": 80, "minimo_categoria": 60, "giorni_guardiano": 3}
RIGA_GIUDICE = re.compile(r"^\s*(grafica|uso|esperienza d'uso|testi)\s*[:=]\s*(\d{1,3})\s*\|\s*(.*?)\s*\|\s*(.*?)\s*$", re.I)


def radice() -> Path:
    p = Path.cwd().resolve()
    for c in (p, *p.parents):
        if (c / ".cantiere").is_dir():
            return c
    sys.exit("Non sono dentro un cantiere (manca .cantiere/)")


def limita(v: float) -> int:
    return int(max(0, min(100, round(v))))


def scala(x: float, punti: list[tuple[float, float]]) -> int:
    """Interpolazione lineare a tratti: punti = [(x, voto), ...] con x crescente."""
    if x <= punti[0][0]:
        return limita(punti[0][1])
    for (x0, v0), (x1, v1) in zip(punti, punti[1:]):
        if x <= x1:
            return limita(v0 + (v1 - v0) * (x - x0) / (x1 - x0))
    return limita(punti[-1][1])


def esegui_json(cmd: list[str], cwd: Path) -> dict | None:
    try:
        out = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=300).stdout
        return json.loads(out.strip().splitlines()[-1]) if out.strip() else None
    except (subprocess.SubprocessError, json.JSONDecodeError, IndexError, OSError):
        return None


def peso_locale_kb(cartella: Path) -> int | None:
    """Peso della home: HTML + risorse locali che richiama (stima senza browser)."""
    home = cartella / "index.html"
    if not home.is_file():
        return None
    html = home.read_text(encoding="utf-8", errors="replace")
    totale = home.stat().st_size
    visti = set()
    for rif in re.findall(r"""(?:src|href)\s*=\s*["']([^"'#?]+)""", html):
        if rif.startswith(("http:", "https:", "//", "data:", "mailto:", "tel:")) or rif in visti:
            continue
        visti.add(rif)
        f = (cartella / rif.lstrip("/")) if rif.startswith("/") else (home.parent / rif)
        if f.is_file() and f.suffix.lower() not in (".html", ".htm"):
            totale += f.stat().st_size
    return round(totale / 1024)


def main() -> int:
    R = radice()
    c = R / ".cantiere"
    misurata = "--misurata" in sys.argv
    conf_p = json.loads((c / "pagella.json").read_text()) if (c / "pagella.json").is_file() else {}
    pesi = {**PESI_DEFAULT, **conf_p.get("pesi", {})}
    soglie = {**SOGLIE_DEFAULT, **conf_p.get("soglie", {})}
    conf_g = json.loads((c / "guardiano.json").read_text()) if (c / "guardiano.json").is_file() else {}
    sito = R / conf_g.get("cartella_sito", "03_CODICE")
    pubblicata = (sito / conf_g.get("cartella_pubblicata", ".")).resolve()

    voti: dict[str, int | None] = {k: None for k, _ in CATEGORIE}
    note: dict[str, str] = {}
    avvisi: list[str] = []

    # --- guardiano (Lighthouse + giro) ---
    g = None
    rg = c / "guardiano" / "ultimo" / "risultati.json"
    if rg.is_file():
        g = json.loads(rg.read_text())
        eta = (dt.datetime.now(dt.timezone.utc) - dt.datetime.fromisoformat(g["data"].replace("Z", "+00:00"))).days
        if eta > soglie["giorni_guardiano"]:
            avvisi.append(f"rapporto del guardiano vecchio di {eta} giorni: lancia `scarica.sh` o un nuovo giro")
        lh = g.get("lighthouse", {})
        for k in ("prestazioni", "accessibilita", "seo", "buone_pratiche"):
            if lh.get("medie", {}).get(k) is not None:
                voti[k] = int(lh["medie"][k])
                note[k] = "Lighthouse, media pagine (telefono e desktop)"
        if lh.get("lcp_ms") is not None:
            v = scala(lh["lcp_ms"], [(2500, 100), (4000, 60), (6000, 20), (10000, 10)])
            cls = lh.get("cls") or 0
            v -= 30 if cls > 0.25 else 10 if cls > 0.1 else 0
            voti["velocita"] = limita(v)
            note["velocita"] = f"LCP peggiore su telefono {lh['lcp_ms']} ms, CLS {cls}"
        if lh.get("peso_kb") is not None:
            voti["peso"] = scala(lh["peso_kb"], [(500, 100), (1000, 90), (2000, 70), (3000, 50), (5000, 0)])
            note["peso"] = f"pagina più pesante {lh['peso_kb']} KB (Lighthouse)"
        unici: dict[str, str] = {}
        for p in g.get("problemi", []):
            if p["tipo"] in ("lighthouse", "accessibilita"):
                continue
            d = re.sub(r"\d+px", "", p["dettaglio"])
            unici[f"{p['tipo']}|{p['pagina']}|{d}"] = p["gravita"]
        n_err = sum(1 for x in unici.values() if x == "errore")
        n_avv = len(unici) - n_err
        voti["robustezza"] = limita(100 - 8 * n_err - 2 * n_avv)
        note["robustezza"] = f"guardiano: {n_err} errori e {n_avv} avvisi distinti su {len(g.get('pagine', []))} pagine × 8 dispositivi"
        if voti["accessibilita"] is None:
            acc = [p for p in g.get("problemi", []) if p["tipo"] == "accessibilita"]
            gravi = sum(1 for p in acc if p["gravita"] == "errore")
            voti["accessibilita"] = limita(100 - 10 * gravi - 3 * (len(acc) - gravi))
            note["accessibilita"] = "axe-core (Lighthouse assente)"
    else:
        avvisi.append("nessun rapporto del guardiano: prestazioni, SEO, velocità e robustezza non misurate")

    if voti["peso"] is None:
        kb = peso_locale_kb(pubblicata)
        if kb is not None:
            voti["peso"] = scala(kb, [(500, 100), (1000, 90), (2000, 70), (3000, 50), (5000, 0)])
            note["peso"] = f"home {kb} KB (stima locale senza browser)"

    # --- controlli statici ---
    strum = c / "strumenti"
    ctl = esegui_json([sys.executable, str(strum / "controlli.py"), str(sito), "--json"], R) if sito.is_dir() else None
    if ctl:
        k = ctl["conteggi"]
        gravi = k.get("json_rotti", 0) + k.get("conflitti", 0) + k.get("html_rotto", 0)
        voti["codice"] = limita(100 - 15 * gravi - 8 * k.get("link_rotti", 0) - 3 * k.get("ancore_rotte", 0)
                                - min(20, 2 * k.get("debug", 0)) - min(10, k.get("todo", 0))
                                - 2 * k.get("whatsapp_sospetti", 0) - min(15, 2 * k.get("html_meta", 0))
                                - min(10, k.get("alt_mancanti", 0)) - min(10, 2 * k.get("file_pesanti", 0)))
        note["codice"] = (f"errori gravi {gravi}, link rotti {k.get('link_rotti', 0)}, debug {k.get('debug', 0)}, "
                          f"TODO {k.get('todo', 0)}, file pesanti {k.get('file_pesanti', 0)}")
        voti["sicurezza"] = limita(100 - 50 * k.get("segreti", 0) - 10 * k.get("http_non_sicuro", 0))
        note["sicurezza"] = f"segreti nel codice {k.get('segreti', 0)}, risorse http {k.get('http_non_sicuro', 0)}"
        dac = k.get("da_completare", 0)
    else:
        dac = 0
        avvisi.append(f"cartella del sito non trovata ({sito.relative_to(R)}): codice e sicurezza non misurati")

    # --- lingue ---
    lng = esegui_json([sys.executable, str(strum / "bilingue.py"), str(pubblicata), "--json"], R) if pubblicata.is_dir() else None
    if lng and lng.get("voto") is not None:
        voti["lingue"] = int(lng["voto"])
        note["lingue"] = f"{len(lng['errori'])} errori, {len(lng['avvisi'])} avvisi su {lng['coppie']} coppie di pagine"

    # --- completezza e approvazioni ---
    attesa = 0
    ap = c / "APPROVAZIONI.md"
    if ap.is_file():
        attesa = sum(1 for r in ap.read_text(encoding="utf-8").splitlines()
                     if r.startswith("|") and ("⏳" in r or "📨" in r or "✏️" in r))
    voti["completezza"] = limita(100 - 2 * dac - 5 * attesa)
    note["completezza"] = f"segnaposto [DA COMPLETARE] {dac}, approvazioni in sospeso {attesa}"

    # --- giudici ---
    giudici: dict[str, dict[str, tuple[int, str, str]]] = {}
    if not misurata:
        for f in sorted((c / "tmp").glob("giudice-*.md")):
            for riga in f.read_text(encoding="utf-8").splitlines():
                m = RIGA_GIUDICE.match(riga)
                if m:
                    cat = {"esperienza d'uso": "uso"}.get(m.group(1).lower(), m.group(1).lower())
                    giudici.setdefault(cat, {})[f.stem.replace("giudice-", "")] = (min(100, int(m.group(2))), m.group(3), m.group(4))
        for cat in GIUDICATE:
            if cat in giudici:
                vv = [v[0] for v in giudici[cat].values()]
                voti[cat] = round(sum(vv) / len(vv))
                note[cat] = " · ".join(f"{chi} {v}: {mot} → {az}" for chi, (v, mot, az) in giudici[cat].items())
                if len(vv) > 1 and max(vv) - min(vv) > 15:
                    avvisi.append(f"giudici in disaccordo su {cat} ({min(vv)}–{max(vv)}): decide Matteo")
        if len({chi for d in giudici.values() for chi in d}) < 2:
            avvisi.append("servono 2 giudici diversi (Claude + un'altra IA) per una pagella completa")

    # --- totale e verdetto ---
    validi = {k: v for k, v in voti.items() if v is not None}
    peso_tot = sum(pesi[k] for k in validi)
    totale = round(sum(v * pesi[k] for k, v in validi.items()) / peso_tot) if peso_tot else 0
    sotto = [k for k, v in validi.items() if v < soglie["minimo_categoria"]]
    motivi = []
    if totale < soglie["totale"]:
        motivi.append(f"totale {totale} < {soglie['totale']}")
    if sotto:
        motivi.append("sotto " + str(soglie["minimo_categoria"]) + ": " + ", ".join(sotto))
    if attesa:
        motivi.append(f"{attesa} approvazioni in sospeso")
    if misurata or not all(voti[k] is not None for k in GIUDICATE):
        motivi.append("mancano i voti dei giudici")
    if g is None:
        motivi.append("manca il guardiano")
    elif g.get("semaforo") == "🔴":
        motivi.append("guardiano rosso")
    consegnabile = not motivi

    ora = dt.datetime.now()
    tipo = "misurata" if misurata else "completa"
    risultato = {"data": ora.isoformat(timespec="minutes"), "tipo": tipo, "voti": voti, "totale": totale,
                 "consegnabile": consegnabile, "motivi": motivi, "note": note, "avvisi": avvisi}

    if "--non-salvare" not in sys.argv:
        cella = lambda k: "—" if voti[k] is None else str(voti[k])  # noqa: E731
        riga = (f"| {ora:%Y-%m-%d %H:%M} | {tipo} | " + " | ".join(cella(k) for k, _ in CATEGORIE)
                + f" | **{totale}** | {'✅' if consegnabile else '❌'} |")
        storico = c / "PAGELLE.md"
        if storico.is_file():
            testo = storico.read_text(encoding="utf-8")
            if "| Grafica |" in testo and "| Robustezza |" not in testo:  # intestazione vecchia: si aggiorna
                testo = re.sub(r"\| Data \|.*\n\|[-| ]+\|\n", "", testo)
            if "| Robustezza |" not in testo:
                testo = testo.rstrip("\n") + "\n\n| Data | Tipo | " + " | ".join(n for _, n in CATEGORIE) + " | **TOTALE** | Consegnabile? |\n|" + "---|" * (len(CATEGORIE) + 4) + "\n"
            storico.write_text(testo.rstrip("\n") + "\n" + riga + "\n", encoding="utf-8")
        arch = c / "archivio" / "pagelle"
        arch.mkdir(parents=True, exist_ok=True)
        det = [f"# Pagella {tipo} — {ora:%Y-%m-%d %H:%M}", "", f"**Totale: {totale}/100 · Consegnabile: {'✅ sì' if consegnabile else '❌ no'}**", ""]
        if motivi:
            det += ["Perché non è consegnabile: " + "; ".join(motivi), ""]
        det += ["| Categoria | Voto | Peso | Da dove viene |", "|---|---|---|---|"]
        det += [f"| {n} | {cella(k)} | {pesi[k]} | {note.get(k, 'non misurato')} |" for k, n in CATEGORIE]
        if avvisi:
            det += ["", "## Avvisi", *[f"- {a}" for a in avvisi]]
        (arch / f"{ora:%Y-%m-%d_%H%M}_{tipo}.md").write_text("\n".join(det) + "\n", encoding="utf-8")

    if "--json" in sys.argv:
        print(json.dumps(risultato, ensure_ascii=False))
    else:
        peggiori = sorted(validi.items(), key=lambda kv: kv[1])[:3]
        print(f"📊 Pagella {tipo}: **{totale}/100** · consegnabile: {'✅' if consegnabile else '❌'}")
        print("   " + " · ".join(f"{n} {'—' if voti[k] is None else voti[k]}" for k, n in CATEGORIE))
        print("   Più basse: " + ", ".join(f"{k} {v} ({note.get(k, '')[:60]})" for k, v in peggiori))
        if motivi:
            print("   Non consegnabile perché: " + "; ".join(motivi))
        for a in avvisi:
            print(f"   ⚠️ {a}")
    return 0 if consegnabile else 1


if __name__ == "__main__":
    sys.exit(main())
