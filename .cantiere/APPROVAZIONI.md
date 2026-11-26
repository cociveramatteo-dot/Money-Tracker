# APPROVAZIONI DEL COMMITTENTE

Tutto ciò che il cliente deve vedere e approvare prima di andare online o in consegna.
Stato: ⏳ da inviare · 📨 inviato, in attesa · ✅ approvato · ✏️ da correggere
Si aggiorna, non si cancella: quando cambia lo stato si aggiorna la riga e si annota la data.

| ID | Cosa | Dove (file/sezione) | Chi deve approvare | Stato | Data | Note |
|---|---|---|---|---|---|---|

| S-19 | Revisione traduzioni ricorrenze (23 chiavi, blocco S-13g) in 7 lingue: de «Termin/Reihe», zh «项目/结束/系列», ja «シリーズ», fr «Sauter ce mois» | MoneyTracker/*.lproj/Localizable.strings | Matteo (+ madrelingua de/ja/zh/fr/es se possibile) | ✅ | 2026-11-16 | Approvato da Matteo in chat 2026-11-16 (senza rilettura di madrelingua); termini da far rileggere elencati in CONSEGNA |
| S-18 | Serie programmate: card Sentiero, icona categoria 38×38, nome/importo, frequenza/stato, prossima data. Virtuali: riga Movimenti, icona tratteggiata e importo ambra, data e avviso esclusa dai totali; adattivo light/dark/XL/tedesco | ProgrammedRuleCard.swift | Matteo | ✅ approvato | 2026-11-16 | Proposta approvata in chat prima di implementare; risultato da collaudare |

## S-6 · testi del riferimento · ✅ (13 traduzioni compilate dal redattore, approvate da Matteo 2026-11-16)
Italiano dal mockup: «Andamento», «Per categoria», «PDF». «Netto» riusa la chiave già tradotta. PDF mantenuto come sigla nelle 7 lingue; per gli altri due testi le sei traduzioni non fornite sono `[DA COMPLETARE]`, senza inventarle. Approvazione e completamento Matteo/redattore pendenti.

## S-7 · testi di presentazione · ✅ (idem)
Dal riferimento: «Multi-categoria», «Nessuna scadenza», «Aggiungi progresso», «Progresso complessivo», «Avviso all’80%», «Mancano %lld giorni». «Storico Budget» riusa la chiave esistente. Nuove traduzioni non fornite: `[DA COMPLETARE]` nelle sei lingue; chiavi preesistenti riusate.

## S-8 · testi del riferimento · ✅ (idem)
«Patrimonio totale», «Liquidità», «Risparmio e investimenti», «Sotto la soglia di %@», «Escluso dal totale»: italiano dal sorgente/handoff. Traduzioni nuove non fornite `[DA COMPLETARE]` nelle sei lingue, riusate quelle già esistenti se presenti. «Archiviati» e «A conti fatti» riusano chiavi esistenti.
| S-6/7/8 | 13 traduzioni nuove (Andamento, Per categoria, Multi-categoria, Nessuna scadenza, Aggiungi progresso, Progresso complessivo, Avviso all'80%, Mancano %lld giorni, Patrimonio totale, Liquidità, Risparmio e investimenti, Sotto la soglia di %@, Escluso dal totale) in 6 lingue, proposte dal redattore; dubbi: singolare «1 giorno», «Liquidità»=Cash/現金, de «Sparen & Anlagen»/«Nicht in Summe» | MoneyTracker/*.lproj/Localizable.strings | Matteo | ✅ | 2026-11-16 | Approvate da Matteo in chat 2026-11-16 (dubbio singolare «1 giorno» e madrelingua aperti); compilate al posto dei [DA COMPLETARE]; plutil ok, chiavi allineate |

## S-7p · plurale giorni · ✅ approvato da Matteo 2026-11-16
Forme singolari proposte, derivate dai testi esistenti: it «Manca %lld giorno»; en «%lld day left»; de «Noch %lld Tag»; es «Falta %lld día»; fr «Plus que %lld jour». Plurali e zero conservano i testi già presenti (italiano «Mancano %lld giorni» invariato). ja «残り%lld日» e zh-Hans «还剩%lld天» mantengono una sola forma. Nessun nuovo contenuto, solo accordo grammaticale; approvazione pendente.

## S-14 · confronto mese su mese · ritirate — Matteo 2026-11-16 (S-31)
Approvazioni ritirate: card rimossa su richiesta di Matteo; tabella conservata come storico.

Testi funzionali proposti sui dati reali del confronto, non dati o percentuali fissi. Percentuali assenti quando la base è zero. Nessun termine lasciato ambiguo; tutte le proposte richiedono approvazione. I valori sono nelle sezioni `S-14` dei sette Localizable.strings.

| Sorgente italiana | en | de | es | fr | ja | zh-Hans |
|---|---|---|---|---|---|---|
| Confronto mese su mese | Month-over-month comparison | Monatsvergleich | Comparación mensual | Comparaison mensuelle | 前月との比較 | 月度对比 |
| Giorni 1–%lld · %@ / %@ | Days 1–%lld · %@ / %@ | Tage 1–%lld · %@ / %@ | Días 1–%lld · %@ / %@ | Jours 1–%lld · %@ / %@ | %2$@ / %3$@ · 1～%1$lld日 | %2$@ / %3$@ · 1–%1$lld日 |
| Questo mese hai speso il %@%% in più per %@ | This month you spent %@%% more on %@ | Diesen Monat hast du für %2$@ %1$@%% mehr ausgegeben | Este mes has gastado un %@%% más en %@ | Ce mois-ci, tu as dépensé %@%% de plus pour %@ | 今月の%2$@への支出は、前月の同期間より%1$@%%増えました | 本月%2$@的支出比上月同期增加了%1$@%% |
| Questo mese hai speso il %@%% in meno per %@ | This month you spent %@%% less on %@ | Diesen Monat hast du für %2$@ %1$@%% weniger ausgegeben | Este mes has gastado un %@%% menos en %@ | Ce mois-ci, tu as dépensé %@%% de moins pour %@ | 今月の%2$@への支出は、前月の同期間より%1$@%%減りました | 本月%2$@的支出比上月同期减少了%1$@%% |
| Questo mese hai speso il %@%% in più in totale | In total, you spent %@%% more this month | Diesen Monat hast du insgesamt %@%% mehr ausgegeben | Este mes has gastado un %@%% más en total | Ce mois-ci, tu as dépensé %@%% de plus au total | 今月の支出総額は、前月の同期間より%@%%増えました | 本月总支出比上月同期增加了%@%% |
| Questo mese hai speso il %@%% in meno in totale | In total, you spent %@%% less this month | Diesen Monat hast du insgesamt %@%% weniger ausgegeben | Este mes has gastado un %@%% menos en total | Ce mois-ci, tu as dépensé %@%% de moins au total | 今月の支出総額は、前月の同期間より%@%%減りました | 本月总支出比上月同期减少了%@%% |
| Questo mese hai speso quanto nel periodo precedente per %@ | This month you spent the same on %@ as in the previous period | Diesen Monat hast du für %@ genauso viel ausgegeben wie im vorherigen Zeitraum | Este mes has gastado lo mismo en %@ que en el período anterior | Ce mois-ci, tu as dépensé autant pour %@ que pendant la période précédente | 今月の%@への支出は、前月の同期間と同じです | 本月%@的支出与上月同期相同 |
| Questo mese hai speso quanto nel periodo precedente in totale | This month’s total spending matches the previous period | Deine Gesamtausgaben in diesem Monat entsprechen dem vorherigen Zeitraum | El gasto total de este mes es igual al del período anterior | Les dépenses totales de ce mois sont identiques à celles de la période précédente | 今月の支出総額は、前月の同期間と同じです | 本月总支出与上月同期相同 |
| Questo mese hai speso %@ per %@; nessuna spesa nel periodo precedente | This month you spent %@ on %@; no spending in the previous period | Diesen Monat hast du %1$@ für %2$@ ausgegeben; im vorherigen Zeitraum gab es keine Ausgaben | Este mes has gastado %@ en %@; no hubo gastos en el período anterior | Ce mois-ci, tu as dépensé %@ pour %@ ; aucune dépense pendant la période précédente | 今月の%2$@への支出は%1$@です。前月の同期間の支出はありません | 本月%2$@的支出为%1$@；上月同期没有支出 |
| Questo mese hai speso %@ in totale; nessuna spesa nel periodo precedente | This month you spent %@ in total; no spending in the previous period | Diesen Monat hast du insgesamt %@ ausgegeben; im vorherigen Zeitraum gab es keine Ausgaben | Este mes has gastado %@ en total; no hubo gastos en el período anterior | Ce mois-ci, tu as dépensé %@ au total ; aucune dépense pendant la période précédente | 今月の支出総額は%@です。前月の同期間の支出はありません | 本月总支出为%@；上月同期没有支出 |
| Spesa pari a zero nei due periodi per %@ | Spending on %@ is zero in both periods | Für %@ liegen die Ausgaben in beiden Zeiträumen bei null | El gasto en %@ es cero en ambos períodos | Les dépenses pour %@ sont nulles sur les deux périodes | 両期間とも%@への支出はゼロです | 两个时段的%@支出均为零 |
| Spesa totale pari a zero nei due periodi | Total spending is zero in both periods | Die Gesamtausgaben liegen in beiden Zeiträumen bei null | El gasto total es cero en ambos períodos | Les dépenses totales sont nulles sur les deux périodes | 両期間とも支出総額はゼロです | 两个时段的总支出均为零 |

### S-14 · formulazione percentuali italiana · ritirate — Matteo 2026-11-16 (S-31)
Proposte italiane effettive senza articolo davanti al numero (valide anche per 1% e 8%); le chiavi precedenti restano identificativi del messaggio:
- «Questo mese hai speso di più per %2$@ (+%1$@%%)»
- «Questo mese hai speso di meno per %2$@ (−%1$@%%)»
- «Questo mese hai speso di più in totale (+%@%%)»
- «Questo mese hai speso di meno in totale (−%@%%)»

## S-30 · Categoria dall’ultima volta · ✅ traduzioni approvate da Matteo 2026-11-16
Chiave `· Ultima usata` in `MoneyTracker/*.lproj/Localizable.strings`, approvate da Matteo il 2026-11-16.

| it | en | de | es | fr | ja | zh-Hans | Stato |
|---|---|---|---|---|---|---|---|
| · Ultima usata | · Last used | · Zuletzt verwendet | · Última utilizada | · Dernière utilisée | · 前回使用 | · 上次使用 | ✅ 2026-11-16 |

## SC-3 · Testi social, scheda App Store e landing (IT/EN) · ✅ approvati (testi), bio aggiornate da Matteo
⚠️ 2026-11-19: il formato è cambiato (faceless, SC-7): i testi vanno rivisti prima dell'approvazione. File: `SOCIAL/testi-v1.md` (redattore, 2026-11-17). Bio per TikTok/Instagram/YouTube, caption e hook di F8/F1/F13/F3/F4/F5, scheda App Store IT+EN, testi landing IT+EN. Da decidere/completare: fonte esatta Banca d'Italia; cifre reali per F8 e per l'esempio di F13; titolare e informativa privacy della landing; contatti; conteggi caratteri App Store da ricontrollare nei campi reali; limiti di TikTok su nome/bio; procedura del tocco posteriore per F4; hook F3 «restano sul tuo telefono» escluso finché la sincronizzazione Supabase non è chiarita.
| Stato | ✅ testi approvati e bio aggiornate da Matteo (STATO 2026-11-24); landing approvata 2026-11-20. Scheda App Store: da riesaminare solo prima dell'invio ad Apple (nessun invio senza Matteo) |

## SC-7 · Carosello di presentazione (testi) · ✅ approvato da Matteo 2026-11-19
File: `SOCIAL/caroselli/presentazione-v1.md` (redattore, 2026-11-19). 8 slide, caption TikTok/Instagram, mood musica. Aggiornato 2026-11-19: file riscritto (v2) con titolo «Ogni conto al suo posto. Ogni euro in chiaro.», 9 slide, caption nuove. Grafica approvata da Matteo; mancano «testi ok» e la scelta del suono.
| Stato | ✅ approvato da Matteo il 2026-11-19 («testi ok»): testi e caption del post 1. Resta da scegliere il suono in app. |

- ✅ 2026-11-24 (pubblicato da Matteo su Instagram e TikTok) · SC-7, post 2 F13 · testi e grafica della revisione a 8 slide sulle spese fisse e variabili. Anteprima ed esportazione in Drive, «Da postare/post-2». Caption in `SOCIAL/istruzioni-post/post-2.txt`.

| SC-4c | Landing IT/EN con lancio iPhone e Android e collegamento bancario tra le funzioni dopo il lancio | SOCIAL/landing | Matteo | ✅ | 2026-11-20 | Pubblicazione autorizzata da Matteo e verificata in produzione |
| SC-3c | Bio Instagram e TikTok, descrizione YouTube e chiusura post con iPhone e Android | SOCIAL/testi-v1.md, §1 | Matteo | ✅ | 2026-11-20 | Testi approvati e bio dichiarate aggiornate da Matteo. YouTube Studio verificato |
| S-39 | 44 traduzioni nuove in 6 lingue per stringhe che comparivano in italiano (Login, Registrazione, Impostazioni/Account, Cronologia modifiche, blocco app, «Saldo/Atteso», «Periodo»…); «movimenti» reso come Bewegungen/movimientos/mouvements/取引/交易 per coerenza con l'app; «ELIMINA» invariato perché il codice lo confronta | MoneyTracker/*.lproj/Localizable.strings (blocco «S-39») | Matteo (+ madrelingua de/ja/zh se possibile) | ✅ | 2026-11-24 | Approvate da Matteo in chat 2026-11-24 (senza rilettura di madrelingua); proposte del capocantiere; dubbi: de «Saldo», ja «見込み» per «Atteso», fr «Se déconnecter» |

| 2026-11-26 13:40 | S-50o · schermate Protezione avanzata iOS+Android (incluse `protezione-rimossa-*`) e testi `e2e_*` nelle 7 lingue | ✅ Matteo («approvo») |

## S-50p · Sito: FAQ sicurezza (IT/EN) e informativa privacy con la Protezione avanzata · ✅ Matteo 2026-11-26 18:23 (operaio, 2026-11-26)
File: `SOCIAL/landing/index.html` e `en.html` (FAQ `#sicurezza`, 3° paragrafo sostituito), `SOCIAL/landing/privacy.html` (nuova sezione prima di «Destinatari e trasferimenti», data aggiornata al 26 novembre 2026). Testi del §10.3 S-50p di `.cantiere/progetto-e2e-sync.md`. Nessuna pubblicazione senza ✅.
- **FAQ it:** «Con la Protezione avanzata, facoltativa (Impostazioni → Sicurezza), i dati vengono cifrati sul telefono con una chiave che hai solo tu, prima della sincronizzazione: sul cloud restano illeggibili, anche per noi. Il server vede solo informazioni tecniche, come il tuo account, quante voci hai e quando sincronizzi. Se perdi sia la frase di sicurezza sia la chiave di recupero, i dati sul cloud non si possono recuperare. Senza Protezione avanzata la sincronizzazione non usa la cifratura end-to-end. L’app non contiene pubblicità né tracker.»
- **FAQ en:** «With Advanced Protection, which is optional (Settings → Security), your data is encrypted on your phone with a key only you hold, before it syncs: in the cloud it stays unreadable, even to us. The server only sees technical information, such as your account, how many items you have and when you sync. If you lose both your security phrase and your recovery key, your cloud data can’t be recovered. Without Advanced Protection, sync does not use end-to-end encryption. The app contains no ads and no trackers.»
- **Privacy (solo it: la pagina esiste solo in italiano):** titolo «Sincronizzazione dell’app e Protezione avanzata» · «Se usi l’account facoltativo per sincronizzare i dispositivi e attivi la Protezione avanzata (Impostazioni → Sicurezza), il server conserva i tuoi dati solo cifrati (AES-256-GCM), insieme alle chiavi avvolte, che non si possono usare senza la tua frase di sicurezza o la chiave di recupero, e ai parametri tecnici della cifratura. Restano visibili l’account, gli identificativi, il numero e il tipo dei record, la dimensione approssimativa dei dati, le date di sincronizzazione e l’indirizzo IP da cui sincronizzi. Nessuno, nemmeno il gestore del servizio, può decifrare i dati.»

| Stato | ✅ approvato da Matteo 2026-11-26 18:23 · pubblicato su Cloudflare Pages |

## S-50v · Privacy dell'app (it/en) · ✅ Matteo 2026-11-26 18:23 (redattore, 2026-11-26)
File: `SOCIAL/landing/privacy.html` (riscritta, testo lista d'attesa/sito e Protezione avanzata invariati), `SOCIAL/landing/privacy-en.html` (nuova, traduzione fedele), `SOCIAL/landing/en.html` (2 link «Privacy (Italian)» → `privacy-en.html`). Data: 26 novembre 2026. Chi approva: Matteo. Nessuna pubblicazione senza ✅.
- **Sezioni nuove:** introduzione (app + sito + lista) · L'app senza account (dati solo sul dispositivo, niente pubblicità/statistiche/tracciamento; Face ID, notifiche, esportazione, widget e scorciatoie, demo in locale) · L'account e la sincronizzazione (dati, finalità, base giuridica art. 6.1.b, sicurezza, logout) · Eliminazione dell'account (Impostazioni → Elimina account, cancellazione a cascata dal server, poi dal dispositivo; anche via email) · Supabase tra i destinatari · Conservazione dei dati dell'account · Diritti (aggiunti opposizione, risposta entro un mese, diritti esercitabili dall'app, reclamo anche all'autorità del proprio Paese) · Minori · Modifiche.
- **Promesse nuove:** «rispondiamo entro un mese»; «ti avvisiamo nell'app o via email prima di modifiche sui dati dell'account»; solo in inglese: «in caso di differenze prevale la versione italiana». ✅ approvate da Matteo 2026-11-26.
- **[DA COMPLETARE] risolti con le risposte di Matteo (2026-11-26), segnaposto tolti da entrambi i file:** 1) titolare: solo nome + email · 2) email dell'account inviate dal servizio email predefinito di Supabase · 3) dati ospitati nell'UE (Irlanda, eu-west-1) · 4) accessi extra-UE coperti dalle clausole contrattuali standard del DPA di Supabase · 5) backup: formula neutra («secondo i tempi tecnici del fornitore»), nessun numero di giorni (piano Free) · 6) account inattivi: nessuna cancellazione automatica · 7) età minima 14 anni.
- **Da far rileggere a un madrelingua inglese:** «keep your devices in step», «wrapped keys», «Data controller», «lodge a complaint».

| Stato | ✅ approvato da Matteo 2026-11-26 18:23 · pubblicato su Cloudflare Pages |
