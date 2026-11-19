#!/usr/bin/env python3
"""Esporta un post nella cartella Drive «da postare» (visibile da Finder e dall'app File dell'iPhone).
Uso (dalla radice del repo): python3 SOCIAL/esporta-post.py 1
Prende le slide da SOCIAL/clip-social/post-N/pronto e il testo da SOCIAL/istruzioni-post/post-N.txt.
Scrive in «Il mio Drive/Da postare/post-N/» (alla radice del Drive: File > Google Drive > Da postare): cartelle TikTok/ e Instagram/ con le immagini
numerate 01-10, la copertina facoltativa e il file di testo con tutte le istruzioni."""
import shutil, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
n = sys.argv[1] if len(sys.argv) > 1 else "1"
pronto = ROOT / f"SOCIAL/clip-social/post-{n}/pronto"
testo = ROOT / f"SOCIAL/istruzioni-post/post-{n}.txt"
DA_POSTARE = Path.home() / "Library/CloudStorage/GoogleDrive-cociveramatteo@gmail.com/Il mio Drive/Da postare"
dest = DA_POSTARE / f"post-{n}"
if not pronto.is_dir() or not testo.is_file():
    sys.exit(f"Mancano {pronto} o {testo}")

DA_POSTARE.mkdir(exist_ok=True)
if dest.exists():
    shutil.rmtree(dest)                    # ogni export riparte pulito: niente file vecchi
for piattaforma, nome9 in (("TikTok", "slide-10-tiktok.png"), ("Instagram", "slide-10-instagram.png")):
    d = dest / piattaforma
    d.mkdir(parents=True)
    files = [pronto / f"slide-{i:02d}.png" for i in range(1, 10)] + [pronto / nome9]
    for i, f in enumerate(files, start=1):
        shutil.copy2(f, d / f"{i:02d}.png")
cop = pronto / "copertina.png"
if cop.exists():
    (dest / "Copertina facoltativa").mkdir()
    shutil.copy2(cop, dest / "Copertina facoltativa" / "copertina.png")
shutil.copy2(testo, dest / f"00 LEGGIMI - POST {n}.txt")
print("ok →", dest)
for p in sorted(dest.rglob("*")):
    print("  ", p.relative_to(dest))
