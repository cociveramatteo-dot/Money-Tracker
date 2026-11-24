# CHECKPOINT — MoneyTracker

**Data** 2026-11-24 02:16 · **Tag** `checkpoint-2026-11-24-0216` (creato al sigillo) · **Ramo** `redesign-sentiero` · **Fatto da** segretario (Claude Code · Haiku 5.5)

## Siamo qui

- **Android** completo sulle schermate B0–B11 (parità con iOS): Room v3, export, notifiche, blocco, demo, widget. 247 test JVM verdi e collaudo 🟢 del 2026-11-23. Prova a mano su emulatore: spesa da 12,50 € in demo, saldi coerenti. Sync e login provati solo con server finto.
- **iOS**: 94/94 unit e 17/18 UI (1 fragile, verde al rilancio). S-41 e S-42 chiusi. S-36 chiuso: rami vecchi cancellati, resta solo `fix/nightly-20260727-0411` per decisione di Matteo.
- **Manca prima della consegna**: prova sync reale Android (serve ok di Matteo e account di prova), telefono Android vero, pagella consegnabile (1 approvazione in sospeso, voti giudici e guardiano mancanti).

## Fatto dall'ultimo checkpoint (2026-11-21 10:30)

| Quando | Chi (strumento · modello) | Cosa |
|---|---|---|
| 2026-11-23 12:36 | capocantiere (Claude Code · Sonnet) | Social v2: Post 5–42 unificati in Post-5–15 (81 slide), in Drive «Da postare» |
| 2026-11-23 20:55 | capocantiere (Claude Code · Sonnet) | Android B0–B11, test di parità grafica, stress test (10 bug corretti, guardia anti-cancellazione cloud) |
| 2026-11-23 | collaudatore (Claude Code · Sonnet) | Verbale collaudo Android 🟢 (`collaudo-android-2026-11-23.md`) |
| 2026-11-24 00:44 | collaudatore (Claude Code · Sonnet) | Collaudo iOS: S-41 e S-42 chiusi, 94 unit ok, UI 17/18 |
| 2026-11-24 00:52 | capocantiere (Claude Code · Sonnet) | Commissione Suprema 10/10 al giro 2 (4 correzioni). Prova a mano Android in demo |
| 2026-11-24 | non verificato | Rami nightly cancellati (840 → 530 MB), tag `archivio/tmp-stash-inspect` |

## Stato di salute

| Controllo | Esito | Note |
|---|---|---|
| Build / test / lint | 🟢 | Android: 247 test JVM verdi. iOS: 94/94 unit, UI 17/18 (1 fragile) |
| Guardiano notturno | 🟡 | 404: il workflow non è su `main`. Ultimo esito non verificato |
| Pagella (misurata) | 🟡 | 98/100. Non consegnabile: 1 approvazione in sospeso, voti giudici e guardiano mancanti |
| Commissione Suprema | 🟢 | 10/10 al giro 2, 4 correzioni (`commissione-suprema-2026-11-24.md`) |
| Lingue allineate | 🟡 | Non verificate in questo periodo |
| Sicurezza | 🟡 | Guardia anti-cancellazione cloud in Android. Sync reale mai provato |
| Ordine e spazio | 🟡 | 12 GB liberi, sotto soglia 35 GB. Screenshot di parità da 114 MB ancora in `99_DA_SMISTARE/parita` |
| Grafo aggiornato | 🟢 | 3901 nodi, 7763 archi. Entra `bucktrail-android` |

## Bug

- Risolti: 10 bug dello stress test Android. 4 correzioni della Commissione (debug Android con URL finto, stringa demo, cache proiezione Home, separatore ultima riga).
- Aperti: UI test `testDeleteMonthlyFixedSeriesFromMovementMenuAllScopes` fragile (iOS, da assegnare). Passaggio di mese di S-41 non provato in UI (da assegnare).

## Cantiere

- Spostati/rinominati: Post 5–42 unificati in Post-5–15 (81 slide) in Drive «Da postare». Calendario v2 e v1 in archivio.
- Eliminati: rami nightly vecchi e `tmp-stash-inspect` (il secondo recuperabile dal tag `archivio/tmp-stash-inspect`).
- Da confermare (Matteo): trasloco degli screenshot di parità (vedi sotto). Ramo `fix/nightly-20260727-0411` tenuto (tocca `Auth/`).

## Struttura (dal grafo)

- Grafo: 3901 nodi, 7763 archi. Android entra nel grafo come `03_CODICE/bucktrail-android`.
- Archi dubbi iOS → `PdfReport.kt`: probabili omonimie, non verificato.
- 16 file JSON senza nodi nel grafo.

## Domani si riparte così

1. Sessione nuova nella cartella → `riprendiamo`
2. Primo lavoro: prova sync Android con Matteo (solo con suo ok e account di prova) — prompt: «Riprendiamo la prova sync Android del cantiere MoneyTracker. Leggi .cantiere/CHECKPOINT.md, sezione "Cose che deve fare Matteo", e la voce "prova reale a due dispositivi" in .cantiere/PER-MATTEO.md. Non usare il Supabase reale senza il mio ok esplicito. Guidami passo passo e registra l'esito in .cantiere/CONSEGNA.md.»
3. Poi: S-38 → Codex (virtuali, filtri, force-unwrap) — prompt: «Esegui il task S-38 del cantiere MoneyTracker (Codex). Leggi AGENTS.md e solo il task S-38 in .cantiere/PIANO.md, poi i file indicati. Nessun altro task. Build e test iOS verdi. Nessun push né merge. Registra in .cantiere/CONSEGNA.md.»
4. Poi: S-39 (traduzioni, redattore) e S-40 (font fissi, Codex). Banca: solo dopo la conferma di Matteo sulla proposta in PIANO.md.

## Cose che deve fare Matteo

- [ ] **Trasloco screenshot di parità (114 MB).** 📍 Terminale, nuova scheda, cartella del cantiere: `cd /Users/matteo/Desktop/APP/MoneyTracker` · ▶️ `bash .cantiere/strumenti/trasloco.sh 99_DA_SMISTARE/parita 02_RISORSE/lavorate/fuori-git/parita-android-2026-11-23` e scrivi `si` solo se dice «Copia verificata» · ↩️ l'ultima riga che stampa.
- [ ] **Post 5–15 su Instagram e TikTok.** 📍 Drive → `Da postare` → `Post-05…`. ▶️ Carica le slide in ordine, titolo e hashtag da `titolo-e-hashtag.txt`, date in `SOCIAL/calendario-v2.md`. Post-15: prova prima il doppio tocco su un iPhone vero. ↩️ «pubblicato post N».
- [ ] **TikTok, nome dal 24/11.** 📍 TikTok → Modifica profilo. ▶️ Nome: `Bucktrail · budget`. Dopo il primo post: Impostazioni e privacy → Account → Account Business, sito web `https://bucktrailapp.com/?utm_source=tiktok&utm_medium=bio`. ↩️ «tiktok ok».
- [ ] **Testi App Store.** 📍 Apri `SOCIAL/testi-v1.md`, scheda IT e EN. ▶️ Scrivi nella chat del capocantiere «testi App Store ok» o le correzioni. ↩️ l'esito.
- [ ] **NotebookLM, 6 fonti.** 📍 notebooklm.google.com → notebook «MoneyTracker App» → «Aggiungi fonte» → «Google Drive» → `MAGAZZINO/CANTIERI/moneytracker/`. ▶️ Aggiungi `02_RISORSE/originali/bucktrail-redesign/BRIEF_CANTIERE.md` e `DESIGN_HANDOFF.md` (importanti). Le licenze dei font sono facoltative. ↩️ «notebook ok».
- [ ] **Spazio disco.** 12 GB liberi, sotto soglia 35 GB. 📍 Terminale, cartella del cantiere · ▶️ `bash .cantiere/strumenti/spazio.sh` · ↩️ l'esito. Dopo il trasloco va meglio.
- [ ] **Prova sync reale Android e telefono vero** (biometria, widget, notifiche): quando vuoi. 📍 Chat del capocantiere · ▶️ scrivi «prova sync android» · ↩️ l'esito.
- [ ] **Approvazioni ⏳** in `.cantiere/APPROVAZIONI.md`: vedi `PER-MATTEO.md`.

## Suggerimenti · Rischi

- La release Android usa il Supabase reale (voluto). Ogni prova di sync tocca dati veri: nessuna prova senza ok di Matteo.
- Il guardiano notturno dà 404 finché il workflow non è su `main`. Il merge su `main` resta una decisione di Matteo.
- PIANO.md ha due voci S-36: la riga 173 è [x]; la voce «fix in TrailView» (riga 424) resta [~] e non è verificata.
- L'UI test fragile va rilanciato prima di dare per buono un verde.
