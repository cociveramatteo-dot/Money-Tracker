# CONSEGNA — capocantiere · 2026-11-23 20:55

- **Android** (`03_CODICE/bucktrail-android`, commit d934e5b…0ec9d96): blocchi B0–B11 completati. Gate `assembleDebug assembleRelease lintDebug testDebugUnitTest` verde, ~250 test JVM + 2 strumentati. Parità grafica verificata a coppie con iOS (`.cantiere/android-parita-test.md`), stress test in `.cantiere/android-stress-test.md`. Specifica e checklist: `.cantiere/android-parita.md`; decisioni in `DECISIONI.md`.
- **Mai toccato il Supabase reale.** Sync provato solo con `scripts/fake-supabase.py`. Il build release senza `-PsupabaseUrl` punta al cloud vero.
- **Social:** Post 5–42 unificati in Post-5–15 (81 slide) in Drive `Da postare`; calendario in `SOCIAL/calendario-v2.md`, archivio v1 in `SOCIAL/archivio-v1/` e Drive `_archivio-v1`.
- **Pulizia (ok di Matteo):** tmp → magazzino `fuori-git/collaudi-2026-11-14`, due copie doppie del carosello di prova tolte, `.Rhistory` e `.agent/` rimossi.
- **Aperto:** collaudo e commissioni; Post-15 gesto da provare su iPhone; telefono Android vero (biometria, widget, notifiche programmate); prova sync reale a due dispositivi (serve OK di Matteo e account di prova); RTL non supportato; 4 rischi iOS §4.99 (pull non paginato ecc.); S-41/S-42/S-36 ancora da collaudare.
- Fuori dal commit: modifiche preesistenti a `AGENTS.md` e `archivio/modello-base/AGENTS.md`; `99_DA_SMISTARE/parita/` (screenshot, non versionati).
