# CONSEGNA — collaudo S-13g + S-20

**Da:** collaudatore (Claude Code · Sonnet) · 2026-11-14 11:15.
- S-13g **collaudato ok** (be6ceb0): ambiti solo questa/successive/tutte, salta, termina da qui/dopo questa, elimina con conferma, alert errori e avvii verificati nel diff; virtuali solo in sezione separata, mai in totali/saldi; build + 67 unit + 1 UI verdi (log /tmp/moneytracker-s13g-final.log). Domain/Models/Sync non toccati.
- Note minori: doppio `safeSave` ridondante in AddTransactionView (ramo non ricorrente); in caso di errore del materializer vengono tolti solo regola e transazione propri.
- **S-20 CONFERMATO** con test temporaneo (rimosso): terminate dalla prima occorrenza → poi delete(.all)/edit(.all) = `invalidOccurrence`. Dettagli e fix proposto in PIANO S-20.
