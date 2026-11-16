# APPROVAZIONI DEL COMMITTENTE

Tutto ciò che il cliente deve vedere e approvare prima di andare online o in consegna.
Stato: ⏳ da inviare · 📨 inviato, in attesa · ✅ approvato · ✏️ da correggere
Si aggiorna, non si cancella: quando cambia lo stato si aggiorna la riga e si annota la data.

| ID | Cosa | Dove (file/sezione) | Chi deve approvare | Stato | Data | Note |
|---|---|---|---|---|---|---|

| S-19 | Revisione traduzioni ricorrenze (23 chiavi, blocco S-13g) in 7 lingue: de «Termin/Reihe», zh «项目/结束/系列», ja «シリーズ», fr «Sauter ce mois» | MoneyTracker/*.lproj/Localizable.strings | Matteo (+ madrelingua de/ja/zh/fr/es se possibile) | ✅ | 2026-11-16 | Approvato da Matteo in chat 2026-11-16 (senza rilettura di madrelingua); termini da far rileggere elencati in CONSEGNA |
| S-18 | Serie programmate: card Sentiero, icona categoria 38×38, nome/importo, frequenza/stato, prossima data. Virtuali: riga Movimenti, icona tratteggiata e importo ambra, data e avviso esclusa dai totali; adattivo light/dark/XL/tedesco | ProgrammedRuleCard.swift | Matteo | ✅ approvato | 2026-11-16 | Proposta approvata in chat prima di implementare; risultato da collaudare |

## S-6 · testi del riferimento · ⏳
Italiano dal mockup: «Andamento», «Per categoria», «PDF». «Netto» riusa la chiave già tradotta. PDF mantenuto come sigla nelle 7 lingue; per gli altri due testi le sei traduzioni non fornite sono `[DA COMPLETARE]`, senza inventarle. Approvazione e completamento Matteo/redattore pendenti.

## S-7 · testi di presentazione · ⏳
Dal riferimento: «Multi-categoria», «Nessuna scadenza», «Aggiungi progresso», «Progresso complessivo», «Avviso all’80%», «Mancano %lld giorni». «Storico Budget» riusa la chiave esistente. Nuove traduzioni non fornite: `[DA COMPLETARE]` nelle sei lingue; chiavi preesistenti riusate.

## S-8 · testi del riferimento · ⏳
«Patrimonio totale», «Liquidità», «Risparmio e investimenti», «Sotto la soglia di %@», «Escluso dal totale»: italiano dal sorgente/handoff. Traduzioni nuove non fornite `[DA COMPLETARE]` nelle sei lingue, riusate quelle già esistenti se presenti. «Archiviati» e «A conti fatti» riusano chiavi esistenti.
| S-6/7/8 | 13 traduzioni nuove (Andamento, Per categoria, Multi-categoria, Nessuna scadenza, Aggiungi progresso, Progresso complessivo, Avviso all'80%, Mancano %lld giorni, Patrimonio totale, Liquidità, Risparmio e investimenti, Sotto la soglia di %@, Escluso dal totale) in 6 lingue, proposte dal redattore; dubbi: singolare «1 giorno», «Liquidità»=Cash/現金, de «Sparen & Anlagen»/«Nicht in Summe» | MoneyTracker/*.lproj/Localizable.strings | Matteo | ⏳ | 2026-11-16 | Compilate al posto dei [DA COMPLETARE]; plutil ok, chiavi allineate |
