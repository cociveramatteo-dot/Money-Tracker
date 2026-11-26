# CONSEGNA — 2026-11-26 18:27 · collaudatore (Claude Code · Sonnet)

- **S-50u [x]** · collaudo ok su `2c313aa`. Filtro `key_id=neq.<viva>` URL-encoded (Android `enc()`, iOS `.neq`), DELETE invariate `key_id=eq.<morta>`, nessun altro percorso di sync toccato, fake-supabase gestisce neq ed esclude chiavi nulle (come PostgREST). Due test nuovi significativi, nessun test esistente modificato.
- **S-50w [x]** · collaudo ok. `ecfc4f3` tocca solo `.cantiere/`: nessun `app/src/release` né cleartext nel manifest di release, nessun segreto (keystore di debug pubblico), proguard invariato.
- **Test rilanciati** · iOS unitari 187/187 (iPhone 18 Pro), Android `testDebugUnitTest` 324/324 (dopo pulizia di una cartella di cache Gradle kotlin-dsl corrotta in ~/.gradle, ambiente e non codice), fake-supabase 19/19. UI iOS non rilanciati: i 2 rossi del primo giro sono la stessa instabilità di S-50r e S-50u non tocca la UI.
- **PIANO** · S-50x era finito fra il titolo di S-50w e le sue note: spostato sotto.
- **File modificati fuori dal turno** · `graphify-out/` (output generato), lasciato fuori dal commit.

**Prossimo** · S-50x (Brevo SMTP) con Matteo, poi decisione di pubblicazione.
