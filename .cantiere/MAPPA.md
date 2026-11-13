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
