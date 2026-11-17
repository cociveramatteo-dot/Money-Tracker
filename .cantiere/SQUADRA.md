# SQUADRA — organigramma, smistamento e albo delle assunzioni

## Squadra fissa
Vedi AGENTS.md §2. Subagenti Claude in `.claude/agents/`, skill in `.agents/skills/`.

## Smistamento (chi fa cosa) — regola: il più economico che lo fa bene
| Lavoro | Chi | Note |
|---|---|---|
| Capire un progetto nuovo, scrivere il piano | architetto (Opus) | una volta; poi si lavora sul piano |
| Scelte di tecnologia, struttura, formato dati | architetto | in DECISIONI.md |
| Implementare task già descritti (HTML, CSS, JS, sezioni) | **impresa principale: Antigravity** (Gemini, modello predefinito) | il grosso del lavoro |
| Task difficili di implementazione | Antigravity col modello più forte disponibile (con AI Pro), altrimenti Codex | quota Google/OpenAI, non Claude |
| Grafica, varianti, animazioni, responsive | Antigravity | skill `frontend-design`, il brand vince |
| Test visivi nel browser, Lighthouse a mano | Antigravity | |
| Logica JS, script, dati, Google Sheet | **seconda impresa: Codex** | fino al 9/12 circa; poi Copilot |
| Task piccoli e medi già descritti, correzioni del guardiano | **terza impresa: Copilot** (`copilot`, Fusion) | ~1,5 crediti per task piccolo su 200 al mese; niente task grossi |
| Refactor lunghi e ripetitivi | Antigravity o Codex | poi collaudatore |
| Task piccolo urgente / imprese senza quota | operaio (Sonnet) | riserva |
| Testi, traduzioni, SEO, messaggi al cliente | redattore (Sonnet) o Gemini app | in APPROVAZIONI prima di andare online |
| Domande sui documenti del cliente | **bibliotecario: NotebookLM** | invece di leggere i documenti |
| Verifica di ogni lavoro | collaudatore (Sonnet) | legge solo il diff |
| Voti grafica / uso / testi | giudice (Claude) + Gemini o Codex | prima delle consegne |
| Collaudo automatico, dispositivi, link, monkey test | **guardiano** (GitHub Actions) | 0 crediti, anche a Mac spento |
| Grafo, catalogo, pulizia, verbali | geometra, magazziniere, pulizie, segretario (Haiku) | al checkpoint |
| Pareri, ricerche, seconda opinione | consulente (Gemini Deep Research / ChatGPT) | materiale incollato |

## Quando un'IA è senza quota
Antigravity → Codex → Copilot → operaio. Copilot senza crediti (si azzerano il 1° del mese): si ferma da solo, non addebita niente. Claude senza quota → si lavora solo con Antigravity/Codex (seguono AGENTS.md) e il collaudo aspetta.

## Albo delle assunzioni
| Data | Nome | Cosa è | Mansione | Costo | Limiti | Stato |
|---|---|---|---|---|---|---|
| 2026-11-13 | graphify | skill + CLI | grafo del progetto (geometra) | gratis, locale | — | in squadra |
| 2026-11-13 | frontend-design | skill (Anthropic) | direzione grafica | gratis | il brand del cliente vince | in squadra |
| 2026-11-13 | web-design-guidelines | skill (Vercel) | regole UX/accessibilità per giudici e collaudo | gratis | regole pensate per React | in squadra |
| 2026-11-17 | GitHub Copilot | CLI (Copilot Student) | terza impresa | gratis, 200 crediti/mese | modello scelto da Fusion; budget extra $0 | in squadra |
