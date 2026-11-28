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
