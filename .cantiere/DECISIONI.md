# REGISTRO DELLE DECISIONI

Le decisioni che non si devono ridiscutere ogni volta. Solo aggiunte.

## D-001 · 2026-11-13 · Adozione del modello Cantiere
- **Decisione:** il progetto segue il regolamento in AGENTS.md.
- **Perché:** stessa squadra e stesso metodo in ogni progetto, ripresa del lavoro a basso costo di token.
- **Chi ha deciso:** Matteo

## D-002 · 2026-11-13 · Rimosso il guardiano dei siti web
- **Decisione:** cancellato `.github/workflows/guardiano.yml` (Lighthouse/Playwright).
- **Perché:** è pensato per i siti web, inutile su un'app iOS, e girerebbe a ogni push su `main` e ogni notte consumando minuti GitHub. Un eventuale workflow `xcodebuild test` su runner macOS si valuta più avanti, solo con l'ok di Matteo.
- **Chi ha deciso:** brief del cantiere (Matteo)

## D-003 · 2026-11-13 · `@MainActor` su CurrencyFormattingTests
- **Decisione:** aggiunto `@MainActor` alla struct `CurrencyFormattingTests` (nessuna asserzione cambiata).
- **Perché:** il target app ha `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, quindi `Decimal.parseAmount` è isolato su MainActor e il test target (non isolato) non compilava: i test unitari erano rotti già prima del cantiere. Eccezione puntuale alla regola «test esistenti intoccabili», autorizzata da Matteo.
- **Chi ha deciso:** Matteo

## D-004 · 2026-11-13 · Simulatore di riferimento
- **Decisione:** i test si lanciano su **iPhone 18 Pro, iOS 27.2** (`id=37445D1E-DEF7-4A32-9A39-EA9EACCA3E48`, su questo Mac).
- **Perché:** il runtime iOS 26.5 è stato rimosso; su iOS 27.1 c'era solo «iPhone Duo» e i 12 test UI fallivano (anche sul codice originale `tour-v1`: problema d'ambiente, non del cantiere). Su 27.2 tutto verde.
- **Chi ha deciso:** Matteo / Claude Code

## D-005 · 2026-11-13 · Token «Sentiero» e dark mode (S-1)
- **Decisione:** i token stanno nell'enum `DS` di `Views/Theme.swift`, adattivi con `Color(lightHex:darkHex:)`; **non** si usa `Color(hex:)` di `BucktrailTheme.swift` (colori fissi, cancellerebbe il dark mode). Un solo token per ruolo: i nomi storici restano e cambiano valore: `ink` (testo), `paper` (= `bg`), `fog` (= `border`), `smoke` (= `inkSecondary`), `positive` = alias di `accent`, `negative` = alias di `danger`. Nuovi: `surface`, `divider`, `accent`, `onAccent`, `accentSoft`, `planned`, `plannedText`, `plannedSoft`, `danger`, `dangerSoft`, `transfer`, `hero`, `heroText`, `heroSecondary`, `heroDivider`, `heroAccent`, `heroPlanned`.
- **Valori light:** tabella §2 dell'handoff. **Valori dark:** `bg #0E1210`, `surface #171C19`, testo `#F1F3EF`, `hero #1F2622` come proposto; in più `accent`/`heroAccent` `#5FD19B`, `planned`/`plannedText` `#F2A65A`, `danger #F26B5E`, `transfer #6FA8E0`, `inkSecondary #9AA39D`. **Scarto dall'handoff:** l'handoff teneva accent/planned «invariati» in dark, ma `#1F7A4D` su `#0E1210` ha contrasto ≈3.6:1 (sotto AA per il testo): le varianti schiarite superano 4.5:1 su bg e surface (calcolato). Per lo stesso motivo `onAccent` è quasi-nero in dark (testo su FAB verde chiaro).
- **Effetto visivo:** i nomi storici cambiano valore, quindi l'app prende subito una leggera tinta verde-grigia (paper, fog, smoke, ink); layout e componenti invariati finché non migrano gli step 3–9.
- **Font:** Space Grotesk (Medium, SemiBold, Bold) e Inter 18pt (Regular, Medium, SemiBold), statici, in `MoneyTracker/Resources/Fonts/` + `UIAppFonts` in `Info.plist` + licenze OFL accanto. `DS.Typo` usa `Font.custom(…, relativeTo:)` (Dynamic Type) con ripiego automatico su SF Pro; importi con `.monospacedDigit()`. Originali in `02_RISORSE/originali/font/`.
- **Chi ha deciso:** Claude Code (brief + handoff)

## D-006 · 2026-11-13 · Tinte categoria
- **Regola:** `CategoryTint.tint(for: nome)` (`Views/CategoryTint.swift`): mappa fissa per le 14 categorie predefinite (verde: Salute, Lavoro, Risparmio, Altro; ambra: Cibo, Shopping, Regali; blu: Trasporti, Casa, Viaggi, Giroconto; viola: Svago, Abbonamenti, Istruzione); per le personalizzate hash **FNV-1a 32 bit** del nome in UTF-8 modulo 4 (non `hashValue`, instabile tra avvii). Nessuna modifica al modello SwiftData; varianti dark per ogni tinta. Test in `CategoryTintTests`.
- **Chi ha deciso:** Claude Code (brief)

## D-007 · 2026-11-13 · Serie del saldo per la TrailView
- **Regola:** `Domain/BalanceTrail.swift`, funzione pura `BalanceTrail.make(currentBalance:entries:now:)`, nessuna modifica alle funzioni esistenti. Parte dal saldo attuale e va all'indietro togliendo i movimenti fatti (serie reale, giorno 1 → oggi); la proiezione aggiunge i non fatti in avanti (oggi → fine mese). Pianificati scaduti ancorati a oggi, oltre fine mese all'ultimo giorno, così l'ultimo punto proiettato = «Saldo atteso» (`futureBalance`) sempre, anche con date anomale. Fatti con data futura → oggi, precedenti al mese → giorno 1. Senza pianificati nessuna proiezione.
- **Perché:** coerenza obbligatoria con i saldi di `AccountBalanceCache` senza ricalcolarli a modo nostro. `Decimal` esatto; test in `BalanceTrailTests` (6 casi).
- **Nella vista:** la serie sta in `@State`, ricalcolata con `onChange` su firma (n. movimenti, saldo attuale, saldo atteso, giorno), mai nel `body`. Limite noto: cambiare solo la data di un pianificato senza toccare saldi o conteggio aggiorna la curva alla chiusura della modifica o al rientro nella schermata.
- **Chi ha deciso:** Claude Code (brief)

## D-008 · 2026-11-13 · Nuovo motore delle ricorrenze (serie virtuali) — ok scritto di Matteo
- **Autorizzazione:** Matteo ha autorizzato per iscritto di agire su logica e dati (deroga a «solo visivo» e alle zone intoccabili Domain/, Models/Persistence, Sync/ limitatamente a questo lavoro).
- **Regole decise:** (1) la serie è un solo oggetto (inizio, frequenza mensile/settimanale/annuale, fine opzionale); (2) le occorrenze future sono **virtuali** (solo visualizzazione, mai in saldi, spese, entrate, statistiche); (3) il **primo del mese** tutte le occorrenze di quel mese diventano transazioni vere **pianificate**; (4) saltare **solo questo mese**; (5) disattivare **per sempre** = la serie finisce da quella data, il passato resta; (6) modifica/eliminazione con scelta **solo questa / questa e le successive / tutte**; valido per tutte le frequenze.
- **Dati esistenti:** NESSUNA migrazione automatica delle ricorrenti attuali: le sistema Matteo a mano (lo storico è inattendibile perché il vecchio motore non funzionava). Il nuovo schema non deve alterare né cancellare le transazioni esistenti.
- **Vincoli:** nuova versione schema SwiftData con migrazione leggera che non tocca i dati; Decimal; test nuovi; allineamento Sync/Supabase; Commissione Suprema prima del merge.
- **Alternative scartate:** generazione nel giorno esatto (comportamento attuale); conversione automatica dello storico.
- **Chi ha deciso:** Matteo

## D-009 · 2026-11-14 · Dettagli S-13 (risposte di Matteo, integrano D-008)
- **Via il vecchio motore:** `RecurringTransactionEngine.swift` e `RecurringTransactionEngineTests.swift` si cancellano (conferma di Matteo: deroga alla zona «test esistenti intoccabili», limitata a questo file). Gli altri test restano intoccabili.
- **«Elimina tutte»:** toglie le occorrenze pianificate non ancora fatte; quelle già fatte (isDone) restano sempre.
- **«Disattiva da qui in poi»:** la serie termina da quella occorrenza compresa; se l'occorrenza di oggi è ancora pianificata sparisce, se già fatta resta. Nel menu anche una voce «Termina dopo questa» per l'altro caso.
- **Regola generale:** le copie già fatte non si toccano mai.
- **Fuori da S-13 (Matteo non li vuole):** lista «vecchie ricorrenti da sistemare», ricorrenze sui trasferimenti, card «Prossime scadenze» in Home. Le vecchie ricorrenti le rifà Matteo a mano.
- **Piano tecnico:** architetto (RecurringRule, SchemaV3, UUIDv5 deterministico, materializzazione il primo del mese dal contesto principale, tabella `mt_recurring_rules` su Supabase). Causa individuata: le copie del vecchio motore, salvate su un contesto in background, non risultano «sporche» per il sync e il pull le cancella (`SyncService.swift` ~651).
- **Chi ha deciso:** Matteo

### Nota di esecuzione D-009 · 2026-11-14 02:20 · Codex
- S-13c: eliminati `Domain/RecurringTransactionEngine.swift` e i suoi tre test in `RecurringTransactionEngineTests.swift`, come autorizzato. Nessun dato legacy convertito/cancellato e nessun altro test esistente modificato.
- Dettaglio operativo del limite del piano: massimo **36 mesi più recenti**, incluso quello corrente; il watermark avanza al mese corrente. `nil` è una regola nuova e parte solo dal mese corrente (o dal mese di inizio futuro), evitando storico inventato. Test dedicati verdi.
- Stop esplicito di Matteo durante la suite UI: salvare tutto e riprendere da Claude Code, poi Codex, senza rifare l'implementazione. Nessun merge/push e nessuna dichiarazione di collaudo completo.

## D-010 · 2026-11-15 · Campi ricorrenti uniformi per scope (S-25, sostituisce S-23 e parte di D-009)
- **Chi decide:** Matteo: autorizzazione esplicita a modificare Domain per S-24/S-25; autorizzati anche i test S-15 per ottenere suite UI verde senza cambiare comportamento dell'app.
- **Editor normale:** modifica tutti i campi della serie, passato/futuro e copie effettuate comprese, tramite lo stesso RecurringSeriesEditor con scope Tutte. Frequenza/fine restano fuori dall'editor normale.
- **Scope:** Solo questa memorizza tutti i campi editabili nel codec dell'eccezione, incluso il conto esplicitamente vuoto; successive aggiorna dalla data originale selezionata e ricollega le copie alla nuova serie; Tutte aggiorna tutte le copie esistenti e la regola dei virtuali futuri.
- **Già effettuato:** Matteo ha precisato che resta uno stato della singola copia. Non viene propagato dal motore; l'editor normale può ancora modificarlo sulla sola copia scelta.
- **Override precedenti:** Tutte sostituisce gli override di valori e date con i valori salvati per la serie. I salti espliciti restano saltati se la cadenza non cambia; con nuova cadenza si applica il reset già previsto dal motore. Nessuna copia viene creata per inventare lo storico mancante.
- **Cambio date/frequenza:** le copie esistenti in scope seguono la stessa posizione nella nuova cadenza (giorno limitato all'ultimo del mese nei mesi corti), con ID deterministici riallineati per evitare duplicati. La materializzazione resta pianificata per le nuove copie.
- **Eliminazione:** invariata la protezione delle copie effettuate e dei dati legacy. Da qui in poi confronta il giorno originale dell'occorrenza, non il timestamp (che escludeva erroneamente il mattino) né la data eventualmente spostata.
- **Alternative scartate:** duplicare il motore nelle viste; lasciare eccezioni di valori che contraddicono Tutte; propagare lo stato effettuato e alterare i saldi delle altre copie senza volontà di Matteo.

## 2026-11-16 · Riferimenti S-6/S-7/S-8 (Matteo)
Autorizzata lettura diretta del sorgente HTML inline dei mockup, comprese le strutture ripetute sc-for/hint-placeholder-count, senza rendering/support.js. DESIGN_HANDOFF §4 prevale in caso di conflitto. PNG originali assenti: confrontare screenshot simulatore light/dark/XL/de con misure, token e struttura del sorgente; dichiarare differenze residue, senza dichiarare conformità. Confronto visivo definitivo al collaudatore. Nessun push/merge.

## D-011 · 2026-11-16 · Categoria dall'ultima volta (S-30)
- **Chi decide:** Matteo. **Cosa:** per nomi senza categoria dalle parole chiave, si propone la categoria dell'ultimo movimento con lo stesso nome; preselezionata come oggi; etichetta «Ultima usata»; vince sempre l'ultima scelta.
- **Quando:** solo dopo la chiusura del restyling (S-14, S-10, checkpoint, merge): Matteo avvia il lavoro.
- **Perché:** impara dalle abitudini, copre i nomi che l'elenco fisso non conosce, nessuna migrazione o sync (si usa la cronologia).
- **Alternative scartate:** tabella nome→categoria da sincronizzare (più parti in movimento); categoria più frequente (meno semplice, non coincide con la richiesta); somiglianza approssimata dei nomi (suggerimenti sbagliati).

## D-012 · 2026-11-16 · Rimozione confronto mese su mese (S-31)
- **Chi decide:** Matteo. **Cosa:** rimozione completa della card S-14 da Statistiche, del calcolo dedicato, dei relativi test e delle sole 12 chiavi esclusive nelle sette lingue.
- **Perché:** non gradito a Matteo. Il resto dell'app è confermato e resta invariato.
- **Alternative scartate:** nasconderla senza cancellare il codice.
- **Vincoli:** ramo rimuovi-confronto-mese; nessun push o merge. Medie, grafici, 6M/12M, confronto annuale, PDF/Export e plurale giorni S-7p invariati.

## D-013 · 2026-11-17 · Changelog con versioni vere, S-13 rilascio a sé
- **Chi decide:** Matteo. **Cosa:** il changelog del libro passa da «v3.x» a versioni numerate (3.1, 3.2…), una per blocco di lavoro coerente; il motore ricorrenze a serie virtuali (S-13, cambio di schema/sync/modello) è un rilascio a sé.
- **Perché:** il libro diventa un vero libro di bordo dei rilasci; S-13 tocca la zona protetta e merita una voce di versione chiara.
- **Alternative scartate:** lasciare «v3.x» ovunque.

## D-014 · 2026-11-17 · Funzioni nuove: prima mockup approvato, poi codice
- **Chi decide:** Matteo (ok «ci può stare»). **Cosa:** per ogni funzione nuova (non restyling) si presenta prima un mockup/descrizione a Matteo; il codice parte solo dopo l'approvazione.
- **Perché:** S-14 (confronto mese su mese) è stato costruito con 7 lingue e test e rimosso il giorno dopo da S-31: lavoro buttato.
- **Alternative scartate:** codice subito e verifica a posteriori.

## 2026-11-17 · Social prima di Apple Developer Program
- **Cosa:** si parte coi social senza pagare l'Apple Developer Program; il pagamento dipende da un segnale di interesse nelle prime settimane.
- **Perché:** Matteo non vuole spendere prima di sapere se c'è interesse.
- **Conseguenze:** niente pre-order né campaign link Apple: i link in bio vanno a una landing con email (fallback del manuale §10.1), misurata con UTM. Il lancio del 12/01/2027 regge solo se si paga entro circa metà dicembre (build, App Review, pre-order: manuale §15, giorni 9-15); oltre, il lancio slitta. Soglia del «segnale» da definire (SC-1b).
- **Alternative scartate:** pagare subito (rischio di spesa a vuoto).

## 2026-11-17 · Regola permanente del progetto SOCIAL
- **Cosa:** per tutto il lavoro social (testi, format, montaggio, calendario, pubblicazione, metriche, rischi legali) si seguono sempre le direttive di `SOCIAL/Bucktrail_Manuale_Strategico_v2.pdf`: claim ammessi/vietati (§1), format F1–F13 (§6), produzione (§7), pubblicazione (§8), metriche (§9), legale (§12). Conflitti: vince il manuale; le deviazioni si scrivono qui con il motivo.
- **Perché:** sono le fonti che Matteo considera importanti; il manuale distingue fatti verificati da opinioni.
- **Deviazioni decise finora:** niente pagamento Apple prima del gate (vedi sotto); inizio anticipato al 18/11; link in bio = landing con email.

## 2026-11-17 · Soglie del segnale di interesse (✅ CONFERMATE da Matteo il 2026-11-17, cifre comprese: 40 iscritti, 200 visite, 5%, 5 commenti — non si spostano più) — SC-1b
Il manuale non dà benchmark (§9.5, §15.4): le soglie sono relative ai dati di Matteo e di processo. Quindi sono mie **inferenze** costruite su §9.5, §9.3, §15.4. Gate: **dom 06/12/2026** (≈17 giorni di pubblicazione, ≥10 video per piattaforma).
**Segnali che contano** (dal più forte): 1) iscrizioni alla landing con email; 2) commenti/DM «quando esce? dov'è il link?»; 3) invii (DM) e salvataggi su Reels/caroselli; 4) tempo medio e completamento sopra la mediana dei propri ultimi 10 video; 5) click bio → landing. Le view da sole non contano (§9 intro). Un video virale isolato non basta: il caso dumbphone mostra risultati asimmetrici (13% dei video oltre 50× la media).
**Verde (si paga):** almeno 3 su 4: (a) ≥1 format sopra la mediana in 2 varianti su 3 (§15.4 punto 2); (b) landing: iscritti [DA COMPLETARE: proposta 40 organici] e conversione visita→email almeno ~5% con ≥200 visite [proposta, INFERENZA]; (c) ≥5 commenti o DM che chiedono link/uscita; (d) trend crescente di invii/salvataggi settimana su settimana. Nota: un solo iscritto o poche view = non è un segnale.
**Giallo (una settimana in più):** 1–2 criteri su 4, o tutti ma con dati troppo pochi (<10 video).
**Rosso (stop o cambio angolo):** 0 criteri dopo 10+ video, con format già variati (3 angoli per argomento, §9.6).
Le cifre 40, 200, 5%, 5 commenti sono mie stime di ordine di grandezza (non fonti): Matteo le conferma o le cambia prima del 22/11, poi non si spostano.

## 2026-11-17 · Nome utente dei profili social: @bucktrailapp
- **Cosa:** `@bucktrailapp` su Instagram, TikTok e YouTube; email dedicata `bucktrailapp@gmail.com` (da creare). Nome visualizzato: «Bucktrail · budget senza abbonamento».
- **Perché:** `@bucktrail` era occupato su Instagram e TikTok (libero solo su YouTube); `@bucktrailapp` è libero su tutte e tre. Deviazione dal manuale §8.4, che consigliava `@bucktrail`: lo stesso nome ovunque resta l'obiettivo.
- **Da fare:** `testi-v1.md` e la landing citano `@bucktrail`: sostituire con `@bucktrailapp`. Capire chi occupa `@bucktrail` (rischio di confusione di marchio).

## 2026-11-17 · TikTok: account personale, senza musica
- **Cosa:** `@bucktrailapp` resta account personale; la voce «Passa all'account Business» non compare per Matteo e «verified business» richiede un'impresa registrata che non c'è. Nei primi video nessuna musica (solo voce ed effetti).
- **Perché:** manuale §4.6/§7.7 (master senza musica, Commercial Sounds solo per Business). Non verificato come TikTok gestisca oggi i profili commerciali.
- **Da rivedere:** quando c'è l'app sullo Store/un'impresa o se la voce Business riappare. Punto fiscale (partita IVA/regime) da chiarire prima di pagare Apple.

- **Promemoria 2026-11-24:** nome visualizzato TikTok da cambiare in «Bucktrail · budget» (cambio consentito dopo 7 giorni). Vedi PER-MATTEO.md.

## 2026-11-17 · Nessun premium in abbonamento
- **Cosa:** Matteo esclude il premium opzionale a €1,99/mese citato nel manuale §1.1. L'app resta a pagamento una tantum (€4,99, prezzo di lancio previsto), senza abbonamento.
- **Perché:** coerenza del messaggio «paghi una volta, le altre ogni mese» (F2, F12) e fiducia.
- **Effetto sui testi:** «senza abbonamento» e «4,99 € una volta» sono ora promesse pienamente coerenti; restano vietate le promesse su sincronizzazione/cloud («mai cloud»), che sono un'altra cosa (§1.3). Il manuale §1.1 su questo punto è superato.

## 2026-11-17 · Social senza elementi personali; video in IA in valutazione
- **Cosa:** niente volto, voce, nome, «studente», «di Parma», storie personali in testi e video. Il brand parla come «Bucktrail». Deroga alla scelta del manuale §4.4/F8 (build in public personale). F8 diventa un video di brand a solo testo; F9 solo come esempio dichiarato (manuale §12.4). Task SC-3b al redattore.
- **Video interamente con IA:** richiesta di Matteo, parere del capocantiere in chat. Il manuale (§4.7) consiglia l'IA solo per test sugli hook, sempre etichettata; schermo reale dell'app e curva restano reali. Decisione in attesa.

## 2026-11-18 · Landing online: dominio, hosting, lista d'attesa (SC-4)
- **Cosa:** dominio `bucktrailapp.com` comprato su Aruba (1,83 € il primo anno, rinnovo da verificare, scade circa 18/11/2027) con DNS su Cloudflare; landing su Cloudflare Pages (progetto `bucktrailapp`, caricamento manuale della cartella `SOCIAL/landing`); form della lista d'attesa → `_worker.js` → Brevo (lista «Bucktrail lancio», ID 3) con double opt-in (modello ID 1, tag `optin`); notifica a `bucktrailapp@gmail.com` a ogni iscrizione; mittente `ciao@bucktrailapp.com` (inoltro Cloudflare Email Routing → Gmail).
- **Perché:** tutto gratuito tranne il dominio, fornitori UE/USA con garanzie GDPR, nessun cookie, nessun codice lato app.
- **Privacy:** titolare Matteo Cocivera come persona fisica (obbligo di legge: il nome compare solo nell'informativa, non nei contenuti social, quindi nessuna deroga alla regola «social senza elementi personali»). Conservazione proposta: fino al lancio + 30 giorni. **[APPROVATA da Matteo il 2026-11-18]**
- **Alternative scartate:** hosting Aruba (inutile per un sito statico), Google Forms/servizi USA per le email (privacy più delicata), form senza conferma (meno prova di consenso).
- **Da ricordare:** la chiave API Brevo scade il 18/11/2027 e dopo 90 giorni senza uso; il mittente `bucktrailapp@gmail.com` in Brevo non è autenticabile e non va usato per inviare.

## 2026-11-19 · Formato dei contenuti social: «faceless», mani + telefono, caroselli puliti (Matteo)
- **Cosa:** si copia il formato di @easlonotes (TikTok). Mai voce né volto: al massimo le mani di Matteo che tengono l'iPhone con l'app; titolo grande in sovrimpressione (hook: POV, «How to…», «Beginners vs Pros», serie pt.1/pt.2); caroselli «foto» su sfondo bianco con mockup iPhone + frase corta, prima slide titolo, ultima «Follow for more!» col logo; audio = musica/suoni di tendenza di TikTok. Stile pulito e semplice come l'app. Dettagli: memoria `project-social-formato-faceless`.
- **Perché:** Matteo non vuole usare voce/volto; il formato è dimostrato (28K–82K view con 12K follower) e si produce con screen e foto delle mani.
- **Effetto sul manuale:** cambia il FORMATO (F8 «Giorno 1» a voce e ogni parlato decadono, cfr. deroga 2026-11-17); restano validi strategia, claim vietati §1.3, gate 06/12, soglie, diario metriche.
- **Da verificare:** la decisione 2026-11-17 «niente musica» valeva per l'account Business; con l'account personale la libreria musicale TikTok è disponibile (da controllare in app). Prima di passare a Business il 24/11 considerare che lì le musiche di tendenza sono limitate.
- **Procedura:** per ogni contenuto il capocantiere dice a Matteo cosa serve (video schermo, screenshot, foto/video delle mani); poi testi (redattore) e montaggio (script `SOCIAL/montaggio`, caroselli in `SOCIAL/caroselli`).

- **Regola 2026-11-19 (Matteo):** negli screenshot e nelle registrazioni dell'app per i social si toglie SEMPRE la scritta «modalità demo» prima di usarli (montaggio: ritaglio/copertura, controllo finale; se non pulito, si rifà lo screen).

## 2026-11-19 · Messaggio di brand dei social (Matteo)
- **Cosa:** i cinque temi (design pulito e professionale; tanta complessità ben divisa; c'è tutto in un'app sola; senza abbonamento; basta Excel e basta pagare altri servizi/IA) vanno in tutti i contenuti. Testo completo in `.cantiere/REGOLE-PROGETTO.md`, sezione «Messaggio di brand dei social».
- **Da verificare prima di dirlo:** la parte «soldi dati alle IA» (cosa si intende e se è vera: l'app sincronizza con Supabase). Finché non è chiaro non è una promessa pubblica.
- **Frase del titolo (prima slide):** in scelta. Opzione consigliata «Basta Excel. Basta abbonamenti. Un'app sola.» sotto «Conti, movimenti, budget, obiettivi e statistiche.»

## 2026-11-20 · Direttive e calendario social
- Matteo richiede controllo visivo di tutti i post precedenti a ogni nuovo post, tre rubriche alternate, approvazione singola e una cartella permanente per le schermate.
- Il riferimento operativo corrente è `SOCIAL/direttive-social.md`; sostituisce la gerarchia social del 17/11. Il PDF strategico resta la fonte per format, spunti, metriche e cautele. Il calendario conserva lo storico e tiene separate le 36 proposte.
- La simulazione parte il 23/11 solo per rendere concreto l’ordine. Date, orari, proposte di doppio slot e contenuti aspettano Matteo. Le catture restano locali fuori da Git.

## 2026-11-20 · Una spesa fissa singola entra nella previsione Home nel suo mese (S-41)
- Richiesta di Matteo: una spesa fissa già nota (es. tasse universitarie), pianificata con data e importo, partecipa alla previsione mensile solo nel mese della data, senza generare una serie.
- Il filtro è applicato insieme alla curva, al saldo atteso e alle carte conti in Home. Una spesa effettuata partecipa al saldo reale secondo la regola esistente. La tab Conti continua a mostrare «A conti fatti», previsione complessiva.

## 2026-11-20 · Lancio mobile e collegamento bancario sulla landing
- iPhone e Android fanno parte del lancio previsto. Lo stesso profilo è previsto per ritrovare i dati sulle due piattaforme.
- Il collegamento bancario arriva dopo il lancio. È facoltativo conto per conto, importa i movimenti dalle banche supportate e chiede conferma quando rileva un possibile doppione manuale. La versione web è fuori dalla comunicazione corrente.
- SC-4c è circoscritto alla landing e alla conferma della lista d’attesa, in italiano e inglese.

## 2026-11-23 · Android parità: fondamenta (B0) e dati (B1)
- **Anomalie iOS §4.99:** su Android non si replicano; vale il comportamento coerente. Già applicati: raggruppamento Movimenti per data (non per stringa «d MMM», #5), filtro tipo Movimenti coerente (#1). Le altre si applicano nei blocchi che toccano quelle schermate.
- **Font form:** Inter variabile (OFL, `inter_variable.ttf`) al posto di SF Pro per sheet e form.
- **Importi:** `BigDecimal` nel dominio, centesimi `Long` nelle colonne Room, arrotondamento HALF_UP a 2 decimali come iOS.
- **Migrazione Room 2→3:** ricrea le tabelle (FK RESTRICT→CASCADE); le voci con giorno futuro e `planned=false` diventano `isDone=false`; categoria «Altro»/`tray.fill`. Provata su emulatore con un database v2 reale.
- **Movimento con data futura:** il form propone «Pianificato» attivo (`isDone=false`) ma l'utente può cambiarlo; pianificato ⇔ `!isDone`.
- **Stringhe:** `scripts/ios-strings-to-android.py` genera `values*/strings.xml` dai cataloghi iOS; le stringhe solo-Android stanno in `scripts/android-extra-strings.json`.
- **Supabase:** nessuna sync sul progetto reale di Matteo prima del blocco B9 e del suo ok.
