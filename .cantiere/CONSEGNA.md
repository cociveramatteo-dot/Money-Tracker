# CONSEGNA — capocantiere · 2026-11-24 13:12

- **S-38 [~]** commit 49088bf (Domain toccato solo in `RecurringSeriesDetector` e `RecurringMaterializer`, su richiesta esplicita di Matteo). **S-40 [~]** commit 2b88670. **S-39 [~]** traduzioni in `*.lproj` + riga ⏳ in APPROVAZIONI.
- Verifica: build ok, 94/94 unit, UI mirati ricorrenze/transazioni 13/13, suite UI completa 45/48. I 3 rossi sono `SentieroReviewFixUITests` (S-43): falliscono identici anche su a4131c2, quindi non sono causati da questi lavori.
- Da collaudare: S-38, S-39, S-40 (controllo visivo con testo XL/accessibilità e tedesco; i layout con cornici fisse possono tagliarsi).
- Matteo: approvare le traduzioni S-39; il resto in `PER-MATTEO.md`.
- Prossimo: collaudatore su S-38/S-39/S-40; poi S-43 (Codex).
