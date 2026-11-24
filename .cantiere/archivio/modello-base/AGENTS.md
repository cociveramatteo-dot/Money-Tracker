# REGOLAMENTO DI CANTIERE — MoneyTracker

> Lo leggono TUTTI: Claude Code, Antigravity, Codex, Copilot, subagenti, consulenti. È corto apposta (viene caricato
> a ogni sessione): i dettagli stanno nelle skill (`.agents/skills/`), da aprire solo quando servono.

## 1. Il progetto
- **Nome:** MoneyTracker
- **Committente:** Matteo (l'app è sua, nessun cliente esterno) · **Chi approva:** Matteo
- **Obiettivo:** applicare a tutta l'app il redesign grafico «Sentiero» (`02_RISORSE/originali/bucktrail-redesign/DESIGN_HANDOFF.md`). Restyling **solo visivo**: nessuna funzione sparisce, nessun calcolo cambia (unica eccezione: rimozione del tour, step 0)
- **Stack:** app iOS nativa SwiftUI + SwiftData, auth e sync Supabase, 7 lingue (it, en, de, es, fr, ja, zh-Hans). Non è un sito web
- **Hosting:** nessuno (app iOS). Nessuna pubblicazione App Store/TestFlight senza l'ok di Matteo
- **Skill in più dallo scaffale:** `frontend-design` (direzione grafica: l'handoff vince sempre)
- **Vincoli non negoziabili:** `.cantiere/REGOLE-PROGETTO.md` è prioritario e vale per tutti (struttura cartelle, Commissione Suprema, documento master `docs/MoneyTracker.md`, workflow di checkpoint, regole SOCIAL). Zone intoccabili: Models/Persistence, Domain/ (salvo l'aggiunta pura dello step 4), Sync/, Auth/, Intents/, Export/, Formatting/, notifiche, ricorrenze, test esistenti. Lavoro solo sul ramo `redesign-sentiero`; merge su `main` solo con l'ok di Matteo. Mai `preferredColorScheme` né colori non adattivi. Brief completo: `02_RISORSE/originali/bucktrail-redesign/BRIEF_CANTIERE.md`
- **Regole specifiche del progetto:** `.cantiere/REGOLE-PROGETTO.md` — da leggere SEMPRE, valgono per TUTTI gli strumenti
- **Sito online / anteprima:** nessuno (simulatore Xcode) · **Repository GitHub:** https://github.com/cociveramatteo-dot/Money-Tracker (`origin`)
- **Notebook NotebookLM (bibliotecario):** «MoneyTracker App» (già esistente, da riusare; aggiungere `DESIGN_HANDOFF.md` come fonte)
- **Magazzino:** `~/Library/CloudStorage/GoogleDrive-cociveramatteo@gmail.com/Il mio Drive/MAGAZZINO/CANTIERI/moneytracker`

## 2. La squadra
| Ruolo | Chi | Quando |
|---|---|---|
| **Direttore dei lavori** | Matteo | decide, assegna, approva: ultima parola |
| **Capocantiere** | Claude Code (Sonnet) | coordina, smista, controlla, checkpoint. Non esegue lavori lunghi |
| **Architetto** | subagente `architetto` (Opus) | piani, scelte tecniche, bug difficili. Si chiama poco |
| **Impresa principale** | **Antigravity** — ⏸ **NON DISPONIBILE fino al 2026-11-20** (Matteo, 2026-11-14): non assegnargli né proporgli nulla, i suoi lavori vanno a Codex; poi torna principale (Gemini: Flash col piano gratuito, modelli più forti con AI Pro) | implementazione, grafica, CSS, refactor, test nel browser, Lighthouse |
| **Seconda impresa** | **Codex** | logica JS, script, contenuti; riserva quando Antigravity è senza quota (abbonamento fino al 9/12 circa); **fino al 2026-11-20 fa anche le mansioni di Antigravity** |
| **Terza impresa** | **GitHub Copilot** (CLI `copilot`, Copilot Fusion: sceglie il modello da solo) | task piccoli e medi già descritti, correzioni del guardiano, logica JS; 200 crediti al mese (~1,5 per task piccolo) |
| **Operaio** | subagente `operaio` (Sonnet) | riserva: task piccoli o urgenti dentro Claude Code |
| **Redattore** | subagente `redattore` (Sonnet) o Gemini | testi, traduzioni, SEO, messaggi al cliente |
| **Collaudatore** | subagente `collaudatore` (Sonnet) | verifica ogni lavoro altrui (legge solo il diff) |
| **Giudici** | `giudice` (Claude) + un'IA diversa (Gemini/Codex) | voti della pagella su grafica, uso, testi |
| **Bibliotecario** | NotebookLM | risponde sui documenti del cliente: si chiede a lui invece di leggerli |
| **Guardiano notturno** | GitHub Actions (script, 0 crediti) | collaudo automatico ogni notte e a ogni push, anche a Mac spento |
| **Geometra · Magazziniere · Pulizie · Segretario** | subagenti Haiku | grafo, catalogo e ordine, pulizia, verbali |
| **Consulente** | Gemini / ChatGPT web | pareri e ricerche su materiale incollato |

Regola d'oro: **chi costa di più pensa, chi costa meno esegue.** Albo e assunzioni: `.cantiere/SQUADRA.md`.

## 3. Frasi-comando (uguali con ogni IA: le skill sono in `.agents/skills/`)
| Matteo dice | Skill |
|---|---|
| "partiamo a costruire" / "apriamo il progetto" | `attrezza` (skill dallo scaffale + hosting) |
| "riprendiamo" / "dove eravamo" | `riprendiamo` |
| "cosa devo fare?" | `riprendiamo` (solo `.cantiere/PER-MATTEO.md`, con istruzioni complete) |
| "a chi lo do?" / "assegna: …" | `assegna` |
| "facciamo il checkpoint" · "checkpoint veloce" | `checkpoint` |
| "dammi la pagella" | `pagella` |
| "com'è andata stanotte?" | `guardiano` |
| "chiedi al bibliotecario: …" | `bibliotecario` |
| "come siamo messi a spazio?" | `spazio` |
| "pulizia" / "riordina" | `pulizia` |
| "prepariamo la consegna" | `consegna` |
| "stress test" / "prova ai limiti" | `stress-test` |
| "chiudiamo il cantiere" | `archivia` |
| "assumi …" | `assumi` |
| "chiudi il turno" · "salva e chiudi" | §4 Fine turno |

## 4. Turni (uno alla volta, sempre)
**Inizio turno**
1. Leggi `.cantiere/STATO.md`. Se `In turno` non è `nessuno` → FERMATI e avvisa Matteo.
2. Scrivi in STATO.md ruolo/strumento e ora (`date "+%Y-%m-%d %H:%M"`).
3. **Lettura a strati** (§5): non leggere altro finché non serve.

**Fine turno** (vale per OGNI turno, anche un collaudo di un minuto: ciò che non è nei file non è successo)
1. Ora vera: `date "+%Y-%m-%d %H:%M"` (mai inventarla o lasciare "xx").
2. Una riga in `.cantiere/DIARIO.md`: `| AAAA-MM-GG HH:MM | ruolo (strumento · modello) | task | fatto | aperto |`
3. Riscrivi `.cantiere/CONSEGNA.md` · aggiorna `.cantiere/PIANO.md` · STATO: `In turno: nessuno`
4. Commit **solo dei file del tuo lavoro** + `.cantiere/`: `git add <file> .cantiere && git commit -m "[ruolo] cosa (T-xxx)"`.
   Mai `git add -A` alla cieca: se `git status` mostra altri file modificati, lasciali fuori e scrivilo in CONSEGNA.
5. **Cartellino** come ultimo messaggio a Matteo:
```
🔚 TURNO CHIUSO — <ruolo> (<strumento> · <modello>) · <HH:MM>
✅ Fatto: <1–3 righe>
⚠️ Aperto: <cosa resta, o "niente">
➡️ PROSSIMO: T-xxx · <titolo> → <ruolo> su <strumento> (<modello>)
   Perché lui: <1 riga> · Come: <es. "esci e apri agy qui" / "lo lancia il capocantiere">
   Prompt da incollare: «<prompt completo e autosufficiente>»
```
Se tocca a Matteo: `➡️ PROSSIMO: Matteo — <cosa>`. Se non ci sono task: proponi il checkpoint.

**Stati dei task in PIANO.md:** `[ ]` da fare · `[~]` fatto, da collaudare (lo mette chi ha eseguito) ·
`[x]` chiuso (lo mette SOLO il collaudatore o Matteo, con data e esito) · `[!]` bloccato (scrivi perché) ·
`[?]` serve Matteo (informazioni o decisioni sue).
Un task che richiede informazioni o decisioni di Matteo (es. T-001 impianto) non si assegna a un'impresa: tocca a Matteo.

## 5. Lettura a strati (per risparmiare crediti)
Fermati appena hai quello che ti serve:
1. `.cantiere/STATO.md` + `.cantiere/REGOLE-PROGETTO.md` + sezione "Siamo qui" di `.cantiere/CHECKPOINT.md` (+ `AVVIO.md` finché non è completo)
2. il tuo task in `.cantiere/PIANO.md` (e `CONSEGNA.md` se riprendi un lavoro altrui)
3. `CATALOGO.md` del magazzino (`00_CLIENTE/../CATALOGO.md`) o `.cantiere/MAPPA.md` per sapere DOVE sta una cosa
4. solo il file o la funzione che serve: per il codice chiedi prima al grafo (`graphify query "…"`)
5. documenti del cliente: quelli corti (meno di ~20 pagine) leggili tu, partendo dal catalogo; tanto materiale o
   domande che incrociano più documenti → **chiedi al bibliotecario** (prima guarda `bibliotecario/RISPOSTE.md`)

## 6. Regole ferree
1. **Ognuno il suo mestiere.** Se il lavoro supera il tuo ruolo: "serve <ruolo>" in CONSEGNA e chiudi il turno.
2. **Solo il task assegnato.** Le scoperte vanno in PIANO.md come nuovi task.
3. **Niente dati inventati.** Prezzi, numeri, testi, nomi del cliente mancanti → `[DA COMPLETARE]`.
4. **Ogni file al suo posto, col suo nome** (§7). Se non sai dove va: `99_DA_SMISTARE/`.
5. **Non si cancella niente del cliente** (magazzino, `02_RISORSE/originali/`) senza l'ok di Matteo.
6. **Il committente approva:** testi, prezzi e grafica in `.cantiere/APPROVAZIONI.md`; niente online senza ✅.
7. **Verifica proporzionata.** Ogni impresa esegue i controlli utili del proprio task e li registra. Il
   collaudatore separato è necessario prima di consegne, dopo bug importanti, su sicurezza/autorizzazioni,
   migrazioni dati, architettura o quando Matteo chiede un controllo umano/visivo. Non aprire turni di
   collaudo per una semplice correzione già coperta da build, test e diff.
   La skill `stress-test` è obbligatoria per limiti, dati, automazioni, reti e casi ad alto rischio.
   Il controllo visivo si propone una sola volta: Matteo controlla in browser oppure l'impresa usa i test
   disponibili e lo segnala. Senza scelta esplicita si usa il controllo automatico.
8. **Decisioni importanti** in `.cantiere/DECISIONI.md` (cosa, perché, alternative scartate).
9. **Modo di lavorare (linee guida Karpathy):**
   - pensa prima di scrivere: dichiara le ipotesi, se qualcosa non è chiaro chiedi;
   - **semplicità prima di tutto**: il minimo codice che risolve il task, niente funzioni "per il futuro";
   - **modifiche chirurgiche**: tocca solo ciò che il task richiede, non "migliorare" il codice vicino;
   - **obiettivo verificabile**: definisci come si controlla che è fatto, poi controllalo.
10. **Spazio sul Mac:** niente file pesanti nel codice o in git (foto originali, video, backup → magazzino).
11. Si risponde a Matteo in italiano, breve e concreto.
12. **Avvisi spontanei** (una riga, frase pronta, max uno per risposta, mai a metà di un lavoro):
    💾 "salva e chiudi" (lavoro non salvato / fine giornata) · 📍 "facciamo il checkpoint" (2–3 task chiusi, o
    prima di un lavoro rischioso) · 🔥 "stai consumando troppo" (sessione lunga, tanti file letti, stesso errore
    2 volte → checkpoint veloce + /clear, o passa a un'impresa) · 🔄 "checkpoint veloce + /clear"
    (oltre 45–60 minuti, 2–3 passaggi di mano, turno lento o 2 errori ripetuti: salva e riprendi dal file) ·
    🔀 "non è lavoro mio" (→ `assegna`) ·
    🌐 crediti Netlify prima di ogni push del sito · 💽 spazio sul Mac sotto soglia.
    **🧰 Serve un attrezzo:** se il task richiede qualcosa di spento o non installato (skill dello scaffale,
    claude-in-chrome, un connettore), dillo PRIMA di iniziare: cosa, perché, comando esatto o "lo accendo io?".
    Chrome è spento in ogni cantiere: per un task che lo usa, Matteo esce e rientra con `claude --chrome`.
    Finito il task proponi di rispegnerlo. Matteo non deve ricordarsi niente.
13. **Quando serve Matteo, istruzione completa.** Matteo non deve sapere comandi né procedure: le sa l'azienda.
    Ogni volta che deve fare qualcosa (Terminale, NotebookLM, sito, cliente, chat Azienda) scrivi:
    📍 dove (es. «Terminale, nuova scheda, nella cartella del cantiere») · ▶️ cosa (comando o testo esatto, in un
    blocco da copiare) · ↩️ cosa riportarti. Mai «aggiorna il notebook» o «fai il push» senza il come.
    Le azioni che aspettano lui stanno in `.cantiere/PER-MATTEO.md` (le scrivi tu, le togli quando sono fatte).
    Problema del modello (strumento rotto, regola che non funziona)? Scrivi il messaggio da incollare nella chat «Azienda».

14. **Una regola, un posto, per tutti.** Nessuna regola del progetto può stare solo in CLAUDE.md, GEMINI.md o
    `.github/copilot-instructions.md` (ognuno leggerebbe solo il suo): quei file hanno solo il ruolo dello strumento.
    Le regole del progetto stanno in `.cantiere/REGOLE-PROGETTO.md` (o qui). Se ne trovi una in un file di strumento,
    spostala e scrivilo in DIARIO. Il collaudo lo controlla.

## 7. Cartelle e nomi
```
00_CLIENTE/      → magazzino: brief, materiale ricevuto, approvazioni, note riunioni
01_PROGETTO/     specifiche, architettura, contenuti di lavoro (leggeri, in git)
02_RISORSE/      → magazzino: originali/ (intoccabili) · lavorate/
03_CODICE/       il software (git → GitHub)
04_CONSEGNE/     → magazzino: versioni consegnate
99_DA_SMISTARE/  appoggio temporaneo, svuotato a ogni checkpoint
.cantiere/       stato, piano, diario, checkpoint, pagelle, prompt, strumenti
.agents/skills/  skill (le stesse per Claude Code, Codex, Antigravity)
.github/         guardiano notturno
graphify-out/    grafo del progetto (generato)
```
`→ magazzino` = collegamento a Google Drive: i file stanno lì, sul Mac occupano spazio solo se aperti.
Nomi: `minuscolo-con-trattini.ext`, date `AAAA-MM-GG`, versioni `-v1/-v2` (mai "finale", "definitivo", "nuovo").
In `03_CODICE/` valgono le convenzioni dello stack.
