#!/usr/bin/env bash
# Copia di sicurezza aggiornata del cantiere: la lancia il checkpoint (fase 7), o Matteo quando vuole.
#   bash .cantiere/strumenti/backup.sh
# 1. GitHub: push del cantiere (se ha un remoto) → copia sempre aggiornata, con tutta la storia.
# 2. Magazzino su Drive: un file "bundle" per repository (cantiere e, se c'è, sito) in <magazzino>/backup/,
#    sovrascritto a ogni giro: è la copia nel magazzino, sempre all'ultimo checkpoint.
#    Si ripristina con:  git clone <file>.bundle <cartella>
# Non tocca il sito online (niente push del repository del sito: quello lo decide Matteo, per i crediti Netlify).
set -uo pipefail
RADICE="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "❌ Non è un repository git"; exit 2; }
cd "$RADICE"
MAGC="$(python3 -c 'import json,os;print(os.path.expanduser(json.load(open(".cantiere/cantiere.json"))["magazzino"]))' 2>/dev/null)"
SLUG="$(python3 -c 'import json;print(json.load(open(".cantiere/cantiere.json")).get("slug","cantiere"))' 2>/dev/null || echo cantiere)"
REPO_SITO="$(python3 -c 'import json;print(json.load(open(".cantiere/guardiano.json")).get("repo_sito",""))' 2>/dev/null || true)"
ESITO=0

# 1. GitHub
if git remote get-url origin >/dev/null 2>&1; then
  if git push -q --follow-tags origin HEAD 2>/dev/null; then echo "✅ GitHub: cantiere aggiornato"; else echo "🟡 GitHub: push non riuscito (rete?)"; ESITO=1; fi
else
  echo "🟡 GitHub: il cantiere non ha un backup. Matteo, nel Terminale nella cartella del cantiere:"
  echo "      gh repo create $SLUG-cantiere --private --source . --push"
  ESITO=1
fi

# 2. Magazzino (bundle)
DEST="$MAGC/backup"
if [ -z "$MAGC" ] || [ ! -d "$MAGC" ]; then
  echo "🟡 Magazzino non raggiungibile (Google Drive è aperto?): copia nel magazzino saltata"; exit 1
fi
if mkdir -p "$DEST" 2>/dev/null && git bundle create "$DEST/$SLUG-cantiere.bundle" --all >/dev/null 2>&1; then
  OK="cantiere"
  if [ -n "$REPO_SITO" ] && [ -d "$REPO_SITO/.git" ]; then
    git -C "$REPO_SITO" bundle create "$DEST/$SLUG-sito.bundle" --all >/dev/null 2>&1 && OK="$OK + sito"
  fi
  printf 'Copie di sicurezza del cantiere (aggiornate a ogni checkpoint: %s).\nRipristino: git clone %s-cantiere.bundle CARTELLA\n' \
    "$(date '+%Y-%m-%d %H:%M')" "$SLUG" > "$DEST/LEGGIMI.txt"
  echo "✅ Magazzino: copia aggiornata ($OK) in backup/"
else
  echo "🟡 Non posso scrivere nel magazzino da qui (zona protetta dell'IA). Matteo, nel Terminale nella cartella del cantiere:"
  echo "      bash .cantiere/strumenti/backup.sh"
  ESITO=1
fi
exit $ESITO
