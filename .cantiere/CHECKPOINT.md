# CHECKPOINT — MoneyTracker

**Data:** 2026-11-26 00:50 · **Tag:** `checkpoint-2026-11-26-0050` · **Ramo:** `redesign-sentiero` · **Fatto da:** capocantiere (Claude Code · Sonnet 5.5), checkpoint veloce

## Siamo qui

- **S-50 (cifratura end-to-end della sync, «Protezione avanzata»):** scritto da Codex e collaudato per i blocchi 1, 2 e 3. Fatti e chiusi `[x]`: S-50a…l (crittografia, server finto, migrazione e rollback su iOS e Android, interfaccia in 7 lingue, uscita/cambio utente/eliminazione account, stress, bug S-50l.1). **Interruttore SPENTO** in release su entrambe le piattaforme: gli utenti non vedono nulla.
- **Bloccanti per l'accensione (S-50p):** S-50h2 (iOS: 3 gare nel migratore, da allineare ad Android) · S-50q (guardia atomica sul server: secondo SQL che Matteo dovrà incollare in Supabase, con istruzioni complete) · S-50l.2 (iOS: ricevute di verifica nei log di debug). Poi S-50m (Commissione Suprema 10/10 + docs), S-50n/S-50o (Matteo approva le schermate, prova su due dispositivi).
- **Banca (S-60/S-61):** modello deciso (abbonamento 2/6 banche, mensile o annuale, solo acquisto in-app), in `DECISIONI.md` e `.cantiere/banca-modello-economico.md`. Mail inviata a Enable Banking da `ciao@bucktrailapp.com`: **si aspetta la risposta** (costo per conto, minimo mensile, persona fisica senza P.IVA). Nessun codice prima.
- **Sito:** `ciao@bucktrailapp.com` al posto della Gmail, «pulsante», nuove pagine Chi siamo / About, online.
- **Apple Developer:** Matteo non ha account; non pagare prima del gate social del 6/12.
- **Quota Codex:** al 12% a fine serata, finestra da 5 ore.

## Fatto dall'ultimo checkpoint (2026-11-24 23:56)

| Quando | Chi (strumento · modello) | Cosa |
|---|---|---|
| 2026-11-25 | impresa (Codex) | S-50a…l: crittografia, vault, migrazione/rollback iOS e Android, interfaccia 7 lingue, ciclo di vita chiavi, stress (20.000 movimenti, 17 interruzioni di rete) |
| 2026-11-25/26 | collaudatore (Claude Code · Sonnet) | collaudi dei blocchi 1, 2, 3: 165 unitari + 49 UI iOS, 311 JVM + lint Android verdi; difetti in PIANO (S-50h2, S-50q, S-50l.2) |
| 2026-11-25 | capocantiere (Claude Code · Sonnet 5.5) | sito: email, «pulsante», Chi siamo/About; modello economico banca, mail a Enable Banking, routing email Cloudflare; regola Codex `--yolo` in tutti i cantieri |

## Stato di salute

| Controllo | Esito | Note |
|---|---|---|
| Build / test / lint | 🟢 | iOS 165 unitari + 49 UI (4 prove instabili del simulatore, verdi alla riprova); Android 311 JVM e lint verdi |
| Guardiano notturno | 🟡 | non riletto in questo giro |
| Pagella (misurata) | 🟡 | 94/100 · Velocità 66 (LCP 3,7 s), Lingue 74 (privacy non tradotta in inglese) · non consegnabile: mancano i giudici |
| Sicurezza | 🟡 | flag E2E spento; S-50l.2 (log) e S-50h2/S-50q da chiudere prima di accendere |
| Ordine e spazio | 🟡 | `magazzino.py` segnala cartelle di build/cache da ignorare (`.kotlin/sessions`, ecc.), niente di grave |
| Grafo aggiornato | 🟢 | `graphify update .` eseguito |
| Commissione Suprema | 🟡 | non rieseguita: prevista in S-50m prima dell'accensione |

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
2. **S-50h2 + S-50l.2** a Codex in un solo turno (iOS, lavori piccoli; controllare la quota con `/status`). Si lancia con `codex --yolo -C /Users/matteo/Desktop/APP/MoneyTracker`.
3. **S-50q** (SQL guardia atomica sul server): la scrive il capocantiere; poi Matteo la esegue su Supabase con istruzioni complete; Codex adatta server finto e test.
4. Poi S-50m (Commissione Suprema) → S-50o (Matteo approva schermate) → S-50p (accensione). Non si accende prima.
5. Se arriva la risposta di Enable Banking in `bucktrailapp@gmail.com`: rifare le tabelle prezzi con `c` e minimo reali.
6. Opzionale: APK Android per l'amico (da un commit stabile, quando Codex è fermo; build `assembleDebug`).

## Cose che deve fare Matteo

- [ ] Leggere la risposta di Enable Banking quando arriva e riportarla al capocantiere.
- [ ] Fare le 4 domande al professionista (Banca d'Italia, GDPR/DPIA, P.IVA per vendere negli store, P.IVA per essere cliente Enable Banking): testo in `.cantiere/banca-modello-economico.md` §8.
- [ ] Non iscriversi ad Apple Developer prima del 6/12.
- [ ] Pubblicare i Post 5–15 · nome TikTok · riprese faceless (SC-2) · 6 fonti NotebookLM. Istruzioni in `.cantiere/PER-MATTEO.md`.

## Suggerimenti · Rischi

- La landing ha due codici di misura: se non vuoi i doppioni, togliere il nostro dalle 5 pagine.
- Velocità della landing: LCP 3,7 s su telefono; immagini da ottimizzare.
