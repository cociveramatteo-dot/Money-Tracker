# CONSEGNA — collaudo E2E S-50h2, S-50l.2, S-50q, S-50q.1

Collaudatore (Claude Code · Sonnet), 2026-11-26 11:01 · ramo `redesign-sentiero` · commit collaudati 8a5020b, 1492143, 668b0e1.

- **Chiusi [x]:** S-50h2, S-50l.2, S-50q (parte client), S-50q.1 (parte client).
- **Test rieseguiti:** 173 unitari iOS (timeout 180 s per test), 6 UI della suite E2EUITests, 313 JVM Android + `lintDebug` (rieseguiti con `--rerun`), 19 test HTTP del server finto. Tutti verdi.
- **Zone intoccabili:** `Auth/SupabaseManager.swift` e `SyncService` (iOS e Android) sono modifiche minime e inerte a interruttore spento. La rimozione della pulizia dopo `delete_own_account` però cambia il progetto (R9): aperto **S-50q.3 [?]**, serve una verifica SQL di Matteo.
- **Nuovo difetto:** **S-50q.2** (MEDIA). Se D7 si interrompe e un altro dispositivo riattiva, le righe di una chiave morta restano nel vault e bloccano la pull normale su tutti i dispositivi. → Codex.
- **Interruttori:** spenti in release (iOS `#else isEnabled = false`, Android release `E2E_ENABLED=false`). Simulatori spenti, colima spento. Resta acceso un demone Gradle che non ho lanciato io (ho usato `--no-daemon`).
- Le modifiche preesistenti in `graphify-out/` restano fuori dal commit.

➡️ **Prossimo:** S-50q.2 → Codex. In parallelo S-50q.3 → Matteo (una query in SQL Editor). S-50p resta bloccato da entrambi.
