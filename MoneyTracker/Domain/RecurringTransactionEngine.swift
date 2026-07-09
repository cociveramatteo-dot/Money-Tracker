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

    /// Crea automaticamente le istanze delle transazioni ricorrenti per il periodo
    /// corrente se non esistono ancora. Chiamata al lancio dell'app; include una
    /// guardia giornaliera per evitare duplicati se l'app viene rilanciata più volte.
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

        let twoMonthsAgo = cal.date(byAdding: .month, value: -2, to: now) ?? now
        var allDescriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.recurringFrequency.isEmpty && $0.date >= twoMonthsAgo }
        )
        allDescriptor.fetchLimit = 500
        let all = (try? modelContext.fetch(allDescriptor)) ?? []

        for tmpl in templates {
            let freq = tmpl.recurringFrequency

            // Il template stesso è una transazione vera e propria (compare
            // normalmente in Tutti/Uscite/Entrate come qualsiasi altra) — se la
            // sua data ricade già nel periodo corrente, quel periodo è coperto:
            // senza questo controllo il motore lo ignora (recurringFrequency non
            // è vuoto, quindi resta fuori dal fetch `all` qui sotto) e genera una
            // copia duplicata per lo stesso mese/settimana/anno del template.
            let templateCoversCurrentPeriod: Bool =
                (freq == "mensile"     && tmpl.date.isSameMonth(as: now)) ||
                (freq == "settimanale" && tmpl.date.isSameWeek(as: now))  ||
                (freq == "annuale"     && tmpl.date.isSameYear(as: now))
            if templateCoversCurrentPeriod { continue }

            let tmplId = tmpl.id.uuidString
            let alreadyExists = all.contains { t in
                t.recurringFrequency.isEmpty
                && (
                    // Preferenza: match per templateId (preciso) se disponibile
                    (!t.templateId.isEmpty && t.templateId == tmplId)
                    ||
                    // Fallback per transazioni generate prima dell'aggiunta di templateId
                    (t.templateId.isEmpty
                     && t.name     == tmpl.name
                     && abs(t.amount - tmpl.amount) < 0.01
                     && t.category == tmpl.category)
                )
                && (
                    (freq == "mensile"     && t.date.isSameMonth(as: now))  ||
                    (freq == "settimanale" && t.date.isSameWeek(as: now))   ||
                    (freq == "annuale"     && t.date.isSameYear(as: now)
                     && cal.component(.month, from: t.date) == cal.component(.month, from: tmpl.date))
                )
            }

            if alreadyExists { continue }

            let newDate: Date
            if freq == "mensile" {
                var comps = cal.dateComponents([.year, .month], from: now)
                let templateDay = cal.component(.day, from: tmpl.date)
                let daysInMonth = cal.range(of: .day, in: .month, for: now)?.count ?? 28
                comps.day = min(templateDay, daysInMonth)
                newDate = cal.date(from: comps) ?? now
            } else if freq == "annuale" {
                var comps = cal.dateComponents([.year], from: now)
                let tComps = cal.dateComponents([.month, .day], from: tmpl.date)
                comps.month = tComps.month
                comps.day   = tComps.day
                newDate = cal.date(from: comps) ?? now
            } else if freq == "settimanale" {
                let templateWeekday = cal.component(.weekday, from: tmpl.date)
                var comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
                comps.weekday = templateWeekday
                newDate = cal.date(from: comps) ?? now
            } else {
                newDate = now
            }

            let copy = Transaction(
                name:               tmpl.name,
                amount:             tmpl.amount,
                type:               tmpl.transactionType,
                category:           tmpl.category,
                categoryIcon:       tmpl.categoryIcon,
                date:               newDate,
                isDone:             false,    // pianificata, da confermare
                isFixed:            tmpl.isFixed,
                notes:              tmpl.notes,
                recurringFrequency: "",       // copia normale, non un template
                templateId:         tmpl.id.uuidString,
                account:            tmpl.account
            )
            modelContext.insert(copy)
            changed = true
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
