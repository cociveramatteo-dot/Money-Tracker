# CONSEGNA — 2026-11-27 13:26 · impresa (Codex · GPT-6)

## Lavoro completato [~]

- **S-51g** · `8aa349e`. Un pull senza conti rimuove l’ultimo conto sincronizzato cancellato altrove. I conti in attesa del primo push sono preservati. I test verificano che un push successivo non resusciti il conto.
- **S-51e** · `dd09649`. Il preflight della disattivazione usa la base a tre vie nel vault. Le regressioni verificano sia le cancellazioni note nei due sensi, sia una nuova riga remota arrivata durante la disattivazione. La riga entra nella copia locale e in quella in chiaro e viene verificata.
- **S-51h** · ultimo commit del turno. Il test t10 annulla e attende il push debounced prima del conteggio. Le asserzioni del test sono integre.

## Verifiche

- Build Debug iOS e 54 test mirati in nove suite con `-only-testing`, su iPhone 18 Pro (iOS 27.2). Tre ripetizioni consecutive di t10.
- Android `./gradlew testDebugUnitTest assembleDebug`, con Java 17 e SDK Android impostati. 334 test verdi.
- Prova reale `prova-due-dispositivi.py` su Supabase con simulatori isolati, 12/12. Protezione finale disattivata e record preesistenti presenti. Riassunto senza credenziali in `/tmp/moneytracker-s51-prova-due-dispositivi-2026-11-27.md`.
- Lo schema Xcode e `graphify-out/` avevano modifiche locali precedenti al turno e sono fuori dai commit. Il grafo è stato aggiornato localmente.

## Prossimo

Collaudo indipendente di S-51g, S-51e e S-51h. Verificare i tre commit sul ramo redesign-sentiero e registrare l’esito in PIANO e DIARIO.
