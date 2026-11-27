# CHECKPOINT — MoneyTracker

**Data:** 2026-11-26 18:55 · **Tag:** `checkpoint-2026-11-26-1855` · **Ramo:** `redesign-sentiero` · **Fatto da:** capocantiere (Claude Code · Sonnet 5.5), checkpoint COMPLETO

## Siamo qui

> **Aggiornamento veloce 2026-11-27 13:36** (capocantiere · Claude Code · Sonnet), tag `checkpoint-2026-11-27-1336`.

- **Serie S-51 (sync) CHIUSA e collaudata:** S-51 archivio volatile (e462c34), S-51d+S-51c merge a tre vie iOS/Android (53d62d9, 9d58e4e), S-51f crash rendering iOS 27.2 con `RootView` (c0ca6b8), S-51g conto cancellato altrove (8aa349e), S-51e disattivazione E2E a tre vie (dd09649), S-51h test t10 stabile (d0f1aab). Prova reale automatica S-51b su Supabase 12/12 nelle tre fasi.
- **Manca solo la prova di Matteo sui telefoni veri** (account di prova) per chiudere S-50. Poi S-70 → Codex.
- Rischio accettato (CONSEGNA): se il server rispondesse per errore con zero conti, il telefono cancellerebbe in locale i conti già sincronizzati; nessuna perdita sul server, tornano al pull dopo.
- Notato dal collaudatore sul simulatore: schermo bianco per qualche secondo al primissimo avvio dopo l'installazione. Matteo verifica sul telefono vero.
- `.xcscheme` modificato in locale con `-E2EEnabled YES` (prove di Matteo): NON committarlo, toglierlo a fine prove.

## Fatto dall'ultimo checkpoint (2026-11-26 15:36)

| Quando | Chi (strumento · modello) | Cosa |
|---|---|---|
| 16:32 | operaio (Claude Code · Sonnet) | S-50p: interruttori accesi in release, FAQ e privacy it/en |
| 16:37 | collaudatore (Claude Code · Sonnet) | S-50p collaudo ok |
| 17:09 | impresa (Codex · GPT-6) | S-50u (select solo righe obsolete) e S-50w (prova APK release R8) |
| 18:23 | Matteo | testi FAQ e privacy approvati, sito pubblicato |
| 18:27 | collaudatore (Claude Code · Sonnet) | S-50u e S-50w collaudo ok |
| 18:30 | collaudatore (Claude Code · Sonnet) | ecfc4f3 (S-50w) controllato: nessun segreto, nessun cleartext |
| 18:32 | collaudatore (Claude Code · Sonnet) | checkpoint fase 1: Commissione, bilingue, guardiano, test |
| 18:52 | capocantiere + Matteo | S-50x: email dell'account via SMTP Brevo, email di recupero di prova ricevuta |
| 18:54 | Matteo | S-50y meta e hreflang approvati e pubblicati; privacy it/en aggiornata |

## Stato di salute

| Controllo | Esito | Note |
|---|---|---|
| Build / test | 🟢 | iOS 46/46 test di sync (+73/73 con ricorrenze nel collaudo S-51f); Android 334/334 con `--rerun-tasks` |
| Prova reale Supabase | 🟢 | S-51b 12/12, protezione finale disattivata, record preesistenti presenti |
| Pagella (misurata) | 🟡 | 85/100, invariata: robustezza 32 (falso positivo CORS del guardiano, S-50g2), velocità 62 |
| Magazzino / spazio | 🟡 | come il 26/11: cartelle di build/cache segnalate; APK debug 24 MB proponibile al magazzino |
| Grafo | 🟢 | `graphify update .` fatto |
| Commissione Suprema | ⏳ | non fatta (checkpoint veloce): si fa al prossimo completo, prima del merge su main |

## Bug

- Risolti: privacy dell'app solo in italiano (ora it/en, S-50v); meta description mancante sulle pagine secondarie (S-50y); Bug 9 della Commissione (riga di reset nel test).
- Aperti: guardiano, falso positivo CORS (S-50g2). Velocità landing LCP 3,9 s su telefono (noto, nessun task assegnato: non verificato).

## Cantiere

- Spostati: log dei collaudi S-50 (694 MB) → `02_RISORSE/lavorate/collaudi-s50-2026-11/`.
- Da confermare (Matteo): nessuno.
- `docs/MoneyTracker.md`: v3.29 nel Changelog e versione in testata. Non rigenerato il PDF (lo fa il capocantiere).

## Struttura (dal grafo)

- Grafo aggiornato a fine checkpoint. Nessun cambio di struttura da segnalare (numeri nodi non verificati in questa fase).

## Domani si riparte così

1. Sessione nuova → «riprendiamo: S-51 chiusa, tocca alla mia prova reale sul telefono (S-50), poi S-70 a Codex».
2. **Matteo** prova sui telefoni veri con l'account di prova (istruzioni in `.cantiere/PER-MATTEO.md`): movimento creato, telefono bloccato, riapertura; iPhone→Android e Android→iPhone; con e senza Protezione avanzata; occhio allo schermo bianco al primo avvio.
3. Se va bene: **checkpoint completo** (con Commissione Suprema), S-50 chiuso, poi **S-70** → Codex (prompt §7 di `.cantiere/progetto-s70-doppio-tap-simulazione.md`).
4. Non urgenti: S-50z, S-50g2 (Matteo sceglie A = solo quella riga su main, B = merge completo dopo le prove); i 2 test UI Conti instabili visti il 26/11 non sono stati riverificati.

## Cose che deve fare Matteo

- [ ] Prova reale della Protezione avanzata con account di prova: iPhone + Android (istruzioni in `.cantiere/PER-MATTEO.md`).
- [ ] Risposta di Enable Banking (mail del 25/11, attesa 2–5 giorni lavorativi). Incollarla al capocantiere: si rifanno le tabelle prezzi.
- [ ] Le 4 domande al professionista (`.cantiere/banca-modello-economico.md` §8).
- [ ] 6 fonti NotebookLM (`.cantiere/PER-MATTEO.md`).
- [ ] TikTok: nome e account Business; SC-2 materiale faceless (`.cantiere/PER-MATTEO.md`).

## Suggerimenti · Rischi

- Guardiano 🔴 è un falso positivo: non cambia l'app. Chiuderlo con S-50g2 per non avere allarmi finti.
- `docs/MoneyTracker.md` §6 «Protezione avanzata», riga «Stato» è ancora quella di prima (cita S-50r/s/q.4 come aperti). Da aggiornare alla prossima revisione del manuale: non l'ho toccata in questo turno.
- Velocità della landing: LCP 3,9 s su telefono; immagini da ottimizzare.
- Due codici di misura sulla landing (il nostro e quello di Cloudflare): innocuo, da togliere se vuoi un solo conteggio.
