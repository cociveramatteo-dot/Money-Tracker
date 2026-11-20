#!/usr/bin/env bash
# Controllo spazio: disco del Mac, peso del cantiere (senza seguire i collegamenti al magazzino),
# file pesanti fuori posto. Non cancella niente. Compatibile con la bash 3.2 di macOS.
# Uso: bash .cantiere/strumenti/spazio.sh
set -uo pipefail
RADICE="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$RADICE" || exit 1

# Spazio libero (KB) sul volume della home
LIBERI_KB=$(df -Pk "$HOME" | awk 'NR==2{print $4}')
TOTALE_KB=$(df -Pk "$HOME" | awk 'NR==2{print $2}')
LIBERI_GB=$(( LIBERI_KB / 1024 / 1024 ))
TOTALE_GB=$(( TOTALE_KB / 1024 / 1024 ))
if   [ "$LIBERI_GB" -ge 35 ]; then SEM="🟢"
elif [ "$LIBERI_GB" -ge 20 ]; then SEM="🟡"
else SEM="🔴"; fi

peso() { du -sh "$1" 2>/dev/null | awk '{print $1}'; }

echo "## Spazio"
echo "- Disco: $SEM **$LIBERI_GB GB liberi** su $TOTALE_GB GB (soglia di sicurezza: 35 GB)"
echo "- Cantiere sul Mac (collegamenti al magazzino esclusi): **$(peso .)**"
for d in .git node_modules 03_CODICE/node_modules graphify-out .cantiere/archivio .cantiere/guardiano 99_DA_SMISTARE; do
  [ -e "$d" ] && [ ! -L "$d" ] && echo "  - \`$d\`: $(peso "$d")"
done
echo
echo "### File più pesanti sul Mac (> 20 MB, magazzino escluso)"
TROVATI=$(find . -type f -size +20M \
  -not -path './.git/*' -not -path '*/node_modules/*' 2>/dev/null | head -n 15)
if [ -z "$TROVATI" ]; then
  echo "- nessuno 🟢"
else
  echo "$TROVATI" | while IFS= read -r f; do
    echo "- \`${f#./}\` ($(peso "$f")) → proposta: magazzino"
  done
fi
echo
echo "### Collegamenti al magazzino"
for d in 00_CLIENTE 02_RISORSE 04_CONSEGNE; do
  if [ -L "$d" ]; then
    if [ -e "$d" ]; then echo "- \`$d\` → $(readlink "$d") 🟢"; else echo "- \`$d\` → $(readlink "$d") 🔴 non raggiungibile (Drive aperto?)"; fi
  elif [ -d "$d" ]; then
    echo "- \`$d\` è una cartella sul Mac (non nel magazzino): $(peso "$d")"
  fi
done
