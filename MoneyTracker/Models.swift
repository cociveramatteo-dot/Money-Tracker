import Foundation
import SwiftData
import OSLog

// MARK: - Loggers

extension Logger {
    static let persistence = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MoneyTracker", category: "Persistence")
    static let recurring   = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MoneyTracker", category: "Recurring")
    static let classifier  = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MoneyTracker", category: "Classifier")
}

// MARK: - ModelContext safe save

extension ModelContext {
    /// Salva il context loggando l'errore invece di sopprimerlo silenziosamente.
    /// In debug crasha per permettere di individuare il problema immediatamente.
    /// In release logga e ritorna false senza crashare.
    @discardableResult
    func safeSave(file: String = #file, line: Int = #line) -> Bool {
        do {
            try save()
            return true
        } catch {
            let source = (file as NSString).lastPathComponent
            Logger.persistence.error("SwiftData save failed at \(source, privacy: .public):\(line) → \(error.localizedDescription, privacy: .public)")
            assertionFailure("SwiftData save failed: \(error)")
            return false
        }
    }
}

// MARK: - Enums (non-customizable)

enum TransactionType: String, Codable, CaseIterable {
    case uscita  = "Uscita"
    case entrata = "Entrata"

    var localizedName: String { NSLocalizedString(rawValue, comment: "") }
}

enum AccountType: String, Codable, CaseIterable {
    case contanti    = "Contanti"
    case carta       = "Carta"
    case conto       = "Conto Bancario"
    case risparmio   = "Risparmio"
    case investimento = "Investimento"

    var localizedName: String { NSLocalizedString(rawValue, comment: "") }
}

// MARK: - Category (user-manageable)

@Model
final class Category {
    var id: UUID
    var name: String
    var icon: String        // SF Symbol name
    var isDefault: Bool     // default categories non eliminabili
    var sortOrder: Int
    var createdAt: Date

    init(name: String, icon: String, isDefault: Bool = false, sortOrder: Int = 0) {
        self.id        = UUID()
        self.name      = name
        self.icon      = icon
        self.isDefault = isDefault
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }
}

// MARK: - Account

@Model
final class Account {
    var id: UUID
    var name: String
    var type: String
    var initialBalance: Double
    var colorHex: String
    var createdAt: Date
    var isArchived: Bool
    var isExcludedFromTotal: Bool   // se true, non contribuisce al saldo totale

    @Relationship(deleteRule: .cascade, inverse: \Transaction.account)
    var transactions: [Transaction]

    @Relationship(deleteRule: .cascade, inverse: \Budget.account)
    var budgets: [Budget]

    init(name: String, type: AccountType, initialBalance: Double = 0,
         colorHex: String = "000000", isExcludedFromTotal: Bool = false) {
        self.id                  = UUID()
        self.name                = name
        self.type                = type.rawValue
        self.initialBalance      = initialBalance
        self.colorHex            = colorHex
        self.createdAt           = Date()
        self.isArchived          = false
        self.isExcludedFromTotal = isExcludedFromTotal
        self.transactions        = []
        self.budgets             = []
    }

    var accountType: AccountType { AccountType(rawValue: type) ?? .conto }

    var emoji: String {
        switch accountType {
        case .contanti:     return "💵"
        case .carta:        return "💳"
        case .conto:        return "🏦"
        case .risparmio:    return "🐷"
        case .investimento: return "📈"
        }
    }

    var currentBalance: Double {
        let done = transactions.filter { $0.isDone }
        return initialBalance + done.reduce(0.0) { $0 + $1.signedAmount }
    }

    var futureBalance: Double {
        initialBalance + transactions.reduce(0.0) { $0 + $1.signedAmount }
    }

    var plannedDelta: Double { futureBalance - currentBalance }
}

// MARK: - Transaction

@Model
final class Transaction {
    var id: UUID
    var name: String
    var amount: Double
    var type: String            // TransactionType.rawValue
    var category: String        // nome categoria (stringa libera)
    var categoryIcon: String    // SF Symbol name (copiato al salvataggio)
    var date: Date
    var isDone: Bool            // Fatto? false = pianificato
    var isFixed: Bool           // Spesa fissa (affitto, abbonamenti, ecc.)
    var isTransfer: Bool        // Trasferimento tra conti
    var transferGroupId: String // UUID stringa condiviso dai 2 leg dello stesso trasferimento
    var notes: String
    var recurringFrequency: String  // "": nessuna, "settimanale", "mensile", "annuale"
    var templateId: String          // UUID del template padre (vuoto se non generata da ricorrente)
    var createdAt: Date

    var account: Account?

    init(
        name: String,
        amount: Double,
        type: TransactionType,
        category: String = "Altro",
        categoryIcon: String = "circle.dotted",
        date: Date = Date(),
        isDone: Bool = true,
        isFixed: Bool = false,
        isTransfer: Bool = false,
        transferGroupId: String = "",
        notes: String = "",
        recurringFrequency: String = "",
        templateId: String = "",
        account: Account? = nil
    ) {
        self.id                 = UUID()
        self.name               = name
        self.amount             = amount
        self.type               = type.rawValue
        self.category           = category
        self.categoryIcon       = categoryIcon
        self.date               = date
        self.isDone             = isDone
        self.isFixed            = isFixed
        self.isTransfer         = isTransfer
        self.transferGroupId    = transferGroupId
        self.notes              = notes
        self.recurringFrequency = recurringFrequency
        self.templateId         = templateId
        self.createdAt          = Date()
        self.account            = account
    }

    var transactionType: TransactionType { TransactionType(rawValue: type) ?? .uscita }

    var signedAmount: Double {
        transactionType == .entrata ? amount : -amount
    }
}

// MARK: - Budget

@Model
final class Budget {
    var id: UUID
    var category: String        // nome categoria (o "Tutti" per budget globale conto)
    var categoryIcon: String    // icona per display
    var monthlyLimit: Double
    var month: Int
    var year: Int
    var createdAt: Date

    // Budget per conto specifico (nil = budget per categoria su tutti i conti)
    @Relationship(deleteRule: .nullify)
    var account: Account?

    init(category: String, categoryIcon: String = "circle.dotted",
         monthlyLimit: Double, month: Int, year: Int, account: Account? = nil) {
        self.id           = UUID()
        self.category     = category
        self.categoryIcon = categoryIcon
        self.monthlyLimit = monthlyLimit
        self.month        = month
        self.year         = year
        self.createdAt    = Date()
        self.account      = account
    }
}

// MARK: - Goal

@Model
final class Goal {
    var id: UUID
    var name: String
    var emoji: String
    var targetAmount: Double
    var currentAmount: Double
    var deadline: Date?
    var isCompleted: Bool
    var createdAt: Date

    init(name: String, targetAmount: Double, currentAmount: Double = 0,
         emoji: String = "target", deadline: Date? = nil) {
        self.id            = UUID()
        self.name          = name
        self.emoji         = emoji
        self.targetAmount  = targetAmount
        self.currentAmount = currentAmount
        self.deadline      = deadline
        self.isCompleted   = false
        self.createdAt     = Date()
    }

    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(currentAmount / targetAmount, 1.0)
    }
    var remaining: Double { max(targetAmount - currentAmount, 0) }
}

// MARK: - Default Categories

extension Category {
    static let defaults: [(name: String, icon: String, order: Int)] = [
        ("Cibo",         "fork.knife",             0),
        ("Trasporti",    "car.fill",               1),
        ("Svago",        "gamecontroller.fill",    2),
        ("Shopping",     "bag.fill",               3),
        ("Salute",       "heart.fill",             4),
        ("Casa",         "house.fill",             5),
        ("Abbonamenti",  "repeat.circle.fill",     6),
        ("Lavoro",       "briefcase.fill",         7),
        ("Istruzione",   "book.fill",              8),
        ("Viaggi",       "airplane",               9),
        ("Regali",       "gift.fill",              10),
        ("Risparmio",    "banknote",               11),
        ("Giroconto",    "arrow.left.arrow.right", 12),
        ("Altro",        "tray.fill",               13),
    ]

    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<Category>())) ?? 0
        guard count == 0 else {
            migrateIconsIfNeeded(context: context)
            return
        }
        for (name, icon, order) in defaults {
            context.insert(Category(name: name, icon: icon, isDefault: true, sortOrder: order))
        }
        context.safeSave()
    }

    @MainActor
    private static func migrateIconsIfNeeded(context: ModelContext) {
        let all = (try? context.fetch(FetchDescriptor<Category>())) ?? []
        var changed = false
        for cat in all {
            if let (_, icon, _) = defaults.first(where: { $0.0 == cat.name }), cat.icon != icon {
                cat.icon = icon
                changed = true
            }
        }
        if changed { context.safeSave() }
    }
}

// MARK: - Formatter caches

// @MainActor: all formatters are created and read exclusively on the main thread
// (views, @MainActor AppIntents). This annotation makes Swift 6 concurrency formal.
@MainActor
enum FormatterCache {
    // NumberFormatter for currency — recreated when the currency code changes.
    private static var _currencyFormatter: NumberFormatter?
    private static var _currencyFormatterCode: String = ""

    // Date formatters — recreated on locale change via NSLocale.currentLocaleDidChangeNotification.
    private static var _monthYear:  DateFormatter?
    private static var _dayMonth:   DateFormatter?
    private static var _shortMonth: DateFormatter?
    private static var _csvDate:    DateFormatter?

    /// Call once at app start to wire up locale-change invalidation.
    static func registerLocaleObserver() {
        NotificationCenter.default.addObserver(
            forName: NSLocale.currentLocaleDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            // `queue: .main` garantisce esecuzione sul main thread a runtime;
            // `assumeIsolated` informa il type-checker Swift 6 in modo formale
            // (evita i warning "Main actor-isolated property can not be mutated from a Sendable closure").
            MainActor.assumeIsolated {
                _currencyFormatter     = nil
                _currencyFormatterCode = ""
                _monthYear             = nil
                _dayMonth              = nil
                _shortMonth            = nil
                _csvDate               = nil
            }
        }
    }

    static func currencyFormatter() -> NumberFormatter {
        let code = UserDefaults.standard.string(forKey: "currencyCode") ?? "EUR"
        if let cached = _currencyFormatter, _currencyFormatterCode == code {
            return cached
        }
        let f = NumberFormatter()
        f.numberStyle  = .currency
        f.currencyCode = code
        f.locale       = Locale.current
        _currencyFormatter     = f
        _currencyFormatterCode = code
        return f
    }

    static var monthYear: DateFormatter {
        if let f = _monthYear { return f }
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; f.locale = Locale.current
        _monthYear = f; return f
    }

    static var dayMonth: DateFormatter {
        if let f = _dayMonth { return f }
        let f = DateFormatter(); f.dateFormat = "d MMM"; f.locale = Locale.current
        _dayMonth = f; return f
    }

    static var shortMonth: DateFormatter {
        if let f = _shortMonth { return f }
        let f = DateFormatter(); f.dateFormat = "MMM"; f.locale = Locale.current
        _shortMonth = f; return f
    }

    /// Shared CSV date formatter (dd/MM/yyyy) — cached and locale-aware.
    static var csvDate: DateFormatter {
        if let f = _csvDate { return f }
        let f = DateFormatter(); f.dateFormat = "dd/MM/yyyy"; f.locale = Locale.current
        _csvDate = f; return f
    }
}

// MARK: - Helpers

extension Double {

    static var activeCurrencyCode: String {
        UserDefaults.standard.string(forKey: "currencyCode") ?? "EUR"
    }

    @MainActor static var currencySymbol: String {
        FormatterCache.currencyFormatter().currencySymbol
    }

    @MainActor var currencyFormatted: String {
        let f = FormatterCache.currencyFormatter()
        return f.string(from: NSNumber(value: self)) ?? "\(Double.currencySymbol)\(self)"
    }

    @MainActor var currencyCompact: String {
        guard abs(self) >= 1000 else { return currencyFormatted }
        let sign = self < 0 ? "-" : ""
        return "\(sign)\(Double.currencySymbol)\(Int(abs(self) / 1000))k"
    }
}

extension Date {
    @MainActor var monthYearFormatted: String {
        FormatterCache.monthYear.string(from: self).capitalized
    }
    @MainActor var dayMonthFormatted: String {
        if Calendar.current.isDateInToday(self) { return String(localized: "Oggi") }
        if Calendar.current.isDateInYesterday(self) { return String(localized: "Ieri") }
        return FormatterCache.dayMonth.string(from: self)
    }
    var startOfMonth: Date {
        Calendar.current.dateInterval(of: .month, for: self)?.start ?? self
    }
    var endOfMonth: Date {
        Calendar.current.dateInterval(of: .month, for: self)?.end ?? self
    }
    func isSameMonth(as other: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: other, toGranularity: .month)
    }
    func isSameWeek(as other: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: other, toGranularity: .weekOfYear)
    }
    func isSameYear(as other: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: other, toGranularity: .year)
    }
}

// MARK: - Recurring Transaction Logic

extension Transaction {
    /// Crea automaticamente le istanze delle transazioni ricorrenti per il periodo corrente se non esistono ancora.
    /// Chiamata al lancio dell'app; include una guardia giornaliera per evitare duplicati se init() gira più volte.
    static func processRecurring(context: ModelContext) {
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
        let templates = (try? context.fetch(templateDescriptor)) ?? []
        guard !templates.isEmpty else { return }

        var changed = false

        let twoMonthsAgo = cal.date(byAdding: .month, value: -2, to: now) ?? now
        var allDescriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.recurringFrequency.isEmpty && $0.date >= twoMonthsAgo }
        )
        allDescriptor.fetchLimit = 500
        let all = (try? context.fetch(allDescriptor)) ?? []

        for tmpl in templates {
            let freq = tmpl.recurringFrequency

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
            context.insert(copy)
            changed = true
        }

        if changed {
            do {
                try context.save()
                // ✅ Segna lastRun solo dopo save riuscito: se fallisce, riprova al prossimo lancio
                UserDefaults.standard.set(today, forKey: lastRunKey)
                Logger.recurring.info("processRecurring: saved new recurring instances")
            } catch {
                Logger.recurring.error("processRecurring save failed: \(error.localizedDescription, privacy: .public)")
                assertionFailure("processRecurring save failed: \(error)")
            }
        } else {
            // Nessuna nuova transazione da creare, ma marchiamo comunque il giorno
            UserDefaults.standard.set(today, forKey: lastRunKey)
        }
    }
}
