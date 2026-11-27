# STATO DEL CANTIERE

In turno: nessuno
Ultimo checkpoint: 2026-11-27 13:36 (checkpoint-2026-11-27-1336, veloce)
Fase: progetto SOCIAL, post 1 pubblicato il 19/11 su Instagram e TikTok, primo rilevamento registrato; post 2 F13 pubblicato su Instagram e TikTok, formato faceless. Ramo redesign-sentiero (da portare su main con l'ok di Matteo). Fix curva Home S-36 da chiudere.
Social: direttive in `SOCIAL/direttive-social.md`; Post-3 «Guida: HOME» approvato come tema, sequenza e impostazione delle slide 2–3; data e grafica finale da confermare. Post-4–12 approvati come tema e sequenza. Intero piano fino al Post-42 approvato da Matteo con copertura dell’app. Archivio permanente locale in `SOCIAL/schermate-app/`.
S-41: competenza mensile delle spese fisse singole in Home, implementata e verificata con la suite BalanceTrailTests e una prova mirata; da collaudare in UI.
S-42: annullamento eliminazione serie e layout Ultimi movimenti verificati in modalità demo su iPhone 18 Pro.
SC-4c: landing pubblicata e verificata su bucktrailapp.com in italiano e inglese. SC-3c: testi approvati, bio aggiornate da Matteo, messaggio fissato per i prossimi post. Matteo conferma anche post fissato e banner YouTube aggiornati; email di lancio rimandata.
SC-9: Post-3–42 in Drive. Post-23–42 esportati e verificati, 103 slide con Bucktrail su 120. I LEGGIMI di Post-39 e 41 segnalano le verifiche prima della pubblicazione.
Android 2026-11-23: B0–B11 completi, parità grafica e stress test fatti (commit fino a 0ec9d96); restano collaudo, commissioni, prove su telefono vero e prova sync reale. Social: post 5–15 (v2) pronti in Drive «Da postare». Android (storico): movimenti locali con data, modifica e pianificazione, migrazione Room verificata. Prossimi flussi locali: categorie e filtri. Supabase rinviato.
Banca (S-60): progetto esecutivo pronto in `.cantiere/progetto-banca.md` (Enable Banking, piano B Salt Edge); esecuzione dopo S-50. S-60t (verifiche commerciali/legali di Matteo) si può fare subito.
Social: calendario e pubblicazione gestiti direttamente da Matteo.
E2E: S-50 chiuso e collaudato (p, u, v, w, x, y) 2026-11-26; interruttore acceso in release iOS e Android. Resta la prova reale di Matteo con account di prova. Prossimo: S-70 → Codex.
E2E 2026-11-26 18:27: S-50u e S-50w collaudati [x] (iOS 187, Android 324, fake 19 verdi). Prossimo: S-50x Brevo.
S-51/S-51d 2026-11-27 12:13: S-51, S-51c, S-51d collaudati [x] (iOS 40, Android 332). S-51f diagnosticato (AsyncRenderer SwiftUI sulla closure del WindowGroup), correzione a Codex; poi S-51b. S-51e aperto.
S-51f e S-51b 2026-11-27 12:53: correzione e prova reale completate [~]. Su iOS 27.2 (24B8117) 12/12 verifiche su Supabase, assenza di nuovi crash e protezione finale disattivata con record preesistenti presenti. Build iOS, 40 test mirati iOS al rilancio e 332 unitari Android verdi. Prossimo: collaudo indipendente. Intermittenza del test t10 registrata in S-51h.
S-51f/S-51b 2026-11-27 13:00: collaudo ok [x] (73/73 test mirati, avvio senza crash). Aperti S-51g, S-51h, S-51e.
S-51g/S-51e/S-51h 2026-11-27 13:26: implementati [~]. Build Debug iOS e Android, 54 test mirati iOS, 334 unitari Android e tre ripetizioni di t10 verdi. Prova Supabase 12/12, protezione finale disattivata e record preesistenti presenti. Prossimo: collaudo indipendente.
S-51g/S-51e/S-51h 2026-11-27 13:34: collaudo ok [x] (iOS 46/46 mirati, t10 3/3, Android 334/334). S-51 chiuso. Prossimo: S-70 → Codex.
