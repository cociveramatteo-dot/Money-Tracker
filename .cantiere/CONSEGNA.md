# CONSEGNA — capocantiere · 2026-11-24 00:52

- Collaudi: `collaudo-android-2026-11-23.md`, `collaudo-ios-2026-11-24.md`. Commissione Suprema: `commissione-suprema-2026-11-24.md` (tutti 10/10, giro 2, commit 045392e).
- S-41 e S-42 chiusi. S-36 resta `[~]`: nessun ramo vecchio è in main; solo `fix/nightly-20260727-0411` ha lavoro utile (tocca Auth/). Gli altri 6 nightly e `tmp-stash-inspect` sono cancellabili: serve l'ok di Matteo.
- Aperto: UI test `testDeleteMonthlyFixedSeriesFromMovementMenuAllScopes` fragile; passaggio di mese S-41 non provato in UI; telefono Android vero; prova sync reale (serve ok e account di prova); release Android usa il Supabase reale (voluto).
- Fuori dal commit: modifiche preesistenti a `AGENTS.md`, `archivio/modello-base/AGENTS.md`, `99_DA_SMISTARE/parita/`.
- Prossimo: checkpoint (docs/MoneyTracker.md, PDF, push) e poi prova sync con Matteo.
