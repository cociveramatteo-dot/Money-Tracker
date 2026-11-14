# CHECKPOINT — MoneyTracker

> Il file per ripartire. Chi riapre il cantiere legge SOLO questo per capire dove siamo.
> Gli storici stanno in `.cantiere/archivio/checkpoint/`.

**Data:** — **Tag git:** — **Fatto da:** —

## Siamo qui
Promemoria di sospensione richiesto da Matteo, 2026-11-14 02:20 (non un checkpoint formale né un collaudo): ramo `redesign-sentiero`; S-12 chiuso, S-13a/b/c implementati [~]. S-13c ha build e 48 unit verdi; suite UI interrotta su richiesta di Matteo (5 UI verdi, stress S-15 ancora fallito, restanti da eseguire).

## Prima cosa da fare alla ripresa
Matteo scriverà «riprendiamo» a Claude Code. Leggere `.cantiere/STATO.md` e `.cantiere/CONSEGNA.md`, poi indirizzarlo a Codex col prompt completo già scritto nella consegna: **completare la sola verifica UI di S-13c**, non rifare l'implementazione e non iniziare S-13d prima. Due fallimenti UI preesistenti sono S-15; non aggirarli modificando test o viste.
