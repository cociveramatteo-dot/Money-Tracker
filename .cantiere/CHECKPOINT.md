# CHECKPOINT — MoneyTracker

**Data:** 2026-11-24 22:31 · **Tag:** `checkpoint-2026-11-24-2231` · **Ramo:** `redesign-sentiero` (= `main`) · **Fatto da:** capocantiere (Claude Code · Sonnet 5.5), in autonomia su delega di Matteo

## Siamo qui

- **S-50 (cifratura end-to-end della sync):** progetto esecutivo pronto in `.cantiere/progetto-e2e-sync.md` (13 task S-50a…S-50m, 18–22 ore di Claude Code). SQL su Supabase già eseguito da Matteo (S-50n, 13 righe, inerte). **Nessun codice scritto: Matteo ripartirà quando vuole.**
- **S-60 (collegamento bancario):** progetto esecutivo pronto in `.cantiere/progetto-banca.md` (fornitore Enable Banking, piano B Salt Edge; 19 task S-60a…v, dopo S-50). Nessun codice. Prima verifica per Matteo: S-60t in PER-MATTEO (tipo di account Apple, email a Enable Banking, domanda al professionista).
- **iOS:** restyling «Sentiero» completo, 99 test unitari e 49 UI verdi (ultimo giro 15:09). Nessun codice iOS toccato in questo giro.
- **Android:** parità con iOS completa, installata e provata da Matteo su telefono vero (Samsung): sync con il Supabase reale funziona, avvio senza icona, icone di login e sblocco come su iPhone.
- **Sito:** online su bucktrailapp.com con la risposta «i miei dati sono al sicuro?» (it/en), privacy aggiornata e Cloudflare Web Analytics attivo.
- **Manca:** i voti dei giudici (solo prima di una consegna), le pubblicazioni social, qualche ritocco della landing (vedi sotto).

## Fatto dall'ultimo checkpoint (2026-11-24 15:09)

| Quando | Chi (strumento · modello) | Cosa |
|---|---|---|
| 2026-11-24 | capocantiere (Claude Code · Sonnet 5.5) | `main` portato a `redesign-sentiero` (ok di Matteo), APK installato sul telefono via cavo |
| 2026-11-24 | capocantiere (Claude Code · Sonnet 5.5) | S-44 verifica sicurezza (`sicurezza-dati-2026-11-24.md`), S-45 FAQ sicurezza it/en, S-46 Cloudflare Web Analytics (CSP, privacy, 5 pagine), S-47 splash Android, S-48 icone lucchetto/torta, S-49 sync reale (Matteo) |
| 2026-11-24 | capocantiere (Claude Code · Sonnet 5.5) | Strumento `bilingue.py` corretto (abbinamenti en↔it), hreflang e meta description sulla landing, manuale v3.26 e PDF |

## Stato di salute

| Controllo | Esito | Note |
|---|---|---|
| Build / test / lint | 🟢 | Android: build debug, lint e 247 test JVM verdi; provato su emulatore API 36 e su telefono. iOS invariato |
| Guardiano notturno | 🟡 | ultimo rapporto 15:06: 0 errori, 7 avvisi. Un giro nuovo era in corso alle 21:28Z, da rileggere domani con `/guardiano` |
| Pagella (misurata) | 🟡 | 93/100 prima della correzione di `bilingue.py` (Lingue 64 → 87); più bassa Velocità 66 (LCP 3,7 s su telefono). Non consegnabile: mancano i voti dei giudici |
| Lingue allineate | 🟡 | it/en allineati; la privacy esiste solo in italiano (voto 87) |
| Sicurezza | 🟢 | relazione S-44: nessuna falla; sync reale provato |
| Ordine e spazio | 🟢 | cantiere 568 MB; tolti 2 `.DS_Store` e una cartella vuota |
| Grafo aggiornato | 🟢 | 3949 nodi, 7886 archi, 406 community |
| Commissione Suprema | 🟡 | non rieseguita: il diff di oggi è solo asset Android, testi e configurazione del sito. Collaudo indipendente (collaudatore): 0 bug |

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

1. Sessione nuova nella cartella → `riprendiamo`
2. **Solo quando Matteo scrive «parti con S-50»** (e conferma il permesso su Sync/ e Auth/ per S-50): S-50a → operaio Claude Code (prompt nel progetto §10.3). **S-60 parte solo dopo S-50m**, con «parti con S-60». Finché non lo dice, entrambi restano fermi.
3. Nel frattempo, lavori indipendenti: titoli e LCP della landing (Codex o operaio), privacy in inglese, giudici prima di una consegna.

## Cose che deve fare Matteo

- [ ] Pubblicare i Post 5–15 · nome TikTok · riprese faceless (SC-2) · 6 fonti NotebookLM. Istruzioni complete in `.cantiere/PER-MATTEO.md`.

## Suggerimenti · Rischi

- La landing ha due codici di misura: se non vuoi i doppioni, togliere il nostro dalle 5 pagine.
- Velocità della landing: LCP 3,7 s su telefono; immagini da ottimizzare.
