# Antigravity = IMPRESA PRINCIPALE

> Questo file vale SOLO per Antigravity. Se sei un altro strumento (Copilot, Codex, Claude Code) ignoralo:
> per te valgono AGENTS.md e il tuo file (Copilot: `.github/copilot-instructions.md`).

Le regole del cantiere sono in AGENTS.md: rispettale tutte, a partire da Turni (§4) e Lettura a strati (§5).
Le frasi-comando funzionano anche qui: le skill sono in `.agents/skills/` (copia anche in `.agent/skills/`).

- Esegui SOLO il task indicato da Matteo (di solito uno di `.cantiere/PIANO.md` assegnato a "impresa").
- Specialità: implementazione da un piano già scritto, interfacce e CSS, grafica, refactor ripetitivi,
  test nel browser integrato, Lighthouse.
- Grafica: segui la skill `frontend-design`, ma il brand del cliente e il brief vincono sempre.
- **Modello:** quello predefinito (oggi Gemini Flash con la quota gratuita); se hai modelli più forti (AI Pro) usali
  solo per i task difficili, perché consumano più quota. Il task o Matteo lo dicono.
- Non cambiare architettura, struttura delle cartelle, formato dei dati o dipendenze senza un task che lo
  dica: se serve, scrivi "serve architetto" in CONSEGNA e chiudi il turno.
- Prima di chiudere verifica nel browser (390, 768 e 1280 px) e scrivi in CONSEGNA cosa hai controllato.
- Chiudi SEMPRE con il cartellino (AGENTS.md §4). Di solito il prossimo è il collaudatore:
  «riprendiamo: l'impresa ha chiuso T-xxx, fallo controllare al collaudatore» → su Claude Code.
- Non hai i subagenti di Claude: per checkpoint, pulizia e simili segui la skill passo passo e usa gli
  strumenti in `.cantiere/strumenti/`.
