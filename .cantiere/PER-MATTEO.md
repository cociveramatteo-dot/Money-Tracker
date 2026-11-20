# PER MATTEO — le cose che aspettano te

Le scrivono le IA del cantiere, sempre con istruzioni complete (AGENTS.md §6.13). Quando una è fatta, la spostano
in "Fatte" con la data. `riprendiamo` e il checkpoint te le ricordano, in ordine.

## Da fare

### SOCIAL · SC-6 — avvia Copilot per il diario metriche
📍 Terminale, nuova scheda, nella cartella del cantiere: `copilot`.
▶️ Incolla:
```text
Task SC-6 (progetto SOCIAL). Crea SOCIAL/diario-metriche.csv con intestazioni (una riga per pubblicazione): data, ora, piattaforma, codice_format, variante_hook, durata_s, view, tempo_medio_s, pct_completamento, invii, salvataggi, commenti, visite_profilo, click_link, iscritti_landing. Crea SOCIAL/diario-metriche.md con le istruzioni d'uso e queste regole del manuale §9.5/9.7: ogni domenica si calcola la mediana (non la media) degli ultimi 10 video per piattaforma; un format si promuove se 2 varianti su 3 superano la mediana, si abbandona dopo 6 pubblicazioni sotto; engagement rate = interazioni totali / copertura × 100. Aggiungi una riga di esempio chiaramente segnata come ESEMPIO. Non inventare numeri reali. Niente altro. Commit solo di SOCIAL/diario-metriche.* e .cantiere come da AGENTS.md §4.
```
↩️ Riportami «SC-6 fatto».

### SOCIAL · TikTok — dal 24/11
📍 TikTok → Modifica profilo.
▶️ Dal 24/11 cambia il nome in `Bucktrail · budget`. Dopo il primo post passa ad Account Business (Impostazioni e privacy → Account) e metti nel campo Sito web: `https://bucktrailapp.com/?utm_source=tiktok&utm_medium=bio`; poi la bio può tornare a «link in bio».
↩️ Scrivi «tiktok ok».

### CHECKPOINT 2026-11-19 · Decisioni di pulizia (solo un sì/no, a parole va bene)
📍 In chat, quando riprendiamo.
▶️ Dimmi cosa fare di: 1) `.cantiere/tmp/`: 19 PNG di collaudo (14/11) e le cartelle `review-*` (s6, s7, s8, s14, s31): le sposto nel magazzino o le cancello? 2) il vecchio carosello di prova (17/11, con frasi personali): ora ci sono 3 copie nel magazzino (`lavorate/social-prove/prova-01`, `lavorate/social-caroselli/prova-01`, `lavorate/fuori-git/...`): ne tengo una sola? 3) nella radice del progetto restano `.Rhistory` (vuoto) e `.agent/` (doppione di `.agents/`): li tolgo?
↩️ Scrivi «tmp: sposta/cancella · prova: tieni una · radice: togli/lascia».

### CHECKPOINT 2026-11-19 · NotebookLM (bibliotecario): 6 fonti da aggiungere
📍 notebooklm.google.com → notebook «MoneyTracker App».
▶️ «Aggiungi fonte» → «Google Drive» → `MAGAZZINO/CANTIERI/moneytracker/` → aggiungi: `02_RISORSE/originali/bucktrail-redesign/BRIEF_CANTIERE.md` e `DESIGN_HANDOFF.md` (le due importanti); le 4 licenze dei font (`OFL.txt`/`README.txt` di Inter e Space Grotesk) sono facoltative.
↩️ Scrivi «notebook ok».

### SOCIAL · SC-0 — approva il calendario un post alla volta
📍 Qui in chat, con `SOCIAL/calendario-v1.md`.
▶️ Tema e sequenza dei Post-3–9 approvati. Comunica il giorno di partenza quando lo sai. La prossima proposta è Post-10.
↩️ Dopo ogni risposta si registra l’esito e si passa alla proposta successiva.

### SOCIAL · SC-2 — archivio schermate dell’app
📍 Sul Mac, Finder → Vai → Vai alla cartella e incolla:
```text
/Users/matteo/Desktop/APP/MoneyTracker/SOCIAL/schermate-app
```
▶️ Trascina qui gli screenshot. Nel README trovi l’elenco delle viste. Se vuoi contribuire con altre catture, puoi aggiungerle qui. Per le schermate necessarie ai post l’impresa usa il simulatore.
↩️ Scrivi «schermate pronte» e indica quali aree hai coperto.

### S-33 — decidere osservazione dopo diagnosi non riproducibile
Diagnosi autorizzata il 2026-11-16 ed eseguita: due run isolati e tutta la suite verdi sul main `4fb666a`, senza modificare codice/test. Causa del vecchio rosso non accertata; dettagli in CONSEGNA. Proposta: mantenerlo in osservazione.
📍 Nella chat del capocantiere (Claude Code).
▶️ Incolla:
```text
S-33: mantienilo in osservazione, senza dichiarare corretta o accertata una causa. Fai verificare il dossier CONSEGNA dal collaudatore (Claude Code · Sonnet) sul ramo fix-recurrence-ui-test: nessun codice/test modificato; due run isolati verdi e suite 90 unit + 45 UI tutta verde. Bundle conservato in /tmp/mt-s33-full-main.xcresult. Se ricompare, conserva immediatamente il bundle del fallimento prima di nuovi run e prepara una diagnosi con video e gerarchia. Nessun push o merge.
```
↩️ Riporta l'esito del collaudo del dossier oppure richiedi esplicitamente una campagna aggiuntiva di riproduzione.

### Approvazione traduzioni (APPROVAZIONI.md)
📍 Apri `.cantiere/APPROVAZIONI.md`.
▶️ Controlla le voci ⏳ S-19/S-28 e S-6/S-7/S-8. Per i testi già tradotti scrivi ✅ o la correzione. I nuovi testi del redesign hanno `[DA COMPLETARE]` dove manca una traduzione fornita: prima vanno completati dal redattore.
📍 Nella chat del capocantiere, incolla:
```text
Assegna al redattore il completamento delle sole traduzioni [DA COMPLETARE] introdotte da S-6, S-7 e S-8 nei Localizable.strings en/de/es/fr/ja/zh-Hans. Le sorgenti italiane e le voci ⏳ sono in APPROVAZIONI.md. Traduci fedelmente i testi forniti senza aggiungere contenuti; preserva esattamente i segnaposto %lld e %@. Non modificare altre chiavi, logica, modelli o viste. Verifica plutil e unicità chiavi x7. Registra le proposte come ⏳ e lasciale alla mia approvazione; dopo le traduzioni serve ricontrollo visivo soprattutto de/XL. Nessun push o merge.
```
↩️ Riporta «traduzioni pronte da approvare» o le correzioni. Per S-19 resta utile la rilettura madrelingua di «Termin» tedesco. S-29 non ha introdotto nuove traduzioni: ha riusato chiavi esistenti.

### S-21 — controllo manuale menu dopo il collaudo — ✅ fatto da Matteo 2026-11-16 21:49: tutto OK
📍 Simulator Xcode, MoneyTracker, scheda Movimenti (dati demo).
▶️ Crea un movimento con ricorrenza Mensile, salva, tieni premuta la sua riga e tocca «Ricorrenza»: deve aprirsi l’editor con «Ambito». Se Simulator è bloccato, chiudilo con ⌘Q e riaprilo da Xcode → Open Developer Tool → Simulator; poi rilancia l’app con ▶︎ in Xcode.
↩️ Riporta «S-21 manuale OK» oppure cosa compare nel menu. Test automatico della stessa pressione prolungata già verde; controllo manuale non disponibile a Codex perché CUA non accede a Simulator.

- [ ] 2026-11-13 · Segnalazione attrezzi (S-5, Codex). 📍 Nella chat «Azienda», incollare:
  ```text
  Nel cantiere MoneyTracker il controllo CUA dell'app Simulator va in timeout. xcodebuild compila (BUILD SUCCEEDED) ma il runner non avvia i test sul simulatore 37445D1E-DEF7-4A32-9A39-EA9EACCA3E48: DTServiceHubClient / com.apple.instruments.deviceservice.lockdown non disponibile. Anche dopo shutdown/boot il problema persiste. Verificare il collegamento tra strumenti Codex e simulatore; non modificare codice o test per aggirare il problema.
  ```
  ↩️ Riportare al collaudatore la risposta o la conferma del ripristino. (Codex)
- [ ] 2026-11-24 · TikTok: cambiare il nome visualizzato da «bucktrailapp» a «Bucktrail · budget» (TikTok lo consente solo dopo 7 giorni dalla creazione; verificato da Matteo). 📍 TikTok → Profilo → Modifica profilo → Nome. ▶️ Scrivi: Bucktrail · budget. ↩️ Scrivi «nome TikTok fatto» (capocantiere)
<!-- - [ ] AAAA-MM-GG · cosa · 📍 dove · ▶️ comando o testo esatto · ↩️ cosa riportare · (chi l'ha chiesto) -->

## Fatte

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

## S-30 — approvazione traduzioni (dopo il collaudo)
- [ ] 📍 In questa chat, dopo il collaudo indipendente, leggere la tabella S-30 in `.cantiere/APPROVAZIONI.md` (it/en/de/es/fr/ja/zh-Hans). ▶️ Rispondere con il testo qui sotto, indicando eventuali correzioni. ↩️ Riportare approvazione o testo corretto per lingua.
```text
S-30: approvo le traduzioni di «Ultima usata» nelle sette lingue.
Oppure: correggere [lingua] in «[testo]».
```
