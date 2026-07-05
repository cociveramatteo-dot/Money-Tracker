import Foundation
import SwiftData

/// Business logic contract per la programmazione delle notifiche locali (budget,
/// spese fisse, obiettivi, soglie di saldo, report mensile). Estratta in protocollo
/// (invece del solo singleton `NotificationManager.shared` chiamato direttamente dalle
/// view) così AddTransactionView/GoalsView/SettingsView possono essere testate iniettando
/// un finto che registra le chiamate, senza toccare `UNUserNotificationCenter` reale.
@MainActor
protocol NotificationScheduling: AnyObject {
    var isEnabled: Bool { get }

    func requestPermission()
    func cancelAll()

    func checkBudgets(context: ModelContext, forMonth date: Date)
    func scheduleFixedReminderIfNeeded(context: ModelContext)
    func scheduleFixedReminder(pendingCount: Int)

    func scheduleGoalDeadline(name: String, goalId: String, deadline: Date)
    func cancelGoalDeadline(goalId: String)

    func checkBalanceThreshold(accountId: String, accountName: String, currentBalance: Double)

    func scheduleMonthlyReportReminder(enabled: Bool)
}
