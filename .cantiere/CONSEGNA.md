# CONSEGNA — S-50j · Protezione avanzata iOS

Turno chiuso il 2026-11-25 21:52 da impresa (Codex · GPT-6), ramo `redesign-sentiero`.

- S-50j [~]. Otto schermate Sentiero, riga in Sicurezza e richiesta automatica di sblocco una volta per sessione. Il controller usa il migratore esistente. Interruttore di produzione spento, attivazione solo nelle prove DEBUG con remoto in memoria.
- T15. Le 49 chiavi di §5.3 sono presenti in it, en, de, es, fr, ja e zh-Hans. T16 e prove mirate sulla build finale in inglese chiaro: sei test UI verdi, inclusi assenza di rete, annullamento dopo interruzione e rifiuto di associare una nuova chiave a una migrazione precedente. Suite iOS completa: 158 unitari e 55 UI verdi (`full.xcresult`).
- Screenshot su iPhone 18 Pro in `.cantiere/tmp/e2e-ios/screenshots/` e `/tmp/e2e-ios/`. Le cartelle prima e dopo contengono il confronto al pixel della sezione Sicurezza con il flag spento. In `after/` ci sono 84 immagini degli otto passaggi in italiano e inglese, chiaro e scuro, più tedesco scuro Dynamic Type XL. Le prove mirate in italiano scuro e tedesco XL sono verdi.
- Da riprendere al collaudo di blocco 3: il giro aggiuntivo in inglese scuro ha prodotto le immagini di tutti gli otto passaggi, ma il test di attivazione è stato interrotto da una perdita di connessione di XCTest al simulatore anche al secondo giro. Cambio frase e sblocco in inglese scuro sono verdi. Le prove UI usano un'autenticazione del dispositivo simulata. Risultati e log in `.cantiere/tmp/e2e-ios/`.
- Scelte di interfaccia: il contatore usa le tappe del migratore. La copia della chiave resta negli appunti locali per due minuti, con condivisione esplicita tramite il foglio nativo. Versioni server sconosciute mostrano K43 senza proporre un ripristino distruttivo.
- Il grafo è stato aggiornato. I file già modificati in `graphify-out/`, le copie locali e gli artefatti di prova restano fuori dal commit.
- D-014: approvazione delle schermate in S-50o, dopo S-50m. S-50h2 e S-50q restano obbligatori prima di S-50p. Nessun push.

➡️ Prossimo: S-50k · interfaccia Android e testi in sette lingue → capocantiere/operaio Claude Code (Sonnet), secondo il piano. Riferimento iOS in `MoneyTracker/Views/E2E/` e screenshot sopra. Dopo S-50k viene S-50l, poi il collaudo del blocco 3.
