import Foundation
import SwiftData
import OSLog

// MARK: - Recurring Transaction Engine (PERF-05)
//
// PRIMA: `Transaction.processRecurring(context:)` girava sincrono sul main actor
// dentro `.task` al lancio dell'app (fetch di template + fino a 500 transazioni,
// confronto O(templates × transazioni) e `try context.save()`, tutto bloccante).
// Con un utente che ha molte transazioni/ricorrenze questo introduce jank percepibile
// proprio nell'istante più delicato: il primo frame utile dopo il login.
//
// DOPO: la stessa logica gira su un `@ModelActor` con un proprio `ModelContext` in
// background, sullo stesso store del container passato. Il main actor resta libero
// per il primo render; le eventuali nuove transazioni pianificate compaiono appena
// il fetch @Query si aggiorna dopo il salvataggio in background (SwiftData notifica
// i @Query cross-context tramite lo store, non serve alcun bridging manuale).
@ModelActor
actor RecurringTransactionActor {

    /// Numero massimo di occorrenze arretrate generate per template ad ogni run.
    /// Un utente che non apre l'app per mesi/anni deve poter recuperare lo storico
    /// mancante (BUG: prima si generava solo il periodo corrente, perdendo per
    /// sempre le occorrenze saltate), ma senza limite un template dimenticato con
    /// data molto vecchia potrebbe generare migliaia di transazioni in un colpo
    /// solo. 60 copre comodamente i casi reali (60 mesi = 5 anni, 60 settimane ≈
    /// 14 mesi, 60 anni); oltre, il recupero prosegue nei run successivi (guardia
    /// giornaliera) finché il backlog non è azzerato.
    private static let maxBackfillPerTemplate = 60

    /// Crea automaticamente le istanze mancanti delle transazioni ricorrenti,
    /// recuperando anche i periodi saltati da quando l'app non viene aperta (non
    /// solo quello corrente). Chiamata al lancio dell'app; include una guardia
    /// giornaliera per evitare duplicati se l'app viene rilanciata più volte.
    func processRecurring() {
        let cal = Calendar.current
        let now = Date()
        let today = cal.startOfDay(for: now)
        let lastRunKey = "processRecurring.lastRun"
        if let lastRun = UserDefaults.standard.object(forKey: lastRunKey) as? Date,
           lastRun >= today {
            return
        }
        // ⚠️ NON impostare lastRun qui — verrà impostato solo dopo save riuscito

        let templateDescriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { !$0.recurringFrequency.isEmpty }
        )
        let templates = (try? modelContext.fetch(templateDescriptor)) ?? []
        guard !templates.isEmpty else {
            UserDefaults.standard.set(today, forKey: lastRunKey)
            return
        }

        var changed = false
        var anyCapped = false

        for tmpl in templates {
            let freq = tmpl.recurringFrequency
            guard freq == "mensile" || freq == "settimanale" || freq == "annuale" else { continue }

            let tmplId = tmpl.id.uuidString

            // Occorrenza più recente già generata per questo template — fetch mirato
            // per template invece di una finestra temporale fissa (BUG: una finestra
            // fissa di 2 mesi perdeva di vista le ricorrenze annuali generate da più
            // di 2 mesi, causando un duplicato ad ogni run successivo). Preferenza al
            // match per templateId (preciso); fallback per copie generate prima che
            // templateId esistesse.
            var byIdDescriptor = FetchDescriptor<Transaction>(
                predicate: #Predicate<Transaction> { $0.templateId == tmplId },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            byIdDescriptor.fetchLimit = 1
            let latestById = (try? modelContext.fetch(byIdDescriptor))?.first

            var latestDate = tmpl.date
            if let latestById {
                latestDate = max(latestDate, latestById.date)
            } else {
                let name = tmpl.name
                let category = tmpl.category
                var fallbackDescriptor = FetchDescriptor<Transaction>(
                    predicate: #Predicate<Transaction> {
                        $0.recurringFrequency.isEmpty && $0.templateId.isEmpty
                        && $0.name == name && $0.category == category
                    },
                    sortBy: [SortDescriptor(\.date, order: .reverse)]
                )
                fallbackDescriptor.fetchLimit = 5
                let candidates = (try? modelContext.fetch(fallbackDescriptor)) ?? []
                if let match = candidates.first(where: { abs($0.amount - tmpl.amount) < 0.01 }) {
                    latestDate = max(latestDate, match.date)
                }
            }

            let templateDay     = cal.component(.day, from: tmpl.date)
            let templateMonth   = cal.component(.month, from: tmpl.date)
            let templateWeekday = cal.component(.weekday, from: tmpl.date)

            func nextOccurrence(after date: Date) -> Date {
                switch freq {
                case "mensile":
                    let base = cal.date(byAdding: .month, value: 1, to: date) ?? date
                    var comps = cal.dateComponents([.year, .month], from: base)
                    let daysInMonth = cal.range(of: .day, in: .month, for: base)?.count ?? 28
                    comps.day = min(templateDay, daysInMonth)
                    return cal.date(from: comps) ?? base
                case "annuale":
                    let base = cal.date(byAdding: .year, value: 1, to: date) ?? date
                    var comps = cal.dateComponents([.year], from: base)
                    comps.month = templateMonth
                    let daysInTargetMonth = cal.range(of: .day, in: .month, for: base)?.count ?? 31
                    comps.day = min(templateDay, daysInTargetMonth)
                    return cal.date(from: comps) ?? base
                default: // "settimanale"
                    let base = cal.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
                    var comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: base)
                    comps.weekday = templateWeekday
                    return cal.date(from: comps) ?? base
                }
            }

            var cursor = latestDate
            var generated = 0
            while generated < Self.maxBackfillPerTemplate {
                let candidate = nextOccurrence(after: cursor)
                guard candidate <= now else { break }

                let copy = Transaction(
                    name:               tmpl.name,
                    amount:             tmpl.amount,
                    type:               tmpl.transactionType,
                    category:           tmpl.category,
                    categoryIcon:       tmpl.categoryIcon,
                    date:               candidate,
                    isDone:             false,    // pianificata, da confermare
                    isFixed:            tmpl.isFixed,
                    notes:              tmpl.notes,
                    recurringFrequency: "",       // copia normale, non un template
                    templateId:         tmplId,
                    account:            tmpl.account
                )
                modelContext.insert(copy)
                changed = true
                generated += 1
                cursor = candidate
            }
            if generated == Self.maxBackfillPerTemplate && nextOccurrence(after: cursor) <= now {
                anyCapped = true
            }
        }

        if anyCapped {
            Logger.recurring.warning("processRecurring: backfill capped at \(Self.maxBackfillPerTemplate, privacy: .public) per template, will continue next run")
        }

        if changed {
            do {
                try modelContext.save()
                // PERF-04: il save avviene su un ModelContext diverso da quello della UI,
                // quindi non passa dall'estensione ModelContext.safeSave() — invalidiamo
                // esplicitamente la cache saldi così Dashboard/AccountsView non mostrano
                // valori stantii dopo l'inserimento delle nuove transazioni pianificate.
                AccountBalanceCache.shared.invalidateAll()
                // ✅ Segna lastRun solo dopo save riuscito: se fallisce, riprova al prossimo lancio
                UserDefaults.standard.set(today, forKey: lastRunKey)
                Logger.recurring.info("processRecurring: saved new recurring instances")
            } catch {
                Logger.recurring.error("processRecurring save failed: \(error.localizedDescription, privacy: .public)")
            }
        } else {
            // Nessuna nuova transazione da creare, ma marchiamo comunque il giorno
            UserDefaults.standard.set(today, forKey: lastRunKey)
        }
    }
}
