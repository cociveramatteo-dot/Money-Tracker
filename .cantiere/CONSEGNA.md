# CONSEGNA — S-13g UI funzionale

**Da:** seconda impresa (Codex · GPT-6) · 2026-11-14 10:59 · ramo `redesign-sentiero`.
**Stato:** implementato [~], da collaudare. Nessuna modifica a Models, Domain, Sync o test esistenti.

## Fatto
- `AddTransactionView`: ricorrenza solo in creazione, nuova RecurringRule e prima Transaction con UUIDv5/templateId; materializzazione e primo salvataggio insieme, pulizia dei soli inserimenti propri in caso d'errore. Niente nuovi template legacy. Anche gli accessi da altre schermate riconoscono le copie delle nuove serie.
- `RecurrenceControls`: editor nativo con Theme esistente; solo questa / successive / tutte; solo questa espone soltanto nome, importo, note, data nello stesso mese; successive mantiene l'ancora scelta. Frequenza, tipo, categoria, conto e fissa per successive/tutte. Salta mese, termina da qui, termina dopo questa (D-009), elimina con conferma. Copie già fatte preservate da S-13d, avviso visibile.
- `TransactionsView`: serie programmate accanto alle serie rilevate esistenti, importo/frequenza/prossima/stato; virtuali soltanto nei mesi futuri, separati dalle Transaction e dai totali/saldi/filtri importo. Etichetta esplicita di esclusione dai totali. Apertura editor da riga, menu e swipe elimina; rimosso comando legacy di interruzione inefficace.
- Avvii materializer già implementati in S-13c: verificati login e foreground dopo l'await del sync, scenePhase active anche offline/demo, significantTimeChange. Ora gli errori entrano nel RecurrenceOperationStatus osservabile e in un alert con messaggio localizzato, anziché solo log.
- Stringhe nelle 7 lingue, blocchi marcati **DA RIVEDERE DAL REDATTORE** (S-19). Rifinitura grafica separata S-18 per Antigravity.

## Verifiche
- Build + **67 unit verdi**, inclusi due nuovi test di collegamento UI (risoluzione della data originale da UUID deterministico anche con copia spostata indietro; legacy non trattato come regola): `/tmp/moneytracker-s13g.log`.
- Test UI nuovo `RecurrenceFlowUITests`: creazione mensile, modifica tutte, cancellazione tutte **verde**. Build + 67 unit + 1 UI verdi insieme sul codice finale: `/tmp/moneytracker-s13g-final.log`; xcresult `Test-MoneyTracker-2026.11.14_10-58-13-+0100.xcresult`.
- Primi due tentativi UI: nel primo uno swipe sulla tastiera ha aggiunto testo al nome (gerarchia esportata in `/tmp/s13g-ui-attachments`); nel secondo il test selezionava una serie residua del primo tentativo (`/tmp/s13g-ui-attachments-2`). Il terzo è arrivato alla cancellazione ma mancava lo scorrimento al pulsante nel Form; corretto il test. Correzioni limitate al test e a identificatori accessibilità univoci; nessun test esistente indebolito/modificato.
- Sintassi Swift, `git diff --check`, parità nuove chiavi nelle 7 lingue e `plutil -lint` tutti ok.
- Grafo aggiornato AST-only. Avviso noto: 9 JSON senza nodi (configurazioni/Contents), non sorgenti Swift. `graphify-out/2026-11-14/` era già non tracciata all'ingresso; resta fuori dal commit.

## Aperti / limiti
- Collaudo indipendente S-13g e S-13h; confronto grafico light/dark/XL/tedesco da completare in S-18. Nessun nuovo mockup inventato.
- Prova Supabase reale a due dispositivi/due utenti ancora da fare (S-13f resta [~]); i test UI sono offline/demo.
- **S-20 da verificare:** terminare dalla prima occorrenza imposta endDate prima di startDate; il guard `invalidOccurrence` di S-13d sembra impedire ulteriori azioni sulla serie vuota, compreso elimina tutte. Analisi statica, non aggirata nella UI e Domain intatto. Serve diagnosi del collaudatore, poi assegnazione separata se confermato.
- S-15 (due vecchi test UI) e S-16 (Decimal) restano fuori perimetro.

## Prossimo
Collaudatore (Claude Code · Sonnet): leggi il diff del commit S-13g, controlla i flussi e gli avvii/alert, registra il collaudo in PIANO. Approfondisci S-20 senza modificare Domain senza assegnazione. Poi revisione S-19 e prova reale S-13f; la grafica resta S-18.
