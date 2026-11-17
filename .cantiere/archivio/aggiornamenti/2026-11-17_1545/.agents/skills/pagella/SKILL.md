---
name: pagella
description: Pagella del progetto con voti da 0 a 100 per categoria (prestazioni, accessibilità, SEO, peso, velocità, robustezza, codice, sicurezza, lingue, completezza, grafica, uso, testi), totale pesato e verdetto di consegna. Usala quando Matteo dice "dammi la pagella", "che voto ha il sito", prima di ogni consegna, e (solo parte misurata) a ogni checkpoint.
---
# Pagella

Voti **misurati** (strumenti, 0 crediti) + voti dei **giudici** (2 IA diverse, solo grafica/uso/testi).

1. **Dati freschi**: `bash .cantiere/strumenti/guardiano/scarica.sh` (rapporto del guardiano: Lighthouse,
   giro su 8 dispositivi). Se è più vecchio di 3 giorni o manca: `gh workflow run guardiano.yml` e aspetta,
   oppure procedi segnalandolo.
2. **Solo misurata** (checkpoint): `python3 .cantiere/strumenti/pagella.py --misurata` e fermati qui.
3. **Giudici** (pagella completa, prima delle consegne):
   - giudice 1: in Claude Code il subagente `giudice` (scrive `.cantiere/tmp/giudice-claude.md`);
   - giudice 2: un'IA DIVERSA da chi ha costruito il sito (Gemini in Antigravity o Codex) con il prompt di
     `PROMPT_GIUDICE.md`; il verdetto va in `.cantiere/tmp/giudice-<nome>.md`.
   Entrambi usano SOLO `CRITERI.md` e guardano gli screenshot del guardiano.
4. `python3 .cantiere/strumenti/pagella.py` → storico in `.cantiere/PAGELLE.md`, dettaglio in `.cantiere/archivio/pagelle/`.
   **I conti li fa lo script**: non ricalcolare a mano, non riscrivere i verdetti (se un file di un giudice non
   viene letto, correggi solo la riga fuori formato e rilancia). Il giudice 2 si prepara dal file
   `PROMPT_GIUDICE.md` così com'è, nominando l'IA scelta.
5. Rispondi a Matteo in max 8 righe: totale, consegnabile sì/no e perché, le 3 categorie più basse con
   l'azione per alzarle. Per ognuna crea un task in PIANO.md (skill `assegna`).
6. Se i giudici sono in disaccordo (> 15 punti) decide Matteo; il brand e il gusto del cliente vincono sui giudici.

Pesi e soglie: `.cantiere/pagella.json` (consegna se totale ≥ 80 e nessuna categoria < 60, approvazioni
complete, guardiano non rosso).
