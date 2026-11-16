# CHECKPOINT — MoneyTracker

> Il file per ripartire. Chi riapre il cantiere legge SOLO questo per capire dove siamo.
> Gli storici stanno in `.cantiere/archivio/checkpoint/`.

**Data:** 2026-11-16 21:45 · **Tag git:** checkpoint-2026-11-16-2145 · **Fatto da:** capocantiere (Claude Code · Sonnet)

## Siamo qui
Ramo `rimuovi-confronto-mese`. Redesign Sentiero completo e collaudato; S-31 (rimozione confronto mese su mese, D-012) chiuso [x]. Collaudo automatico 🟢; 83 unit test e 4 UI Statistiche verdi. Documento master e PDF aggiornati. Non ancora fatto il merge su `main` (serve l'ok di Matteo).

## Stato di salute
🟢 build, test, collaudo.sh. Aperti: controlli manuali S-24 e S-21, prova Supabase reale (S-13f), S-16, `TransactionsView` 864 righe. Nota: il .strings italiano ha 88 chiavi contro 394 delle altre lingue (preesistente, da confermare che sia voluto).

## Domani si riparte così
1. Matteo decide il merge di `rimuovi-confronto-mese` su `main` (prima rilanciare i 4 UI test S-6 sulla build finale).
2. Controlli manuali S-24 e S-21 (Matteo).
3. Poi S-30 «categoria dall'ultima volta» (D-011).
