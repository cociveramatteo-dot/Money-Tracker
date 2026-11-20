#!/usr/bin/env python3
"""Esporta un post nella cartella Drive «da postare» (visibile da Finder e dall'app File dell'iPhone).
Uso (dalla radice del repo): python3 SOCIAL/esporta-post.py 1
Prende le slide da SOCIAL/clip-social/post-N/pronto e il testo da SOCIAL/istruzioni-post/post-N.txt.
Scrive in «Il mio Drive/Da postare/post-N/» (alla radice del Drive: File > Google Drive > Da postare): cartelle TikTok/ e Instagram/ con le immagini
numerate in ordine, la copertina facoltativa e il file di testo con tutte le istruzioni."""
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

comuni = sorted(pronto.glob("slide-[0-9][0-9].png"))
if not comuni:
    sys.exit(f"Nessuna slide in {pronto}")
if [p.name for p in comuni] != [f"slide-{i:02d}.png" for i in range(1, len(comuni) + 1)]:
    sys.exit(f"La numerazione delle slide in {pronto} non è consecutiva")
chiusura = len(comuni) + 1
varianti = {
    piattaforma: pronto / f"slide-{chiusura:02d}-{piattaforma.lower()}.png"
    for piattaforma in ("TikTok", "Instagram")
}
usa_varianti = any(p.is_file() for p in varianti.values())
if usa_varianti and not all(p.is_file() for p in varianti.values()):
    sys.exit(f"Manca una variante della slide {chiusura:02d}")

DA_POSTARE.mkdir(exist_ok=True)
if dest.exists():
    shutil.rmtree(dest)                    # ogni export riparte pulito: niente file vecchi
for piattaforma, variante in varianti.items():
    d = dest / piattaforma
    d.mkdir(parents=True)
    files = comuni + ([variante] if usa_varianti else [])
    for i, f in enumerate(files, start=1):
        specifica = pronto / f"slide-{i:02d}-{piattaforma.lower()}.png"
        shutil.copy2(specifica if specifica.is_file() else f, d / f"{i:02d}.png")
cop = pronto / "copertina.png"
if cop.exists():
    (dest / "Copertina facoltativa").mkdir()
    shutil.copy2(cop, dest / "Copertina facoltativa" / "copertina.png")
shutil.copy2(testo, dest / f"00 LEGGIMI - POST {n}.txt")
print("ok →", dest)
for p in sorted(dest.rglob("*")):
    print("  ", p.relative_to(dest))
