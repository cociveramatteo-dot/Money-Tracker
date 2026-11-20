#!/usr/bin/env bash
# Installa il guardiano notturno in un repository del sito che vive in una sottocartella del cantiere
# (es. TARTUFARM/sito, già collegato a GitHub e Netlify). Il guardiano gira sul repository che sta su GitHub.
#   bash .cantiere/strumenti/guardiano/installa-nel-repo.sh <cartella-del-repo>
# Copia: workflow, script del guardiano, .cantiere/guardiano.json (build e cartella pubblicata letti da netlify.toml).
# Se il sito usa Netlify aggiunge a netlify.toml la regola "ignore": i push che cambiano solo .cantiere/ e .github/
# non ripubblicano il sito (niente crediti Netlify spesi per il guardiano).
# Aggiorna il guardiano.json del cantiere (repo_sito) così scarica.sh e pagella.py sanno dove guardare.
set -euo pipefail
RADICE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
REPO="$(cd "${1:?Uso: installa-nel-repo.sh <cartella-del-repo>}" && pwd)"
[ -d "$REPO/.git" ] || { echo "❌ $REPO non è un repository git"; exit 1; }
REL="${REPO#$RADICE/}"

mkdir -p "$REPO/.github/workflows" "$REPO/.cantiere/strumenti/guardiano"
cp "$RADICE/.cantiere/strumenti/guardiano/guardiano.yml" "$REPO/.github/workflows/guardiano.yml"
for f in package.json giro.mjs riassunto.mjs esegui.sh scarica.sh; do
  cp "$RADICE/.cantiere/strumenti/guardiano/$f" "$REPO/.cantiere/strumenti/guardiano/$f"
done
chmod +x "$REPO/.cantiere/strumenti/guardiano/"*.sh

# build e cartella pubblicata da netlify.toml (se c'è)
BUILD=""; PUBBLICATA="."
if [ -f "$REPO/netlify.toml" ]; then
  BUILD="$(python3 -c "import re;t=open('$REPO/netlify.toml').read();m=re.search(r'^\s*command\s*=\s*\"([^\"]*)\"',t,re.M);print(m.group(1) if m else '')")"
  PUBBLICATA="$(python3 -c "import re;t=open('$REPO/netlify.toml').read();m=re.search(r'^\s*publish\s*=\s*\"([^\"]*)\"',t,re.M);print(m.group(1) if m else '.')")"
fi
python3 - "$REPO/.cantiere/guardiano.json" "$RADICE/.cantiere/guardiano.json" "$BUILD" "$PUBBLICATA" "$REL" <<'PY'
import json, sys, pathlib
nel_repo, del_cantiere, build, pub, rel = sys.argv[1:6]
base = json.loads(pathlib.Path(del_cantiere).read_text()) if pathlib.Path(del_cantiere).is_file() else {}
r = {**base, "cartella_sito": ".", "comando_build": build, "cartella_pubblicata": pub}
r.pop("repo_sito", None)
pathlib.Path(nel_repo).write_text(json.dumps(r, indent=2, ensure_ascii=False) + "\n")
c = {**base, "repo_sito": rel, "cartella_sito": rel, "comando_build": build, "cartella_pubblicata": pub}
pathlib.Path(del_cantiere).write_text(json.dumps(c, indent=2, ensure_ascii=False) + "\n")
PY
NETLIFY=""
if [ -f "$REPO/netlify.toml" ] && ! grep -qE '^\s*ignore\s*=' "$REPO/netlify.toml"; then
  python3 - "$REPO/netlify.toml" <<'PY2'
import pathlib, re, sys
p = pathlib.Path(sys.argv[1]); t = p.read_text(encoding="utf-8")
riga = ('  # Non ripubblicare (e non spendere crediti) se il push cambia solo il cantiere o il guardiano.\n'
        '  ignore = "git diff --quiet $CACHED_COMMIT_REF $COMMIT_REF -- . \':(exclude).cantiere\' \':(exclude).github\'"\n')
m = re.search(r"^\[build\][^\n]*\n", t, re.M)
t = t[:m.end()] + riga + t[m.end():] if m else "[build]\n" + riga + "\n" + t
p.write_text(t, encoding="utf-8")
PY2
  NETLIFY=" · netlify.toml: aggiunta la regola che non ripubblica per i soli file del guardiano"
fi
# nel repo del sito i rapporti locali e le dipendenze del guardiano non vanno in git
touch "$REPO/.gitignore"
for riga in ".cantiere/guardiano/" ".cantiere/strumenti/guardiano/node_modules/"; do
  grep -qxF "$riga" "$REPO/.gitignore" || echo "$riga" >> "$REPO/.gitignore"
done
echo "✅ Guardiano installato nel repository $REL (build: ${BUILD:-nessuna} · pubblica: $PUBBLICATA)$NETLIFY"
echo "   Si attiva al prossimo push: cd \"$REPO\" && git add .github .cantiere .gitignore $([ -f "$REPO/netlify.toml" ] && echo netlify.toml) && git commit -m \"guardiano notturno\" && git push"
