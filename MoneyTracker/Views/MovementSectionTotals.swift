import SwiftUI

struct MovementSectionTotalsValue: Equatable {
    let expenses: Decimal
    let income: Decimal
    let transferred: Decimal
}

enum MovementSectionTotals {
    /// Calcola i totali sulle stesse righe mostrate dalla lista (reali + virtuali),
    /// escludendo i trasferimenti da spese/entrate e deduplicandoli per `transferGroupId`.
    static func compute(real: [Transaction], virtual: [Occurrence]) -> MovementSectionTotalsValue {
        var expenses = Decimal.zero
        var income = Decimal.zero
        var transferred = Decimal.zero
        var seenTransferGroups: Set<String> = []

        for t in real {
            if t.isTransfer {
                let group = t.transferGroupId.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if !group.isEmpty {
                    guard seenTransferGroups.insert(group).inserted else { continue }
                }
                transferred += t.amount
            } else if t.transactionType == .entrata {
                income += t.amount
            } else {
                expenses += t.amount
            }
        }

        for occ in virtual {
            if TransactionType(rawValue: occ.type) == .entrata {
                income += occ.amount
            } else {
                expenses += occ.amount
            }
        }

        return MovementSectionTotalsValue(expenses: expenses, income: income, transferred: transferred)
    }
}

struct MovementTotalsBlock: View {
    let filter: TxFilter
    let totals: MovementSectionTotalsValue
    let hidden: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let pairLayout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: DS.Space.m))
            : AnyLayout(HStackLayout(spacing: DS.Space.m))

        Group {
            switch filter {
            case .tutti:
                pairLayout {
                    FixedTotalTile(title: "Uscite", amount: totals.expenses, color: DS.negative, hidden: hidden)
                    FixedTotalTile(title: "Entrate", amount: totals.income, color: DS.positive, hidden: hidden)
                }
            case .fisse:
                pairLayout {
                    FixedTotalTile(title: "Spese fisse", amount: totals.expenses, color: DS.negative, hidden: hidden)
                    FixedTotalTile(title: "Entrate fisse", amount: totals.income, color: DS.positive, hidden: hidden)
                }
            case .uscite:
                FixedTotalTile(title: "Uscite", amount: totals.expenses, color: DS.negative, hidden: hidden)
            case .entrate:
                FixedTotalTile(title: "Entrate", amount: totals.income, color: DS.positive, hidden: hidden)
            case .trasf:
                FixedTotalTile(title: "Trasferito", amount: totals.transferred, color: DS.transfer, hidden: hidden)
            case .ricorrenti:
                pairLayout {
                    FixedTotalTile(title: "Uscite programmate", amount: totals.expenses, color: DS.negative, hidden: hidden)
                    FixedTotalTile(title: "Entrate programmate", amount: totals.income, color: DS.positive, hidden: hidden)
                }
            }
        }
        .accessibilityIdentifier("tx_sectionTotals")
    }
}
