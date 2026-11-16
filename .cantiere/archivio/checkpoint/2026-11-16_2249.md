# CHECKPOINT — MoneyTracker

> Il file per ripartire. Chi riapre il cantiere legge SOLO questo per capire dove siamo.
> Gli storici stanno in `.cantiere/archivio/checkpoint/`.

**Data:** 2026-11-16 22:49 · **Tag git:** checkpoint-2026-11-16-2249 · **Fatto da:** capocantiere (Claude Code · Sonnet)

## Siamo qui
S-30 «categoria dall'ultima volta» collaudata e con Commissione Suprema 10/10 (secondo giro); traduzioni approvate da Matteo. S-13f e S-13 chiusi da Matteo; S-24 e S-21 verificati. Merge di `categoria-ultima-volta` su `main` e push in questo checkpoint.

## Stato di salute
🟢 build, 90 unit test, UI S-30 e S-6, collaudo.sh. 🟡 `DemoShowcaseUITests.testShowcaseScreens` rosso anche su main (S-32, da assegnare a Codex). Nota: il .strings italiano ha 88 chiavi contro 395 delle altre lingue (preesistente).

## Domani si riparte così
1. S-32: sistemare il test demo rosso → Codex (Antigravity sospeso fino al 2026-11-20).
2. `TransactionsView` ancora 864 righe; S-16 precisione Decimal (opzionali).
