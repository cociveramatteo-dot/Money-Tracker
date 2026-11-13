# MAPPA DEL CANTIERE — dove sta tutto

> Mappa del banco di lavoro (Mac). Per i file del cliente c'è il CATALOGO nel magazzino
> (`~/Library/CloudStorage/GoogleDrive-cociveramatteo@gmail.com/Il mio Drive/MAGAZZINO/CANTIERI/moneytracker/CATALOGO.md`), per il codice il grafo (`graphify query "…"`).
> La aggiorna il magazziniere a ogni checkpoint.

| Percorso | Cosa contiene | Dove sta davvero | Chi lo tocca |
|---|---|---|---|
| `00_CLIENTE/` | brief, materiale, approvazioni, note riunioni | magazzino (Drive) | Matteo, magazziniere |
| `01_PROGETTO/` | specifiche, architettura, contenuti di lavoro | Mac + git | architetto, redattore |
| `02_RISORSE/originali/` | file originali del cliente (intoccabili) | magazzino | magazziniere |
| `02_RISORSE/lavorate/` | versioni ottimizzate | magazzino | imprese |
| `03_CODICE/` | il software | Mac + git → GitHub | imprese, operaio, collaudatore |
| `04_CONSEGNE/` | versioni consegnate | magazzino | capocantiere |
| `99_DA_SMISTARE/` | appoggio temporaneo | Mac | tutti scrivono, il magazziniere svuota |
| `.cantiere/` | gestione del cantiere | Mac + git | capocantiere, segretario |
| `.agents/skills/` | skill per tutte le IA | Mac + git | solo dalla chat Azienda |
| `.github/workflows/` | guardiano notturno | Mac + git → GitHub | solo dalla chat Azienda |
| `graphify-out/` | grafo generato | Mac + git | geometra |

## Come si costruisce
<!-- Lo compila il capocantiere all'avvio (o la skill assegna la prima volta che serve). I prompt per le imprese
     citano questa sezione: niente comandi inventati, niente modifiche a file generati. -->
- **Sorgenti** (si modificano): [DA COMPILARE: es. scripts/build.js, data/, public/css/]
- **Generati** (MAI a mano, si rigenerano): [DA COMPILARE: es. public/*.html da `node scripts/build.js`]
- **Build:** [DA COMPILARE: comando esatto, o "nessuna"]
- **Anteprima in locale:** [DA COMPILARE: es. `npx serve public`]
- **Verifiche:** guardiano dopo il push (`bash .cantiere/strumenti/guardiano/scarica.sh`) · controlli locali
  `python3 .cantiere/strumenti/controlli.py` · lingue `python3 .cantiere/strumenti/bilingue.py <cartella sito>`
- **Pubblicazione:** [DA COMPILARE: GitHub Pages / Netlify (push su main) …]

## Dettaglio
<!-- il magazziniere elenca qui sottocartelle e file chiave del banco di lavoro, una riga ciascuno -->
