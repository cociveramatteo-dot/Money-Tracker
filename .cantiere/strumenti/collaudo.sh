#!/usr/bin/env bash
# Collaudo automatico del cantiere. Compatibile con la bash 3.2 di macOS.
# Uso: bash .cantiere/strumenti/collaudo.sh [cartella_codice]
# Rileva lo stack, lancia gli strumenti che trova e scrive il rapporto in .cantiere/tmp/collaudo.md.
# Non installa niente da solo: se manca uno strumento lo segnala.
# Exit code: 0 = tutto ok · 1 = avvisi · 2 = errori.
set -uo pipefail

RADICE="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$RADICE" || exit 2
CODICE="${1:-03_CODICE}"
[ -d "$CODICE" ] || CODICE="."
OUT=".cantiere/tmp/collaudo.md"
mkdir -p .cantiere/tmp
STATO=0   # 0 ok, 1 avvisi, 2 errori
peggiora() { [ "$1" -gt "$STATO" ] && STATO="$1"; return 0; }

{
  echo "# Rapporto di collaudo — $(date '+%Y-%m-%d %H:%M')"
  echo
  echo "Cartella del codice: \`$CODICE\`"
  echo
} > "$OUT"

esegui() { # esegui "Titolo" livello_se_fallisce comando...
  local titolo="$1" livello="$2"; shift 2
  local log=".cantiere/tmp/ultimo.log"
  if "$@" > "$log" 2>&1; then
    echo "- 🟢 **$titolo**" >> "$OUT"
  else
    if [ "$livello" = "2" ]; then echo "- 🔴 **$titolo** (fallito)" >> "$OUT"; else echo "- 🟡 **$titolo** (avvisi)" >> "$OUT"; fi
    peggiora "$livello"
    { echo '  ```'; tail -n 40 "$log" | sed 's/^/  /'; echo '  ```'; } >> "$OUT"
  fi
}
manca() { echo "- ⚪ **$1**: non disponibile ($2)" >> "$OUT"; }

echo "## Strumenti dello stack" >> "$OUT"
TROVATO=0

# --- Node / JavaScript / TypeScript ---
if [ -f "$CODICE/package.json" ]; then
  TROVATO=1
  if ! command -v npm >/dev/null 2>&1; then
    manca "Node" "npm non installato"; peggiora 1
  elif [ ! -d "$CODICE/node_modules" ]; then
    echo "- 🟡 **Dipendenze**: manca node_modules, esegui \`npm install --prefix $CODICE\`" >> "$OUT"; peggiora 1
  else
    for s in lint typecheck test build; do
      if node -e "process.exit(require('./$CODICE/package.json').scripts?.['$s']?0:1)" 2>/dev/null; then
        lvl=2; [ "$s" = "lint" ] && lvl=1
        esegui "npm run $s" "$lvl" npm --prefix "$CODICE" run "$s" --silent
      fi
    done
  fi
fi

# --- Python ---
if [ -f "$CODICE/pyproject.toml" ] || [ -f "$CODICE/requirements.txt" ] || [ -f "$CODICE/setup.py" ]; then
  TROVATO=1
  if command -v ruff >/dev/null 2>&1; then esegui "ruff check" 1 ruff check "$CODICE"; else manca "ruff" "pipx install ruff"; fi
  if command -v mypy >/dev/null 2>&1; then esegui "mypy" 1 mypy "$CODICE"; else manca "mypy" "pipx install mypy"; fi
  if ls "$CODICE"/tests "$CODICE"/test_*.py >/dev/null 2>&1 || find "$CODICE" -name 'test_*.py' -not -path '*/.venv/*' | grep -q .; then
    if command -v pytest >/dev/null 2>&1; then esegui "pytest" 2 pytest -q "$CODICE"; else manca "pytest" "pip install pytest"; peggiora 1; fi
  fi
fi

# --- Sito statico ---
if [ "$TROVATO" = "0" ] && find "$CODICE" -maxdepth 3 -name '*.html' -not -path '*/node_modules/*' | grep -q .; then
  echo "- ℹ️ Sito statico: nessun build da eseguire, valgono i controlli statici qui sotto." >> "$OUT"
  TROVATO=1
fi
[ "$TROVATO" = "0" ] && echo "- ℹ️ Nessuno stack riconosciuto in \`$CODICE\`." >> "$OUT"

# --- Controlli statici (sempre) ---
echo >> "$OUT"
python3 .cantiere/strumenti/controlli.py "$CODICE" >> "$OUT" 2>&1
peggiora $?

# --- Git ---
echo "## Git" >> "$OUT"
if git rev-parse --git-dir >/dev/null 2>&1; then
  ULTIMO_TAG="$(git tag -l 'checkpoint-*' --sort=-creatordate | head -n 1)"
  NON_SALVATI="$(git status --porcelain | wc -l | tr -d ' ')"
  echo "- Ultimo checkpoint: ${ULTIMO_TAG:-nessuno}" >> "$OUT"
  echo "- File modificati non salvati: $NON_SALVATI" >> "$OUT"
  if [ -n "$ULTIMO_TAG" ]; then
    echo "- Commit dall'ultimo checkpoint: $(git rev-list --count "$ULTIMO_TAG"..HEAD)" >> "$OUT"
    DIFF="$(git diff --stat "$ULTIMO_TAG"..HEAD | tail -n 25)"
    [ -n "$DIFF" ] && printf '```\n%s\n```\n' "$DIFF" >> "$OUT"
  fi
else
  echo "- 🔴 Non è un repository git: esegui \`git init\`" >> "$OUT"; peggiora 2
fi

case "$STATO" in 0) E="🟢 TUTTO OK";; 1) E="🟡 CI SONO AVVISI";; *) E="🔴 CI SONO ERRORI";; esac
printf '\n## Esito: %s\n' "$E" >> "$OUT"
echo "Collaudo finito: $E — rapporto in $OUT"
exit "$STATO"
