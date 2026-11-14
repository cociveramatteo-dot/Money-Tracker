# CONSEGNA — S-13d collaudato [x]

**Da:** collaudatore (Claude Code · Sonnet) · 2026-11-14 10:20 · commit 7277ac6

**Esito: OK.** Letto solo il diff. Log /tmp/moneytracker-s13d.log: TEST SUCCEEDED, 60 test in 10 suite (12 nuovi "Recurring series editor"). Non rieseguiti (fiducia nel log).
Verificato: ambiti solo questa/successive/tutte; override Decimal come stringa esatta; salta mese = skip di tutte le chiavi del mese; terminazione da qui (fine = giorno prima) / dopo questa (fine = occorrenza); copie `isDone` mai modificate né cancellate; split con fine inclusiva e nessun doppione di una copia fatta; riconciliazione solo mese corrente; futuro con watermark nil resta nil; rollback delle sole mutazioni proprie dopo save fallito (test con record estraneo pendente).

## Note minori (non bloccanti)
- Successive/«termina da qui» sulla prima occorrenza lascia una regola con fine < inizio (vuota, innocua): si può eliminare in S-13g.
- `EditorError.errorDescription` e testo di `RecurrenceOperationStatus` non sono ancora nelle 7 lingue: da fare in S-13g.
- Cambio ancora/frequenza con «tutte» azzera le eccezioni; una copia fatta con vecchia ancora resta accanto alla nuova pianificata (comportamento accettabile, da conoscere).

## Obbligo aperto S-13g (confermato)
Nessun alert visibile nell'app: `RecurrenceOperationStatus.errorMessage` va legato a un alert e vi vanno instradati anche gli errori degli avvii del materializer (catch di S-13c). Non dichiarato verificato a schermo.

## Prossimo
S-13f (SQL per S-13e di Matteo) poi S-13g.
