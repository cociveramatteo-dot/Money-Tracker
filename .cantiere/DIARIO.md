# GIORNALE DEI LAVORI

Una riga per turno, solo aggiunte in fondo. Mai modificare le righe vecchie.
I checkpoint hanno una riga che inizia con `== CHECKPOINT`.

| Quando | Chi (ruolo / strumento / modello) | Task | Fatto | Aperto |
|---|---|---|---|---|
| 2026-11-13 15:49 | Matteo | — | Cantiere aperto | Compilare AGENTS.md §1, primo piano |
| 2026-11-13 19:23 | capocantiere (Claude Code · Sonnet) | S-1 token, font, dark mode | Token Sentiero in DS (light/dark), font Space Grotesk+Inter, CategoryTint, test; build + 21 unit + 12 UI verdi | collaudo S-1 (collaudatore); poi S-2 a Codex |
| 2026-11-13 19:39 | collaudatore (Claude Code · Sonnet) | collaudo S-1 | ✅ collaudato, nessun difetto; contrasti WCAG ok | S-2 a Codex |
| 2026-11-13 20:15 | seconda impresa (Codex · GPT-6) | S-2 componenti base | Sette componenti nuovi, preview light/dark; build + 21 unit + 12 UI verdi | collaudo S-2, verifica visiva preview |
| 2026-11-13 20:20 | collaudatore (Claude Code · Sonnet) | collaudo S-2 | ❌ non conforme: chiavi i18n «Sforato»/«Soglia 80%» mancanti in 7 lingue, raggio hero 16 invece di 24–26; resto ok | S-2b rilavorazione (Codex), poi ricollaudo |
| 2026-11-13 20:35 | seconda impresa (Codex · GPT-6) | S-2b correzioni collaudo | Due chiavi in 7 lingue, hero raggio 24, layout MovementRow, accessibilità percentuale reale; build + 21 unit + 12 UI verdi | ricollaudo S-2b e chiusura S-2 |
| 2026-11-13 20:40 | collaudatore (Claude Code · Sonnet) | ricollaudo S-2b | ✅ quattro correzioni conformi; S-2 e S-2b chiusi [x] | S-3 al capocantiere; resa visiva a vista da Matteo |
| 2026-11-13 21:52 | capocantiere (Claude Code · Sonnet) | S-3 tab bar flottante + FAB | FloatingTabBar, FAB Sentiero, UI test su id tab_*; build + test verdi | collaudo S-3 (collaudatore) |
| 2026-11-13 22:08 | collaudatore (Claude Code · Sonnet) | S-3 | collaudo ok, S-3 [x] (note Dynamic Type accessibilità, FAB da vedere a vista) | S-4 |
| 2026-11-13 22:30 | capocantiere (Claude Code · Sonnet) | S-4 Home con TrailView | BalanceTrail (puro, 6 test), TrailView, HomeHeroCard, Home Sentiero; build + 27 unit + 12 UI verdi | collaudo S-4; resa a vista (curva, XL, tedesco, dark) |
| 2026-11-13 22:40 | collaudatore (Claude Code · Sonnet) | S-4 | collaudo ok, S-4 [x]: funzioni Home presenti, BalanceTrail corretto (Decimal, ancoraggi), i18n 6 lingue ok, nessuna modifica al codice | resa a vista (XL, tedesco, altezza righe ultimi movimenti) da confermare da Matteo; poi S-5 |

| 2026-11-13 22:54 | seconda impresa (Codex · GPT-6) | S-5 Movimenti | restyling, MovementRow, chip, pianificati e card giornaliere; i18n x7; build verde, grafo aggiornato | test bloccati dal runner/simulatore; collaudo e resa a vista aperti, S-5 [~] |
| 2026-11-13 23:16 | collaudatore (Claude Code · Sonnet) | S-5 collaudo | runner ripristinato; 27 unit + 12 UI verdi; resa hub light/dark/XL/de ok; S-5 [x] | riserve cosmetiche in S-11; sezioni interne non fotografate |
| 2026-11-14 00:22 | capocantiere (Claude Code · Sonnet) | S-12 | turno Antigravity interrotto per quota e liberato su ordine di Matteo; modifiche non committate lasciate nel ramo | Codex riprende S-12, verifica e confronto mockup da fare |

| 2026-11-14 01:14 | seconda impresa (Codex · GPT-6) | S-12 | riprese modifiche Antigravity; pagina unica, chip da mockup, Ricorrenti/storico, demo e XL; 27 unit + 12 UI verdi; 8 varianti reali confrontate più swipe/storico/filtri/MonthBar; test temporaneo rimosso, grafo aggiornato | S-12 [~] da collaudare; tab bar XL in S-10; motore ricorrenze S-13 |
| 2026-11-14 01:30 | collaudatore (Claude Code · Sonnet) | S-12 collaudo | confronto col mockup su screenshot (light, dark, XL, tedesco, filtri attivi, swipe, Ricorrenti); pagina unica, chip, banner, totale XL ok; 27 unit + 12 UI verdi (rieseguiti da me); 7 lingue valide; S-12 [x] | tab bar XL → S-10; motore ricorrenze → S-13; ritocchi Ricorrenti minori |

| 2026-11-14 02:05 | seconda impresa (Codex · GPT-6) | S-13a + S-13b | Calculator/UUIDv5/codec, RecurringRule e SchemaV3, app/Siri aggiornati; build e 40 unit verdi; grafo aggiornato | [~] da collaudare; UI 10/12, due fallimenti riprodotti → S-15; prossimo S-13c |

| 2026-11-14 02:20 | seconda impresa (Codex · GPT-6) | S-13c | Materializer/mainContext e 11 test, avvii serializzati, vecchio motore/test rimossi; build e 48 unit verdi; grafo aggiornato | Stop esplicito di Matteo, UI interrotti: 5 verdi e stress S-15 fallito; ripresa Claude→Codex per completare sola verifica UI; S-13c [~] |

| 2026-11-14 09:29 | seconda impresa (Codex · GPT-6) | Ripresa verifica UI S-13c | Completati i 6 UI sospesi: 5 verdi, 1 fallito noto; totale sul codice invariato 10/12 UI, build e 48 unit già verdi; solo documenti aggiornati | S-13a/b/c [~] da collaudare, S-15 aperto (stessi 2 fallimenti); poi S-13d |
| 2026-11-14 09:55 | collaudatore (Claude Code · Sonnet) | S-13a/b/c | Diff rivisto, build + 48 unit verdi rieseguiti; i 2 UI falliscono uguali su 0a76000 (indipendenti da S-13) → [x] | S-15 aperto; commenti vecchio actor in S-13h |

| 2026-11-14 09:56 | seconda impresa (Codex · GPT-6) | S-13d | Editor Domain, ambiti/eccezioni/riconciliazione, recupero errore; build e 60 unit verdi; grafo aggiornato | Collaudo d; alert e collegamento errori materializer/editor in S-13g; S-15 invariato |
| 2026-11-14 10:20 | collaudatore (Claude Code · Sonnet) | collaudo S-13d | ok: ambiti, codec, copie fatte immutate, split, watermark nil, rollback; 60 unit verdi da log | note minori + obbligo S-13g (alert errori) |

| 2026-11-14 10:18 | seconda impresa (Codex · GPT-6) | S-13f, sola preparazione SQL | SQL mt_recurring_rules e istruzioni S-13e in PER-MATTEO; 16 colonne, indice, grant CRUD, 4 policy RLS; controlli statici e diff puliti | Collaudo SQL, esecuzione S-13e a Matteo; codice Sync S-13f ancora da fare |
| 2026-11-14 10:30 | collaudatore (Claude Code · Sonnet) | collaudo SQL S-13f (563980d) | ok: 16 colonne, numeric, grant, 4 policy RLS; SQL non eseguito | Matteo esegue S-13e; Sync S-13f da implementare |
| 2026-11-14 10:27 | capocantiere (Claude Code · Sonnet) | registra S-13e | Matteo ha creato mt_recurring_rules: rls_attiva = true, numero_policy = 4 | Sync S-13f da implementare |
| 2026-11-14 10:33 | seconda impresa (Codex · GPT-6) | S-13f Swift | DTO, push/pull regole, max watermark, logout, 4 test; build + 64 unit verdi; grafo aggiornato | collaudo S-13f, prova reale tra dispositivi/utenti; S-16 precisione elevata |
| 2026-11-14 10:40 | collaudatore (Claude Code · Sonnet) | collaudo S-13f (cff65f7) | Swift ok: DTO/NULL/push/orphans/pull max watermark/logout/64 test; S-16 diagnosi preliminare da log; trovato rischio S-17 | prova reale Supabase non eseguita (manca UI regole → S-13g); S-16 da misurare; S-17 da decidere |
| 2026-11-14 10:42 | seconda impresa (Codex · GPT-6) | S-17 | protezione pull remoto vuoto, test conservazione ID/watermark/eccezioni; build e 5 test verdi | collaudo S-17; remoto parzialmente popolato invariato |
| 2026-11-14 10:50 | collaudatore (Claude Code · Sonnet) | collaudo S-17 (6d1fc6c) | guardia remoto vuoto ok, test ok (suite da 5); S-17 [x] | limite: ultima regola cancellata altrove risorge; 64 test non rilanciati |
| 2026-11-14 10:59 | seconda impresa (Codex · GPT-6) | S-13g UI funzionale | regole/UUIDv5, ambiti/salta/termina, virtuali futuri senza totali, serie programmate, alert/lifecycle, 7 lingue provvisorie; build + 67 unit + 1 UI verdi; grafo aggiornato | collaudo S-13g, Supabase reale, S-18 grafica, S-19 redattore, S-20 diagnosi Domain |
| 2026-11-14 11:15 | collaudatore (Claude Code · Sonnet) | collaudo S-13g (be6ceb0) + riproduzione S-20 | S-13g [x]; S-20 riprodotto (delete/edit .all → invalidOccurrence dopo terminate dalla prima) | fix S-20 da assegnare; S-13h |

| 2026-11-14 11:05 | seconda impresa (Codex · GPT-6) | S-20 | guard corretto e test regressione, 68 unit verdi | collaudo diff |
| 2026-11-14 11:06 | collaudatore (Claude Code · Sonnet) | collaudo S-20 (bf9727e) | guard con base.endDate=nil + test regressione, 68 unit verdi; S-20 [x] | nota: il guard ora accetta anche occorrenze oltre endDate (non raggiungibili dalla UI); S-13h |
| 2026-11-14 11:08 | collaudatore (Claude Code · Sonnet) | S-13h documento + Commissione Suprema | commenti obsoleti, docs+PDF, 68 unit verdi; Commissione: 10/8/10/8/9/8 | S-21, S-22, S-19, S-18 prima del checkpoint |

| 2026-11-14 11:15 | seconda impresa (Codex · GPT-6) | S-21 / S-22 | cache occorrenze, resolve al tap/apertura menu, guard, card e riga virtuale estratte; build + 68 unit + 1 UI verdi; grafo aggiornato | collaudo diff e menu contestuale; S-19/S-18 prima della Commissione |
| 2026-11-14 11:37 | collaudatore (Claude Code · Sonnet) | S-21/S-22 | S-22 ok [x]; S-21 [ ]: voce Ricorrenza nel contextMenu risolta in onAppear, rischio non comparire; xcodebuild mio bloccato (simulatore), fidato log Codex 68+1 verdi | fix menu S-21 |
| 2026-11-14 11:45 | seconda impresa (Codex · GPT-6) | S-21 fix menu | resolve nel body, test invalidazione cache, pressione prolungata UI; build + 69 unit + 1 UI verdi, log conservato | collaudo commit e verifica manuale menu; graphify-out escluso |
| 2026-11-14 11:47 | collaudatore (Claude Code · Sonnet) | S-21 fix menu | collaudo ok, S-21 [x]: resolve nel body, test cache, log 69 unit + 1 UI coerente | controllo manuale menu a Matteo |

| 2026-11-14 12:45 | impresa (Codex · GPT-6) | S-23 editor singola occorrenza e repeat | viste aggiornate, categorie verificate, 70 unit + 2 UI mirati verdi; modifiche preesistenti incluse | collaudo S-23; suite completa con due fallimenti noti S-15 |
| 2026-11-14 12:55 | collaudatore (Claude Code · Sonnet) | S-23 | collaudo ok, S-23 [x]: diff coerente con le 7 richieste, Domain/Models/Sync/Auth intatti, log finale 70 unit + 2 UI verdi, due fallimenti suite completa = S-15 (NavigationStress:55, TransactionFlow:68) | manuale a Matteo (PER-MATTEO) |

| 2026-11-15 11:09 | impresa (Codex · GPT-6) | S-24/S-25 | task creati, test serie tutte aggiunto, bug successive prima delle 12 riprodotto con unit/UI; limite S-25 dimostrato | Domain vietato: entrambi [!], nessun codice app modificato, test reproducer rossi; autorizzazione Matteo |

| 2026-11-15 11:41 | impresa (Codex · GPT-6) | S-24/S-25 + test S-15 autorizzati | corretti giorno originale eliminazione e propagazione completa per scope, effettuato locale, date/ID/rollback; 78 unit e ultimi esiti dei 15 UI verdi tra full e rilanci mirati; S-15 filtro persistente ≥20€ dimostrato e azzerato nei test | collaudo indipendente; blocco Tutte su dati reali non riprodotto, S-18/S-19 e Commissione |
| 2026-11-15 11:55 | collaudatore (Claude Code · Sonnet) | collaudo S-24/S-25/S-15 (125561c) | diff Domain/viste/test riletto; 78 unit verdi rilanciati; log UI verificati (rilanci mirati, no full 15/15 unico); esito [x] con riserva blocco reale su Tutte | S-18/S-19, Commissione S-13h; prova reale Tutte a Matteo |

| 2026-11-16 01:13 | impresa (Codex · GPT-6) | S-26 Demo vetrina | seed v6: otto mesi, nove regole, override/oggi effettuato, pianificati, budget/obiettivi/conti e sette lingue; build + 79 unit + 4 UI verdi, dieci immagini confrontate; commit locale senza push | collaudo indipendente S-26; full UI unico S-27; grafica S-6/S-7/S-8/S-18 |
| 2026-11-16 01:22 | collaudatore (Claude Code · Sonnet) | S-26 | collaudo ok: diff 0cde11c, zone intoccabili intatte, 32 chiavi demo x 7 lingue, unit test verdi | S-27 |

| 2026-11-16 01:40 | impresa (Codex · GPT-6) | S-27 | fallback seeder, reset filtri test, test collisioni; build + 80 unit + 16/16 UI unico run verdi | collaudo indipendente; idle non riprodotto |
| 2026-11-16 03:55 | collaudatore (Claude Code · Sonnet) | S-27 | collaudo ok: diff 35ea8d4, fallback seeder, reset filtri solo --uitesting, test collisioni valido, zone intoccabili intatte, build + 80 unit verdi | S-18/S-19, Commissione S-13h |

| 2026-11-16 09:40 | impresa (Codex · GPT-6) | S-18 | proposta approvata; card serie/virtuali Sentiero; 80 unit + 7 UI verdi e dark reale mirato verde, otto immagini ispezionate | collaudo S-18; S-19/S-13h; tab bar XL S-28 |
| 2026-11-16 09:43 | collaudatore (Claude Code · Sonnet) | S-18 | collaudo ok: diff, immagini, unit verdi | S-19 redattore, S-28 |
| 2026-11-16 09:45 | redattore (Claude Code · Sonnet) | S-19 revisione traduzioni S-13g | 7 lingue riviste (de, fr, ja, zh-Hans corrette; it/en/es confermate), marker rimossi; plutil ok, chiavi allineate | collaudo + rilettura madrelingua |
| 2026-11-16 09:47 | collaudatore (Claude Code · Sonnet) | S-19 | collaudo ok: strings valide, chiavi allineate, 0 marker; note genere de/es su «Nessuno» | approvazione Matteo, S-28 |
