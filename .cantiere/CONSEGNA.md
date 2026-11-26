# CONSEGNA — 2026-11-26 15:24 · seconda impresa (Codex · GPT-6)

- **S-50q.4 [~] · `c5a0416`.** Pulizia delle chiavi obsolete condivisa tra A4, pull vault riuscita e D7 su iOS e Android. Ogni DELETE aggiuntiva è vincolata a ID, utente, tipo e `key_id=eq.<chiave morta>`. I nuovi test coprono DELETE fallita in A4, pull fallita, retry riuscito al pull o in D7 e conservazione dei dati vivi.
- **S-50s [~] · `39db954`.** Operazioni E2E in `SyncService+E2E.swift`, proprietà salvate nella classe. L’accesso ai membri condivisi è interno al modulo. `UploadMode` mantiene le modalità incrementale, preflight e copia completa, con le opzioni di pulizia già in uso.
- **S-50t [~].** Su `Bucktrail_API_36`, con Java 17, `connectedDebugAndroidTest` filtrato su `E2EKeyStoreInstrumentedTest`. Passati 3/3 casi: isolamento e chiave non esportabile, recupero da chiave corrotta e PATCH HTTP limitata alla riga richiesta. Emulatore spento al termine.

**Verifiche.** iOS, build, 186 unitari e 8 UI E2E verdi per entrambi i task, inclusa la verifica con interruttore spento. Android, `assembleDebug`, 323 test JVM e `lintDebug` verdi per S-50q.4. Nei primi giri, il doppio iOS contava anche la proiezione dei metadati come lettura cifrata e il conteggio Android includeva il controllo della chiave in un percorso senza snapshot completo. I giri successivi sono verdi. Nel refactor, il test sul preflight ha rilevato la selezione dei movimenti da correggere e passa nella suite finale.

**Stato.** Tre commit su `redesign-sentiero`. Interruttori E2E spenti in release. I due file di test aggiunti coprono il retry. Grafo del codice aggiornato.

**Prossimo.** Il capocantiere passa al collaudatore il diff di S-50q.4, S-50s e l’esito di S-50t.
