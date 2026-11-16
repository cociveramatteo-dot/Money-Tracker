import SwiftData
import Foundation

/// Fictional showcase data, exclusively for the separate demo container.
struct DemoDataSeeder {
    private static let seedVersion = 6
    private static let seedVersionKey = "demoSeedVersion"

    @MainActor
    static func forceReset(context: ModelContext) {
        // Remove rules too: otherwise a later materialization recreates old demo copies.
        if let rows = try? context.fetch(FetchDescriptor<RecurringRule>()) { rows.forEach { context.delete($0) } }
        if let rows = try? context.fetch(FetchDescriptor<Transaction>()) { rows.forEach { context.delete($0) } }
        if let rows = try? context.fetch(FetchDescriptor<Account>()) { rows.forEach { context.delete($0) } }
        if let rows = try? context.fetch(FetchDescriptor<Budget>()) { rows.forEach { context.delete($0) } }
        if let rows = try? context.fetch(FetchDescriptor<Goal>()) { rows.forEach { context.delete($0) } }
        context.safeSave()
        Category.seedIfNeeded(context: context)
        seed(context: context)
        UserDefaults.standard.set(seedVersion, forKey: seedVersionKey)
    }

    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<Account>())) ?? 0
        if count == 0 || UserDefaults.standard.integer(forKey: seedVersionKey) < seedVersion {
            forceReset(context: context)
        }
    }

    @MainActor
    private static func seed(context: ModelContext) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        let now = Date()
        let calculator = RecurrenceCalculator()
        let today = calculator.noon(now)
        let month = cal.dateInterval(of: .month, for: now)?.start ?? today
        // Calendar arithmetic preserves civil days across DST and year boundaries.
        func date(_ offset: Int, _ day: Int) -> Date {
            let start = cal.date(byAdding: .month, value: offset, to: month) ?? month
            let clamped = min(day, (cal.range(of: .day, in: .month, for: start)?.count ?? 28))
            return calculator.noon(cal.date(byAdding: .day, value: clamped - 1, to: start) ?? start)
        }
        func name(_ key: String) -> String {
            NSLocalizedString("demo." + key, comment: "Fictional demo data")
        }
        let conto = Account(name: name("account.conto"), type: .conto, initialBalance: 2_900, colorHex: "1F7A4D")
        let risparmi = Account(name: name("account.risparmi"), type: .risparmio, initialBalance: 6_200, colorHex: "2F6FB0")
        let carta = Account(name: name("account.carta"), type: .carta, initialBalance: 4_800, colorHex: "5A4AA3")
        let contanti = Account(name: name("account.contanti"), type: .contanti, initialBalance: 650, colorHex: "B45309")
        for account in [conto, risparmi, carta, contanti] { context.insert(account) }

        @discardableResult
        func movement(_ key: String, _ amount: Decimal, _ category: String, _ when: Date,
                      _ account: Account, type: TransactionType = .uscita) -> Transaction {
            let icon = Category.defaults.first { $0.name == category }?.icon ?? "tray.fill"
            let tx = Transaction(name: name(key), amount: amount, type: type, category: category,
                                 categoryIcon: icon, date: when, isDone: when < today, account: account)
            context.insert(tx)
            return tx
        }

        // Real series and calculator-derived identities, exactly as the editor expects.
        // Current-month future copies remain planned; later months stay virtual, as in production.
        // The watermark prevents duplicate materialization.
        func series(_ key: String, _ amount: Decimal, _ category: String, _ day: Int,
                    _ account: Account, type: TransactionType = .uscita, override: Bool = false) {
            let icon = Category.defaults.first { $0.name == category }?.icon ?? "tray.fill"
            // Preserve a day-29/30/31 anchor even if the first historical month is shorter.
            let start = cal.component(.day, from: date(-7, day)) == day ? date(-7, day) : date(-8, day)
            let rule = RecurringRule(name: name(key), amount: amount, type: type.rawValue,
                                     category: category, categoryIcon: icon, isFixed: true,
                                     accountId: account.id, frequency: "mensile", startDate: start,
                                     materializedThrough: date(0, 1))
            var exceptions: [String: RecurrenceException] = [:]
            if override {
                exceptions[calculator.key(for: date(0, day))] = RecurrenceException(amount: "112.40")
                rule.exceptionsJSON = (try? RecurrenceExceptionCodec.encode(exceptions)) ?? "{}"
            }
            context.insert(rule)
            let snapshot = RuleSnapshot(id: rule.id, name: rule.name, amount: amount, type: rule.type,
                                        category: category, categoryIcon: icon, isFixed: true,
                                        accountId: account.id, frequency: rule.frequency,
                                        startDate: rule.startDate, exceptions: exceptions)
            for occurrence in calculator.occurrences(rule: snapshot,
                in: DateInterval(start: date(-7, 1), end: date(1, 1))) {
                let tx = movement(key, occurrence.amount, category, occurrence.date, account, type: type)
                tx.id = occurrence.id
                tx.templateId = rule.id.uuidString
                tx.isFixed = true
                // The gym occurrence today has already been paid; other today copies are planned.
                tx.isDone = occurrence.date < today || (key == "tx.gym" && cal.isDate(occurrence.date, inSameDayAs: today))
            }
        }
        series("tx.stipendio", 2_850, "Lavoro", 1, conto, type: .entrata)
        series("tx.affitto", 780, "Casa", 3, conto)
        series("tx.bolletta", 86, "Casa", cal.component(.day, from: today), conto, override: true)
        series("tx.internet", 29, "Casa", 9, conto)
        series("tx.streaming", 15.99, "Abbonamenti", 12, carta)
        series("tx.music", 10.99, "Abbonamenti", 6, carta)
        series("tx.gym", 45, "Salute", cal.component(.day, from: today), conto)
        series("tx.insurance", 64, "Trasporti", 23, conto)
        series("tx.installment", 125, "Shopping", 10, conto)

        // Eight distinct monthly profiles. Current-month purchases are distributed over
        // elapsed days so every launch, including the first of a month, has useful budgets.
        let variation = [0, 18, -12, 35, 8, -5, 24, 12]
        for offset in -7...0 {
            let v = Decimal(variation[offset + 7])
            let elapsed = offset == 0 ? cal.component(.day, from: today) : 28
            func spent(_ key: String, _ amount: Decimal, _ category: String, _ day: Int, _ account: Account) {
                let purchaseDay = offset == 0 ? max(1, day * elapsed / 28) : day
                let when = date(offset, purchaseDay)
                let tx = movement(key, amount, category, when, account)
                tx.isDone = true
            }
            for day in [2, 8, 15, 28] {
                spent("tx.supermercato", 62 + v / 4, "Cibo", day, conto)
            }
            spent("tx.carburante", 58 + v, "Trasporti", 6, conto)
            spent("tx.ristorante", 68 + v, "Svago", 11, carta)
            spent("tx.cinema", 32, "Svago", 19, contanti)
            spent("tx.farmacia", 22 + v / 2, "Salute", 14, carta)
            spent("tx.shopping", 75 + v, "Shopping", 18, carta)
            spent("tx.course", 35, "Istruzione", 10, carta)
            spent("tx.regalo", offset == -1 ? 240 : 40 + v, "Regali", 24, carta)
            spent("tx.other", 12, "Altro", 7, contanti)
            if offset == -3 || offset == -6 {
                spent("tx.volo", offset == -3 ? 320 : 145, "Viaggi", 13, carta)
                spent("tx.hotel", offset == -3 ? 640 : 210, "Viaggi", 17, carta)
            }
            if offset == -2 { spent("tx.dentista", 280, "Salute", 16, conto) }
            if offset == -4 || offset == -1 {
                let bonus = movement("tx.bonus", offset == -4 ? 450 : 180, "Lavoro", date(offset, 18), conto, type: .entrata)
                bonus.isDone = true
            }
            let interest = movement("tx.interest", Decimal(275) / 100, "Risparmio",
                                    date(offset, min(2, elapsed)), risparmi, type: .entrata)
            interest.isDone = true
            // Paired transfer: visible in accounts, excluded from income/expense reports.
            let group = UUID().uuidString
            for (account, type) in [(conto, TransactionType.uscita), (risparmi, .entrata)] {
                let tx = movement("tx.risparmio", 180, "Giroconto", date(offset, min(5, elapsed)), account, type: type)
                tx.isDone = true
                tx.isTransfer = true
                tx.transferGroupId = group
            }
        }
        // A non-series plan remains visible even on the final day of the month.
        movement("tx.hotel", 195, "Viaggi", date(0, 31), carta)
        movement("tx.course", 90, "Istruzione", cal.date(byAdding: .day, value: 3, to: today) ?? today, conto)

        for offset in -7...0 {
            let anchor = date(offset, 1)
            let budgets: [(String, Decimal)] = [("Cibo", 300), ("Svago", 90), ("Trasporti", 240),
                                                ("Salute", 180), ("Shopping", 170)]
            for (category, limit) in budgets {
                context.insert(Budget(category: category,
                    categoryIcon: Category.defaults.first { $0.name == category }?.icon ?? "circle.dotted",
                    monthlyLimit: limit, month: cal.component(.month, from: anchor),
                    year: cal.component(.year, from: anchor)))
            }
        }
        // MARK: Obiettivi

        context.insert(Goal(
            name:          String(localized: "demo.goal.vacanza"),
            targetAmount:  2_800,
            currentAmount: 1_960,   // 70%
            emoji:         "airplane",
            deadline:      cal.date(byAdding: .month, value: 2, to: now)
        ))
        context.insert(Goal(
            name:          String(localized: "demo.goal.emergenza"),
            targetAmount:  15_000,
            currentAmount: 6_640,   // 44%
            emoji:         "banknote",
            deadline:      nil
        ))
        context.insert(Goal(
            name:          String(localized: "demo.goal.computer"),
            targetAmount:  2_499,
            currentAmount: 640,     // 26%
            emoji:         "laptopcomputer",
            deadline:      cal.date(byAdding: .month, value: 8, to: now)
        ))
        context.insert(Goal(
            name:          String(localized: "demo.goal.fotografia"),
            targetAmount:  450,
            currentAmount: 450,     // 100% completato
            emoji:         "camera.fill",
            deadline:      nil
        ))

        context.safeSave()
    }
}
