# CONSEGNA — collaudo S-7p + S-14 (collaudatore, 2026-11-16 14:37)

Esito: S-7p [x] e S-14 [x], collaudo ok sui diff 5d59c8d e 6580f59. Nessuna zona intoccabile toccata, nessun test esistente modificato, un solo file aggiunto in Domain/. Build/test non rilanciati (dichiarati verdi dall'impresa: build + 90 unit + 4 UI).

Verificato: plutil -lint su 14 file ok; stringsdict 0/1/2+ coerenti per le 7 lingue (zero/other in it/en/de/es/fr, solo other in ja/zh), testi "other" identici ai .strings approvati; calcolo Decimal puro con test richiesti; serie in cache con onChange (nel body solo lo snapshot Equatable); card tra Andamento e Per categoria; freccia + testo, DS.danger/ink/smoke/surface/divider; screenshot light/dark/XL/de senza tagli né bordi anomali.
Non verificato: build/test, mockup (card non presente), rendering reale di ja/zh.

Note minori (nessun task): percentuali >=1000% arrotondate a 3 cifre significative; lo snapshot transactions.map gira a ogni body (O(n)), il calcolo pesante no.

Da Matteo: approvare le traduzioni ⏳ in APPROVAZIONI.md (singolari S-7p, 12 chiavi S-14 x 7 lingue, formulazione italiana percentuali).
