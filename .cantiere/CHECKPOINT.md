# CHECKPOINT — MoneyTracker

**Data:** 2026-11-26 13:42 · **Tag:** `checkpoint-2026-11-26-1342` · **Ramo:** `redesign-sentiero` · **Fatto da:** capocantiere (Claude Code · Sonnet 5.5), checkpoint veloce

## Siamo qui

- **S-50 (Protezione avanzata):** S-50m chiuso (Commissione Suprema **10/10** dopo 3 giri, correzioni `ccd3db2` + `83965ff`, manuale v3.27 + PDF). **S-50o approvato da Matteo** (13:40, incluse le 8 schermate nuove). Interruttore ancora **SPENTO** in release su iOS e Android.
- **Novità:** se la protezione sparisce dal server mentre il dispositivo ha la chiave, l'app non torna in chiaro da sola: mostra «Protezione avanzata disattivata» e chiede (DECISIONI 2026-11-26).
- **Prima dell'accensione (S-50p):** S-50r (iOS: decodifica del vault fuori dal main thread, consigliato). Non bloccanti: S-50s (pulizia architettura), S-50q.4.
- **Banca (S-60/S-61):** in attesa della risposta di Enable Banking. **Apple Developer:** non pagare prima del gate social del 6/12.

## Fatto dall'ultimo checkpoint (2026-11-24 23:56)

| Quando | Chi (strumento · modello) | Cosa |
|---|---|---|
| 2026-11-25 | impresa (Codex) | S-50a…l: crittografia, vault, migrazione/rollback iOS e Android, interfaccia 7 lingue, ciclo di vita chiavi, stress (20.000 movimenti, 17 interruzioni di rete) |
| 2026-11-25/26 | collaudatore (Claude Code · Sonnet) | collaudi dei blocchi 1, 2, 3: 165 unitari + 49 UI iOS, 311 JVM + lint Android verdi; difetti in PIANO (S-50h2, S-50q, S-50l.2) |
| 2026-11-25 | capocantiere (Claude Code · Sonnet 5.5) | sito: email, «pulsante», Chi siamo/About; modello economico banca, mail a Enable Banking, routing email Cloudflare; regola Codex `--yolo` in tutti i cantieri |

## Stato di salute

| Controllo | Esito | Note |
|---|---|---|
| Build / test / lint | 🟢 | 13:36: iOS 184 unitari + 8 UI E2E, Android 321 JVM + lint 0 errori; `E2EKeyStoreInstrumentedTest` compilato, non eseguito |
| Commissione Suprema | 🟢 | S-50m 10/10 su tutti i 6 giudici (giro 3 su 83965ff) |
| Guardiano notturno | 🟡 | ultimo rapporto 24/11: 4 avvisi sul sito, niente nelle app |
| Pagella (misurata) | 🟡 | 94/100 · Velocità 66 (LCP 3,7 s), Lingue 74 · non consegnabile: mancano i giudici |
| Sicurezza | 🟢 | flag E2E spento; difetto «protezione spenta dal server» chiuso |
| Ordine e spazio | 🟡 | `magazzino.py`: cartelle di build/cache da ignorare (invariato); collegamenti al magazzino 🟢 |
| Grafo aggiornato | 🟢 | `graphify update .` 13:41 |

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
2. **S-50r · Codex** (`codex --yolo -C /Users/matteo/Desktop/APP/MoneyTracker`): decodifica e cifratura del vault iOS fuori dal main thread (dettagli in PIANO e `.cantiere/tmp/s50m-commissione-giro1.md`, G4#3).
3. **S-50p · accensione** dell'interruttore + FAQ e privacy del sito: dopo S-50r collaudato.
4. Non bloccanti: S-50s, S-50q.4; eseguire `E2EKeyStoreInstrumentedTest` su emulatore Android.
5. Se arriva la risposta di Enable Banking: rifare le tabelle prezzi.

## Cose che deve fare Matteo

- [ ] Leggere la risposta di Enable Banking quando arriva e riportarla al capocantiere.
- [ ] Fare le 4 domande al professionista (Banca d'Italia, GDPR/DPIA, P.IVA per vendere negli store, P.IVA per essere cliente Enable Banking): testo in `.cantiere/banca-modello-economico.md` §8.
- [ ] Non iscriversi ad Apple Developer prima del 6/12.
- [ ] Pubblicare i Post 5–15 · nome TikTok · riprese faceless (SC-2) · 6 fonti NotebookLM. Istruzioni in `.cantiere/PER-MATTEO.md`.

## Suggerimenti · Rischi

- La landing ha due codici di misura: se non vuoi i doppioni, togliere il nostro dalle 5 pagine.
- Velocità della landing: LCP 3,7 s su telefono; immagini da ottimizzare.
