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
| `03_CODICE/` | **vuota di proposito**: il codice resta in `MoneyTracker/` (nessun trasloco, romperebbe i percorsi Xcode) | — | — |
| `MoneyTracker/`, `MoneyTracker.xcodeproj`, `MoneyTrackerTests/`, `MoneyTrackerUITests/`, `docs/` | app SwiftUI, progetto, test, documento master | Mac + git → GitHub | imprese, operaio, collaudatore |
| `04_CONSEGNE/` | versioni consegnate | magazzino | capocantiere |
| `99_DA_SMISTARE/` | appoggio temporaneo | Mac | tutti scrivono, il magazziniere svuota |
| `.cantiere/` | gestione del cantiere | Mac + git | capocantiere, segretario |
| `.agents/skills/` | skill per tutte le IA | Mac + git | solo dalla chat Azienda |
| `.github/` | nessun workflow (guardiano web rimosso, vedi D-002) | — | — |
| `graphify-out/` | grafo generato | Mac + git | geometra |

## Come si costruisce
<!-- Lo compila il capocantiere all'avvio (o la skill assegna la prima volta che serve). I prompt per le imprese
     citano questa sezione: niente comandi inventati, niente modifiche a file generati. -->
- **Sorgenti** (si modificano): `MoneyTracker/` (Views, Domain, Models, ...), `MoneyTrackerTests/`, `MoneyTrackerUITests/`
- **Generati** (MAI a mano): `graphify-out/`, `docs/MoneyTracker.pdf` (da `docs/MoneyTracker.md`), `*.xcodeproj` solo da Xcode
- **Build + test:** `xcodebuild -scheme MoneyTracker -destination 'platform=iOS Simulator,name=<iPhone disponibile>' build test`
  (scegli il simulatore con `xcrun simctl list devices available`; lo schema è `MoneyTracker`)
- **Anteprima:** Xcode / simulatore
- **Verifiche:** Commissione Suprema (CLAUDE.md) · nessun guardiano web
- **Pubblicazione:** nessuna senza l'ok di Matteo (App Store / TestFlight)

## Dettaglio
<!-- il magazziniere elenca qui sottocartelle e file chiave del banco di lavoro, una riga ciascuno -->
- `SOCIAL/direttive-social.md` — riferimento operativo obbligatorio per ogni sessione social (git)
- `SOCIAL/Bucktrail_Manuale_Strategico_v2.pdf` — manuale strategico, fonte per contenuti e metriche (git)
- `SOCIAL/schermate-app/` — archivio condiviso delle catture, con indice in git e immagini locali
- `SOCIAL/guida/` — indice della serie «Guida: …» (git)
- `SOCIAL/calendario-v1.md` — calendario dei post (git)
- `SOCIAL/testi-v1.md`, `SOCIAL/diario-metriche.md` / `.csv` — testi e metriche (git)
- `SOCIAL/esporta-post.py` — esporta un post su Drive: `python3 SOCIAL/esporta-post.py N` → «Il mio Drive/Da postare/post-N/» (radice del Drive, NON nel magazzino)
- `SOCIAL/istruzioni-post/post-N.txt` — testo e istruzioni del post N (git)
- `SOCIAL/clip-social/post-N/materiale/` — screenshot grezzi di Matteo (fuori da git, non si tocca)
- `SOCIAL/clip-social/post-N/pronto/` — slide pronte del post N (fuori da git)
- `SOCIAL/clip-social/post-N/_lavoro/` — HTML e PNG di lavorazione del post 1 (fuori da git)
- `SOCIAL/caroselli/presentazione-v1/build.py` — genera le slide del carosello da `materiale/` a `pronto/` (`python3 SOCIAL/caroselli/presentazione-v1/build.py`)
- `SOCIAL/caroselli/presentazione-v1.md` — testo del carosello di presentazione (git)
- Carosello di prova superato (17/11): spostato nel magazzino in `02_RISORSE/lavorate/social-prove/prova-01/` (doppione anche in `social-caroselli/` e `fuori-git/`)
- `SOCIAL/landing/`, `SOCIAL/montaggio/` — sito landing e script di montaggio (git)
- `.cantiere/tmp/` — solo appunti correnti (`collaudo.md`, `giudice-*.md`); i log e gli .xcresult dei collaudi S-50 sono nel magazzino in `02_RISORSE/lavorate/collaudi-s50-2026-11/` (s50l, s50m, s50q-2, s50r, e2e-ios, e2e-android, giro1/giro2 commissione) spostati il 2026-11-26. Il file `s70/` resta in `.cantiere/tmp/` quando esiste
- `02_RISORSE/lavorate/fuori-git/parita-android-2026-11-23/` — screenshot di parità iOS↔Android del 2026-11-23 (114 MB, fuori da git, magazzino). Già spostata: `99_DA_SMISTARE/` è vuota
- `02_RISORSE/lavorate/screenshot-app-iphone/` — doppione di `screenshot-app/` (stessi 13 file): da decidere se eliminarlo (non cancellato). Doppioni del manuale in `social-manuale-versioni/` e `non-committati-2026-11-18/`: stesso caso

## Social · backup novembre 2026

- Export dei Post-3–42: Google Drive → «Da postare». Istruzioni e grafiche sorgenti testuali in Git sotto `SOCIAL/`.
- Archivio ricostruibile dei materiali e delle schermate: magazzino → `02_RISORSE/lavorate/fuori-git/SOCIAL/`.
