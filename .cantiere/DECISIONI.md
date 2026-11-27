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

## 2026-11-23 · Android parità: Home, Ricorrenze, Pianifica (B4–B6)
- **Ricorrenze:** editor e materializzazione sono funzioni pure (`RecurringOps`) che restituiscono le modifiche; Room le applica in un'unica transazione (se fallisce non cambia nulla, come il rollback iOS). Eliminare una copia di serie da Movimenti apre l'editor (come iOS); l'eliminazione dall'editor offre «Annulla».
- **Obiettivo creato già completo:** `isCompleted = current ≥ target` anche alla creazione (iOS lo calcola solo alla modifica, anomalia #3 §4.99 non replicata).
- **Menu a tendina e tab bar:** menu Material con colori/raggio Sentiero; etichette tab con riduzione fino al 50% a font grandi (iOS `minimumScaleFactor`).
- **Notifiche budget/soglia dopo il salvataggio:** non ancora (blocco B8).

## 2026-11-23 · Android parità: Statistiche, Export, Notifiche, blocco, audit, demo (B7–B8)
- **Nome mostrato su Android:** «Bucktrail» ovunque (PDF, blocco app, avvisi, canale notifiche), non «MoneyTracker» come iOS (anomalia #17 §4.99). Resta da decidere con Matteo per iOS.
- **PDF con la valuta scelta** nelle Impostazioni, non quella di sistema (anomalia #4 non replicata); categorie del PDF localizzate. Impaginazione pura (`PdfReport`) con le misure di `PDFReportGenerator`; stampa su `PdfDocument`.
- **Condivisione:** i file CSV/JSON/PDF passano da `FileProvider` nella cache privata (Android non può condividere dati solo in memoria come `ShareLink`); la cartella si svuota alla chiusura delle Impostazioni.
- **Avvisi programmati con `AlarmManager.setAndAllowWhileIdle`** (inesatto, nessun permesso di sveglie esatte): per promemoria al 1° del mese e −7 giorni va bene; ripianificati all'avvio, dopo il riavvio e dopo l'aggiornamento dell'app. In demo non si programma nulla. Budget (2 s) e soglia saldo (1 s) partono in-process come iOS.
- **Permesso notifiche:** richiesto al primo avvio (preferenza assente) e attivando «Avvisi automatici». Se negato il toggle resta spento (iOS lo lascia acceso: anomalia non replicata) e compare una riga di spiegazione.
- **Cronologia modifiche:** invece di agganciare ogni salvataggio, `AuditTracker` confronta le istantanee reattive dei dati reali (equivale alla notifica di salvataggio iOS): copre anche materializzazione ricorrenze e import futuri. File `audit-log.jsonl` append-only; mai attivo in demo; cambio database = nuova base di confronto.
- **Modalità demo:** secondo database Room (`bucktrail-demo.db`), nessun riavvio: `Repository.switchTo` cambia il database attivo e tutta la UI segue. Semina `DemoData` (v6) solo se vuoto o con versione inferiore. L'obiettivo «Corso di fotografia» è completato (come la decisione B6).
- **Blocco app:** `BiometricPrompt` con biometria debole o PIN/schema/password del dispositivo; il velo è anche una finestra sopra i fogli aperti (iOS lo copre per costruzione, qui i `Dialog` sono finestre separate). `MainActivity` ora estende `FragmentActivity` (richiesto da BiometricPrompt, fragment 1.8.9 per evitare il crash del codice richiesta permessi).
- **Spazio in fondo alle schermate:** `Dim.listBottomPadding + Dim.tabBarReserved` (100 + 94) su tutte le schermate a scorrimento: prima l'ultima riga restava sotto la tab bar.

## 2026-11-23 · Android parità: Account, sync Supabase, scorciatoie e widget (B9–B10)
- **Account facoltativo su Android:** iOS non entra senza login; Android resta pienamente locale e offline come prima (richiesta di Matteo). «Accedi o crea un account» sta in Impostazioni → Account; le schermate Login/Registrazione sono quelle di iOS (dimensioni, testi, errori) in una pagina a tutto schermo con «Chiudi». Con account attivo compaiono banner sync e pull-to-refresh.
- **Nessuna libreria Supabase:** client HTTP minimo (`HttpURLConnection` + kotlinx-serialization) per GoTrue e PostgREST, interfaccia `SupabaseApi`; così il sync si prova con un finto server (JDK `ServerSocket`, `FakeSupabase` in memoria) e `scripts/fake-supabase.py` per l'emulatore. Sessione cifrata con chiave AES-GCM dell'Android Keystore (equivale al Keychain). URL e chiave anon si leggono al build da `MoneyTracker/Auth/SupabaseConfig.swift` (BuildConfig, mai nel repository né nei documenti); `-PsupabaseUrl/-PsupabaseKey` puntano a un server finto.
- **Sicurezza del sync (più severa di iOS):** (1) nessun push finché non c'è un primo scambio riuscito per quell'utente (`syncedUserId`); (2) mai ripiegare sul push se la lettura del cloud fallisce; (3) il pull non cancella nulla se il remoto è senza conti ma il locale no; (4) tutto il pull in un'unica transazione Room; (5) push dei movimenti: «sporchi» + quelli che il cloud non ha (una marcatura persa non fa mai cancellare un movimento al pull); (6) le marcature portano un istante: una modifica fatta durante un push resta in coda; (7) sessione ripresa: prima push poi pull; (8) letture paginate.
- **Dati creati senza account + cloud già pieno:** scelta esplicita «Usa i dati del cloud» (sostituisce il dispositivo) o «Annulla» (esce dall'account, nulla cambia). Alternativa scartata: fondere i due insiemi (iOS non ha merge, rischio duplicati).
- **Dirty tracking:** `ChangeWatcher` confronta le istantanee reattive (come l'audit); le scritture del sync stesso sono «silenziose». Scritture fuori dalle schermate (scorciatoie): push immediato (max 5 s) prima che il sistema congeli il processo.
- **Eliminazione account:** RPC `delete_own_account` (codice SQL non nel repository: da verificare con la prova reale).
- **B10 extra Android:** `QuickAddActivity` e `BalanceActivity` con la stessa logica degli App Intent (`QuickAdd`), scorciatoie dell'icona, widget Glance «Saldo» (importi oscurati se «oscura importi» o blocco app), riquadro Impostazioni rapide, link `bucktrail://add|balance|home` (precompilano, non salvano da soli). App Actions Google rinviate (servono Google Play). Il doppio tocco sul retro iOS non ha equivalente: nei testi si indica la «Tocco rapido» dei Pixel.

## 2026-11-24 · Checkpoint in autonomia: scelte del capocantiere (delega di Matteo)
- **S-40, font scalabili:** `.scaledFont(size:weight:)` (modificatore con `@ScaledMetric`) al posto dei 239 `.font(.system(size:))`. Alternativa scartata: mappare tutto su `DS.Typo.*`, perché Inter e Space Grotesk avrebbero cambiato l'aspetto di icone e numeri decorativi; il restyling dev'essere solo visivo.
- **S-38 e Domain:** toccati solo `RecurringSeriesDetector` (force-unwrap) e `RecurringMaterializer` (snapshot unico), senza cambiare il comportamento. Autorizzato da Matteo con «tutto quello che puoi fare».
- **S-41, mese di competenza:** la condizione è estratta in `DashboardView.countsInProjection` (pura, testata) e la data di riferimento si aggiorna anche a mezzanotte. Alternativa scartata: spostarla in `Domain/`, per non allargare la zona protetta.
- **Dialogo di conferma «Salta mese/Termina…»:** `confirmationDialog` ancorato; in questa versione di iOS compare come popover senza «Annulla» (si annulla toccando fuori). Accettato: stesso comportamento degli altri dialoghi dell'app.
- **S-43:** corretta l'asserzione del test perché superata dal progetto (la lista scorre sotto la barra per scelta), non indebolita: ora verifica la posizione dell'ultimo testo.
- **Guardiano notturno:** puntato sulla landing (`SOCIAL/landing`), l'unico sito del progetto: prima guardava `03_CODICE`, senza pagine, e restava rosso («pagina irraggiungibile ×11»). Le voci «lingue 64» della pagella derivano dai nomi piatti della landing (`en.html` accanto a `index.html`) contro la convenzione a cartelle dello strumento: non è un difetto della landing online.
- **S-33:** chiuso in osservazione (test verde in tutti i giri di oggi).

## 2026-11-24 · S-50 Protezione avanzata (E2E della sync): progetto esecutivo (architetto)
Progetto completo: `.cantiere/progetto-e2e-sync.md`. Autorizzazione di Matteo a toccare Sync/ e Auth/ solo per S-50 (riferita dal capocantiere).
- **Dove sta il cifrato:** tabella nuova `mt_vault` (id, user_id, kind, payload) + `mt_e2e` (chiavi avvolte, stato). Scartate: cifrato nelle colonne esistenti di `mt_*` (un client vecchio lo sovrascriverebbe o rimetterebbe i dati in chiaro) e colonna aggiuntiva (stesso problema).
- **Unica modifica SQL, additiva e idempotente:** 2 tabelle + RLS proprie + trigger `mt_e2e_guard` sulle 5 tabelle `mt_*` che rifiuta le scritture in chiaro (`bt_e2e_active`, HTTP 400) quando la protezione è attiva. Scartate: nessuna modifica SQL (impossibile fermare i client vecchi), policy RLS restrittiva (HTTP 403 = Android vecchio rinnova il token a ogni tentativo).
- **Primitive:** AES-256-GCM, PBKDF2-HMAC-SHA256 600 000, HKDF-SHA256, Base64url, Crockford Base32: tutte native (CryptoKit/CommonCrypto, javax.crypto API 26). Scartate: Argon2id/scrypt/XChaCha20 (dipendenze nuove), ChaCha20-Poly1305 (Android solo API 28+).
- **Chiavi:** DEK casuale avvolta con una frase di sicurezza separata dalla password Supabase (che il server vede) e con una chiave di recupero di 160 bit. Reset della password Supabase senza effetti. Scartata: chiave derivata dalla password di login.
- **Payload = la riga JSON di oggi** (DTO iOS / SyncMapper Android): la logica di sync non cambia, cambia solo il trasporto (`SyncRemote` iOS, decoratore `VaultSupabaseApi` Android). Scartato: formato nuovo per campo (riscrittura del merge).
- **Migrazione:** copia in chiaro sul server congelata dal trigger finché la copia cifrata non è verificata (contatori, id, campi, ricevuta SHA-256); riprendibile, idempotente, con rollback fino allo stato `active`. Scartata: migrazione «in un colpo» senza stato server.
- **Interruttore spento** (`E2EFeature.isEnabled`, `BuildConfig.E2E_ENABLED`) fino a S-50p; una volta acceso in produzione non si spegne (si usa `allowNewActivations`).
- **D-014:** rispettata spostando l'approvazione delle schermate (S-50o) prima dell'accensione: il codice resta dietro l'interruttore.
- **Chiavi di localizzazione `e2e_*` identiche** su iOS e Android (in iOS anche in `it.lproj`): eccezione voluta alla convenzione «chiave = testo italiano», per evitare collisioni.
- **Esecuzione:** 13 task Claude Code (S-50a…m, p) + 2 passi di Matteo (S-50n SQL, S-50o schermate e prova reale facoltativa), 3 collaudi di blocco e Commissione Suprema.

## 2026-11-24 · S-60 Collegamento bancario facoltativo: progetto esecutivo (architetto)
Progetto completo: `.cantiere/progetto-banca.md`. Dopo il lancio e dopo S-50. Autorizzazione di Matteo a toccare Sync/, Auth/ e punti minimi di Models/Persistence solo per S-60 (riferita dal capocantiere).
- **Fornitore: Enable Banking** (AISP registrato FIN-FSA, documentazione Italia ufficiale, modalità ristretta gratuita per i conti propri, API semplice). Piano B Salt Edge (Partner Program). Scartati: GoCardless Bank Account Data (iscrizioni chiuse, verificato 2026-11-24), Yapily/TrueLayer/Plaid (minimi mensili), Tink (prezzi non accessibili), open-banking.io (fonte autopromozionale).
- **Backend:** una sola Supabase Edge Function `bank` come proxy; segreti solo in Supabase; nessun dato bancario salvato sul server. Scartati: server proprio (da mantenere), JWT del fornitore consegnato all'app (credenziale globale), pull e salvataggio lato server.
- **Sigilli** `bs1.`/`ba1.` (AES-256-GCM, AAD = utente) al posto dell'ID di sessione e dell'uid del conto: l'app e il database non vedono mai gli identificativi del fornitore.
- **Movimento importato = `Transaction` normale con UUID v5 deterministico**: nessun campo nuovo sui modelli esistenti né colonne su `mt_transactions`; calcoli invariati; idempotenza tra dispositivi. Scartati: campi su `Transaction` (migrazione del modello centrale, client vecchi), archivio JSON separato.
- **Entità nuove senza relazioni:** BankConnection, BankAccountLink, BankDecision (sincronizzate, tabelle `mt_bank_*` o vault) + BankInboxItem (locale). SwiftData V4 e Room 4 solo additivi.
- **Riconciliazione:** doppioni sempre confermati dall'utente (stesso conto, segno, importo al centesimo, finestra −5/+3 giorni; ±7 per i pianificati; ±3 % solo con cambio valuta); pendenti mai importati; nessuna modifica o cancellazione automatica; saldo iniziale calcolato solo per conti nuovi; solo conti nella valuta dell'app.
- **Coerenza con S-50:** percorso unico per tutti; movimenti in transito solo in memoria della funzione; entità bancarie cifrate nel vault con la Protezione avanzata; trigger di guardia esteso alle nuove tabelle. Limite dichiarato: la funzione vede i movimenti in transito.
- **Scollegare** chiude il consenso e cancella i metadati; i movimenti importati restano salvo scelta esplicita.
- **Ritorno dalla banca:** browser di sistema + Universal/App Link + pagina di riserva `bucktrail://`, con state monouso e verificatore tipo PKCE. Niente WebView, niente webhook, niente aggiornamento in background.
- **Interruttori:** compilati spenti fino a S-60v; interruttore server `connect_enabled` solo per spegnere i nuovi collegamenti.
- **Costi:** v1 incluso nel prezzo con limiti (2 banche per utente, tetto globale, 6 h tra aggiornamenti automatici); se il preventivo supera ~0,10 €/conto/mese, «pass 12 mesi» non rinnovabile (progetto separato S-61). Scartato l'abbonamento automatico.
- **D-014:** approvazione visiva sostituita da test UI su tutti gli stati e screenshot (libertà data da Matteo); i testi del sito restano da approvare.
- **Rischio principale da verificare subito (S-60t):** linea guida App Store 5.1.1(ix) per account individuali in ambito finanziario; contratto/KYB Enable Banking per un privato; eventuale registrazione presso Banca d'Italia.

## 2026-11-25 · S-50h · Verifica e cancellazione nel migratore iOS

- I push preparatori A0 e D4 mantengono le righe in chiaro fuori dalla normale rimozione degli orfani. Una divergenza blocca la verifica. A7 cancella solo dopo la prova completa del vault, con marcatore verificato e conferma di stato `active` e `key_id` prima di ogni blocco.
- Se D5 fallisce due volte, il rollback verifica il vault contro il backup D2 e riporta lo stato ad `active` prima della pulizia. Se trova ID in chiaro assenti dalla copia verificata, conserva tutte le righe in chiaro e lascia il marcatore di rollback per il collaudo.
- Le transizioni su `mt_e2e` aggiornano o eliminano soltanto la riga corrispondente a utente, chiave e stato atteso. La cancellazione per blocchi e la lettura di stato sono richieste distinte nello schema §6.2. Il collaudo del blocco 2 deve esaminare un cambio di stato concorrente fra le richieste prima dell'accensione.

## 2026-11-25 · S-50i · Migrazione Android e concorrenza

- A0 e D4 caricano con SyncEngine e conservano le righe in chiaro presenti solo sul server. La pulizia A7 richiede ricevuta, marcatore con prova e stato `active` con generazione corrente prima di ogni blocco. D5 ripristina `active` solo dopo aver verificato la copia cifrata. Se la copia in chiaro contiene un ID sconosciuto o un campo divergente, conserva tutte le righe.
- Android usa `mt_e2e.updated_at` come generazione del dispositivo che guida l'operazione. PATCH e DELETE dei metadati sono condizionati nello stesso statement; la ripresa con la frase può acquisire una nuova generazione e una sessione precedente si ferma alla successiva verifica. D3 resta bloccato finché A7 ha righe in chiaro da pulire. D6 ricontrolla entrambe le copie e D7 conserva ogni residuo cifrato che diverge dal backup verificato.
- Il DELETE per blocchi su dati e il controllo dello stato sono richieste distinte con lo schema §6.2. Prima di accendere, il collaudo deve esaminare il cambio di stato tra queste due richieste e la concorrenza iOS↔Android. Lo schema attuale consente una garanzia atomica sui metadati; per i blocchi dati la garanzia atomica richiede una guardia nella stessa transazione server.

## 2026-11-25 · Banca (S-60/S-61) · modello economico e blocco del codice

- **Modello deciso da Matteo:** collegamento bancario come abbonamento a due livelli (fino a 2 banche / fino a 6 banche), mensile o annuale (annuale ≈ 10 mensilità, circa 2 mesi gratis). Chi non collega banche non paga niente oltre il prezzo dell'app. Pagamento solo con acquisto in-app Apple/Google (StoreKit / Play Billing) e controllo server-side dell'abbonamento su Supabase (progetto S-61).
- **Perché:** Enable Banking fattura Matteo ogni mese per conto collegato (costo `c` non pubblico) con un minimo mensile non noto; la vendita dell'app (netto 3,48 €) non copre un costo ricorrente. Fattore netto dopo IVA 22 % e commissione store 15 % = 0,85/1,22 ≈ 0,697; prezzo di pareggio = banche × c × 1,435.
- **Alternative scartate:** banca inclusa nel prezzo dell'app (costo ricorrente non coperto); pagamento fuori dagli store (vietato per beni digitali).
- **Congelamento:** nessun codice S-60/S-61 finché non arrivano le risposte di Enable Banking (mail inviata da `ciao@bucktrailapp.com`, risposta in `bucktrailapp@gmail.com`): costo `c`, minimo mensile, accettazione di una persona fisica senza P.IVA. Poi si rifanno le tabelle con i valori veri e si fissano i prezzi.
- **Apple:** Matteo non ha ancora un account Developer; scelta Individual, app pubblicata senza funzione bancaria, chiedere ad Apple prima di costruirla (linea guida 5.1.1(ix)). Non pagare i 99 $ prima del gate social del 6/12.
- **Dettaglio completo:** `.cantiere/banca-modello-economico.md` (tabelle per c = 0,10/0,20/0,30/0,50; domande al professionista: Banca d'Italia, GDPR/DPIA, P.IVA).

## 2026-11-26 · S-50q.3 · Eliminazione account e dati cifrati

- **Decisione:** l'app non cancella più «al meglio» `mt_vault`/`mt_e2e` prima di eliminare l'account (modifica di Codex in 1492143, `Auth/SupabaseManager.swift` e Android `SyncService.kt`). Resta così.
- **Perché:** verificato da Matteo su Supabase il 2026-11-26 11:06: `delete_own_account` esegue `delete from auth.users where id = auth.uid()`, e tutte le 7 tabelle (`mt_accounts`, `mt_transactions`, `mt_budgets`, `mt_goals`, `mt_recurring_rules`, `mt_e2e`, `mt_vault`) hanno la chiave esterna verso `auth.users` con `on delete cascade`. La cancellazione è garantita dal server, in un'unica transazione: più affidabile della pulizia dal client. Rischio R9 chiuso.
- **Alternativa scartata:** ripristinare la pulizia dal client filtrata per `key_id` (ridondante; in più richiede chiamate extra che possono fallire a metà).

## 2026-11-26 · S-50q.2 · Righe residue del vault dopo D7

- La sync legge per la chiave viva. Prima di applicare uno snapshot cifrato che può modificare i dati locali, il client verifica che la chiave sia ancora attiva: un cambio durante il pull può produrre uno snapshot parziale.
- La riattivazione raccoglie gli ID delle chiavi obsolete dopo la verifica della nuova copia e prima di A6. Ogni DELETE filtra per utente, tipo, ID e singola chiave obsoleta. Un guasto di trasporto durante la pulizia lascia le righe per una riattivazione successiva. Un cambio di generazione interrompe l'operazione.

## 2026-11-26 · S-50m · Protezione sparita dal server: il dispositivo chiede, non torna in chiaro da solo

- **Cosa:** se la riga `mt_e2e` risulta assente mentre il dispositivo ha ancora la DEK e non ha un proprio marcatore di disattivazione in corso (o ha solo un rollback interrotto), il gate restituisce il nuovo blocco `protectionRemoved`: DEK intatta, niente upload. L'utente vede «Protezione avanzata disattivata» e sceglie «Continua senza protezione» (DEK cancellata, primo accesso con pull) oppure esce dall'account. Una tabella `mt_e2e` irraggiungibile (404) con DEK presente blocca in `unsupported` invece di tornare in chiaro.
- **Perché:** Commissione Suprema, giudice sicurezza (G1#1, ALTA): chi ruba il token o l'amministratore del database poteva cancellare la riga e far ricaricare in chiaro tutti i dati, contro il modello di minaccia §1.2. Risolve anche lo stallo iOS dopo un rollback della disattivazione interrotto (G3#1, G5#1).
- **Scartate:** conferma con Face ID/codice del dispositivo (non protegge da nulla: l'attacco è remoto, chi conferma è l'utente); lasciare il comportamento e dichiarare il rischio in §1.3 (contraddice la promessa della funzione).
- **Effetto UX:** chi disattiva da un dispositivo vede, sugli altri, una richiesta di conferma una volta sola. Da mostrare a Matteo in S-50o.


## 2026-11-26 19:58 · Autorizzazione S-51 (Matteo, in chat)
Matteo autorizza modifiche a `MoneyTracker/Sync/` e `MoneyTracker/MoneyTrackerApp.swift` SOLO per S-51 (perdita dati con archivio volatile) e S-51b (prova automatica a due dispositivi). La scelta sulla protezione file del db va registrata qui da chi esegue, con alternative scartate.

Per il database SQLite reale e i file `-wal` e `-shm` si usa `.completeUntilFirstUserAuthentication`. I file restano protetti fino al primo sblocco dopo il riavvio. In seguito SwiftData può aprire l'archivio anche quando iOS avvia l'app a schermo bloccato. Scartata `.complete` perché un avvio a telefono bloccato dopo il primo sblocco può far fallire l'apertura dell'archivio. Scartato il ripiego silenzioso perché permette di scambiare dati effimeri per dati persistenti. Il ripiego in RAM mostra un banner fisso e blocca la sincronizzazione.


## 2026-11-27 · S-51d · Cancellazioni nella sincronizzazione
Matteo autorizza in chat, per S-51/S-51d, modifiche a `MoneyTracker/Sync/`, alla sync Android e ai due test esistenti che codificano il bug, `SyncServiceFlagOffTests.pushUploadsInOrderAndDeletesOnlyCurrentUsersOrphans` e `SyncEngineTest.pushUploadsDirtyAndMissingAndDeletesOrphansWithOneRequestEach`. Gli orfani cancellabili diventano esplicitamente noti alla base di sync.

La sync cancella sul server solo gli ID della base assenti in locale e non ricarica gli ID della base assenti sul server. La base dell'ultimo scambio riuscito è per utente e per tabella, in UserDefaults e SharedPreferences. Un campo JSON opzionale conserva gli ID già cancellati altrove fino al pull che li rimuove anche in locale: serve quando due push si susseguono o quando il pull viene ritardato. La base di push continua a contenere solo le righe condivise o appena caricate. In iOS, le letture in chiaro usano la paginazione già disponibile per evitare che il limite di risposta Supabase faccia risultare assenti righe ancora presenti.

Scartati il registro delle cancellazioni locali, il pull prima del push, i tombstone SQL e la rinuncia a propagare le cancellazioni. I percorsi di push delle migrazioni E2E sono invariati. Il rischio residuo è in S-51e.

Il §5 del progetto prevede l'adeguamento delle aspettative che falliscono per il cambio di protocollo. Su iOS, i test del login con remoto vuoto e del client in chiaro bloccato da E2E ora attendono la lettura degli ID prima dell'upsert. Su Android, i test della guardia, del consenso tra modalità e dei batch dichiarano la base coerente con lo scenario. Le verifiche sul blocco delle scritture, sulla conferma e sulle dimensioni dei batch restano attive.

I pull intermedi di migrazione mantengono la semantica precedente. Su Android il ripristino autenticato da questo dispositivo apre una nuova base dopo lo svuotamento deliberato del remoto, e il primo accesso con cloud vuoto accoda anche i movimenti creati prima del login. Gli ID remoti illeggibili sono registrati nella base Android. Se il dispositivo non ne ha mai avuto una copia, l'assenza locale non autorizza a cancellarli.

## 2026-11-27 · S-51f · Isolamento della vista radice

`MoneyTrackerApp.body` costruisce `RootView` sul MainActor. La closure `@Sendable` del `WindowGroup` restituisce la vista già costruita e il suo `body` compone l'interfaccia. Il coordinamento del ciclo di vita e la coda delle ricorrenze restano in `MoneyTrackerApp`, condivisi tra le finestre.

I rapporti di crash mostrano che SwiftUI può invocare la closure dalla coda `AsyncRenderer`. L'estrazione di `RootView` da sola ha superato la prima prova reale, ma l'ispezione del binario Debug ha rilevato ancora `swift_task_isCurrentExecutor` nella closure. Con `@Sendable` quella verifica è assente dalla closure nel binario Debug. Spostare anche la coda delle ricorrenze nella vista avrebbe creato una coda per finestra su iPad.

## 2026-11-27 · S-51g / S-51e / S-51h · Cancellazioni e test di sync

- S-51g: con lista remota dei conti vuota il pull elimina i conti locali già noti alla base. Se tutti i conti locali sono in attesa del primo push, resta la guardia sul pull vuoto. Quando coesistono conti noti e nuovi, questi ultimi conservano movimenti e budget locali.
- S-51e: la disattivazione usa il piano di S-51d nel preflight sul vault attivo. Il pull richiede gli ID previsti dal push e la verifica confronta l'intera copia allineata. Su iOS la ricevuta del vault è verificata anche prima di rimuovere i metadati della protezione. I percorsi di copia iniziale e le migrazioni SQL seguono le procedure esistenti.
- S-51h: il test del client precedente annulla e attende il push debounced del servizio moderno prima di contare le richieste. Le asserzioni originali sono tutte presenti.

## 2026-11-27 · S-52 · Autorizzazione e integrità dei collegamenti

Matteo autorizza in chat modifiche a `Sync/` su iOS e Android esclusivamente per S-52. I due ingressi UI di cancellazione del conto registrano la scelta esplicita nella sync. Su iOS il filtro della notifica SwiftData identifica il salvataggio remoto nel momento in cui viene emesso, prima della consegna differita su RunLoop. Su Android si mantiene la finestra di applicazione silenziosa con riallineamento del watcher.

Un push ordinario elimina un conto solo in presenza della scelta esplicita dell'utente. Le righe dipendenti ammesse dal confronto a tre vie si sincronizzano prima del conto. Se il server ha ancora movimenti collegati, il conto resta sul server. Una lettura incompleta che mostra ancora movimenti con quel conto preserva il conto locale. Un conto effettivamente cancellato altrove continua a sparire dal telefono. I movimenti ancora presenti sul server restano in locale, anche quando per effetto della FK hanno ormai il conto vuoto.

La riparazione in chiaro usa una RPC condizionale che aggiorna soltanto `account_id`, con controllo sul proprietario, sulla presenza del conto e sul marcatore di scollegamento deliberato. Il client richiede una copia locale con un conto ancora presente sul server e una riga priva di modifiche in coda. Un errore lascia il collegamento locale disponibile per il pull seguente. Scartato il caricamento integrale delle righe riparate, che poteva sovrascrivere una modifica concorrente. Scartata la classificazione di tutti i null come danno perché il form iOS permette esplicitamente di togliere un conto. Lo schema SQL è in CONSEGNA per Matteo e abilita la riparazione sui dati in chiaro. La protezione atomica della FK chiude la finestra tra il controllo del client e il DELETE.

## 2026-11-27 15:47 · Aggiornati due test esistenti (ok di Matteo)
- Cosa: `SyncRemoteGoldenTests` ora attende le letture paginate (order/limit, da S-50h `fd985e9`); `E2EGateTests:174` attende il `fetchIds(.accounts)` introdotto da S-51d.
- Perché: fallivano già prima di S-52 (verificato sul commit 2635388); il codice è giusto, i test erano indietro.
- Alternative scartate: lasciarli rossi.


## 2026-11-27 · S-70 · Autorizzazione Intents/ e gestione D-014
- **Chi decide:** Matteo (2026-11-26 in chat, riconfermato 2026-11-27).
- **Cosa:** autorizzata la modifica di `MoneyTracker/Intents/AddExpenseIntent.swift` (spese ed entrate) e l'aggiunta di `MoneyTracker/Intents/IntentCategoryMenu.swift`, esclusivamente per S-70a e S-70a2.
- **D-014 per S-70b:** specifica visiva nel progetto `.cantiere/progetto-s70-doppio-tap-simulazione.md` §3 + specifica di Matteo del 2026-11-27 19:05 + screenshot in `.cantiere/tmp/`; approvazione di Matteo prima del merge su `main` (S-70d).
- **Dettagli tecnici confermati:** «ultima usata» calcolata su `createdAt` decrescente per tipo (`uscita` / `entrata`, `isDone == true`, `!isTransfer`, non ricorrente, categoria ancora esistente); «suggerita» identica ad `AddTransactionView` (`LastUsedCategory.suggest` poi `KeywordCategoryClassifier` con >2 caratteri e ≠ `"Altro"`), solo se categoria disponibile; parametro opzionale `categoryName` aggiunto ad `AddIncomeIntent`; nella simulazione «E se…?» i conti esclusi dal totale sono selezionabili singolarmente nel menu (dopo gli inclusi, con `currentBalance`/`futureBalance`), «Tutti» resta il totale della Home (esclusi fuori) e i conti archiviati restano esclusi.

## 2026-11-27 · Movimenti, Ricorrenti, Abitudini, Statistiche (Matteo, in chat)
- Totali in fondo a ogni sezione di Movimenti, per qualsiasi mese, calcolati su ciò che la lista mostra (filtri compresi). Blocchi: Tutti = Uscite|Entrate; Fisse = Spese fisse|Entrate fisse; Uscite = Uscite; Entrate = Entrate; Trasf. = Trasferito; Ricorrenti = Uscite|Entrate programmate. Niente scritta «Mese successivo» (sostituisce S-70f).
- Occorrenze delle serie programmate come righe normali non effettuate (stesse dimensioni, angoli smussati), raggruppate in un gruppo tipo «In arrivo · pianificati» con totale a destra, in cima, SOLO nei mesi futuri; nel mese corrente restano in mezzo agli altri in ordine di data (Matteo, risposta B).
- Il filtro «Ricorrenti» diventa una sezione come le altre (niente pagina separata): solo serie programmate del mese, niente passato. Modifica/elimina serie restano.
- La vecchia pagina dei movimenti che si ripetono diventa «Abitudini», tasto in fondo a Statistiche. Criterio più severo: esclusi trasferimenti e rettifiche saldo, almeno 3 volte in 3 mesi diversi. Matteo autorizza la modifica in Domain/ per questo.
- Statistiche: tolti «↑/↓ rispetto al mese scorso», «Media mensile · ultimi 12 mesi», «2026 vs 2025» (il confronto annuale forse tornerà, da rivedere). Eccezione voluta al «solo visivo».
- Alternative scartate: tenere la pagina Ricorrenti separata (troppo confusa); soglia 2 occorrenze (coincidenze).

## 2026-11-27 · S-72 · Scelte tecniche del progetto (architetto)
- **Cosa:** progetto `.cantiere/progetto-s72-movimenti-abitudini.md`. Totali di sezione calcolati da una funzione pura sulle righe che la lista mostra (effettuati, pianificati, virtuali; trasferimenti esclusi da Uscite/Entrate, contati una volta per `transferGroupId` in «Trasferito»), blocco senza titolo. Logica nuova in file di `Views/` (iOS) e `ui/` (Android), non in Domain/. Unica modifica a Domain/: `RecurringSeriesDetector` (iOS e Android), autorizzata da Matteo. Android `domain/Statistics.kt` non si tocca: `prevMonthSpent`/`deltaPercent` servono al PDF, medie e totali annui restano coperti dai test e il confronto annuale potrebbe tornare. iOS `prevMonthSpent` resta per il PDF. In Ricorrenti la ricerca resta dentro il mese scelto. Filtro di sezione Android locale alla schermata, `TransactionFiltering` invariato.
- **Perché:** totali sempre uguali alla lista, zero test esistenti toccati oltre a quelli delle funzioni tolte da Matteo, nessuna zona intoccabile oltre l'autorizzazione.
- **Alternative scartate:** riusare `nextMonthTotals` di S-70f (calcola un altro mese e ignora ricerca e importi); aggiungere `Recurring` a `TransactionFiltering.TypeFilter` (tocca domain e i suoi test); rimuovere le funzioni morte di `Statistics.kt` (obbliga a cambiare `StatisticsTest`).

## 2026-11-27 · Risposte di Matteo al progetto S-72
- D2 ok: serie senza occorrenze nel mese si gestiscono dal mese in cui compaiono (pressione lunga); serie finite non compaiono in Ricorrenti.
- D3 sì: nel mese corrente anche i pianificati a mano stanno al loro giorno.
- D4 ok: eliminare NextMonthSummaryTests.swift e NextMonthSummaryTest.kt; adattare solo la navigazione di DemoShowcaseUITests, RecurrenceAppearanceUITests, RecurrenceCancelAndHomeUITests (asserzioni identiche).
- D1 = a: in Ricorrenti si vedono tutte le occorrenze del mese (già avvenute, da confermare, future); la differenza è visiva. «Niente passato» = niente storico dei mesi precedenti.

## 2026-11-28 00:35 · S-70k: nel comando «ultima usata» = solo storico stesso nome (come l'app)
- **Cosa:** il comando «Aggiungi movimento» propone le categorie con la stessa regola di AddTransactionView; tolta la riga «categoria dell'ultima spesa in assoluto».
- **Perché:** Matteo (prova S-70d) trovava «Svago · ultima usata» per «supermercato», mai usato: etichetta ingannevole.
- **Scartato:** tenere entrambe le righe (regola S-70a/S-70i).
