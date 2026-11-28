import SwiftUI

/// Individuazione e vista condivisa per i movimenti pianificati di mesi passati non ancora confermati (S-73f).
enum OverduePlannedMovements {
    static func isOverdue(_ t: Transaction, relativeTo today: Date, calendar: Calendar = .current) -> Bool {
        guard !t.isDone, !t.isTransfer else { return false }
        return calendar.compare(t.date, to: today, toGranularity: .month) == .orderedAscending
    }

    static func list(from transactions: [Transaction], relativeTo today: Date, calendar: Calendar = .current) -> [Transaction] {
        transactions.filter { isOverdue($0, relativeTo: today, calendar: calendar) }.sortedForDisplay()
    }

    static func matchingFilter(_ items: [Transaction], filter: TxFilter, ruleIDs: Set<String>) -> [Transaction] {
        switch filter {
        case .tutti:      return items
        case .fisse:      return items.filter { $0.isFixed }
        case .ricorrenti: return items.filter { ruleIDs.contains($0.templateId) }
        case .trasf:      return []
        case .uscite:     return items.filter { $0.transactionType == .uscita }
        case .entrate:    return items.filter { $0.transactionType == .entrata }
        }
    }
}

struct OverduePlannedHeader: View {
    let count: Int
    var isCompactHeader: Bool = false
    var onSeeAll: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center, spacing: DS.Space.xs) {
            Image(systemName: "clock")
                .scaledFont(size: isCompactHeader ? 12 : 14, weight: .semibold)
                .foregroundStyle(DS.plannedText)
                .accessibilityHidden(true)
            Text("Da confermare")
                .font(isCompactHeader ? DS.Typo.secondary.weight(.semibold) : DS.Typo.sectionTitle)
                .foregroundStyle(DS.plannedText)
            Text("\(count)")
                .font(DS.Typo.caption.weight(.semibold))
                .foregroundStyle(DS.plannedText)
                .padding(.horizontal, DS.Space.s)
                .padding(.vertical, 2)
                .background(DS.plannedSoft, in: Capsule())
                .accessibilityHidden(true)
            Spacer(minLength: DS.Space.s)
            if let onSeeAll {
                Button(action: onSeeAll) {
                    Text("Vedi tutti")
                        .font(DS.Typo.secondary)
                        .fontWeight(.semibold)
                        .foregroundStyle(DS.accent)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("overdue_header")
    }
}

struct OverduePlannedRow: View {
    let transaction: Transaction
    let formattedAmount: String
    var showAccount: Bool = true
    var compact: Bool = false
    var onEdit: () -> Void
    var onConfirm: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var metadata: String {
        let cat = NSLocalizedString(transaction.isFixed ? "Fissa" : transaction.category, comment: "")
        let acc = showAccount ? (transaction.account?.name ?? "") : ""
        return [cat, acc, transaction.date.dayMonthFormatted]
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }

    private var movementRow: some View {
        MovementRow(
            name: transaction.name,
            metadata: metadata,
            amount: formattedAmount,
            categoryName: transaction.category,
            categorySymbol: transaction.categoryIcon.isEmpty ? DS.categoryIcon(for: transaction.category) : transaction.categoryIcon,
            kind: transaction.transactionType == .entrata ? .income : .expense,
            isPlanned: true,
            compact: compact,
            isRecurring: !transaction.templateId.isEmpty
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
        .accessibilityValue(Text("Pianificato"))
    }

    private var confirmButton: some View {
        Button(action: onConfirm) {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(DS.Typo.caption)
                Text("Conferma")
                    .font(DS.Typo.caption.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(DS.plannedText)
            .padding(.horizontal, DS.Space.s)
            .padding(.vertical, 6)
            .background(DS.plannedSoft, in: Capsule())
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .fixedSize()
        .accessibilityIdentifier("btn_confirmOverdue_\(transaction.name)")
    }

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                movementRow
                confirmButton
            }
            .accessibilityElement(children: .contain)
        } else {
            HStack(spacing: DS.Space.s) {
                movementRow
                confirmButton
            }
            .accessibilityElement(children: .contain)
        }
    }
}
