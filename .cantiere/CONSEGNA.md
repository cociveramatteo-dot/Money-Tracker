# CONSEGNA — S-19

**Da:** redattore (Claude Code · Sonnet), 2026-11-16. Ramo `redesign-sentiero`. Nessun push/merge.

## Cosa è stato fatto
Revisione delle 23 chiavi del blocco S-13g in 7 Localizable.strings. Chiavi e ordine invariati (nessun placeholder presente nel blocco), codice Swift non toccato. Il marker «DA RIVEDERE» è sostituito da «rivisto dal redattore (S-19)» in tutte le 7 lingue.
- it, en, es: testo confermato (già coerente col lessico esistente).
- de: «Vorkommen» → «Termin» (più naturale); «Serie» → «Reihe» (come «Reihe gelöscht» già presente); «Keines» → «Keine».
- fr: «Ignorer le mois» → «Sauter ce mois».
- ja: «予定された繰り返し» → «予定のシリーズ» (シリーズ come in «シリーズが削除されました»); «次回の予定» → «次回»; «繰り返しに属して…» → «シリーズに属して…».
- zh-Hans: «记录» → «项目» (evita confusione con le transazioni); «终止» → «结束» (uniforme con «结束日期»); «计划系列» → «已计划的系列»; «虚拟记录» → «虚拟».

## Da far rileggere a un madrelingua
de «Termin/Reihe/Umfang», ja «回» e «適用範囲», zh «项目» e «主上下文», fr «Portée». Tono «tu»/«vous» seguito da chiavi esistenti (non verificato riga per riga).

## Limiti dell'esecuzione (importante)
In questo turno non avevo Bash: NON eseguiti `plutil -lint`, `date`, commit, riga in DIARIO.md. Verifica fatta con Grep: 379 righe chiave/valore identiche in es, fr, de, ja, zh-Hans, en; nessun «DA RIVEDERE» residuo. Servono: `plutil -lint` sui 7 file, riga DIARIO con ora vera e commit (`git add MoneyTracker/*.lproj/Localizable.strings .cantiere`, trailer Co-Authored-By).

## Dubbi
«Nessuno» (chiave generica): tradotto senza contesto (de «Keine», es «Ninguno»); verificare dove compare. «contesto principale» è testo tecnico, tradotto alla lettera.
