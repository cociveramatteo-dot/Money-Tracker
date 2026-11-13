#!/usr/bin/env bash
# Guardiano notturno: prepara il sito, fa il giro con Playwright, Lighthouse e riassunto.
# Lo lancia GitHub Actions (.github/workflows/guardiano.yml). Si può lanciare anche a mano:
#   bash .cantiere/strumenti/guardiano/esegui.sh
# Legge la configurazione da .cantiere/guardiano.json. Exit 1 se il semaforo è rosso.
set -uo pipefail
RADICE="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$RADICE" || exit 2
QUI="$RADICE/.cantiere/strumenti/guardiano"
CONF="$RADICE/.cantiere/guardiano.json"
OUT="$RADICE/.cantiere/guardiano/ultimo"
PREC="${GUARDIANO_PRECEDENTE:-$RADICE/.cantiere/guardiano/precedente}"

leggi() { python3 -c "import json,sys;c=json.load(open('$CONF'));v=c.get('$1','$2');print(json.dumps(v) if isinstance(v,(dict,list)) else v)"; }
SITO="$(leggi cartella_sito 03_CODICE)"
BUILD="$(leggi comando_build '')"
PUBBLICATA="$(leggi cartella_pubblicata .)"
URL="$(leggi url '')"
EXTRA="$(python3 -c "import json;print(','.join(json.load(open('$CONF')).get('pagine_extra',[])))")"
MONKEY="$(leggi monkey_secondi 60)"
PRODUZIONE="$(leggi dominio_produzione '')"
SOGLIE="$(leggi soglie '{}')"

# 1. dipendenze del guardiano (versioni fissate in package.json)
if [ ! -d "$QUI/node_modules" ]; then
  (cd "$QUI" && npm install --no-audit --no-fund --loglevel=error) || { echo "🔴 npm install fallito"; exit 2; }
fi
export CHROME_PATH="$(cd "$QUI" && node -e "import('playwright').then(m=>console.log(m.chromium.executablePath()))")"
if [ ! -x "$CHROME_PATH" ]; then
  (cd "$QUI" && npx playwright install --with-deps chromium) || { echo "🔴 installazione Chromium fallita"; exit 2; }
  export CHROME_PATH="$(cd "$QUI" && node -e "import('playwright').then(m=>console.log(m.chromium.executablePath()))")"
fi

# 2. sito: URL pubblico (anteprima) oppure copia locale servita su localhost
SERVER_PID=""
if [ -n "$URL" ]; then
  BASE="${URL%/}"
else
  if [ -n "$BUILD" ]; then
    (cd "$SITO" && bash -c "$BUILD") || { echo "🔴 build fallita: $BUILD"; exit 1; }
  fi
  DIR="$SITO/$PUBBLICATA"
  [ -d "$DIR" ] || { echo "🔴 cartella del sito non trovata: $DIR (controlla .cantiere/guardiano.json)"; exit 2; }
  python3 -m http.server 8080 --bind 127.0.0.1 --directory "$DIR" >/dev/null 2>&1 &
  SERVER_PID=$!
  trap '[ -n "$SERVER_PID" ] && kill $SERVER_PID 2>/dev/null' EXIT
  for i in 1 2 3 4 5 6 7 8 9 10; do curl -sf http://127.0.0.1:8080/ >/dev/null && break; sleep 1; done
  BASE="http://127.0.0.1:8080"
fi

# 3. giro completo
ARG_PREC=()
[ -d "$PREC/screenshot" ] && ARG_PREC=(--precedente "$PREC")
node "$QUI/giro.mjs" --base "$BASE" --out "$OUT" --monkey "$MONKEY" --pagine "$EXTRA" "${ARG_PREC[@]}" ${PRODUZIONE:+--produzione "$PRODUZIONE"} || echo "⚠️ giro terminato con errori"

# 4. Lighthouse su massimo 5 pagine, telefono e desktop
mkdir -p "$OUT/lighthouse"
python3 -c "import json;print('\n'.join(json.load(open('$OUT/risultati.json'))['pagine'][:5]))" 2>/dev/null | while IFS= read -r P; do
  NOME="$(echo "$P" | sed 's#^/##; s#/$##; s#[^A-Za-z0-9]\+#-#g')"; [ -z "$NOME" ] && NOME="home"
  for MODO in telefono desktop; do
    PRESET=(); [ "$MODO" = desktop ] && PRESET=(--preset=desktop)
    "$QUI/node_modules/.bin/lighthouse" "$BASE$P" --quiet --output=json --output-path="$OUT/lighthouse/${NOME}__${MODO}.json" \
      --chrome-flags="--headless=new --no-sandbox" "${PRESET[@]}" >/dev/null 2>&1 || echo "⚠️ Lighthouse non riuscito su $P ($MODO)"
  done
done

# 5. riassunto
node "$QUI/riassunto.mjs" --out "$OUT" --soglie "$SOGLIE"
