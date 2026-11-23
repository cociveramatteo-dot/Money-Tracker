#!/usr/bin/env python3
"""Esporta i post v2 (PNG 1080x1350, un solo set per Instagram e TikTok) con testi e istruzioni.
Uso: python3 SOCIAL/caroselli/v2/esporta.py [N ...]   (dopo build.py)
Scrive in SOCIAL/clip-social/v2/Post-NN-slug/ e in «Il mio Drive/Da postare/Post-NN-slug/»."""
import shutil, sys
from pathlib import Path
import posts, meta
from lib import HERE, ROOT

OUT = HERE / "_out"
REPO = ROOT / "clip-social/v2"
DRIVE = Path.home() / "Library/CloudStorage/GoogleDrive-cociveramatteo@gmail.com/Il mio Drive/Da postare"

def testi(p, m, n):
    ig = f"{m['title']}\n{m['caption']}\n{meta.LAUNCH} Link in bio.\n{meta.IG_BASE} {m['tags']}"
    tt = f"{m['caption']}\n{meta.LAUNCH} bucktrailapp.com\n{meta.TT_BASE} {m['tags']}"
    short = f"""TITOLO (max 90 caratteri, {len(m['title'])} usati)
{m['title']}

DESCRIZIONE TIKTOK (copia-incolla)
{tt}

DESCRIZIONE INSTAGRAM (copia-incolla)
{ig}
"""
    leggimi = f"""POST {p['n']:02d} — {m['title']}

DATA E ORARI (Europe/Rome, indicativi: decide Matteo)
{m['date']} · Instagram {m['ig']} · TikTok {m['tt']}
Giorni esclusi: domeniche, 24 e 25 dicembre, 1 gennaio.

FILE
{n} immagini 1080x1350 (4:5): slide-01.png … slide-{n:02d}.png, in questo ordine, UN SOLO SET per Instagram e TikTok.
Testi dentro le zone sicure di entrambe le piattaforme. L’ultima slide è la chiusura (iOS e Android, sito, invito a seguire/like/condividere/salvare).

TIKTOK — FOTO / CAROSELLO
Apri Da postare → {p_dir(p)} → salva le {n} immagini in Foto, selezionale in ordine e usa slide-01 come copertina. Musica: la scegli tu in piattaforma.
{short.split('DESCRIZIONE INSTAGRAM')[0].strip()}

INSTAGRAM — POST / CAROSELLO
Stesse immagini, stesso ordine, formato 4:5. Titolo della prima slide leggibile nel ritaglio profilo.
DESCRIZIONE INSTAGRAM (copia-incolla)
{ig}

DOPO LA PUBBLICAZIONE
Controlla ordine e ritaglio, registra piattaforma/data/ora/link in SOCIAL/diario-metriche.csv. Dopo 24 ore rileva visualizzazioni, salvataggi, condivisioni, commenti e visite profilo.
"""
    return short, leggimi

def p_dir(p):
    return f"Post-{p['n']:02d}-{p['slug']}"

def main(nums):
    for p in posts.POSTS:
        if nums and p["n"] not in nums:
            continue
        src = OUT / p_dir(p)
        files = sorted(src.glob("slide-*.png"))
        assert files and [f.name for f in files] == [f"slide-{i:02d}.png" for i in range(1, len(files) + 1)], src
        short, leggimi = testi(p, meta.META[p["n"]], len(files))
        for base in (REPO, DRIVE):
            d = base / p_dir(p)
            if d.exists():
                shutil.rmtree(d)
            d.mkdir(parents=True)
            for f in files:
                shutil.copy2(f, d / f.name)
            (d / "titolo-e-hashtag.txt").write_text(short)
            (d / "LEGGIMI.txt").write_text(leggimi)
        print("ok", p_dir(p), len(files))

if __name__ == "__main__":
    main({int(a) for a in sys.argv[1:]})
