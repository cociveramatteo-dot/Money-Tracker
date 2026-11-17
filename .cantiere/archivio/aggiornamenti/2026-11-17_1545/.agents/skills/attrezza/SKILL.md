---
name: attrezza
description: Sceglie gli attrezzi di un progetto all'avvio (skill dallo scaffale dell'azienda, hosting, stack) o quando a metà lavoro serve un attrezzo spento. Usala quando Matteo dice "partiamo a costruire", "apriamo il progetto", "che skill ci servono?", o quando un task richiede una skill, Chrome o un connettore che il cantiere non ha.
---
# Attrezza (scelta degli attrezzi)

Ogni skill installata pesa su OGNI sessione di ogni IA: nel cantiere solo quello che serve davvero.

0. **Avvio guidato**: a "partiamo a costruire" segui `.cantiere/AVVIO.md` voce per voce (questa skill è la voce 2):
   UNA voce alla volta, ognuna con istruzioni complete per Matteo (📍 dove · ▶️ cosa · ↩️ cosa riportare), e la
   spunti quando è fatta. Alla voce 5 (bibliotecario) lancia `python3 .cantiere/strumenti/biblioteca.py` e dai a
   Matteo: nome del notebook, dove crearlo (notebooklm.google.com → Crea nuovo), le fonti esatte da aggiungere;
   quando ti incolla il link, scrivilo in AGENTS.md §1 e lancia `biblioteca.py --segna <file>…`.
1. Leggi AGENTS.md §1, il brief (via `CATALOGO.md` del magazzino o chiedi al bibliotecario) e
   `.cantiere/SCAFFALE.md` (catalogo con "serve per / non serve per"). Elenco di cosa c'è già: `ls .agents/skills`.
2. Proponi a Matteo, in massimo 12 righe:
```
🧰 Attrezzi per <progetto>
🌐 Hosting: GitHub Pages (standard) — oppure Netlify/altro SOLO se serve: redirect 301 da un sito vecchio,
   moduli, intestazioni, anteprime separate → scrivi il motivo
🧱 Stack: HTML/CSS/JS statico (standard) — oppure altro col motivo
➕ Dallo scaffale: <skill> — perché · <skill> — perché   (max 3–4; "nessuna" va benissimo)
➖ Da togliere: <skill non standard già nel cantiere che qui non servono> (se ce ne sono)
▶️ Comando per Matteo (Terminale, nella cartella del cantiere):
   attrezza <skill> <skill>        ·  attrezza --togli <skill>
```
3. Al sì di Matteo: lui lancia il comando (tu non puoi leggere lo scaffale fuori dal cantiere). Poi scrivi
   Hosting e Stack in AGENTS.md §1 e la scelta in `.cantiere/DECISIONI.md` (cosa, perché, alternative).
   La riga "Skill in più" la aggiorna il comando da solo.
4. A metà lavoro (regola 🧰): stessa cosa per un solo attrezzo, PRIMA di iniziare il task. Chrome e
   connettori: in Claude Code `/mcp` → selezionalo → Enable (e Disable a fine task).
- **Non fare:** installare skill che non sono sullo scaffale (vanno prima controllate dalla chat Azienda).
