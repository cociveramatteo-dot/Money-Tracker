# Money Tracker — Guida Completa (v3)

---

## Cosa fa questa app

- **Saldo Attuale**: quello che hai davvero adesso (solo spese/entrate già confermate)
- **A conti fatti**: quello che ti avanzerà dopo aver pagato tutto il pianificato (per conto e totale)
- **Spese Fisse**: affitto, Netflix, abbonamenti — appaiono in home con checkbox. Spunti quando paghi → passano al saldo attuale
- **Stipendio variabile**: inserisci lo stipendio quando lo conosci come entrata non confermata → appare nel saldo futuro → spunti quando arriva → passa al saldo attuale
- **Trasferimento tra conti**: sposta denaro da un conto all'altro
- **Budget mensile** per categoria (con filtro per conto specifico)
- **Obiettivi di risparmio**
- **Categorie personalizzate**: aggiungi, modifica ed elimina le tue categorie con SF Symbol
- **Elimina movimenti**: tieni premuto su una transazione → Elimina
- **Banner Shortcuts**: aggiungi una spesa in 3 secondi senza aprire l'app

---

## File del progetto

```
MoneyTrackerApp.swift         ← Avvia l'app, configura il database, semina le categorie default
Models.swift                  ← Struttura dati (Account, Transaction, Budget, Goal, Category)
Theme.swift                   ← Design system (colori, tipografia, componenti riutilizzabili)
ContentView.swift             ← Tab bar principale + pulsante + (sopra la tab bar)
DashboardView.swift           ← Home: saldo attuale, A conti fatti, spese fisse
TransactionsView.swift        ← Lista movimenti con filtri a 2 righe + elimina con long-press
AccountsView.swift            ← Gestione conti (esclusione dal totale, elimina)
AddTransactionView.swift      ← Schermata aggiunta/modifica spesa o entrata
AddTransferView.swift         ← Trasferimento tra conti
BudgetView.swift              ← Budget per categoria, con opzione per conto specifico
GoalsView.swift               ← Obiettivi di risparmio
CategoryClassifier.swift      ← Categorizzazione automatica on-device (keyword matching)
AddExpenseIntent.swift        ← Il banner Shortcuts (come Quanto) ⭐
CategoryManagementView.swift  ← Gestione categorie personalizzate ⭐ NUOVO
SETUP.md                      ← Questo file
```

---

## PARTE 1 — Installazione

### Cosa ti serve
- **Mac** con macOS 13 o superiore
- **Xcode** (gratuito dall'App Store del Mac) — cerca "Xcode" e scaricalo (~7 GB)
- **iPhone** con iOS 17 o superiore
- **Cavo USB** per collegare iPhone al Mac la prima volta

---

### Passo 1 — Crea il progetto in Xcode

1. Apri **Xcode**
2. Clicca **"Create New Project…"**
3. Seleziona **iOS → App** → clicca **Next**
4. Compila i campi così:
   - **Product Name:** `MoneyTracker`
   - **Team:** (scegli il tuo Apple ID — se non appare, vai in Xcode → Settings → Accounts → "+")
   - **Organization Identifier:** `com.tuonome.moneytracker` *(es. `com.matteo.moneytracker`)*
   - **Interface:** `SwiftUI`
   - **Language:** `Swift`
   - **Storage:** `SwiftData` ✅
5. Clicca **Next** → scegli dove salvare → **Create**

---

### Passo 2 — Aggiungi i file dell'app

1. Elimina i file default creati da Xcode (seleziona → Backspace → "Move to Trash"):
   - `ContentView.swift`
   - `Item.swift` (se presente)
2. Apri la cartella **MoneyTracker** nel Finder
3. Seleziona **tutti i file `.swift`** (Cmd+A) — devono essere 13 file
4. Trascinali dentro Xcode nel pannello sinistro, sotto la cartella `MoneyTracker`
5. Nella finestra che appare:
   - ✅ **"Copy items if needed"**
   - ✅ **"Add to target: MoneyTracker"**
   - Clicca **Finish**

**Verifica:** vai in Xcode → clicca su uno dei file → nel pannello destro (File Inspector) controlla che "Target Membership" abbia ✅ accanto a MoneyTracker. Fallo per tutti i file se vedi errori "Cannot find X in scope".

---

### Passo 3 — Firma e installa sull'iPhone

1. Clicca sull'icona del progetto (in alto nel pannello sinistro)
2. Clicca su **MoneyTracker** sotto "Targets"
3. Tab **"Signing & Capabilities"**
4. Assicurati che il tuo **Team** sia selezionato
5. **NON aggiungere** iCloud o Push Notifications (non supportati con Apple ID gratuito)
6. Collega il tuo iPhone al Mac con il cavo
7. Sul telefono → **"Autorizza"** quando chiede di fidarsi del computer
8. In Xcode, in alto cambia il dispositivo da "Any iOS Device" al **tuo iPhone**
9. Premi **▶ (Play)**
10. Prima volta: vai su iPhone in `Impostazioni → Privacy e sicurezza → App per sviluppatori` → tocca il tuo Apple ID → **"Autorizza"**
11. Riapri l'app

---

### Passo 4 — Configura il banner Shortcuts ⭐

1. App **Comandi** sul tuo iPhone → **"+"** in alto a destra
2. **"Aggiungi azione"** → cerca **"Money Tracker"**
3. Vedrai: Aggiungi spesa, Aggiungi entrata, Controlla saldo
4. Seleziona **"Aggiungi spesa"**
5. Tocca `···` in alto a destra → **"Aggiungi a schermata Home"** o **"Aggiungi a schermata di blocco"**

**Come funziona:** tocchi l'icona → appare il banner in cima allo schermo → inserisci nome e importo → salvato. L'app non si apre nemmeno. Esattamente come "Quanto: Expense Tracker".

---

## PARTE 2 — Come usare l'app

### Primo avvio

1. Tab **Conti** (ultima icona) → **"+"** → aggiungi i tuoi conti con il saldo attuale
2. Aggiungi le spese fisse (affitto, abbonamenti) con il toggle "Spesa fissa" attivo

---

### Stipendio variabile — come gestirlo

**Il 1° del mese, quando sai l'importo:**
1. Tocca **"+"** → tipo **Entrata**
2. Inserisci importo (es. €1.800) e nome (es. "Stipendio Giugno")
3. **Togli la spunta da "Già effettuato"** ← punto chiave
4. Scegli il conto, salva

**Risultato:**
- **Saldo Attuale** → invariato (i soldi non ci sono ancora)
- **A conti fatti** → sale di €1.800

**Il 10, quando arrivano:**
1. Tab **Movimenti** → trova "Stipendio Giugno" (grigio = pianificato)
2. **Tieni premuto** → **"Segna come fatto"** — oppure tocca per aprirlo → attiva "Già effettuato"
3. Il Saldo Attuale sale di €1.800

---

### Spese fisse (affitto, abbonamenti)

1. **"+"** → tipo Uscita
2. Nome (es. "Affitto €850"), importo
3. Attiva **"Spesa fissa"** — "Già effettuato" si spegne automaticamente
4. Salva

**In home:** ○ = da pagare. Tocca quando paghi → ● → passa al Saldo Attuale.

---

### Trasferimento tra conti

1. Tocca **"+"** → menu → **"Trasferimento tra conti"**
2. Inserisci importo
3. Scegli conto **Da** e conto **A**
4. Tocca **"Trasferisci"**

Entrambi i saldi si aggiornano. Nella lista movimenti usa il filtro **"Trasf."** per vederli.

---

### Eliminare una transazione

**Tieni premuto** sulla transazione → appare il menu contestuale → tocca **"Elimina"**.

---

### Categorie personalizzate

Vai in **Movimenti → "+"** → tocca la categoria → in basso al foglio tocca **"Gestisci"**.

Oppure da qualsiasi punto dove aggiungi/modifichi una transazione.

- **Categorie predefinite**: non eliminabili (mostrano il tag "predefinita")
- **Aggiungi**: tocca **"+"** in alto → scegli icona dal pannello → dai un nome
- **Modifica**: tocca una categoria personalizzata
- **Elimina**: tieni premuto → "Elimina"

---

### Conti: esclusione dal totale e eliminazione

**Tieni premuto** su un conto per il menu:
- **Escludi dal totale**: il conto non contribuisce al saldo totale mostrato in home (utile per risparmio separato o conti di terzi)
- **Archivia**: il conto rimane con i suoi movimenti ma non appare nelle liste
- **Elimina**: rimozione definitiva del conto (attenzione: le transazioni collegate rimangono orfane)

---

### Logica saldo attuale / futuro

| | Cosa include |
|---|---|
| **Saldo Attuale** | Solo movimenti già confermati (✓ Già effettuato) |
| **A conti fatti** | Tutto: confermati + pianificati (spese fisse non pagate, stipendio non ancora ricevuto, ecc.) |

La differenza tra i due è esattamente quanto devi ancora pagare o ricevere.

---

### Filtri movimenti

**Riga 1:** Tutti · Fisse · Trasf. · Uscite · Entrate

**Riga 2:** tutte le tue categorie (predefinite + personalizzate)

Puoi combinare i filtri: es. "Uscite" + "Cibo" mostra solo le spese alimentari.

---

### Budget per conto

1. Tab **Budget** → **"+"**
2. Scegli la categoria
3. Nella sezione **"Conto (opzionale)"**: lascia "Tutti" per applicarlo a tutti i conti, oppure seleziona un conto specifico
4. Inserisci il limite mensile → **"Salva"**

---

## PARTE 3 — Aggiornare l'app in futuro

1. Scrivimi e ti do il codice aggiornato
2. Apri il file `.swift` in Xcode → sostituisci il contenuto
3. Premi **▶ (Play)** — la nuova versione si installa in pochi secondi
4. **I dati sono al sicuro**: SwiftData non li cancella durante gli aggiornamenti

**Nota:** con Apple ID gratuito, il certificato scade ogni 7 giorni. Ricollegare il telefono e premere Play lo rinnova. Oppure installa **AltStore** (altstore.io, gratis) per il rinnovo automatico via WiFi.

---

## Errori comuni e soluzioni

| Problema | Soluzione |
|----------|-----------|
| "Cannot find 'Account' in scope" o simili | Clicca su ogni file .swift → File Inspector (destra) → spunta ✅ "MoneyTracker" sotto Target Membership |
| "Personal development teams do not support iCloud" | NON aggiungere iCloud o Push Notifications con Apple ID gratuito — l'app usa solo SwiftData locale |
| App non si apre sul telefono | Impostazioni → Privacy → App per sviluppatori → Autorizza il tuo Apple ID |
| "Untrusted Developer" | Stesso passo sopra |
| "Signing failed" | Xcode → Signing & Capabilities → Team → seleziona il tuo Apple ID |
| Certificato scaduto (7 giorni) | Ricollega iPhone, premi Play in Xcode |
| Trasferimento non disponibile | Devi avere almeno 2 conti non archiviati |
| Il pulsante + copre la tab bar | Aggiornato in v3 — usa `.padding(.bottom, 90)` invece di `.offset` |
| Non riesco a eliminare una transazione | Lo swipe non funziona nelle ScrollView. Usa il **long press** (tieni premuto) |
