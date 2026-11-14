# CONSEGNA — collaudo S-17

**Da:** collaudatore (Claude Code · Sonnet) · 2026-11-14 10:50 · commit 6d1fc6c
**Esito:** ok, S-17 [x].

- Una riga in `mergeRecurringRules`: con remoto vuoto e locale non vuoto non si tocca nulla. Test nuovo: conserva id, watermark, eccezioni. Orfani con remoto popolato ancora coperti dal test di merge.
- Provato: suite da 5 test verde (log /tmp/moneytracker-s17-verified.log). I 64 test completi non rilanciati.
- Limite accettato: l'ultima regola cancellata da un altro dispositivo risorge.
- Non provato: Supabase reale.

## Prossimo
S-13g UI → Codex (dopo S-12 di Antigravity); poi prova reale a due dispositivi/due utenti. S-16 test diagnostico quando c'è tempo.
