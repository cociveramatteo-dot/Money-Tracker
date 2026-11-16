# CONSEGNA — S-7p plurale giorni [~]

Impresa Codex · GPT-6, 2026-11-16 12:14, ramo redesign-sentiero. Turno trovato libero alle 12:03. Nessun push/merge.

Sette nuove risorse Localizable.stringsdict, stesso key «Mancano %lld giorni» e formato lld: it/en/de/es/fr distinguono one, other e zero (zero riusa il plurale esistente); ja/zh-Hans hanno soltanto other. La forma italiana plurale è esattamente «Mancano %lld giorni», come prima. Tutti i plurali preesistenti conservati byte per byte nelle nuove forme other; Localizable.strings invariati. Nuove forme singolari da approvare in APPROVAZIONI, ⏳.
PianificaView: solo la chiamata di formattazione usa ora String.localizedStringWithFormat con NSLocalizedString e Int64(days); countdown, budget e tutte le altre funzioni invariati.

Verifiche: build verde senza warning; 83 unit logici (82 esistenti + nuovo DaysRemainingPluralTests) e UI SentieroPlanningUITests/testItalian verdi in `/tmp/moneytracker-days-plural.xcresult`. Il nuovo test carica le risorse effettive dal bundle app e confronta esattamente 0, 1 e 2 per ciascuna lingua: 21 casi, incluso francese zero plurale e ja/zh con forma unica. Plutil sui sette dict e diff-check verdi. Nessun test esistente modificato. Grafo AST aggiornato ed escluso dal commit insieme alle sue modifiche preesistenti.

Comando: `xcodebuild -scheme MoneyTracker -destination 'platform=iOS Simulator,id=37445D1E-DEF7-4A32-9A39-EA9EACCA3E48' -quiet -parallel-testing-enabled NO -only-testing:MoneyTrackerTests -only-testing:MoneyTrackerUITests/SentieroPlanningUITests/testItalian build test` (appearance light).

Prossimo: S-14, stesso incarico Matteo; funzione pura in un solo nuovo file Domain + test, card fra Andamento e Per categoria, niente cambi ai calcoli statistici esistenti/Export, quattro varianti visive. Poi collaudo separato S-7p e S-14 e approvazioni. S-6/S-7/S-8 già [x] restano tali; Commissione S-13h preesistente ancora aperta. Turno libero prima del commit, ripresa automatica S-14 dopo commit se libero.
