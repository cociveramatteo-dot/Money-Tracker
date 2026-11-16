# CONSEGNA — S-7p + S-14 [~]

Impresa Codex · GPT-6, 2026-11-16 14:34, ramo `redesign-sentiero`. Nessun push/merge.

## S-7p — plurale dei giorni

Commit `5d59c8d` `[impresa] Gestisce plurale giorni nelle sette lingue (S-7p)`. Sette nuovi `Localizable.stringsdict`; localizzazione runtime di 0/1/2 verificata per tutte le lingue (21 casi), conservando il plurale italiano e gli altri testi plurali. Build, 83 unit e UI Pianifica mirata verdi. Le forme singolari proposte sono in APPROVAZIONI.md con ⏳; nessun `Localizable.strings` modificato in questo task.

## S-14 — confronto mese su mese

Nuova funzione pura `Decimal` in `MoneyTracker/Domain/MonthlySpendingComparison.swift`, con intervalli di uguale durata e confronto corrente/precedente, gestione di baseline vuota/zero, categorie nuove e mesi a metà. La vista calcola una serie una volta per cambio dei dati o del giorno e mostra la card tra Andamento e Per categoria, con totale e righe per categoria, stato testuale e freccia oltre al colore. I calcoli statistici precedenti e `Export/` sono invariati. Nuovi testi e proposta grafica sono in APPROVAZIONI.md con ⏳.

Verifiche: build + 90 unit + 4 UI mirati verdi; il run finale dark ha 90 unit + UI dark verdi, e i rilanci finali UI hanno coperto italiano light, Dynamic Type XL, tedesco e dark. I sette test Domain comprendono periodo precedente vuoto, 0/0, categoria nuova/rimossa, periodo di metà mese con confini inclusi/esclusi, mesi di durata diversa, esclusione di entrate/trasferimenti/non completati e mese futuro. Nessun test preesistente modificato. Esiti: `/tmp/moneytracker-s14-final-dark.xcresult`, `/tmp/moneytracker-s14-evidence-light.xcresult`, `/tmp/moneytracker-s14-evidence-dark.xcresult`.

Screenshot affiancati salvati in `.cantiere/tmp/s14/` (`light.png`, `dark.png`, `xl.png`, `de.png`, `comparison-light-xl-de.png`). Sono stati ispezionati a vista. Il mockup statico non include la card S-14, aggiunta secondo la posizione autorizzata; la card sposta più in basso Per categoria. In tedesco e XL le frasi lunghe vanno a capo su più righe; i testi restano interamente leggibili nelle catture sovrapposte. Percentuali mostrate con massimo tre cifre significative, mentre i valori di calcolo restano Decimal. Il riepilogo statistico preesistente continua a confrontare il mese selezionato con l'intero mese precedente, per non modificarne il calcolo. Nessuna dichiarazione di conformità al mockup: confronto visivo indipendente ancora al collaudatore. Screenshot per ricollaudo disponibili nei percorsi sopra.

Comandi eseguiti: `xcodebuild -scheme MoneyTracker -destination 'platform=iOS Simulator,id=37445D1E-DEF7-4A32-9A39-EA9EACCA3E48' -quiet -parallel-testing-enabled NO -only-testing:MoneyTrackerTests -only-testing:MoneyTrackerUITests/MonthlyComparisonUITests/testItalian -only-testing:MoneyTrackerUITests/MonthlyComparisonUITests/testXL -only-testing:MoneyTrackerUITests/MonthlyComparisonUITests/testGerman build test` e rilancio dark mirato; risultato complessivo dei run indicati: 90 unit + 4 UI mirati verdi. Grafo AST aggiornato ma escluso dai commit.

S-7p e S-14 restano `[~]`, in attesa del collaudo indipendente e dell'approvazione dei testi/grafica. S-6/S-7/S-8 restano `[x]`. Modifiche esterne D-011 in DECISIONI.md e S-30 in PIANO.md sono state preservate nel working tree ma escluse dal commit. Nessun push/merge.

Prossimo: collaudo indipendente S-7p e S-14; approvazione Matteo per le proposte ⏳. Dopo il reset, ripartire da questo file.
