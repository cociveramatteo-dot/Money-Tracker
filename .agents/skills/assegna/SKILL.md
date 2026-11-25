---
name: assegna
description: Decide a quale membro della squadra dare un lavoro (Antigravity, Codex, Copilot, architetto, operaio, redattore, collaudatore, bibliotecario, consulente) e prepara il prompt pronto. Usala quando Matteo chiede "a chi lo do?", "assegna: …" o chiede un lavoro nuovo.
---
# Assegna

1. Se il lavoro non è in `.cantiere/PIANO.md`, scrivilo come task AUTOSUFFICIENTE (modello in fondo a PIANO.md):
   obiettivo, file da leggere/toccare, criteri di "fatto", cosa non fare. Lavori misti → più task.
   Se il task richiede informazioni o decisioni di Matteo (impianto, testi da approvare, scelte del cliente) NON
   si assegna: segnalo `[?]` e rispondi "tocca a te: <domande precise>".
   Se serve un attrezzo spento o non installato (skill dello scaffale, Chrome, un connettore) dillo qui (AGENTS.md §6.12 🧰).
2. Raggruppa solo lavori correlati, brevi e descritti senza ambiguità: può essere un unico prompt per 2–3 task
   all'impresa che ha già il contesto. Se un'attività richiede una scelta architetturale, è separata.
   Scegli con la tabella di `.cantiere/SQUADRA.md`: **il più economico che lo fa bene**. Per ESEGUIRE (codice,
   CSS, testi, correzioni) la proposta principale è SEMPRE un'impresa: Antigravity → Codex → Copilot
   (Copilot per task piccoli e medi ben descritti: costa crediti mensili, non task grossi). L'operaio (Claude)
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
- **Impresa (Antigravity / Codex / Copilot)**: copia il prompt di `.cantiere/prompt/IMPRESA.md` PAROLA PER PAROLA (per Codex: «esci e lancia `codex --yolo -C <cartella-del-cantiere>`», sempre con `--yolo`; per Copilot: «esci e apri `copilot` qui»; al primo avvio «sì» alla fiducia nella cartella),
  cambiando solo il numero del task (le istruzioni specifiche stanno nel task in PIANO.md, non nel prompt; al massimo
  una riga "Nota:" in fondo). Poi chiudi il turno (cartellino).
- **Subagente Claude**: "lo lancio?" → al sì delega passandogli SOLO il testo del task.
- **Bibliotecario**: usa la skill `bibliotecario`.
- **Consulente**: prompt di `.cantiere/prompt/CONSULENTE.md` già compilato con il materiale.
5. Se serve un modello diverso dillo chiaro (es. "in Antigravity scegli il modello più forte per questo task", se l'abbonamento lo permette).
