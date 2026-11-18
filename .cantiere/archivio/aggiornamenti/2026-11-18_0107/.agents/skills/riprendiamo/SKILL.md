---
name: riprendiamo
description: Riprende il lavoro del cantiere dall'ultimo checkpoint leggendo solo il minimo. Usala quando Matteo dice "riprendiamo", "dove eravamo", "ripartiamo", o apre una sessione nuova chiedendo a che punto siamo.
---
# Ripresa (pochissimi crediti: non leggere codice né documenti)

1. `.cantiere/STATO.md`. Se c'è un turno aperto qualcuno ha chiuso male: avvisa Matteo, leggi `CONSEGNA.md`
   e `git status` e proponi come chiuderlo.
2. `.cantiere/CHECKPOINT.md` (solo quello).
3. Cosa è successo dopo: `git log --oneline $(git tag -l 'checkpoint-*' --sort=-creatordate | head -1)..HEAD`
   e le righe di `.cantiere/DIARIO.md` dopo l'ultima `== CHECKPOINT`. Se ce ne sono, leggi `CONSEGNA.md`.
4. Se esiste `.cantiere/guardiano/ULTIMO.md` leggi SOLO le prime 5 righe (riassunto della notte).
5. `git status`: segnala modifiche non salvate.
5b. `.cantiere/PER-MATTEO.md` (voci aperte) e, se esiste con voci aperte, `.cantiere/AVVIO.md`: vanno nella riga
   🧑 con istruzioni complete (📍 dove · ▶️ cosa · ↩️ cosa riportare). Se Matteo chiede solo "cosa devo fare?",
   rispondi con queste voci e basta. Una voce di AVVIO già fatta (es. il remoto GitHub c'è) si spunta senza chiedere.
6. `.cantiere/PIANO.md`: SOLO la sezione "In corso / prossimi" (ferma la lettura a "## Fatti"). Prima i task `[~]` (fatti,
   da collaudare → proponi il collaudatore), poi il **primo `[ ]` in ordine**, col suo "A chi". Se è un lavoro
   di esecuzione e "A chi" è vuoto o è l'operaio, proponi un'impresa (Antigravity → Codex → Copilot), come nella skill `assegna`. Mai inventare un T-xxx: se il guardiano o altro
   suggerisce lavori nuovi, proponi di aggiungerli in coda al PIANO, non di passare davanti.
7. Rispondi in massimo 8 righe:
```
📍 Siamo qui: <1 riga>
🩺 Salute: <semaforo> · 🌙 Guardiano: <🟢/🟡/🔴 + 1 riga, se c'è>
✅ Ultimo lavoro: <chi, cosa, quando>
▶️ Propongo: <numero e titolo del primo task aperto del PIANO> → <ruolo> su <strumento> — <motivo>
   Prompt: «…» (oppure "lo lancio io?")
🧑 Per te: <cose da fare fuori dal computer / approvazioni in sospeso>
```
8. Aspetta il via. Al via apri il turno (AGENTS.md §4).
