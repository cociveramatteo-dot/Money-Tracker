# CHECKPOINT — MoneyTracker

**Data:** 2026-11-26 18:55 · **Tag:** `checkpoint-2026-11-26-1855` · **Ramo:** `redesign-sentiero` · **Fatto da:** capocantiere (Claude Code · Sonnet 5.5), checkpoint COMPLETO

## Siamo qui

> **Aggiornamento veloce 2026-11-27 16:14** (capocantiere · Claude Code · Sonnet), tag `checkpoint-2026-11-27-1614`.

- **Incidente S-52 CHIUSO.** Sull'account vero di Matteo 113 movimenti avevano `account_id` null SUL SERVER (dal 29/10, conti cancellati e ricreati con lo stesso id + FK `ON DELETE SET NULL`). Diagnosi `.cantiere/diagnosi-movimenti-scollegati.md`.
  - Riparazione: SQL generato da `prima.json` (Drive, mai nel repo) eseguito da Matteo → 113 ricollegati; export iPhone `riparato.json` identico a `prima.json`.
  - Fix Codex `e5aaf9e` (iOS+Android: guardie sui conti, pull senza eco, ricollegamento automatico) + verifiche iOS del capocantiere (`901a272`, due test vecchi aggiornati con ok di Matteo) + collaudo 🟡 senza bloccanti (`241998f`).
  - S-52s: Matteo ha applicato su Supabase la FK `NO ACTION DEFERRABLE INITIALLY DEFERRED` + colonna `account_link_cleared` + RPC di riparazione, DOPO aver aggiornato l'iPhone.
- **Prossimo:** prova S-50 di Matteo con l'account di prova (aggiornare prima Android), poi S-70 → Codex.
- `.xcscheme` modificato in locale (`-E2EEnabled YES` + Run in **Release**): NON committarlo, ripristinarlo dopo la prova S-50.
- Una build iOS vecchia contro il server nuovo non sincronizza se prova a cancellare un conto con movimenti (errore 23503, nessuna perdita): aggiornare sempre le build.

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
| Build / test | 🟢 | iOS 202 unitari + 58/58 UI (27/11); Android 335 JVM + server finto 19/19 (Codex) |
| Dati account vero | 🟢 | server senza_conto 13/209 (i 13 erano già senza conto), export iPhone identico al backup |
| Pagella (misurata) | 🟡 | 85/100 invariata: robustezza 32 (falso positivo CORS, S-50g2), velocità 62 |
| Magazzino / spazio | 🟡 | come prima: cartelle del progetto Xcode segnalate in radice (ammesse da REGOLE-PROGETTO) |
| Grafo | 🟢 | `graphify update .` fatto |
| Commissione Suprema | ⏳ | non fatta (veloce): al prossimo completo, prima del merge su main |

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

1. Sessione nuova → «riprendiamo: S-52 chiusa, tocca alla mia prova S-50 con l'account di prova su iPhone e Android (aggiornare prima Android), poi S-70 a Codex».
2. **Matteo** aggiorna Android (comando in PER-MATTEO) e fa la prova S-50 con l'account di prova; occhio allo schermo bianco al primo avvio.
3. Poi: ripristino `.xcscheme`, **checkpoint completo** con Commissione Suprema (questo era il 2° veloce di fila), S-70 → Codex (prompt §7 di `.cantiere/progetto-s70-doppio-tap-simulazione.md`).
4. Non urgenti: S-50z, S-50g2.

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
