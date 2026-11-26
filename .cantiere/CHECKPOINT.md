# CHECKPOINT — MoneyTracker

**Data:** 2026-11-26 15:36 · **Tag:** `checkpoint-2026-11-26-1536` · **Ramo:** `redesign-sentiero` · **Fatto da:** capocantiere (Claude Code · Sonnet 5.5), checkpoint veloce

## Siamo qui

- **S-50 (Protezione avanzata):** chiusi e collaudati anche S-50r (vault iOS fuori dal main thread, c8e89c8), S-50q.4 (pulizia chiavi morte ritentata, c5a0416), S-50s (riordino sync, 39db954), S-50t (test Keystore Android 3/3 su emulatore, 5c08e82). Interruttore ancora **SPENTO** in release iOS e Android.
- **Prossimo e unico bloccante:** **S-50p · accensione** + FAQ e privacy del sito (operaio Claude Code). Non bloccante: S-50u (lettura solo righe morte).
- **Dopo S-50p:** Matteo fa la prova reale con un account di prova (voce in PER-MATTEO).
- **Banca (S-60/S-61):** in attesa della risposta di Enable Banking (mail del 25/11, attesa 2–5 giorni lavorativi; sollecito dal 3/12). Professionista: prima commercialista (domande 3–4), avvocato fintech dopo la risposta di Enable Banking.

## Fatto dall'ultimo checkpoint (2026-11-24 23:56)

| Quando | Chi (strumento · modello) | Cosa |
|---|---|---|
| 2026-11-25 | impresa (Codex) | S-50a…l: crittografia, vault, migrazione/rollback iOS e Android, interfaccia 7 lingue, ciclo di vita chiavi, stress (20.000 movimenti, 17 interruzioni di rete) |
| 2026-11-25/26 | collaudatore (Claude Code · Sonnet) | collaudi dei blocchi 1, 2, 3: 165 unitari + 49 UI iOS, 311 JVM + lint Android verdi; difetti in PIANO (S-50h2, S-50q, S-50l.2) |
| 2026-11-25 | capocantiere (Claude Code · Sonnet 5.5) | sito: email, «pulsante», Chi siamo/About; modello economico banca, mail a Enable Banking, routing email Cloudflare; regola Codex `--yolo` in tutti i cantieri |

## Stato di salute

| Controllo | Esito | Note |
|---|---|---|
| Build / test / lint | 🟢 | 15:34: iOS 186 unitari + 7 UI E2E; suite UI completa 57/57 (2 instabili ripassati) al collaudo S-50r; Android 323 JVM + lint, Keystore strumentato 3/3 |
| Commissione Suprema | 🟢 | S-50m 10/10 (13:40); da rifare al checkpoint completo dopo S-50p |
| Guardiano notturno | 🟡 | ultimo rapporto 24/11: 4 avvisi sul sito, niente nelle app |
| Pagella (misurata) | 🟡 | 94/100 · Velocità 66 (LCP 3,7 s), Lingue 74 · non consegnabile: mancano i giudici |
| Sicurezza | 🟢 | interruttori E2E spenti in release |
| Ordine e spazio | 🟡 | `magazzino.py`: cartelle di build/cache da ignorare (invariato); collegamenti al magazzino 🟢 |
| Grafo aggiornato | 🟢 | `graphify update .` 15:35 |

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
2. **S-50p · accensione** interruttore + FAQ e privacy del sito → operaio Claude Code (dettagli §10.3 di `.cantiere/progetto-e2e-sync.md`).
3. Poi checkpoint **completo** (sono 2 veloci di fila) con Commissione Suprema sul diff di S-50p.
4. Non bloccante: S-50u (Copilot o Codex).
5. Se arriva la risposta di Enable Banking: rifare le tabelle prezzi.

## Cose che deve fare Matteo

- [ ] Leggere la risposta di Enable Banking quando arriva e riportarla al capocantiere.
- [ ] Dopo S-50p: prova reale della Protezione avanzata con un account di prova (istruzioni in PER-MATTEO).
- [ ] Fare le 4 domande al professionista (Banca d'Italia, GDPR/DPIA, P.IVA per vendere negli store, P.IVA per essere cliente Enable Banking): testo in `.cantiere/banca-modello-economico.md` §8.
- [ ] Nome TikTok · riprese faceless (SC-2) · 6 fonti NotebookLM. Istruzioni in `.cantiere/PER-MATTEO.md`.

## Suggerimenti · Rischi

- La landing ha due codici di misura: se non vuoi i doppioni, togliere il nostro dalle 5 pagine.
- Velocità della landing: LCP 3,7 s su telefono; immagini da ottimizzare.
