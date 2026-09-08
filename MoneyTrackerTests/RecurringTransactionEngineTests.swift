import Testing
import SwiftData
import Foundation
@testable import MoneyTracker

/// Verifica `RecurringTransactionActor.processRecurring()` su uno store SwiftData
/// reale in memoria: la logica gira in un `@ModelActor` e non è testabile su
/// oggetti @Model non gestiti come `AccountBalanceTests`, serve un `ModelContainer`.
@Suite("Recurring transaction engine", .serialized)
@MainActor
struct RecurringTransactionEngineTests {

    private func makeContainer() throws -> ModelContainer {
        // La guardia giornaliera di processRecurring() vive in UserDefaults.standard,
        // globale al processo di test — senza reset, un test eseguito prima nello
        // stesso run marca "già girato oggi" e i test successivi vedono
        // processRecurring() uscire subito, generando 0 transazioni invece di quelle
        // attese. L'ordine tra i @Test di uno stesso @Suite non è garantito.
        UserDefaults.standard.removeObject(forKey: "processRecurring.lastRun")
        let schema = Schema(versionedSchema: SchemaV2.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: config)
    }

    /// BUG storico: il motore generava solo l'occorrenza del periodo *corrente*,
    /// perdendo per sempre i mesi saltati se l'utente non apriva l'app. Un template
    /// mensile fermo a 3 mesi fa deve recuperare tutte e 3 le occorrenze mancanti,
    /// non solo quella di questo mese.
    @Test("Un template mensile fermo da 3 mesi recupera tutte le occorrenze mancanti")
    func backfillsMissedMonths() async throws {
        let container = try makeContainer()
        let context = container.mainContext

        let cal = Calendar.current
        let now = Date()
        let threeMonthsAgo = cal.date(byAdding: .month, value: -3, to: now)!

        let account = Account(name: "Conto", type: .conto, initialBalance: Decimal(0))
        context.insert(account)
        let template = Transaction(
            name: "Affitto", amount: Decimal(500), type: .uscita,
            date: threeMonthsAgo, isFixed: true,
            recurringFrequency: "mensile", account: account
        )
        context.insert(template)
        try context.save()

        let engine = RecurringTransactionActor(modelContainer: container)
        await engine.processRecurring()

        let templateId = template.id.uuidString
        let generated = try context.fetch(FetchDescriptor<Transaction>(
            predicate: #Predicate<Transaction> { $0.templateId == templateId }
        ))
        // 3 mesi fa → mese scorso, mese scorso → 2 mesi fa colmati, più il mese
        // corrente: il template stesso copre già il suo mese originale (3 mesi fa),
        // quindi ci si aspettano esattamente 3 nuove occorrenze (non 4).
        #expect(generated.count == 3)
        #expect(generated.allSatisfy { $0.isDone == false })
        #expect(generated.allSatisfy { $0.amount == Decimal(500) })
    }

    /// BUG storico: la finestra di ricerca "già esistente" era fissa a 2 mesi,
    /// insufficiente per le ricorrenze annuali → dopo 2 mesi dalla generazione,
    /// ogni run inseriva un duplicato per lo stesso anno.
    @Test("Una ricorrenza annuale già generata quest'anno non viene duplicata dopo 2+ mesi")
    func doesNotDuplicateAnnualAfterTwoMonths() async throws {
        let container = try makeContainer()
        let context = container.mainContext

        let cal = Calendar.current
        let now = Date()
        let twoYearsAgo = cal.date(byAdding: .year, value: -2, to: now)!
        // Occorrenza già generata quest'anno, ma più di 2 mesi fa (fuori dalla
        // vecchia finestra fissa).
        let fourMonthsAgo = cal.date(byAdding: .month, value: -4, to: now)!

        let account = Account(name: "Conto", type: .conto, initialBalance: Decimal(0))
        context.insert(account)
        let template = Transaction(
            name: "Assicurazione auto", amount: Decimal(300), type: .uscita,
            date: twoYearsAgo, recurringFrequency: "annuale", account: account
        )
        context.insert(template)
        let existingCopy = Transaction(
            name: "Assicurazione auto", amount: Decimal(300), type: .uscita,
            date: fourMonthsAgo, recurringFrequency: "",
            templateId: template.id.uuidString, account: account
        )
        context.insert(existingCopy)
        try context.save()

        let engine = RecurringTransactionActor(modelContainer: container)
        await engine.processRecurring()

        let templateId = template.id.uuidString
        let allForTemplate = try context.fetch(FetchDescriptor<Transaction>(
            predicate: #Predicate<Transaction> { $0.templateId == templateId }
        ))
        #expect(allForTemplate.count == 1)   // solo la copia già esistente, nessun duplicato
    }

    @Test("Un template creato oggi non genera subito una copia per il proprio mese")
    func doesNotDuplicateTemplatesOwnPeriod() async throws {
        let container = try makeContainer()
        let context = container.mainContext

        let account = Account(name: "Conto", type: .conto, initialBalance: Decimal(0))
        context.insert(account)
        let template = Transaction(
            name: "Netflix", amount: Decimal(15), type: .uscita,
            date: Date(), recurringFrequency: "mensile", account: account
        )
        context.insert(template)
        try context.save()

        let engine = RecurringTransactionActor(modelContainer: container)
        await engine.processRecurring()

        let templateId = template.id.uuidString
        let generated = try context.fetch(FetchDescriptor<Transaction>(
            predicate: #Predicate<Transaction> { $0.templateId == templateId }
        ))
        #expect(generated.isEmpty)
    }
}
