import SwiftData
import SwiftUI

/// Individuazione e vista condivisa per i movimenti pianificati di mesi passati non ancora confermati (S-73f/S-73g).
enum OverduePlannedMovements {
    static let borderOpacity: Double = 0.35

    static func isOverdue(_ t: Transaction, relativeTo today: Date, calendar: Calendar = .current) -> Bool {
        guard !t.isDone, !t.isTransfer, !(t.account?.isArchived ?? false) else { return false }
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

    static func resolvedCategorySymbol(for transaction: Transaction) -> String {
        if !transaction.categoryIcon.isEmpty && transaction.categoryIcon != "circle.dotted" {
            return transaction.categoryIcon
        }
        return DS.categoryIcon(for: transaction.category)
    }

    /// Cache della scansione «Da confermare»: evita di ri-filtrare e ri-ordinare tutti i movimenti
    /// a ogni render non legato ai dati o al giorno di riferimento. Non è @Observable:
    /// si aggiorna solo la scatola interna senza mutare stato osservato durante il render.
    final class ListCache {
        private var fingerprint: Int?
        private var cached: [Transaction] = []

        func list(from transactions: [Transaction], relativeTo day: Date, calendar: Calendar = .current) -> [Transaction] {
            let fp = Self.fingerprint(transactions: transactions, day: day)
            if fingerprint == fp { return cached }
            let result = OverduePlannedMovements.list(from: transactions, relativeTo: day, calendar: calendar)
            fingerprint = fp
            cached = result
            return result
        }

        private static func fingerprint(transactions: [Transaction], day: Date) -> Int {
            var hasher = Hasher()
            hasher.combine(day)
            hasher.combine(transactions.count)
            for t in transactions {
                hasher.combine(t.persistentModelID)
                hasher.combine(t.id)
                hasher.combine(t.isDone)
                hasher.combine(t.isTransfer)
                hasher.combine(t.account?.persistentModelID)
                hasher.combine(t.account?.isArchived)
                hasher.combine(t.date)
                hasher.combine(t.createdAt)
            }
            return hasher.finalize()
        }
    }

    /// Cache della sezione «Da confermare» in Movimenti: combina la scansione base memoizzata
    /// e i filtri attivi nella tab Movimenti.
    final class FilteredCache {
        private let baseCache = ListCache()
        private var fingerprint: Int?
        private var cached: [Transaction] = []

        func list(
            from transactions: [Transaction],
            relativeTo day: Date,
            selectedMonth: Date,
            searchQuery: String,
            useCustomDates: Bool,
            filter: TxFilter,
            selectedCategory: String,
            minAmountText: String,
            maxAmountText: String,
            rules: [RecurringRule],
            calendar: Calendar = .current
        ) -> [Transaction] {
            let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            guard calendar.isDate(selectedMonth, equalTo: day, toGranularity: .month),
                  trimmedQuery.isEmpty,
                  !useCustomDates else {
                fingerprint = nil
                cached = []
                return []
            }
            let base = baseCache.list(from: transactions, relativeTo: day, calendar: calendar)
            let fp = Self.fingerprint(
                base: base,
                day: day,
                filter: filter,
                selectedCategory: selectedCategory,
                minAmountText: minAmountText,
                maxAmountText: maxAmountText,
                rules: rules
            )
            if fingerprint == fp { return cached }
            let ruleIDs = Set(rules.map { $0.id.uuidString })
            let minAmt = Decimal.parseAmount(minAmountText)
            let maxAmt = Decimal.parseAmount(maxAmountText)
            let filtered = OverduePlannedMovements.matchingFilter(base, filter: filter, ruleIDs: ruleIDs)
                .filter { t in
                    (selectedCategory.isEmpty || t.category == selectedCategory)
                        && (minAmt.map { t.amount >= $0 } ?? true)
                        && (maxAmt.map { t.amount <= $0 } ?? true)
                }
            fingerprint = fp
            cached = filtered
            return filtered
        }

        private static func fingerprint(
            base: [Transaction],
            day: Date,
            filter: TxFilter,
            selectedCategory: String,
            minAmountText: String,
            maxAmountText: String,
            rules: [RecurringRule]
        ) -> Int {
            var hasher = Hasher()
            hasher.combine(day)
            hasher.combine(filter)
            hasher.combine(selectedCategory)
            hasher.combine(minAmountText)
            hasher.combine(maxAmountText)
            hasher.combine(rules.count)
            for r in rules {
                hasher.combine(r.id)
            }
            hasher.combine(base.count)
            for t in base {
                hasher.combine(t.persistentModelID)
                hasher.combine(t.isFixed)
                hasher.combine(t.templateId)
                hasher.combine(t.type)
                hasher.combine(t.category)
                hasher.combine(t.amount)
            }
            return hasher.finalize()
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

struct OverduePlannedSection: View {
    let items: [Transaction]
    let formattedAmount: (Transaction) -> String
    var onSeeAll: (() -> Void)? = nil
    var onEdit: (Transaction) -> Void
    var onConfirm: (Transaction) -> Void

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: DS.Space.m) {
                OverduePlannedHeader(count: items.count, onSeeAll: onSeeAll)
                    .padding(.horizontal, DS.Layout.margin)
                    .padding(.top, DS.Space.l)

                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.persistentModelID) { index, t in
                        if index > 0 {
                            ThinDivider().padding(.leading, 64)
                        }
                        OverduePlannedRow(
                            transaction: t,
                            formattedAmount: formattedAmount(t),
                            compact: false,
                            onEdit: { onEdit(t) },
                            onConfirm: { onConfirm(t) }
                        )
                        .padding(.horizontal, DS.Space.l)
                    }
                }
                .background(DS.surface, in: RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(DS.planned.opacity(OverduePlannedMovements.borderOpacity), lineWidth: 1)
                )
                .padding(.horizontal, 16)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("home_overdueSection")
        }
    }
}

struct OverduePlannedCardBackground: View {
    let isFirst: Bool
    let isLast: Bool
    var cornerRadius: CGFloat = 18

    var body: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: isFirst ? cornerRadius : 0,
            bottomLeadingRadius: isLast ? cornerRadius : 0,
            bottomTrailingRadius: isLast ? cornerRadius : 0,
            topTrailingRadius: isFirst ? cornerRadius : 0
        )
        .fill(DS.surface)
        .overlay {
            OverdueCardBorderShape(isFirst: isFirst, isLast: isLast, cornerRadius: cornerRadius)
                .stroke(DS.planned.opacity(OverduePlannedMovements.borderOpacity), lineWidth: 1)
        }
    }
}

private struct OverdueCardBorderShape: Shape {
    let isFirst: Bool
    let isLast: Bool
    let cornerRadius: CGFloat

    nonisolated func path(in rect: CGRect) -> Path {
        if isFirst && isLast {
            let inset = rect.insetBy(dx: 0.5, dy: 0.5)
            return Path(roundedRect: inset, cornerRadius: max(0, cornerRadius - 0.5))
        }
        let xMin = rect.minX + 0.5
        let xMax = rect.maxX - 0.5
        let yMin = rect.minY + (isFirst ? 0.5 : 0)
        let yMax = rect.maxY - (isLast ? 0.5 : 0)
        let r = max(0, cornerRadius - 0.5)
        var p = Path()

        if isFirst {
            p.move(to: CGPoint(x: xMin, y: yMax))
            p.addArc(tangent1End: CGPoint(x: xMin, y: yMin), tangent2End: CGPoint(x: xMax, y: yMin), radius: r)
            p.addArc(tangent1End: CGPoint(x: xMax, y: yMin), tangent2End: CGPoint(x: xMax, y: yMax), radius: r)
            p.addLine(to: CGPoint(x: xMax, y: yMax))
        } else if isLast {
            p.move(to: CGPoint(x: xMax, y: yMin))
            p.addArc(tangent1End: CGPoint(x: xMax, y: yMax), tangent2End: CGPoint(x: xMin, y: yMax), radius: r)
            p.addArc(tangent1End: CGPoint(x: xMin, y: yMax), tangent2End: CGPoint(x: xMin, y: yMin), radius: r)
            p.addLine(to: CGPoint(x: xMin, y: yMin))
        } else {
            p.move(to: CGPoint(x: xMin, y: yMin))
            p.addLine(to: CGPoint(x: xMin, y: yMax))
            p.move(to: CGPoint(x: xMax, y: yMin))
            p.addLine(to: CGPoint(x: xMax, y: yMax))
        }
        return p
    }
}

struct OverduePlannedRow: View {
    let transaction: Transaction
    let formattedAmount: String
    var compact: Bool = false
    var onEdit: () -> Void
    var onConfirm: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var categoryLabel: String {
        NSLocalizedString(transaction.isFixed ? "Fissa" : transaction.category, comment: "")
    }

    private var dateTail: String {
        " · \(transaction.date.dayMonthFormatted)"
    }

    private var movementRow: some View {
        MovementRow(
            name: transaction.name,
            metadata: categoryLabel,
            metadataTail: dateTail,
            singleLineMetadata: true,
            amount: formattedAmount,
            categoryName: transaction.category,
            categorySymbol: OverduePlannedMovements.resolvedCategorySymbol(for: transaction),
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
            Image(systemName: "checkmark")
                .scaledFont(size: 13, weight: .bold)
                .foregroundStyle(DS.plannedText)
                .frame(width: 32, height: 32)
                .background(DS.plannedSoft, in: Circle())
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .fixedSize()
        .accessibilityLabel(Text("Conferma"))
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
            HStack(spacing: 4) {
                movementRow
                confirmButton
                    .padding(.trailing, -6)
            }
            .accessibilityElement(children: .contain)
        }
    }
}
