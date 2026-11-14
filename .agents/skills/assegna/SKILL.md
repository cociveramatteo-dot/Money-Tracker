---
name: assegna
description: Decide a quale membro della squadra dare un lavoro (Antigravity, Codex, architetto, operaio, redattore, collaudatore, bibliotecario, consulente) e prepara il prompt pronto. Usala quando Matteo chiede "a chi lo do?", "assegna: …" o chiede un lavoro nuovo.
---
# Assegna

1. Se il lavoro non è in `.cantiere/PIANO.md`, scrivilo come task AUTOSUFFICIENTE (modello in fondo a PIANO.md):
   obiettivo, file da leggere/toccare, criteri di "fatto", cosa non fare. Lavori misti → più task.
   Se il task richiede informazioni o decisioni di Matteo (impianto, testi da approvare, scelte del cliente) NON
   si assegna: segnalo `[?]` e rispondi "tocca a te: <domande precise>".
   Se serve un attrezzo spento o non installato (skill dello scaffale, Chrome, un connettore) dillo qui (AGENTS.md §6.12 🧰).
2. Scegli con la tabella di `.cantiere/SQUADRA.md`: **il più economico che lo fa bene**. Per ESEGUIRE (codice,
   CSS, testi, correzioni) la proposta principale è SEMPRE un'impresa: Antigravity → Codex. **Antigravity è sospeso fino al 2026-11-20 (Matteo): salta direttamente a Codex, non proporlo né preparargli prompt.** Dal 2026-11-21 torna normale (controlla la data con `date`). L'operaio (Claude)
   solo come riserva dichiarata ("se le imprese sono senza quota"), mai come prima scelta, anche per task brevi.
   Claude (capocantiere/architetto) solo per pensare e controllare.
3. **Prima di scrivere un prompt per un'impresa** leggi la sezione "Come si costruisce" di `.cantiere/MAPPA.md`
   (se è vuota compilala tu: guarda `package.json`, gli script di build, quali cartelle sono generate). Il task
   deve dire quali file sono sorgenti e quali generati (mai modificare a mano i generati) e citare SOLO comandi
   che esistono davvero nel progetto.
4. Rispondi:
```
📋 T-xxx · <titolo>
👷 A chi: <ruolo> su <strumento> (<modello>) — perché: <1 riga>
💸 Peso sulla quota Claude: nullo / basso / medio / alto
▶️ Come: <una delle opzioni sotto>
```
- **Impresa (Antigravity / Codex)**: copia il prompt di `.cantiere/prompt/IMPRESA.md` PAROLA PER PAROLA,
  cambiando solo il numero del task (le istruzioni specifiche stanno nel task in PIANO.md, non nel prompt; al massimo
  una riga "Nota:" in fondo). Poi chiudi il turno (cartellino).
- **Subagente Claude**: "lo lancio?" → al sì delega passandogli SOLO il testo del task.
- **Bibliotecario**: usa la skill `bibliotecario`.
- **Consulente**: prompt di `.cantiere/prompt/CONSULENTE.md` già compilato con il materiale.
5. Se serve un modello diverso dillo chiaro (es. "in Antigravity scegli il modello più forte per questo task", se l'abbonamento lo permette).
