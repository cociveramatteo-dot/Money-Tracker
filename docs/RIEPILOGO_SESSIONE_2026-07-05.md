# Riepilogo sessione — 5 luglio 2026

Sintesi compatta di tutto il lavoro svolto in questa sessione. Ogni modifica è già applicata sui file del progetto.

---

## 1. Fix definitivo Light/Dark Mode

**Diagnosi.** Due difetti fatali: (a) feedback loop in `MoneyTrackerApp` — `.preferredColorScheme(themeManager…)` + `.onChange(of: colorScheme)` sulla stessa gerarchia inchiodavano l'app al tema chiaro; (b) i colori `DS.*` erano letti da una cache statica non osservabile: dei 368 punti d'uso, solo le viste con `@EnvironmentObject` si aggiornavano.

**Fix.** `AppTheme`, `ThemeManager` e la cache eliminati. `DS.ink/paper/fog/smoke` sono ora `Color` adattivi nativi (dynamic provider UIKit, palette invariata): il sistema risolve light/dark ovunque, transizione istantanea. Rimossi `preferredColorScheme` e tutti gli `@EnvironmentObject` correlati. `themePickerButton()` → `themedNavBar()`.

## 2. Riordino del progetto

- Sorgenti in `App/`, `Models/`, `Views/`, `Services/`, `DesignSystem/` (+ preesistenti `Auth/`, `Sync/`, `OnboardingTour/`). Sicuro: gruppi sincronizzati col filesystem; `Info.plist` e bridging header intoccati.
- Report/audit in `docs/`, script in `scripts/`, `.xctestplan` rinominato `TestPlan.xctestplan` (riparato riferimento rotto nello scheme), aggiunto `.gitignore`, rimossi `.DS_Store`/`.Rhistory`.

## 3. Blindatura finanziaria

- **`Double.parseAmount(_:)`** (Models.swift): unico punto d'ingresso del denaro. Virgola/punto e migliaia in entrambe le convenzioni, rifiuta lettere/segni/NaN/infiniti/oltre 999.999.999, quantizza al centesimo via `Decimal`. Verificato su 19 edge case. Sostituiti gli 8 punti di parsing fragile (AddTransaction, AddTransfer, Budget ×2, Goals, Accounts, filtri Transactions).
- Guard trasferimento stesso conto in `AddTransferView.save()`; quantizzazione centesimi negli intent Siri; `currencyCompact` arrotonda invece di troncare; extra negativi sugli obiettivi non più possibili.
- Verificato già solido: divisioni protette, CSV con difesa formula-injection, trasferimenti atomici, formatter cachati, sync con debounce.
- Fix grafico Statistiche: la LineMark entrate (segmenti fluttuanti sopra le barre) sostituita con **barre affiancate** via `position(by:)`.

## 4. Redesign onboarding

- **Tour: da 15 a 5 passi**, tutti sulla Home (welcome → tab bar → saldo → + → fine). X di uscita su ogni card. CTA finale **"Aggiungi la tua prima spesa"** apre AddTransactionView sul container reale (flag consume-once in TourManager, gestiti entrambi i percorsi di ricreazione).
- **Tip contestuali** (`ContextualTips.swift`): i 9 step rimossi sono diventati suggerimenti one-shot just-in-time (Movimenti/swipe, Statistiche, Budget, Obiettivi, Conti, saldo atteso). Card leggera sopra la tab bar, mai durante il tour, race sul cambio tab protetta, trigger centralizzati in ContentView. "Rivedi tour" azzera anche i tip.
- **Copy** dei 5 step riscritto (una frase, orientato all'azione) in 7 lingue; aggiunto `tour.laterButton`; rimosse 16 chiavi orfane per lingua. I tip riusano le traduzioni esistenti.
- Fix build: `import Combine` mancante in ContextualTips.swift.

## 5. Supabase Auth

Opt-in a `emitLocalSessionAsInitialSession: true` (PR #822/#844, SDK 2.48.0) + bootstrap guidato solo da `authStateChanges`. Warning eliminato, splash più rapido, l'utente offline con token scaduto non viene più buttato al login. Pronto per il default della v3.

## 6. Documenti prodotti

- `docs/PIANO_MIGRAZIONE_DECIMAL.md` — piano completo Double→Decimal: VersionedSchema V1→V2, migrazione custom con backup pre-migrazione, SQL Supabase (`numeric(12,2)`, retro-compatibile, da eseguire PRIMA dell'app), suite di test come gate, rollout TestFlight+phased, ~4 giorni dev.

## 7. Ricerca di mercato (sintesi)

- **Dolori del mercato**: subscription fatigue (YNAB 109$/anno), sfiducia crescente nel dare credenziali bancarie, categorizzazione sbagliata che erode fiducia, attrito dell'inserimento manuale. L'app è già nel quadrante giusto (manual-first, privacy, classificatore on-device).
- **Killer feature premium**: scontrino → transazione in 2 secondi, OCR VisionKit on-device + CategoryClassifier esistente. Argomento privacy invendibile per i concorrenti cloud. ~9,99 €/anno.
- **Bank linking**: solo come modulo Premium futuro. Nordigen/GoCardless free tier chiuso; opzioni: Enable Banking (indie-friendly), Yapily, Fabrick. Costi per conto/mese, re-consent PSD2 ~180gg. Ponte consigliato: **import CSV** prima (zero costi, misura la domanda).
- **Roadmap prodotto**: import CSV → widget/lock screen quick add → forecast fine mese → scontrini OCR premium → bank linking.

## 8. Cosa manca per il rilascio (stato attuale)

**Bloccanti App Store**: eliminazione account in-app (ASSENTE — rifiuto certo), `PrivacyInfo.xcprivacy` (ASSENTE — richiesto dal 2024), privacy policy + termini (URL richiesto).
**Fondamenta**: zero test automatizzati (test plan vuoto — partire dai 19 casi di parseAmount), nessun crash reporting (MetricKit o Sentry), migrazione Decimal in coda come rilascio dedicato.
**Monetizzazione**: nessuno StoreKit — serve con la feature scontrini.

**Sequenza consigliata**: 1) bloccanti + test → 2) TestFlight subito + sviluppo CSV/widget → 3) rilascio Decimal dedicato → 4) scontrini + StoreKit.

## Note tecniche sparse

- Chiave anon Supabase hardcoded: prassi accettata (sicurezza nelle RLS server-side).
- PDF con colori fissi chiari: corretto così.
- Anchor `.tourAnchor` non più usati dal tour lasciati nelle viste: innocui, riutilizzabili.
- Peso app stimato: ~10-20 MB download (verificare con App Thinning Report da Xcode Organizer).
- Da fare al prossimo build: ⌘B, toggle tema dal Control Center, flusso tour completo + tip, "Rivedi tour".
