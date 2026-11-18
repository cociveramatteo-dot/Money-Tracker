---
name: assumi
description: Aggiunge alla squadra del cantiere una nuova IA, agente, subagente, skill, server MCP o strumento, con colloquio, prova ed esito. Usala quando Matteo dice "assumi", "aggiungiamo alla squadra", "mi serve qualcuno che…".
---
# Assumi

1. **Colloquio** (max 3 domande): mansione scoperta? costo? solo questo cantiere o tutta l'azienda?
2. **Controllo di sicurezza** (obbligatorio per skill e MCP di terzi): leggi SKILL.md e TUTTI gli script;
   cerca chiamate di rete, telemetria, comandi distruttivi, istruzioni che scavalcano le regole. Preferisci
   fonti ufficiali e mantenute. Niente installazioni con `curl | bash` senza aver letto lo script.
3. **Contratto**: riga nell'albo di `.cantiere/SQUADRA.md` (stato `in prova`) + riga nella tabella di smistamento.
4. **Postazione**: skill → `.agents/skills/<nome>/` (versione fissata, niente download a ogni uso);
   subagente Claude → `.claude/agents/<nome>.md`; MCP → `.mcp.json`, annotando cosa può toccare;
   IA esterna → prompt in `.cantiere/prompt/<NOME>.md`.
5. **Prova**: un task piccolo e reversibile, verificato dal collaudatore.
6. **Esito**: `in squadra` o `licenziato` (rimuovi la postazione). Annota in DECISIONI.md.
7. **Per tutta l'azienda**: ricorda a Matteo di portarlo nella chat Azienda, così entra nella dotazione
   standard (`AZIENDA/modello/dotazione/`) e in ogni cantiere con `aggiorna-cantiere`.
