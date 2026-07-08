import Foundation
import UserNotifications
import SwiftData
import OSLog

// MARK: - SystemNotificationManager

// nonisolated: letto dai completion handler di UNUserNotificationCenter.add(...), che
// girano su una coda di sistema arbitraria, non sul main actor.
private nonisolated let notifLog = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "notifications")

/// Implementazione di produzione di `NotificationScheduling`, basata su
/// `UNUserNotificationCenter`. Vedi Domain/NotificationScheduling.swift per il contratto
/// e la motivazione dell'estrazione a protocollo (DI/testabilità).
@MainActor
final class SystemNotificationManager: NotificationScheduling {
    static let shared: NotificationScheduling = SystemNotificationManager()
    private init() {}

    var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: "notificationsEnabled")
    }

    // MARK: - Permesso

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    UserDefaults.standard.set(true, forKey: "notificationsEnabled")
                }
            }
        }
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Budget warning (>80%)

    /// Controlla tutti i budget del mese e schedula una notifica per quelli >80%. Da chiamare dopo aver salvato una transazione.
    func checkBudgets(context: ModelContext, forMonth date: Date = Date()) {
        guard isEnabled else { return }

        let cal   = Calendar.current
        let month = cal.component(.month, from: date)
        let year  = cal.component(.year, from: date)

        let budgets = (try? context.fetch(
            FetchDescriptor<Budget>(
                predicate: #Predicate { $0.month == month && $0.year == year }
            )
        )) ?? []
        guard !budgets.isEmpty else { return }

        let startOfMonth = cal.dateInterval(of: .month, for: date)?.start ?? date
        let startOfNext  = cal.date(byAdding: .month, value: 1, to: startOfMonth) ?? date
        let outflows = ((try? context.fetch(
            FetchDescriptor<Transaction>(predicate: #Predicate { t in
                t.isDone && t.date >= startOfMonth && t.date < startOfNext
                && !t.isTransfer    // i trasferimenti non contano come spesa nel budget
            })
        )) ?? []).filter { $0.transactionType == .uscita }

        for budget in budgets {
            let cats: Set<String> = budget.category == "Tutti"
                ? []
                : Set(budget.category.split(separator: ",").map(String.init))

            let spent = outflows.filter {
                (cats.isEmpty || cats.contains($0.category))
                && (budget.account == nil || $0.account?.id == budget.account?.id)
            }.reduce(Decimal(0)) { $0 + $1.amount }

            let pct: Decimal = budget.monthlyLimit > 0 ? spent / budget.monthlyLimit : 0
            guard pct >= 0.8 else { continue }

            let catLabel: String = {
                if budget.category == "Tutti" { return budget.account?.name ?? "Budget" }
                return budget.category.split(separator: ",")
                    .map { NSLocalizedString(String($0), comment: "") }
                    .joined(separator: " + ")
            }()

            // pct alimenta solo il testo della notifica → conversione a Double isolata qui,
            // il calcolo finanziario sopra resta in Decimal.
            scheduleBudgetWarning(name: catLabel, pct: pct.asDouble, id: budget.id.uuidString)
        }
    }

    private func scheduleBudgetWarning(name: String, pct: Double, id: String) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["budget_\(id)"])

        let content        = UNMutableNotificationContent()
        content.sound      = .default
        if pct >= 1.0 {
            content.title  = NSLocalizedString("Budget sforato", comment: "Budget exceeded title")
            content.body   = String(format: NSLocalizedString("Hai superato il limite per \"%@\"", comment: "Budget exceeded body"), name)
        } else {
            content.title  = NSLocalizedString("Budget quasi esaurito", comment: "Budget near limit title")
            content.body   = String(format: NSLocalizedString("\"%@\" — %d%% utilizzato", comment: "Budget near limit body"), name, Int(pct * 100))
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "budget_\(id)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error { notifLog.error("budget schedule failed: \(error, privacy: .public)") }
            else         { notifLog.debug("budget warning scheduled id=budget_\(id, privacy: .private)") }
        }
    }

    // MARK: - Promemoria spese fisse (ogni 1° del mese alle 9:00)

    /// Fetches pending fixed transactions for the current month and schedules the reminder.
    /// STD-04: centralises the fetch+schedule logic so MoneyTrackerApp stays thin.
    func scheduleFixedReminderIfNeeded(context: ModelContext) {
        guard isEnabled else { return }
        let now = Date()
        let startOfMonth = Calendar.current.dateInterval(of: .month, for: now)?.start ?? now
        let startOfNext  = Calendar.current.date(byAdding: .month, value: 1, to: startOfMonth) ?? now
        let fixed = (try? context.fetch(FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.isFixed && !$0.isDone
                                    && $0.date >= startOfMonth && $0.date < startOfNext }
        ))) ?? []
        scheduleFixedReminder(pendingCount: fixed.count)
    }

    func scheduleFixedReminder(pendingCount: Int) {
        guard isEnabled else { return }
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["fixed_reminder"])
        guard pendingCount > 0 else { return }

        let content       = UNMutableNotificationContent()
        content.title     = NSLocalizedString("Spese fisse del mese", comment: "Fixed expenses reminder title")
        content.body      = pendingCount == 1
            ? NSLocalizedString("Hai 1 spesa fissa da segnare come pagata", comment: "Fixed expenses singular")
            : String(format: NSLocalizedString("Hai %d spese fisse da segnare come pagate", comment: "Fixed expenses plural"), pendingCount)
        content.sound     = .default

        var comps         = DateComponents()
        comps.day         = 1
        comps.hour        = 9
        comps.minute      = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: "fixed_reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error { notifLog.error("fixed_reminder schedule failed: \(error, privacy: .public)") }
            else         { notifLog.debug("fixed_reminder scheduled (count=\(pendingCount, privacy: .private))") }
        }
    }

    // MARK: - Obiettivo in scadenza (7 giorni prima della deadline)

    func scheduleGoalDeadline(name: String, goalId: String, deadline: Date) {
        guard isEnabled else { return }

        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["goal_\(goalId)"])

        guard let reminderDate = Calendar.current.date(byAdding: .day, value: -7, to: deadline),
              reminderDate > Date() else { return }

        let content       = UNMutableNotificationContent()
        content.title     = NSLocalizedString("Obiettivo in scadenza", comment: "Goal deadline title")
        content.body      = String(format: NSLocalizedString("\"%@\" scade tra 7 giorni", comment: "Goal deadline body"), name)
        content.sound     = .default

        let comps  = Calendar.current.dateComponents([.year, .month, .day, .hour], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: "goal_\(goalId)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error { notifLog.error("goal deadline schedule failed id=\(goalId, privacy: .private): \(error, privacy: .public)") }
            else         { notifLog.debug("goal deadline scheduled id=\(goalId, privacy: .private)") }
        }
    }

    func cancelGoalDeadline(goalId: String) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["goal_\(goalId)"])
    }

    // MARK: - Saldo sotto soglia

    /// Schedula una notifica se il saldo di un conto è sceso sotto la soglia impostata dall'utente.
    /// La soglia viene letta da UserDefaults keyed by "balanceThreshold_<accountId>", salvata come
    /// stringa (non come Double) per evitare qualunque conversione binaria sui dati finanziari.
    /// Chiamato dopo ogni salvataggio di transazione.
    func checkBalanceThreshold(accountId: String, accountName: String, currentBalance: Decimal) {
        guard isEnabled else { return }
        let key = "balanceThreshold_\(accountId)"
        guard let raw = UserDefaults.standard.string(forKey: key),
              let threshold = Decimal.parseAmount(raw), threshold > 0 else { return }

        let notifId = "balance_\(accountId)"
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [notifId])

        guard currentBalance < threshold else { return }

        let content   = UNMutableNotificationContent()
        content.title = NSLocalizedString("Saldo basso", comment: "Low balance notification title")
        content.body  = String(
            format: NSLocalizedString("Il conto \"%@\" è sceso sotto la soglia impostata.", comment: "Low balance body"),
            accountName
        )
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: notifId, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error { notifLog.error("balance alert schedule failed id=\(notifId, privacy: .private): \(error, privacy: .public)") }
            else         { notifLog.debug("balance alert scheduled id=\(notifId, privacy: .private)") }
        }
    }

    // MARK: - Report mensile PDF (ogni 1° del mese alle 10:00)

    func scheduleMonthlyReportReminder(enabled: Bool) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["monthly_report"])
        guard enabled && isEnabled else { return }

        let content   = UNMutableNotificationContent()
        content.title = NSLocalizedString("Il tuo report mensile è pronto", comment: "Monthly report title")
        content.body  = NSLocalizedString("Apri MoneyTracker per generare e condividere il PDF del mese scorso.", comment: "Monthly report body")
        content.sound = .default

        var comps     = DateComponents()
        comps.day     = 1
        comps.hour    = 10
        comps.minute  = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: "monthly_report", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error { notifLog.error("monthly_report schedule failed: \(error, privacy: .public)") }
            else         { notifLog.debug("monthly_report reminder scheduled") }
        }
    }
}
