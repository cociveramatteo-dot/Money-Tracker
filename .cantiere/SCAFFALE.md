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
| **mobile-native** | siti visti soprattutto da telefono: hover che restano attivi, flash al tocco, bug di 100vh, input che zoomano, safe area | siti solo desktop, app native | basso | emilkowalski/skills @ 64eb3de · MIT |
| **break-ui** | prima di una consegna: mette alla prova un componente con dati estremi (nomi lunghissimi, campi vuoti, emoji, testo non latino) | pagine con testi fissi e già approvati | medio (crea una demo temporanea) | emilkowalski/skills @ 64eb3de · MIT |
| **animate** | costruire un'animazione nuova scegliendo curva, durata e proprietà giuste (anche "non animare") | siti senza movimento | basso | emilkowalski/skills @ 64eb3de · MIT |
| **review-animations** | revisione severa delle animazioni prima della pagella; si attiva solo a mano (`/review-animations`) | siti senza animazioni | basso | emilkowalski/skills @ 64eb3de · MIT |
| **animation-performance** | animazioni che scattano o rallentano su telefono: proprietà giuste, niente lavoro sul thread principale | siti senza animazioni | basso | emilkowalski/skills @ 64eb3de · MIT |

Prove fatte il 10/11/2026 nel cantiere PROVA e controllo del 17/11/2026 (skill di TARTUFARM): `CONTROLLI.md`.

## Da controllare prima di entrare sullo scaffale
Nessuna. (Il 17/11/2026 controllate le 16 skill di TARTUFARM: esito in `CONTROLLI.md`.)

## Scartate
| Skill | Perché |
|---|---|
| notebooklm-skill (PleasePrompto) | browser che aggira i controlli di Google e salva la sessione dell'account nel cantiere |
| notebooklm-py (teng-lin) | canali interni non ufficiali di Google, cookie dell'intero account sul Mac (tolta il 10/11/2026) |
| notebooklm-session-recap | ruba le frasi-comando dell'azienda ("fammi un checkpoint", "riprendi il lavoro"); spostata in `AZIENDA/archivio/skill-globali/` |
| impeccable (pbakaus/impeccable 4.7.0) | programma chiuso da 17 MB dentro il cantiere (finisce in git), si installa da solo come hook che gira a ogni modifica, invia statistiche a impeccable.style, scarica aggiornamenti da GitHub. Per la grafica bastano frontend-design + web-design-guidelines |
| emil-design-eng, apple-design, animation-vocabulary, find-animation-opportunities, improve-animations, prototype (emilkowalski/skills) | sicure (solo istruzioni, MIT) ma doppioni: animate + review-animations coprono il lavoro dei nostri siti; emil-design-eng è lunghissima (pesa su ogni sessione). Si riprendono dalla fonte se un progetto le chiede |
| write-swift, animate-expo, ask-sonner, pick-ui-library (emilkowalski/skills) | sicure ma per Swift, React Native/Expo o librerie React: non per siti HTML/CSS/JS |

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
| `animate/LICENSE` | `4ff5bdb7887ec143` |
| `animate/RECIPES.md` | `129cddcba35dedac` |
| `animate/SKILL.md` | `4ce49ea635ec175b` |
| `animation-performance/LICENSE` | `4ff5bdb7887ec143` |
| `animation-performance/SKILL.md` | `6481e7a611b54c0d` |
| `break-ui/CATALOG.md` | `80522dcc81039bf3` |
| `break-ui/LICENSE` | `4ff5bdb7887ec143` |
| `break-ui/SKILL.md` | `fb126d176f3b6bf7` |
| `mobile-native/LICENSE` | `4ff5bdb7887ec143` |
| `mobile-native/SKILL.md` | `705e267bc47ea61e` |
| `review-animations/LICENSE` | `4ff5bdb7887ec143` |
| `review-animations/SKILL.md` | `9ceb5072ce5d5e51` |
| `review-animations/STANDARDS.md` | `2d2c28e9fe98dd55` |
