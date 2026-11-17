#!/usr/bin/env bash
# Porta sul Mac l'ultimo rapporto del guardiano notturno (serve la CLI gh collegata a GitHub).
# Uso: bash .cantiere/strumenti/guardiano/scarica.sh          → solo il rapporto (pochi MB, veloce)
#      bash .cantiere/strumenti/guardiano/scarica.sh --foto   → anche gli screenshot (pesanti)
set -uo pipefail
FOTO=0; [ "${1:-}" = "--foto" ] && FOTO=1
RADICE="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$RADICE" || exit 2
command -v gh >/dev/null || { echo "🔴 Manca gh: brew install gh && gh auth login"; exit 2; }
CANTIERE="$RADICE"
REPO_SITO="$(python3 -c "import json;print(json.load(open('.cantiere/guardiano.json')).get('repo_sito',''))" 2>/dev/null || true)"
[ -n "$REPO_SITO" ] && [ -d "$REPO_SITO/.git" ] && cd "$REPO_SITO"
gh auth status >/dev/null 2>&1 || { echo "🔴 gh non collegato: gh auth login"; exit 2; }
git remote get-url origin >/dev/null 2>&1 || { echo "🟡 Il cantiere non è ancora su GitHub: il guardiano non può girare (vedi skill guardiano)"; exit 1; }
RIGA=$(gh run list --workflow guardiano.yml --limit 1 --json databaseId,conclusion,createdAt,status -q '.[0] | "\(.databaseId) \(.status) \(.conclusion) \(.createdAt)"' 2>/dev/null)
[ -z "$RIGA" ] && { echo "🟡 Il guardiano non ha ancora fatto nessun giro (si attiva al primo push su GitHub)"; exit 1; }
set -- $RIGA
# a giro in corso "conclusion" è vuota: i campi sono 3 invece di 4
if [ $# -ge 4 ]; then ID=$1; STATO=$2; ESITO=$3; QUANDO=$4; else ID=$1; STATO=$2; ESITO="-"; QUANDO=${3:-?}; fi
if [ "$STATO" != "completed" ]; then echo "⏳ Giro in corso (avviato $QUANDO)"; exit 1; fi
G="$CANTIERE/.cantiere/guardiano"
rm -rf "$G/ultimo" && mkdir -p "$G"
gh run download "$ID" --name guardiano --dir "$G/ultimo" >/dev/null 2>&1 || { echo "🔴 Download del rapporto non riuscito (giro $ID, esito $ESITO)"; exit 2; }
if [ "$FOTO" = 1 ]; then
  gh run download "$ID" --name guardiano-screenshot --dir "$G/ultimo" >/dev/null 2>&1 \
    && echo "📸 Screenshot in .cantiere/guardiano/ultimo/screenshot" || echo "🟡 Screenshot non disponibili per questo giro"
fi
cp "$G/ultimo/RAPPORTO.md" "$G/ULTIMO.md" 2>/dev/null
head -n 5 "$G/ULTIMO.md"
[ "$FOTO" = 0 ] && echo "(screenshot non scaricati: aggiungi --foto se servono)"
exit 0
