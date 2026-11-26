# PER MATTEO — le cose che aspettano te

Le scrivono le IA del cantiere, sempre con istruzioni complete (AGENTS.md §6.13). Quando una è fatta, la spostano
in "Fatte" con la data. `riprendiamo` e il checkpoint te le ricordano, in ordine.

## Da fare

### BANCA · modello economico — cosa resta a te (tutto spiegato in `.cantiere/banca-modello-economico.md`, copia su Drive `02_RISORSE/lavorate/banca-modello-economico-2026-11-25.md`)
1. ✅ Fatto 2026-11-25: nessun account Apple Developer ancora (si sceglie «Individual» all'iscrizione, dopo il gate del 6/12; la banca resta in coda e si chiede ad Apple prima di costruirla). Dettagli nel §10 del documento.
2. 📍 La tua casella email. ▶️ Invia a info@enablebanking.com la mail del §9 del documento (oggetto e corpo già pronti; cambia la stima del volume se vuoi). ↩️ Incollami la risposta: con costo per conto e fattura minima rifaccio le tabelle e fissiamo i prezzi.
3. 📍 Un avvocato o commercialista. ▶️ Le 4 domande del §8 (Banca d'Italia, GDPR, P.IVA per vendere via store, P.IVA per essere cliente di Enable Banking). ↩️ La risposta in poche righe.

### BANCA · S-60t — tre verifiche prima del collegamento bancario (si può fare quando vuoi, non blocca il lavoro dell'IA)
1. 📍 Browser → developer.apple.com/account → «Membership details». ▶️ Guarda il tipo di account. ↩️ «Individual» o «Organization» (le app finanziarie di account individuali rischiano il rifiuto: linea guida 5.1.1(ix)).
2. 📍 Email a info@enablebanking.com. ▶️ Incolla il messaggio in inglese del §11.4 S-60t di `.cantiere/progetto-banca.md` (te lo copio io se vuoi). ↩️ Incollami la risposta.
3. 📍 Un avvocato o consulente fintech/privacy. ▶️ La domanda della riga L2 del §9 dello stesso file (registrazione presso Banca d'Italia) e il registro dei trattamenti. ↩️ La risposta in 3 righe.

### ANDROID · aggiornare l'app sul tuo telefono
📍 Terminale, cartella `03_CODICE/bucktrail-android`, telefono collegato con Debug USB acceso. ▶️ `./gradlew installDebug` (con JAVA_HOME e ANDROID_HOME come l'altra volta). Si aggiorna sopra la versione installata, i dati restano. ↩️ Dimmi se all'apertura non vedi più l'icona e se lucchetto e icona del login ti sembrano come su iPhone.

### SOCIAL · TikTok — nome e account Business
📍 TikTok → Profilo → Modifica profilo → Nome. ▶️ Scrivi `Bucktrail · budget`. Dopo il primo post passa ad Account Business (Impostazioni e privacy → Account) e nel campo Sito web metti `https://bucktrailapp.com/?utm_source=tiktok&utm_medium=bio`; poi la bio può tornare a «link in bio». ↩️ Scrivi «tiktok ok».

### SOCIAL · SC-2 — materiale per i contenuti faceless
📍 Sul Mac, Finder → Vai → Vai alla cartella: `/Users/matteo/Desktop/APP/MoneyTracker/SOCIAL/schermate-app`. ▶️ Per i video con le mani e il telefono servono le tue riprese; le schermate dell'app le fa l'IA dal simulatore. Se vuoi aggiungere tue catture trascinale lì (l'elenco delle viste è nel README). ↩️ «schermate pronte» e quali aree hai coperto.

### NotebookLM (bibliotecario) · 6 fonti da aggiungere
📍 notebooklm.google.com → notebook «MoneyTracker App». ▶️ «Aggiungi fonte» → «Google Drive» → `MAGAZZINO/CANTIERI/moneytracker/` → aggiungi `02_RISORSE/originali/bucktrail-redesign/BRIEF_CANTIERE.md` e `DESIGN_HANDOFF.md` (le due importanti); le 4 licenze dei font (`OFL.txt` e `README.txt` di Inter e Space Grotesk) sono facoltative. ↩️ Scrivi «notebook ok».

## Fatte

- 2026-11-26 13:44 · S-30: traduzioni confermate da Matteo (già ✅ in APPROVAZIONI dal 16/11). Post social: li pubblica Matteo giorno per giorno, non ricordarli più. Apple Developer: ricordarlo solo a ridosso del 6/12.

- 2026-11-26 13:40 · S-50o: Matteo approva le schermate della Protezione avanzata (incluse le 8 nuove «protezione rimossa»).

- 2026-11-26 10:40 · S-50q.1: terzo SQL (rollback atomico) eseguito da Matteo su Supabase, controllo 3 righe ok.

- 2026-11-26 · S-50h2: Matteo ha autorizzato le modifiche a `E2EServer.swift` e `E2EGate.swift`.

- 2026-11-26 10:11 · S-50q: secondo SQL eseguito da Matteo su Supabase, controllo finale 4 righe (colonna key_id, funzione mt_e2e_activate, trigger mt_e2e_state_guard e mt_vault_guard). Inerte finché la protezione è spenta.

- 2026-11-24 23:22 · S-50n: SQL della Protezione avanzata eseguito da Matteo su Supabase, controllo finale 13 righe (8 policy + 5 trigger). Inerte finché nessuno attiva l'opzione.

- 2026-11-24 22:28 · Landing ricaricata su Cloudflare con FAQ sicurezza, privacy aggiornata e Web Analytics (verificato online su 5 pagine). Nota: le pagine hanno 2 codici di misura (il nostro, token b8ce…, e uno iniettato in automatico da Cloudflare, token 4f0c…): innocuo; per tenerne uno solo, togliere il nostro dalle 5 pagine al prossimo caricamento.

- 2026-11-24 22:16 · Android: prova reale del login e della sync su Supabase fatta da Matteo, funziona (S-49).

- 2026-11-24 · `main` portato al redesign (fast-forward, push `6d574da..2364d6e`, ok esplicito di Matteo). Bucktrail Android installata e provata su telefono vero via cavo.

- 2026-11-24 · Ripulita la lista dal capocantiere: chiuse in autonomia S-33 (osservazione), S-39 e S-43 (ok di Matteo in chat), SC-6 (diario metriche popolato), decisioni di pulizia 19/11 (tmp e radice già puliti, copie vecchie del carosello già assenti), traduzioni S-19/S-28/S-6/S-7/S-8 (già ✅), segnalazione strumenti CUA (i test ora girano).

- 2026-11-24 · S-39 traduzioni approvate e S-43 test corretto (ok di Matteo in chat).

- 2026-11-18 · SC-4c: privacy approvata e online, contatti di prova cancellati da Brevo.

- 2026-11-18 · SC-4c: lista d'attesa attiva con double opt-in (Brevo, modello ID 1), email `ciao@bucktrailapp.com`, notifica a Gmail, logo nell'email. Promemoria futuri: chiave API Brevo da rigenerare entro 18/11/2027 (e se resta 90 giorni senza uso); dominio Aruba da rinnovare (calendario 10-15/11/2027).

- 2026-11-18 · SC-4b: landing online su Cloudflare Pages (progetto `bucktrailapp`, caricata a mano da `SOCIAL/landing`), dominio `bucktrailapp.com` e `www` attivi con https. Ogni modifica va ricaricata: Pages, Create deployment, cartella `landing`. Nameserver Aruba → Cloudflare (`melissa`/`randy`). Il form non è ancora attivo (SC-4c).

- 2026-11-18 · SC-4a: dominio `bucktrailapp.com` preso su Aruba (1,83 € il primo anno; prezzo di rinnovo da verificare, scade circa il 18/11/2027). Promemoria 10-15/11/2027 nel calendario (file `.ics` importato).

- 2026-11-16 · Ripulita la lista: rimossi S-26 (collaudo già [x]), S-13e (SQL eseguito), collaudo S-13a/b/c (già [x] 2026-11-14) e il controllo manuale S-23 (superato da S-25: il tap normale ora applica Tutte).

- 2026-11-14 · Collaudo S-12 completato dal collaudatore (01:30, [x]); rimossa richiesta già eseguita.

- 2026-11-14 09:29 · Ripresa Codex completata: eseguiti i sei UI rimasti, note di sospensione sostituite con esito e istruzioni di collaudo.

## S-24 — verifica del blocco sul caso reale
- [x] 📍 Sull'iPhone o sul simulatore dove avveniva il blocco, con la versione contenente le modifiche S-24/S-25. ▶️ Aprire Movimenti, tenere premuto il movimento ricorrente che si bloccava, scegliere Elimina (oppure Ricorrenza), poi Tutte e confermare. Verificare che l'app risponda passando alla tab Home. L'eliminazione conserva le copie già effettuate. ✅ Matteo 2026-11-16 21:49: tutto OK
  ↩️ Riportare questo testo compilato, senza dati personali:
```text
Dispositivo: iPhone / simulatore. Avvio: da icona / da Xcode.
Il blocco su Tutte si ripresenta: sì / no.
Copia: pianificata / già effettuata. Data iniziale serie: …
Se sì: app si chiude / resta ferma / Xcode evidenzia una riga (quale: …).
```
- Autorizzazioni Domain S-24/S-25 e test S-15 ricevute il 2026-11-15; nessuna autorizzazione ulteriore pendente. Già effettuato resta della singola copia (D-010).

- [ ] 📍 **Prova reale a due dispositivi (iPhone + Android) con un account di prova** — Android B9 è finito e provato SOLO con un server finto: il Supabase vero non è mai stato toccato. Prima di usarlo con i tuoi dati serve una prova controllata. ▶️ (1) Su iPhone, nell'app, esci dall'account e crea un account NUOVO con un'email di prova (es. una tua seconda casella): è il «account di prova». Aggiungi 2 conti, 5 movimenti, 1 budget, 1 obiettivo e una spesa ricorrente mensile (con una occorrenza modificata «solo questa»). (2) Sul Mac, Terminale, cartella del cantiere: `cd 03_CODICE/bucktrail-android && export JAVA_HOME="$(/usr/libexec/java_home -v 17)" ANDROID_HOME="$HOME/Library/Android/sdk" && ./gradlew installDebug` (l'emulatore o il telefono Android collegato devono essere accesi; questa build usa il Supabase vero perché legge l'indirizzo dal codice iOS). (3) Su Android: Impostazioni → in fondo «Account» → «Accedi o crea un account» → accedi con l'account di prova. Devono comparire gli stessi conti, movimenti, budget, obiettivi e la serie ricorrente (con l'occorrenza modificata). Se compare l'avviso «Dati già presenti nel cloud» è normale solo se su Android avevi già dati: scegli «Annulla». (4) Su Android aggiungi 1 spesa, modifica un movimento e cancellane uno; su iPhone tira giù per aggiornare e controlla che le tre modifiche ci siano. Poi fai l'inverso (modifica su iPhone, tira giù su Android). (5) Prova l'offline: modalità aereo su Android, aggiungi una spesa, vedi il banner «Offline», riattiva la rete: deve partire da sola. (6) Prova «Esci dall'account» su Android: i dati locali spariscono; riaccedi: tornano. NON provare «Elimina account» sull'account vero. ↩️ Riportami: cosa torna uguale, cosa no (con uno screenshot per ogni differenza) e se qualche movimento è comparso doppio o sparito.
- [ ] 📍 **(Facoltativo, più sicuro) Progetto Supabase di prova** — se vuoi non toccare mai il progetto vero: su supabase.com crea un progetto gratuito nuovo, poi Dashboard → SQL Editor → incolla lo schema delle 5 tabelle `mt_*` (ti preparo io lo script se lo chiedi: nel repository non c'è il codice SQL) con le regole RLS `user_id = auth.uid()` e la funzione `delete_own_account`. Poi dammi URL e chiave «anon/public» del progetto di prova (la chiave anon è pubblica per design, la «service_role» NON darmela mai): le userò con `./gradlew installDebug -PsupabaseUrl=… -PsupabaseKey=…` senza modificare il codice iOS. ↩️ Riportami URL e chiave anon del progetto di prova.
- [ ] 📍 **Prova delle scorciatoie su un telefono Android** — emulatore verificato; sul telefono vero: tieni premuta l'icona di Bucktrail (compaiono «Aggiungi spesa», «Aggiungi entrata», «Saldo conti»); Impostazioni → «Scorciatoie» → «Aggiungi il widget Saldo» e «Aggiungi il riquadro «Aggiungi spesa»». ↩️ Riportami se widget e riquadro compaiono e se con «oscura importi» acceso il widget nasconde le cifre.

