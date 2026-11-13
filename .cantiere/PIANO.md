# PIANO DEI LAVORI

Stato: `[ ]` da fare · `[~]` fatto, da collaudare · `[x]` chiuso (collaudatore o Matteo) · `[!]` bloccato · `[?]` serve Matteo
Lo scrive l'architetto o il capocantiere. Ogni task è AUTOSUFFICIENTE: chi lo esegue legge solo
il task e i file indicati.

## In corso / prossimi

### T-000 [ ] Trasloco nel modello 2.0 (cantiere adottato o aggiornato)
- **A chi:** magazziniere (proposta) → Matteo approva → Matteo lancia `bash .cantiere/strumenti/trasloco.sh <cartella> <destinazione>` per ogni cartella verso il magazzino (Claude Code non può scrivere su Drive) → capocantiere sistema il resto
- **Obiettivo:** materiale pesante e del cliente nel magazzino su Drive; sul Mac solo codice e gestione del cantiere
- **Leggere:** `python3 .cantiere/strumenti/magazzino.py`, `bash .cantiere/strumenti/spazio.sh`, file `*.cantiere-nuovo`
- **Toccare:** spostamenti verso il magazzino (`.cantiere/cantiere.json` → "magazzino"); poi collegamenti 00_CLIENTE/02_RISORSE/04_CONSEGNE
- **Fatto quando:** piano di trasloco approvato ed eseguito; cartelle collegate; tolte da `.gitignore` le righe del
  blocco "adozione" per le cartelle sistemate (ciò che resta sul Mac deve essere leggero prima di entrare in git); `catalogo.py` eseguito; `*.cantiere-nuovo` uniti
  dal capocantiere e cancellati; `.cantiere/guardiano.json` compilato; spazio del cantiere sul Mac < 300 MB (se possibile)
- **Non fare:** cancellare file; rinominare o spostare file del codice senza l'ok dell'architetto; toccare il sito online

### T-001 [ ] Impianto del cantiere
- **A chi:** capocantiere
- **Obiettivo:** compilare AGENTS.md §1, aggiornare MAPPA.md, scrivere i primi task
- **Leggere:** `00_CLIENTE/`, `01_PROGETTO/`
- **Toccare:** `AGENTS.md`, `.cantiere/MAPPA.md`, `.cantiere/PIANO.md`
- **Fatto quando:** AGENTS.md senza `[DA COMPILARE]` (o con le domande per Matteo segnate `[?]`)
- **Non fare:** codice

## Fatti
<!-- i task chiusi si spostano qui, con data e chi li ha fatti -->

---
Modello di task:
```
### T-000 [ ] Titolo
- **A chi:** architetto / operaio / impresa / collaudatore / magazziniere / pulizie / Matteo
- **Obiettivo:**
- **Leggere:**
- **Toccare:**
- **Fatto quando:** (criteri verificabili)
- **Non fare:**
```
