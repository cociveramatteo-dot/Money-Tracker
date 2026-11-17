---
name: bibliotecario
description: Fa domande a NotebookLM (il bibliotecario) sui documenti del cliente invece di leggerli, risparmiando crediti. Usala quando serve un'informazione contenuta nei documenti del cliente (brief, vecchio sito, note riunioni, PDF), o quando Matteo dice "chiedi al bibliotecario: …".
---
# Bibliotecario (NotebookLM)

Il notebook del cantiere è indicato in AGENTS.md §1. Cosa contiene: `.cantiere/bibliotecario/FONTI.md`.
NotebookLM non ha un accesso automatico: le fonti le carica Matteo, guidato da `biblioteca.py` (vedi in fondo).

**Quando usarlo**: tanto materiale del cliente (decine di pagine, molti PDF, vecchi siti, registrazioni) o domande
che incrociano più documenti. File corti (meno di ~20 pagine): leggili tu partendo dal catalogo, costa meno.

1. **Prima guarda le risposte già avute**: `.cantiere/bibliotecario/RISPOSTE.md` (cerca con grep). Se c'è, usala.
2. Se hai uno strumento NotebookLM collegato (server MCP o skill), fai la domanda direttamente.
3. Altrimenti prepara per Matteo la domanda pronta e aspetta:
```
📚 Domanda per il bibliotecario (incollala nel notebook "<nome>"):
«<domanda precisa, chiedi di citare la fonte e di dire "non risulta" se non c'è>»
Poi incolla qui la risposta.
```
4. Salva sempre la risposta in `.cantiere/bibliotecario/RISPOSTE.md`:
   `## AAAA-MM-GG · <domanda>` + risposta breve + fonte. Così la stessa domanda non si fa due volte.
5. Se la risposta contiene un dato del cliente confermato (prezzo, orario, numero), segnalo: va registrato nei
   file dati del progetto e, se serve, in APPROVAZIONI.

Quando NON usarla: per file piccoli e già nel codice (leggili direttamente) o per il codice (usa il grafo).

## Tenere il notebook aggiornato
- `python3 .cantiere/strumenti/biblioteca.py` dice cosa aggiungere, ricaricare o togliere, con le istruzioni per
  Matteo (le lancia il checkpoint). Dopo che Matteo ha fatto: `biblioteca.py --segna <file>…`.
- Google Documenti/Fogli/Presentazioni presi da Drive si aggiornano da soli nel notebook; PDF e altri file sono
  copie ferme e vanno ricaricati quando cambiano (lo segnala lo strumento).
- Prima di fidarti di una risposta su un dato che cambia (prezzi, date, stato lavori), controlla che la fonte non
  sia "da ricaricare". Lo stato del lavoro sta nei file del cantiere, non nel notebook.
