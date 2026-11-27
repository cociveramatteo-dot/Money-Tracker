# CHECKPOINT — MoneyTracker

**Data:** 2026-11-26 18:55 · **Tag:** `checkpoint-2026-11-26-1855` · **Ramo:** `redesign-sentiero` · **Fatto da:** capocantiere (Claude Code · Sonnet 5.5), checkpoint COMPLETO

## Siamo qui

> **Aggiornamento veloce 2026-11-27 11:27** (capocantiere, sessione lunga chiusa con /clear; nessun tag: Codex è in turno).

- **S-50 NON chiuso del tutto.** Codice S-50 collaudato, ma la prova reale di Matteo (26/11 sera) ha fatto emergere due bug di sync **preesistenti** (non causati da S-50):
  - **S-51** (iOS, archivio in RAM a telefono bloccato → movimenti mai inviati e persi): corretto da Codex (e462c34), **da collaudare**.
  - **S-51d** (iOS e Android: ogni push cancella dal server le righe nuove create dall'altro dispositivo; copre anche S-51c, righe cancellate che ricompaiono): progetto architetto `.cantiere/progetto-s51d-sync-cancellazioni.md` (base di sync a tre vie). **Codex in turno dal 2026-11-27 11:26** con il prompt §7. Matteo ha autorizzato l'aggiornamento dei 2 test che codificavano il bug.
  - **S-51b**: prova automatica a due dispositivi sul Supabase reale (script in `03_CODICE/bucktrail-android/scripts/`), account di prova in `~/.config/moneytracker/test-account.env` (mai in git). Prima della correzione: iOS→Android ok, Android→iOS KO.
- **S-70 in attesa** finché S-51/S-51d non sono chiusi (Matteo: «finiamo S-50 per intero, poi S-70»).
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
| Build / test / lint | 🟢 | iOS 187/187 unitari (2 UI instabili, come S-50r); Android 324/324 JVM + lint; server finto 19/19 |
| Commissione Suprema | 🟢 | 6 giudici a 10/10. Giro 1: Bug 9 (riga di reset in `E2EObsoleteVaultFilterTests`), Lingua 9 (meta description, poi S-50y) |
| collaudo.sh | 🟡 | solo cache Gradle ignorata (ambiente, non codice) |
| Guardiano notturno | 🔴 | falso positivo: errore CORS del beacon Cloudflare su 127.0.0.1 (8 «errori» su 4 pagine). Fix in S-50g2 |
| Pagella (misurata) | 🟡 | 85/100. Robustezza 32 (per il falso positivo). Velocità 62 (LCP 3,9 s, noto) |
| Bilingue | 🟢 | 100/100 (`bilingue.py`) |
| Sicurezza | 🟢 | interruttore acceso in release, spento in debug; nessun segreto nel repo; R8 senza cleartext |
| Ordine e spazio | 🟢 | 30 GB liberi (soglia 35). Spostati 694 MB di log collaudi S-50 nel magazzino |
| Grafo aggiornato | 🟢 | `graphify update .` a fine checkpoint |

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

1. Sessione nuova → «riprendiamo — codex ha finito S-51d, lancia il collaudatore».
2. **Collaudatore** su S-51 (e462c34) + S-51b (175ccb0) + S-51d (commit di Codex): diff, test di sync iOS/Android, esito della prova a due dispositivi, e rilancio dei 2 test UI Conti falliti (verificare se instabilità: confronto fab33a5 vs e462c34).
3. Se la prova a due dispositivi passa: **Matteo** rifà la prova sui telefoni veri (movimento creato, telefono bloccato, cavo staccato, riapertura dall'icona; poi Android→iPhone).
4. Solo dopo: checkpoint completo, S-50 chiuso, poi **S-70** (prompt §7 di `.cantiere/progetto-s70-doppio-tap-simulazione.md`).
5. Non urgenti: S-51e (stessa finestra in disattivazione E2E), S-50z, S-50g2 (fix pronto, arriva sul guardiano di `main` solo col merge: Matteo deve scegliere A = solo quella riga su main, B = merge completo dopo le prove).

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
