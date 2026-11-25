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
    legacy = "date" in m          # post 5-9 (non rigenerati): formato vecchio
    assert not legacy, "i post 5-9 non vanno riesportati"
    launch = (f"\n{meta.LAUNCH}" if m["launch"] else "")
    tt = f"{m['caption']}{launch}{' bucktrailapp.com' if m['launch'] else ''}\n{meta.TAGS}"
    ig = f"{m['caption']}{launch}{' Link in bio.' if m['launch'] else ''}\n{meta.TAGS}"
    short = f"""TITOLO (max 90 caratteri, {len(m['title'])} usati)
{m['title']}

DESCRIZIONE TIKTOK (copia-incolla)
{tt}

DESCRIZIONE INSTAGRAM (copia-incolla)
{ig}
"""
    leggimi = f"""POST {p['n']:02d} — {m['title']}

FILE
{n} immagini 1080x1350 (4:5): slide-01.png … slide-{n:02d}.png, in questo ordine, UN SOLO SET per Instagram e TikTok.
Gancio in slide 1; la penultima slide è «Da salvare»; l’ultima è la chiusura. Quando pubblicare lo decidi tu: conta solo l’ordine dei post.

MUSICA
Pubblica il carosello con un suono di tendenza, scelto da te in app (TikTok e Instagram).

TIKTOK — FOTO / CAROSELLO
Apri Da postare → {p_dir(p)} → salva le {n} immagini in Foto, selezionale in ordine e usa slide-01 come copertina.
{short.split('DESCRIZIONE INSTAGRAM')[0].strip()}

INSTAGRAM — POST / CAROSELLO
Stesse immagini, stesso ordine, formato 4:5. Titolo della prima slide leggibile nel ritaglio profilo.
DESCRIZIONE INSTAGRAM (copia-incolla)
{ig}

DOPO LA PUBBLICAZIONE
Controlla ordine e ritaglio, registra piattaforma/data/ora/link in SOCIAL/diario-metriche.csv. Dopo 24 ore rileva visualizzazioni, visione media, % fino all'ultima slide, salvataggi, condivisioni, commenti, visite al profilo e nuovi follower.
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
