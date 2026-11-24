# CHECKPOINT — MoneyTracker

**Data:** 2026-11-24 15:09 · **Tag:** `checkpoint-2026-11-24-1509` · **Ramo:** `redesign-sentiero` · **Fatto da:** capocantiere (Claude Code · Sonnet 5.5), in autonomia su delega di Matteo

## Siamo qui

- **iOS:** restyling «Sentiero» completo. Pacchetto A della Commissione chiuso (S-38 filtri sulle serie virtuali e conferme, S-39 traduzioni, S-40 font che seguono Dynamic Type, S-43 test corretto), più il passaggio di mese di S-41 testato. **99 test unitari e 49 UI verdi.**
- **Android:** parità con iOS completa (B0–B11). 247 test JVM e 2 strumentati su emulatore verdi. Sync e login provati solo con server finto.
- **Manca:** la prova di sync reale su Android e il telefono Android vero (servono le tue mani e un account di prova), le pubblicazioni social, `main` da portare al ramo di lavoro (decisione tua).

## Fatto dall'ultimo checkpoint (2026-11-24 02:17)

| Quando | Chi (strumento · modello) | Cosa |
|---|---|---|
| 2026-11-24 | capocantiere (Claude Code · Sonnet 5.5) | S-38, S-39 (46 chiavi x 6 lingue), S-40 (239 font), S-43 (test), S-16 (precisione Decimal misurata), passaggio di mese S-41 e conferma «Salta mese» con test |
| 2026-11-24 | capocantiere (Claude Code · Sonnet 5.5) | Collaudi S-38/39/40 (`collaudo-ios-s38-s39-s40-2026-11-24.md`) e Commissione Suprema giro 3 10/10 (`commissione-suprema-2026-11-24-giro3.md`) |
| 2026-11-24 | capocantiere (Claude Code · Sonnet 5.5) | Chiusi o collaudati SC-3…SC-9 (landing online uguale al locale, smoke FFmpeg), S-33, S-34, S-36; guardiano puntato sulla landing; registri ripuliti |

## Stato di salute

| Controllo | Esito | Note |
|---|---|---|
| Build / test / lint | 🟢 | iOS 99 unit + 49 UI; Android 247 JVM + 2 strumentati; build debug Android ok |
| Guardiano notturno | 🟡 | giro del 24/11 15:06 sulla landing: 0 errori, 7 avvisi (titoli saltano un livello, 1 link YouTube respinto dal bot). Lighthouse: prestazioni 92, accessibilità 99, SEO 98, buone pratiche 100. Il giro automatico gira su `main`, con la vecchia configurazione fino al merge |
| Pagella (misurata) | 🟡 | 93/100; più bassa Velocità 66 (LCP 3,7 s su telefono, landing). Non consegnabile: mancano i voti dei giudici (servono solo prima di una consegna) |
| Lingue allineate | 🟢 | 439 chiavi uguali in 6 lingue, segnaposto coerenti. «Lingue 64» della pagella = nomi piatti della landing contro lo strumento, non un difetto |
| Sicurezza | 🟡 | Nessuna superficie nuova. Sync reale mai provato |
| Ordine e spazio | 🟢 | 26 GB liberi; cantiere 558 MB; screenshot di parità già nel magazzino |
| Grafo aggiornato | 🟢 | 3937 nodi, 7866 archi |

## Bug

- Risolti: test `SentieroReviewFixUITests` rosso (era il test, non l'app); conferma mancante su «Salta mese/Termina…»; 2 stringhe italiane nella registrazione.
- Aperti: nessuno nell'app. Landing: titoli che saltano un livello (moderato, 3 pagine) → da correggere alla prossima ricarica della landing.

## Cantiere

- Spostati/rinominati: niente. Eliminati: niente.
- `fix/nightly-20260727-0411` tenuto (tocca `Auth/`, decisione di Matteo del 24/11).
- Collegamento bancario: roadmap dopo il lancio, non lavoro aperto.

## Struttura (dal grafo)

- 3937 nodi, 7866 archi, 394 comunità. Novità: `DashboardView.countsInProjection`, `scaledFont` in `Theme.swift`, test `ProjectionMonthTests` e `DecimalPersistenceTests`.

## Domani si riparte così

1. Sessione nuova nella cartella → `riprendiamo`
2. Primo lavoro: prova sync reale Android con Matteo — prompt: «Riprendiamo la prova sync Android del cantiere MoneyTracker. Leggi .cantiere/CHECKPOINT.md e la voce «prova sync reale» in .cantiere/PER-MATTEO.md. Non usare il Supabase reale senza il mio ok esplicito. Guidami passo passo e registra l'esito in .cantiere/CONSEGNA.md.»
3. Poi: pagella completa con i giudici prima di ogni consegna; correzione dei titoli della landing alla prossima ricarica.

## Cose che deve fare Matteo

- [ ] **Portare `main` al ramo di lavoro.** 📍 Chat del capocantiere. ▶️ Scrivi «porta main al redesign» (il push su `main` richiede il tuo ok esplicito: ho provato in autonomia e il controllo permessi l'ha fermato). Così anche il guardiano notturno usa la nuova configurazione. ↩️ Niente.
- [ ] Prova sync reale + telefono Android (account di prova) · pubblicare i Post 5–15 · nome TikTok · riprese faceless (SC-2) · 6 fonti NotebookLM. Istruzioni complete in `.cantiere/PER-MATTEO.md`.

## Suggerimenti · Rischi

- Velocità della landing: LCP 3,7 s su telefono; immagini da ottimizzare alla prossima ricarica.
- Il dialogo di conferma di «Salta mese» in questa versione di iOS non ha «Annulla»: si annulla toccando fuori.
