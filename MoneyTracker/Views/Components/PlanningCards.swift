import SwiftUI

/// Presentazione Sentiero: soglie e colori provengono dai componenti esistenti.
struct PlanningBudgetCard: View {
    let budget: Budget
    let spentAmount: Decimal

    private var progress: Double {
        guard budget.monthlyLimit > 0 else { return 0 }
        return min((spentAmount / budget.monthlyLimit).asDouble, 1.0)
    }
    private var remaining: Decimal { budget.monthlyLimit - spentAmount }
    private var over: Bool { spentAmount > budget.monthlyLimit }
    private var categories: [String] {
        budget.category == "Tutti" ? [] : budget.category.split(separator: ",").map(String.init)
    }
    private var name: String {
        categories.isEmpty ? (budget.account?.name ?? String(localized: "Tutti"))
        : categories.map { NSLocalizedString($0, comment: "") }.joined(separator: ", ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 8) { heading; Spacer(minLength: 0); BudgetStatus(progress: progress).fixedSize() }
                VStack(alignment: .leading, spacing: 8) { heading; BudgetStatus(progress: progress) }
            }
            ProgressBar(progress: progress)
            ViewThatFits(in: .horizontal) {
                HStack { amounts; Spacer(minLength: 8); remainder }
                VStack(alignment: .leading, spacing: 4) { amounts; remainder }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(DS.surface, in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
    }
    private var heading: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name).font(DS.Typo.rowAmount).foregroundStyle(DS.ink)
            HStack(spacing: 0) {
                Text(categories.isEmpty ? "Conto" : categories.count > 1 ? "Multi-categoria" : "Categoria")
                Text(verbatim: " · ")
                Text("Mensile")
            }.font(DS.Typo.caption).foregroundStyle(DS.smoke)
            if !categories.isEmpty, let account = budget.account {
                Text(account.name).font(DS.Typo.caption).foregroundStyle(DS.smoke)
            }
        }
    }
    private var amounts: some View {
        HStack(spacing: 0) {
            Text(spentAmount.currencyFormatted).foregroundStyle(DS.ink)
            Text(" / " + budget.monthlyLimit.currencyFormatted).foregroundStyle(DS.smoke)
        }
            .font(DS.Typo.secondary).monospacedDigit().fixedSize(horizontal: true, vertical: false)
    }
    private var remainder: some View {
        Text(over ? String(localized: "Sforato di") + " " + abs(remaining).currencyFormatted
             : remaining.currencyFormatted + " " + String(localized: "rimasti"))
            .font(DS.Typo.caption).foregroundStyle(over ? DS.danger : DS.smoke)
    }
}

struct PlanningGoalCard: View {
    let goal: Goal
    let addProgress: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14).fill(DS.accentSoft).frame(width: 42, height: 42)
                    if !goal.emoji.isEmpty, !goal.emoji.unicodeScalars.allSatisfy({ $0.value < 128 }) {
                        Text(goal.emoji).font(DS.Typo.rowName)
                    } else {
                        Image(systemName: goal.emoji.isEmpty ? "target" : goal.emoji).foregroundStyle(DS.accent)
                    }
                }.accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.name).font(DS.Typo.rowAmount).foregroundStyle(DS.ink)
                    if let deadline = goal.deadline {
                        Text(String(localized: "Entro") + " " + deadline.dayMonthFormatted)
                            .font(DS.Typo.caption).foregroundStyle(DS.smoke)
                    } else {
                        Text("Nessuna scadenza").font(DS.Typo.caption).foregroundStyle(DS.smoke)
                    }
                }
                Spacer(minLength: 0)
                Button(action: addProgress) {
                    Image(systemName: "plus").foregroundStyle(DS.ink)
                        .frame(width: 44, height: 44)
                        .background(DS.surface, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(DS.fog))
                }
                .buttonStyle(.plain).accessibilityLabel("Aggiungi progresso")
                .accessibilityIdentifier("goal_add_\(goal.id.uuidString)")
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(DS.divider)
                    Capsule().fill(DS.accent).frame(width: geometry.size.width * goal.progress)
                }
            }.frame(height: 8).accessibilityHidden(true)
            ViewThatFits(in: .horizontal) {
                HStack { amounts; Spacer(); percentage }
                VStack(alignment: .leading, spacing: 4) { amounts; percentage }
            }
            if goal.isCompleted {
                Text("Obiettivo raggiunto").font(DS.Typo.caption).foregroundStyle(DS.accent)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(DS.surface, in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .contain)
    }
    private var amounts: some View {
        HStack(spacing: 0) {
            Text(goal.currentAmount.currencyFormatted).foregroundStyle(DS.ink)
            Text(" / " + goal.targetAmount.currencyFormatted).foregroundStyle(DS.smoke)
        }
            .font(DS.Typo.secondary).monospacedDigit().fixedSize(horizontal: true, vertical: false)
    }
    private var percentage: some View {
        Text(goal.progress, format: .percent.precision(.fractionLength(0)))
            .font(DS.Typo.rowAmount).foregroundStyle(DS.accent)
    }
}

struct PlanningProgressRing: View {
    let progress: Double
    var body: some View {
        ZStack {
            Circle().stroke(DS.heroDivider, lineWidth: 10)
            Circle().trim(from: 0, to: progress)
                .stroke(DS.heroAccent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 74, height: 74).padding(5).accessibilityHidden(true)
    }
}
