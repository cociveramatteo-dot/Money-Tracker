#!/usr/bin/env python3
"""Controllo di allineamento tra le lingue di un sito statico (skill bilingual-static-sync).

Uso: python3 .cantiere/strumenti/bilingue.py [cartella_sito] [--json]

Abbina le pagine delle diverse lingue (es. /index.html ↔ /en/index.html, guardando la cartella
della lingua e l'attributo lang) e per ogni coppia controlla:
- stesse sezioni (id), stesso numero di titoli, immagini, link e pulsanti WhatsApp;
- <title> e meta description presenti e diversi tra le lingue;
- link hreflang reciproci e lang corretto su <html>;
- testi lunghi identici nelle due lingue (probabile traduzione dimenticata).
Voto 0–100 e rapporto Markdown. Exit code: 0 ok, 1 avvisi, 2 errori. Solo libreria standard.
"""
from __future__ import annotations

import json
import re
import sys
from collections import Counter
from dataclasses import dataclass, field
from html.parser import HTMLParser
from pathlib import Path

LINGUE = {"it", "en", "fr", "de", "es", "pt", "nl", "fi", "sv", "no", "da", "ru", "zh", "ja", "ar", "pl", "ro"}
IGNORA = {".git", "node_modules", ".netlify", ".cache", "graphify-out", ".cantiere", ".agents", ".claude", ".github"}
TESTO_MIN = 40  # caratteri: sotto questa soglia testi uguali sono normali (nomi, prezzi)


@dataclass
class Pagina:
    percorso: Path
    lang: str = ""
    title: str = ""
    description: str = ""
    ids: list[str] = field(default_factory=list)
    titoli: int = 0
    immagini: int = 0
    link: int = 0
    whatsapp: int = 0
    hreflang: dict[str, str] = field(default_factory=dict)
    testi: list[str] = field(default_factory=list)


class Lettore(HTMLParser):
    def __init__(self, pagina: Pagina) -> None:
        super().__init__(convert_charrefs=True)
        self.p = pagina
        self._in_title = False
        self._salta = 0  # dentro script/style

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        a = {k: (v or "") for k, v in attrs}
        if tag in ("script", "style"):
            self._salta += 1
        if tag == "html":
            self.p.lang = a.get("lang", "").split("-")[0].lower()
        elif tag == "title":
            self._in_title = True
        elif tag == "meta" and a.get("name", "").lower() == "description":
            self.p.description = a.get("content", "").strip()
        elif tag == "link" and a.get("rel", "").lower() == "alternate" and a.get("hreflang"):
            self.p.hreflang[a["hreflang"].lower()] = a.get("href", "")
        if tag in ("h1", "h2", "h3"):
            self.p.titoli += 1
        if tag == "img":
            self.p.immagini += 1
        if tag == "a":
            self.p.link += 1
            if "wa.me" in a.get("href", "") or "whatsapp.com" in a.get("href", ""):
                self.p.whatsapp += 1
        if a.get("id"):
            self.p.ids.append(a["id"])

    def handle_endtag(self, tag: str) -> None:
        if tag in ("script", "style") and self._salta:
            self._salta -= 1
        if tag == "title":
            self._in_title = False

    def handle_data(self, data: str) -> None:
        if self._salta:
            return
        if self._in_title:
            self.p.title += data.strip()
        testo = re.sub(r"\s+", " ", data).strip()
        if len(testo) >= TESTO_MIN:
            self.p.testi.append(testo)


def leggi(percorso: Path) -> Pagina:
    pagina = Pagina(percorso)
    try:
        Lettore(pagina).feed(percorso.read_text(encoding="utf-8", errors="replace"))
    except Exception as e:  # pagina malformata: la segnaliamo con lang vuota
        print(f"⚠️ {percorso}: non leggibile ({e})", file=sys.stderr)
    return pagina


def radice_web(radice: Path) -> Path:
    """Cartella servita come "/" del sito: quella con index.html più vicina alla radice (es. public/, dist/).
    Senza questo, in sito/public/en/ la prima cartella sarebbe "public" e la lingua "en" non verrebbe vista."""
    if (radice / "index.html").is_file():
        return radice
    candidati = sorted((p.parent for p in radice.rglob("index.html")
                        if not any(x in IGNORA or x == "node_modules" for x in p.relative_to(radice).parts)),
                       key=lambda d: len(d.relative_to(radice).parts))
    return candidati[0] if candidati else radice


def chiave(rel: Path) -> tuple[str, str]:
    """(lingua dalla cartella, percorso senza cartella della lingua)."""
    parti = rel.parts
    if parti and parti[0].lower() in LINGUE:
        return parti[0].lower(), "/".join(parti[1:])
    return "", "/".join(parti)


def main() -> int:
    argomenti = [a for a in sys.argv[1:] if not a.startswith("--")]
    radice = Path(argomenti[0] if argomenti else ".").resolve()
    if not radice.is_dir():
        print(f"Cartella non trovata: {radice}", file=sys.stderr)
        return 2
    radice = radice_web(radice)

    pagine: dict[str, dict[str, Pagina]] = {}
    lingue_radice: Counter[str] = Counter()  # lingua delle pagine fuori dalle cartelle di lingua = principale
    for f in sorted(radice.rglob("*.html")):
        rel = f.relative_to(radice)
        if any(x in IGNORA for x in rel.parts) or rel.name == "404.html":
            continue
        lingua_cartella, base = chiave(rel)
        pag = leggi(f)
        lingua = lingua_cartella or pag.lang or "?"
        if not lingua_cartella:
            lingue_radice[lingua] += 1
        pagine.setdefault(base, {})[lingua] = pag

    lingue = Counter(l for gruppo in pagine.values() for l in gruppo)
    errori: list[str] = []
    avvisi: list[str] = []
    coppie = 0

    if len(lingue) < 2:
        risultato = {"voto": None, "lingue": dict(lingue), "coppie": 0, "errori": [], "avvisi": [],
                     "nota": "sito in una sola lingua: controllo non applicabile"}
        if "--json" in sys.argv:
            print(json.dumps(risultato, ensure_ascii=False))
        else:
            print("## Lingue\n\nℹ️ Sito in una sola lingua: controllo non applicabile.")
        return 0

    principale = (lingue_radice or lingue).most_common(1)[0][0]
    for base, gruppo in sorted(pagine.items()):
        if principale not in gruppo:
            avvisi.append(f"`{base}`: esiste solo in {', '.join(gruppo)} (manca in {principale})")
            continue
        ref = gruppo[principale]
        for lingua in lingue:
            if lingua == principale:
                continue
            if lingua not in gruppo:
                errori.append(f"`{base}`: manca la versione {lingua}")
                continue
            coppie += 1
            alt = gruppo[lingua]
            nome = f"`{base}` {principale}↔{lingua}"
            mancanti = [i for i in ref.ids if i not in alt.ids]
            in_piu = [i for i in alt.ids if i not in ref.ids]
            if mancanti:
                errori.append(f"{nome}: sezioni mancanti in {lingua}: {', '.join(mancanti[:8])}")
            if in_piu:
                avvisi.append(f"{nome}: sezioni in più in {lingua}: {', '.join(in_piu[:8])}")
            for campo, etichetta in (("titoli", "titoli"), ("immagini", "immagini"), ("whatsapp", "pulsanti WhatsApp")):
                a, b = getattr(ref, campo), getattr(alt, campo)
                if a != b:
                    avvisi.append(f"{nome}: {etichetta} {a} vs {b}")
            for p, l in ((ref, principale), (alt, lingua)):
                if not p.title:
                    errori.append(f"{nome}: manca <title> in {l}")
                if not p.description:
                    errori.append(f"{nome}: manca la meta description in {l}")
                if p.lang and p.lang != l and l != "?":
                    errori.append(f"{nome}: <html lang=\"{p.lang}\"> ma la pagina è {l}")
            if ref.title and ref.title == alt.title:
                avvisi.append(f"{nome}: <title> identico nelle due lingue")
            if ref.description and ref.description == alt.description:
                avvisi.append(f"{nome}: meta description identica nelle due lingue")
            if not ref.hreflang or not alt.hreflang:
                avvisi.append(f"{nome}: mancano i link hreflang (SEO multilingua)")
            # indirizzi, telefoni e simili restano uguali in tutte le lingue: non contano
            uguali = sorted(x for x in set(ref.testi) & set(alt.testi) if not re.search(r"\d{3,}", x))
            if uguali:
                avvisi.append(f"{nome}: {len(uguali)} testi lunghi identici (non tradotti?) es. «{uguali[0][:70]}…»")

    voto = max(0, 100 - 10 * len(errori) - 3 * len(avvisi))
    risultato = {"voto": voto, "lingue": dict(lingue), "coppie": coppie, "errori": errori, "avvisi": avvisi}
    if "--json" in sys.argv:
        print(json.dumps(risultato, ensure_ascii=False))
    else:
        print(f"## Lingue — voto {voto}/100\n")
        print(f"Lingue: {', '.join(f'{k} ({v} pagine)' for k, v in lingue.items())} · coppie confrontate: {coppie}\n")
        for titolo, voci, icona in (("Errori", errori, "🔴"), ("Avvisi", avvisi, "🟡")):
            print(f"### {icona} {titolo} ({len(voci)})")
            print("\n".join(f"- {v}" for v in voci[:40]) or "- nessuno")
            print()
    return 2 if errori else (1 if avvisi else 0)


if __name__ == "__main__":
    sys.exit(main())
