# SCAFFALE DELLE SKILL

Skill controllate che NON vanno in tutti i cantieri: si scelgono progetto per progetto, perché ogni skill
installata pesa su ogni sessione di ogni IA (la sua descrizione viene letta sempre).

- **Standard (sempre, senza chiedere):** le skill dell'azienda (riprendiamo, assegna, checkpoint, pagella,
  guardiano, bibliotecario, spazio, pulizia, consegna, archivia, assumi, attrezza) + graphify.
- **Dallo scaffale:** le propone il capocantiere quando Matteo dice "partiamo a costruire" (skill `attrezza`),
  o durante il lavoro quando servono (regola 🧰). Matteo approva; si installano con il comando
  `attrezza <nome>` dal Terminale, dentro la cartella del cantiere. Si tolgono con `attrezza --togli <nome>`
  (finiscono in `.cantiere/archivio/skill-tolte/`, non si cancellano).
- **Si aggiornano solo dalla chat "Azienda":** nuova fonte → controllo del codice → impronte qui sotto.

## Catalogo

| Skill | Serve per | Non serve per | Peso | Fonte (versione fissata) · licenza |
|---|---|---|---|---|
| **frontend-design** | siti e pagine con grafica curata, landing, restyling | app senza interfaccia, script, contenuti | basso | anthropics/skills @ 2c5958e · Apache-2.0 |
| **web-design-guidelines** | revisione di interfacce web: accessibilità, form, tipografia, focus | progetti senza interfaccia web | basso | vercel-labs/agent-skills @ 1a2c79d + regole @ 434b7f9 · MIT · *modificata: legge `regole.md` locale, niente download* |
| **grill-me** + **grilling** | inizio di un progetto con idea ancora vaga, prima di un lavoro grosso: domande a raffica con risposta consigliata finché il piano è chiaro | modifiche piccole, task già scritti nel PIANO | costosa (lancia subagenti): solo quando serve, si attiva a mano (`/grill-me`) | mattpocock/skills @ 4ae2317 · MIT |
| **caveman** | sessioni lunghe di codice col capocantiere: risposte telegrafiche, meno crediti in uscita (`/caveman`, `stop caveman`) | testi per il cliente, spiegazioni a Matteo | basso | JuliusBrussee/caveman @ 3dc497a · Apache-2.0 · *modificata: tolti rimandi a skill non incluse; cartellino e messaggi al cliente restano completi* |

Prove fatte il 10/11/2026 nel cantiere PROVA: `CONTROLLI.md`.

## Da controllare prima di entrare sullo scaffale
Skill già presenti in TARTUFARM, di fonti non ancora controllate: impeccable, animate, animate-expo,
animation-performance, animation-vocabulary, apple-design, ask-sonner, break-ui, emil-design-eng,
find-animation-opportunities, improve-animations, mobile-native, pick-ui-library, prototype,
review-animations, write-swift. Restano dove sono finché non le controlla la chat Azienda.

## Scartate
| Skill | Perché |
|---|---|
| notebooklm-skill (PleasePrompto) | browser che aggira i controlli di Google e salva la sessione dell'account nel cantiere |
| notebooklm-py (teng-lin) | canali interni non ufficiali di Google, cookie dell'intero account sul Mac (tolta il 10/11/2026) |
| notebooklm-session-recap | ruba le frasi-comando dell'azienda ("fammi un checkpoint", "riprendi il lavoro"); spostata in `AZIENDA/archivio/skill-globali/` |

## Impronte (sha256, primi 16 caratteri)
| File | Impronta |
|---|---|
| `caveman/LICENSE` | `cfc7749b96f63bd3` |
| `caveman/SKILL.md` | `8129ddbebe493322` |
| `frontend-design/LICENSE.txt` | `0d542e0c8804e39a` |
| `frontend-design/SKILL.md` | `d91970639e9f5c37` |
| `grill-me/LICENSE` | `0e7ac423bf2c6e22` |
| `grill-me/SKILL.md` | `caaf8b8de1684f96` |
| `grill-me/agents/openai.yaml` | `c061e39c3e0f9d86` |
| `grilling/LICENSE` | `0e7ac423bf2c6e22` |
| `grilling/SKILL.md` | `a146842ed93ca43d` |
| `grilling/agents/openai.yaml` | `1411d7df7d99b7e6` |
| `web-design-guidelines/LICENSE.txt` | `6cd1609c9c122335` |
| `web-design-guidelines/SKILL.md` | `2c31df6f48b27ac8` |
| `web-design-guidelines/regole.md` | `d246b026f4f29b58` |
