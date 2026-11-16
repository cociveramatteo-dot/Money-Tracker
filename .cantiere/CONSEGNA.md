# CONSEGNA — S-26 Demo vetrina

**Da:** impresa (Codex · GPT-6), 2026-11-16 01:13. Ramo `redesign-sentiero`. Nessun push/merge.

## Implementazione
- `DemoDataSeeder` versione 6: otto mesi di dati interamente fittizi, stipendio 2.850 €, premi occasionali, due viaggi, picco regali, dentista, acquisti distribuiti; quattro tipi di conto (carta prepagata), giroconti mensili bilanciati e interessi sui risparmi.
- Nove vere `RecurringRule`: stipendio, affitto, bolletta, internet, video, musica, palestra, assicurazione, rata. Copie storiche/current-month con ID del calculator e `templateId`; bolletta di oggi con override 112,40 €, palestra di oggi già effettuata. Mesi successivi virtuali, watermark al mese corrente (decisione ricorrenze già in DECISIONI.md).
- Pianificati: bolletta, assicurazione, hotel a fine mese, corso tra tre giorni. Budget per otto mesi, sotto soglia / 80–99% / sforati, quattro obiettivi al 26/44/70/100% circa. Tutte le categorie principali, esclusa la categoria tecnica Rettifica saldo.
- 32 chiavi `demo.*` usate, coperte in tutte le sette lingue; 12 nuove chiavi per lingua e nome carta aggiornato. Nessuna modifica alle zone intoccabili o ai test esistenti.
- Reset elimina anche le regole; test dedicato su container in memoria verifica due reset, ID, override, effettuato oggi, storia, categorie, budget, giroconti, mancata rimaterializzazione e delta pianificato non nullo.

## Verifiche
- Build e controllo finale: **79 unit + 4 UI verdi**, `TEST SUCCEEDED` (unit + RecurrenceFlowUITests + DemoShowcaseUITests). Log `/tmp/moneytracker-s26-final.log`; xcresult `/Users/matteo/Library/Developer/Xcode/DerivedData/MoneyTracker-ccjguvvnbihhyiemgfhjfvaiqfwa/Logs/Test/Run-MoneyTracker-2026.11.15_12-43-24-+0100.xcresult`. L'ultimo UI è passato dopo un lunghissimo timeout di idle del simulatore; non è un risultato veloce/prestazionale. Tentata interruzione solo quando sembrava bloccato: il processo era già terminato, nessun test interrotto.
- Dieci immagini finali esportate e ispezionate in `/tmp/moneytracker-s26-images/` (manifest con nomi). Home: attuale 21.973,16 €, atteso 21.511,76 €, quattro pianificati −461,40 €, curva verde/ambra senza incassi del mese successivo. Movimenti: supermercato e palestra effettuati oggi, indicatori repeat; editor Solo questa con bolletta 112,4; serie con prossime date anche virtuali di dicembre. Statistiche: sei barre mensili diverse, picco vacanze agosto e premio luglio. Budget: Cibo 260/300 (86,7%), Svago 112/90 e Shopping 212/170 sforati, Trasporti 70/240 e Salute 73/180 sotto; Obiettivi: 25/44/70/100% visualizzati. Conti: quattro tipi e saldi positivi plausibili.
- Primo full run: 79 unit verdi, 14/16 UI verdi. Due test ricorrenze non trovavano righe fuori dalla parte visibile della lista. Distribuzione acquisti e scadenze del seed corretta; rilancio intermedio unit + tutte le ricorrenze + showcase verde (83 test). Nessun test esistente modificato.
- `plutil -lint` su sette Localizable.strings e controllo delle chiavi: verdi. `git diff --check` verde.
- Acquisizioni tramite XCTest su iPhone 18 Pro / iOS 27.2, demo `--uitesting` (desktop CUA non disponibile). Screenshot e xcresult restano locali, fuori da git.
- Confronto con `DESIGN_HANDOFF.md` e `reference/*.dc.html`: Home mostra hero, curva verde e proiezione ambra; gli altri schermi possono essere popolati e verificati, ma Statistiche/Pianifica/Conti non sono ancora tutti conformi ai mockup: lavori già aperti S-6/S-7/S-8. Le serie programmate hanno ancora la grafica da rifinire in S-18. S-26 non certifica il redesign completo.

## File esclusi
`graphify-out/` era già modificato/non tracciato all'inizio. Eseguito aggiornamento AST senza LLM; tutti gli artefatti del grafo (compresi quelli preesistenti) restano fuori dal commit. Nessun'altra modifica estranea inclusa.

## Prossimo
Collaudo indipendente S-26 → collaudatore su Claude Code (Sonnet), leggendo solo il diff del commit e queste evidenze. Solo il collaudatore o Matteo può portare S-26 a [x]. Dopo: S-27 (full UI unico e altri miglioramenti già elencati); poi S-18/S-19 e Commissione S-13h. Nessun push/merge.

## Collaudo S-26 (2026-11-16 01:22)
Esito: OK. Nessuna modifica a zone intoccabili/test esistenti; seed solo su demoContainer separato; 32 chiavi demo.* in 7 lingue; unit test verdi (rilanciati). Note minori: force-unwrap solo in codice Debug (dateInterval, Category.defaults) accettabili. Prossimo: S-27.
