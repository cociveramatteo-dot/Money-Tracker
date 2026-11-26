# CHECKPOINT — MoneyTracker

**Data:** 2026-11-26 11:56 · **Tag:** `checkpoint-2026-11-26-1156` · **Ramo:** `redesign-sentiero` · **Fatto da:** capocantiere (Claude Code · Sonnet 5.5), checkpoint veloce

## Siamo qui

- **S-50 (Protezione avanzata, cifratura end-to-end):** tutto il lavoro tecnico è chiuso e collaudato `[x]`: S-50a…l, S-50h2, S-50l.2, S-50q, S-50q.1, S-50q.2, S-50q.3. **Interruttore SPENTO** in release su iOS e Android.
- **Server Supabase completo:** eseguiti da Matteo i tre script (§6.2 S-50n, §6.7 S-50q guardia vault + `mt_e2e_activate`, §6.9 S-50q.1 rollback atomico `mt_e2e_rollback` + lock `for share`). Gara A6/rollback provata su PostgreSQL 16 in entrambi gli ordini. `delete_own_account` cancella `auth.users` e le 7 tabelle `mt_*` vanno in cascata (DECISIONI 2026-11-26).
- **Restano per l'accensione:** S-50m (Commissione Suprema 10/10 + `docs/MoneyTracker.md`/PDF) → S-50o (Matteo approva le schermate) → S-50p (accensione + FAQ/privacy del sito). S-50q.4 (ritentare la pulizia delle chiavi morte, BASSA) non blocca.
- **Banca (S-60/S-61):** in attesa della risposta di Enable Banking; nessun codice prima.
- **Apple Developer:** non pagare prima del gate social del 6/12.
- **Quota Codex:** 29% alle 11:28, si resetta alle 14:24.

## Fatto dall'ultimo checkpoint (2026-11-24 23:56)

| Quando | Chi (strumento · modello) | Cosa |
|---|---|---|
| 2026-11-25 | impresa (Codex) | S-50a…l: crittografia, vault, migrazione/rollback iOS e Android, interfaccia 7 lingue, ciclo di vita chiavi, stress (20.000 movimenti, 17 interruzioni di rete) |
| 2026-11-25/26 | collaudatore (Claude Code · Sonnet) | collaudi dei blocchi 1, 2, 3: 165 unitari + 49 UI iOS, 311 JVM + lint Android verdi; difetti in PIANO (S-50h2, S-50q, S-50l.2) |
| 2026-11-25 | capocantiere (Claude Code · Sonnet 5.5) | sito: email, «pulsante», Chi siamo/About; modello economico banca, mail a Enable Banking, routing email Cloudflare; regola Codex `--yolo` in tutti i cantieri |

## Stato di salute

| Controllo | Esito | Note |
|---|---|---|
| Build / test / lint | 🟢 | collaudo S-50q.2 delle 11:50: iOS 175 unitari + 6 UI E2E (1 prova instabile per Mac carico, verde alla 3ª), Android 315 JVM + lint, server finto 19 |
| Guardiano notturno | 🟡 | ultimo rapporto 24/11: 4 avvisi sul sito, niente nelle app |
| Pagella (misurata) | 🟡 | 94/100 · Velocità 66 (LCP 3,7 s), Lingue 74 · non consegnabile: mancano i giudici |
| Sicurezza | 🟢 | flag E2E spento; bloccanti S-50h2/q/q.1/q.2/q.3/l.2 chiusi; manca solo la Commissione Suprema (S-50m) |
| Ordine e spazio | 🟡 | `magazzino.py`: cartelle di build/cache da ignorare; APK debug 24 MB in `app/build` (si rigenera) |
| Grafo aggiornato | 🟢 | 5657 nodi, 12552 archi, 494 community |
| Commissione Suprema | 🟡 | prevista in S-50m prima dell'accensione |

## Bug

- Risolti: falso allarme «Lingue 64» (era lo strumento).
- Aperti: landing, titoli che saltano un livello e LCP 3,7 s su telefono; privacy non tradotta in inglese. Nessuno nelle app.

## Cantiere

- Eliminati: `.DS_Store` (2), cartella vuota `SOCIAL/clip-social/post-3/materiale`.
- Da confermare (Matteo): `app/build` di Android pesa decine di MB tra APK e mapping (si rigenera, non è in git); le due pagine di conferma `confermato`/`confirmed` sono la coppia it/en, non un doppione. Il worker della landing ha 2 codici di misura (il nostro e quello iniettato da Cloudflare): innocuo.
- `.gitignore`, `.graphifyignore`, `CLAUDE.md`, `.claude/` non sono nell'elenco della radice di REGOLE-PROGETTO: restano, sono configurazione.

## Struttura (dal grafo)

- 3949 nodi (+12), 7886 archi (+20), 406 community (+12): nuove le icone vettoriali di `SfIcons.kt` e le risorse dello splash. 16 file JSON degli strumenti non producono nodi (graphify riproverà).

## Domani si riparte così

1. Sessione nuova nella cartella → `riprendiamo`.
2. **S-50m · Commissione Suprema** sul lavoro S-50 (6 giudici, 10/10), poi aggiornamento `docs/MoneyTracker.md` e PDF. Diff ampio: valutare se dare le correzioni a Codex (`codex --yolo -C /Users/matteo/Desktop/APP/MoneyTracker`).
3. **S-50o:** Matteo guarda e approva le schermate (comando in PER-MATTEO).
4. **S-50p:** accensione dell'interruttore + FAQ e privacy del sito. Non prima di S-50m e S-50o.
5. In coda, non bloccanti: S-50q.4 (Codex); suggerimenti del collaudo (accorciare E2EDeadVaultKeyTests 136 s, `simctl bootstatus -b` prima delle UI, test riga doppia chiave morta/viva nel server finto).
6. Se arriva la risposta di Enable Banking: rifare le tabelle prezzi.

## Cose che deve fare Matteo

- [ ] Leggere la risposta di Enable Banking quando arriva e riportarla al capocantiere.
- [ ] Fare le 4 domande al professionista (Banca d'Italia, GDPR/DPIA, P.IVA per vendere negli store, P.IVA per essere cliente Enable Banking): testo in `.cantiere/banca-modello-economico.md` §8.
- [ ] Non iscriversi ad Apple Developer prima del 6/12.
- [ ] Pubblicare i Post 5–15 · nome TikTok · riprese faceless (SC-2) · 6 fonti NotebookLM. Istruzioni in `.cantiere/PER-MATTEO.md`.

## Suggerimenti · Rischi

- La landing ha due codici di misura: se non vuoi i doppioni, togliere il nostro dalle 5 pagine.
- Velocità della landing: LCP 3,7 s su telefono; immagini da ottimizzare.
