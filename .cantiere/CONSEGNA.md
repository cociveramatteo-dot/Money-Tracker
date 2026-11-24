# CONSEGNA — architetto · 2026-11-24 23:01

- **S-50 · progetto esecutivo della Protezione avanzata (E2E della sync):** `.cantiere/progetto-e2e-sync.md` (11 sezioni con indice). Nessun codice toccato.
- Decisioni chiave: tabella nuova `mt_vault` + `mt_e2e`; trigger SQL additivo che blocca le scritture in chiaro dei client vecchi; AES-256-GCM, PBKDF2-SHA256 600k, HKDF, chiave di recupero Crockford; DEK separata dalla password Supabase; payload = riga JSON di oggi (la logica di sync non cambia); migrazione con copia in chiaro congelata fino a verifica; interruttore spento fino a S-50p. Registrate in DECISIONI.md.
- Task creati in PIANO: S-50a…S-50m e S-50p (Claude Code, in ordine, 3 collaudi di blocco), S-50n e S-50o per Matteo ([?]).
- Unico passo manuale di Matteo: SQL del §6.2 (S-50n, istruzioni in PER-MATTEO.md). È inerte: si può fare quando vuole.
- Aperto: tutto l'esecuzione. Prossimo: S-50a (server finto) → operaio Claude Code, prompt nel progetto §10.3.
