#!/usr/bin/env bash
# Trasloco sicuro di una cartella del banco di lavoro (Mac) verso il magazzino del cantiere (Google Drive).
# Lo lancia Matteo dal Terminale: Claude Code nella sua zona protetta non può scrivere su Drive né cancellare.
#
#   bash .cantiere/strumenti/trasloco.sh <cartella> <destinazione nel magazzino>
#   es. bash .cantiere/strumenti/trasloco.sh 06_FOTO 02_RISORSE/originali/foto-prodotti
#
# 1. copia (cp -Rp) · 2. confronta numero di file e byte · 3. SOLO se coincidono chiede "si" e cancella
#    l'originale dal Mac. Se qualcosa non torna non cancella niente. Registro: .cantiere/archivio/trasloco.log
set -uo pipefail
RADICE="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$RADICE" || exit 2
[ $# -eq 2 ] || { echo "Uso: trasloco.sh <cartella> <destinazione nel magazzino>"; exit 2; }
SRC="${1%/}"; DEST_REL="${2%/}"
[ -d "$SRC" ] || { echo "❌ Cartella non trovata: $SRC"; exit 2; }
[ -L "$SRC" ] && { echo "❌ $SRC è già un collegamento al magazzino"; exit 2; }
case "$DEST_REL" in /*|*..*) echo "❌ La destinazione va scritta relativa al magazzino del cantiere (es. 00_CLIENTE/x)"; exit 2;; esac

MAGC="$(python3 -c 'import json,os;print(os.path.expanduser(json.load(open(".cantiere/cantiere.json"))["magazzino"]))' 2>/dev/null)"
[ -n "$MAGC" ] && [ -d "$MAGC" ] || { echo "❌ Magazzino non raggiungibile: ${MAGC:-?} (Google Drive è aperto?)"; exit 2; }
DEST="$MAGC/$DEST_REL"
if [ -d "$DEST" ] && [ -n "$(ls -A "$DEST" 2>/dev/null)" ]; then
  echo "❌ $DEST_REL nel magazzino esiste già e non è vuota: scegli un'altra destinazione"; exit 2
fi

conta() {  # numero di file e byte totali (stesso metodo per Mac e Drive; .DS_Store esclusi)
  python3 - "$1" <<'PY'
import os, sys
n = b = 0
for d, _, files in os.walk(sys.argv[1]):
    for f in files:
        if f == ".DS_Store":
            continue
        p = os.path.join(d, f)
        if os.path.islink(p):
            continue
        n += 1
        b += os.path.getsize(p)
print(n, b)
PY
}

read -r N1 B1 <<<"$(conta "$SRC")"
printf "📦 %s → magazzino/%s  (%s file, %s MB)\n" "$SRC" "$DEST_REL" "$N1" "$((B1 / 1048576))"
mkdir -p "$DEST" || { echo "❌ Non riesco a creare $DEST"; exit 2; }
cp -Rp "$SRC/." "$DEST/" || { echo "❌ Copia non riuscita: niente è stato cancellato"; exit 1; }
read -r N2 B2 <<<"$(conta "$DEST")"

mkdir -p .cantiere/archivio
LOG=".cantiere/archivio/trasloco.log"
if [ "$N1" != "$N2" ] || [ "$B1" != "$B2" ]; then
  echo "🔴 Non coincide: Mac $N1 file / $B1 byte · magazzino $N2 file / $B2 byte. NON cancello niente."
  echo "$(date '+%Y-%m-%d %H:%M') DIVERSO $SRC → $DEST_REL ($N1/$B1 vs $N2/$B2)" >> "$LOG"
  exit 1
fi
echo "✅ Copia verificata: $N2 file, $B2 byte identici."

if [ "${TRASLOCO_SI:-}" = "1" ]; then R="si"; else
  printf "Cancello \"%s\" dal Mac? Scrivi si per confermare: " "$SRC"; read -r R
fi
if [ "$R" = "si" ]; then
  rm -rf "$SRC" && echo "🧹 $SRC tolta dal Mac (resta nel magazzino)."
  echo "$(date '+%Y-%m-%d %H:%M') SPOSTATO $SRC → $DEST_REL ($N2 file, $B2 byte)" >> "$LOG"
else
  echo "↩️  Non cancellato: $SRC resta anche sul Mac."
  echo "$(date '+%Y-%m-%d %H:%M') COPIATO $SRC → $DEST_REL ($N2 file, $B2 byte), originale tenuto" >> "$LOG"
fi
