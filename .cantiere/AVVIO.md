# AVVIO DEL CANTIERE

Lo guida il capocantiere quando Matteo dice "partiamo a costruire": UNA voce alla volta, con istruzioni complete
(AGENTS.md §6.13), spuntandola quando è fatta. Se una voce risulta già fatta (es. il remoto GitHub c'è già), si spunta
e basta. Finché ci sono voci aperte, `riprendiamo` le ricorda.

- [ ] 1. **Progetto**: AGENTS.md §1 (committente, chi approva, obiettivo, vincoli) — domande a Matteo, poche e precise
- [ ] 2. **Attrezzi**: hosting, stack e skill dallo scaffale (skill `attrezza`) → Matteo lancia `attrezza …`
- [ ] 3. **Chrome spento**: in Claude Code `/mcp` → claude-in-chrome → Disable (si riaccende con 🧰 quando serve)
- [ ] 4. **Magazzino**: materiale del cliente in `00_CLIENTE/` e `02_RISORSE/` (se è sul Mac: `trasloco.sh`), poi
      `python3 .cantiere/strumenti/catalogo.py`
- [ ] 5. **Bibliotecario**: notebook NotebookLM col nome del progetto, fonti indicate da
      `python3 .cantiere/strumenti/biblioteca.py`, link in AGENTS.md §1, poi `biblioteca.py --segna …`
- [ ] 6. **Backup**: `gh repo create <nome>-cantiere --private --source . --push` (se `git remote -v` è vuoto)
      e permesso del magazzino: Matteo, in Claude Code, `/permissions` → Workspace → Add directory → il percorso di
      "magazzino" in `.cantiere/cantiere.json` → salva nelle impostazioni del progetto (solo quella cartella, lo
      approva lui). Poi primo `bash .cantiere/strumenti/backup.sh`: deve dare ✅ GitHub e ✅ magazzino
- [ ] 7. **Come si costruisce** in `.cantiere/MAPPA.md` (appena c'è del codice)
- [ ] 8. **Primo checkpoint**
