import SwiftUI

struct MovementRow: View {
    enum Kind { case expense, income, transfer }

    let name: String
    /// Testo già localizzato e formattato dalla vista chiamante.
    let metadata: String
    /// Importo già formattato, senza segno.
    let amount: String
    let categoryName: String
    let categorySymbol: String
    var kind: Kind = .expense
    var isPlanned = false
    var compact = false
    var isRecurring = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var amountColor: Color {
        if isPlanned { return DS.plannedText }
        switch kind {
        case .expense: return DS.ink
        case .income: return DS.accent
        case .transfer: return DS.transfer
        }
    }
    private var signedAmount: String {
        switch kind {
        case .expense: return "−" + amount
        case .income: return "+" + amount
        case .transfer: return amount
        }
    }

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: DS.Space.s) {
                    movementTitle
                    Text(metadata).font(DS.Typo.caption).foregroundStyle(DS.smoke)
                    Text(signedAmount).font(DS.Typo.rowAmount).foregroundStyle(amountColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            } else {
                standardRow
            }
        }
        .padding(.vertical, compact ? 10 : DS.Layout.rowVPad)
        .accessibilityElement(children: .combine)
    }

    private var movementTitle: some View {
        HStack(spacing: DS.Space.xs) {
            Text(name).font(DS.Typo.rowName).foregroundStyle(DS.ink)
            if isRecurring {
                Image(systemName: "repeat")
                    .font(DS.Typo.caption)
                    .foregroundStyle(DS.smoke)
                    .accessibilityLabel(Text("Ricorrenza"))
            }
        }
    }

    private var standardRow: some View {
        HStack(spacing: DS.Space.m) {
            Image(systemName: kind == .transfer ? "arrow.left.arrow.right" : categorySymbol)
                .font(DS.Typo.rowName)
                .foregroundStyle(isPlanned ? DS.plannedText : kind == .transfer ? DS.transfer : CategoryTint.tint(for: categoryName).foreground)
                .frame(width: 38, height: 38)
                .background {
                    if !isPlanned {
                        RoundedRectangle(cornerRadius: DS.Space.m)
                            .fill(CategoryTint.tint(for: kind == .transfer ? "Giroconto" : categoryName).background)
                    }
                }
                .overlay {
                    if isPlanned {
                        RoundedRectangle(cornerRadius: DS.Space.m)
                            .strokeBorder(DS.planned, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    }
                }
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                movementTitle
                    .lineLimit(1)
                Text(metadata).font(DS.Typo.caption).foregroundStyle(DS.smoke)
            }
            Spacer(minLength: DS.Space.s)
            Text(signedAmount).font(DS.Typo.rowAmount).foregroundStyle(amountColor)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .layoutPriority(1)
        }
    }
}

#Preview("Light") {
    MovementRow(name: "Spesa", metadata: "Cibo · Conto · 13 nov", amount: "42 €", categoryName: "Cibo", categorySymbol: "cart")
        .padding().background(DS.surface).environment(\.colorScheme, .light)
}
#Preview("Dark") {
    VStack {
        MovementRow(name: "Spesa", metadata: "Cibo · Conto · 13 nov", amount: "42 €", categoryName: "Cibo", categorySymbol: "cart")
        MovementRow(name: "Stipendio", metadata: "Lavoro · Conto", amount: "2.000 €", categoryName: "Lavoro", categorySymbol: "briefcase", kind: .income)
        MovementRow(name: "Affitto", metadata: "Casa · Conto", amount: "600 €", categoryName: "Casa", categorySymbol: "house", isPlanned: true)
        MovementRow(name: "Giroconto", metadata: "Conto · Risparmio", amount: "100 €", categoryName: "Giroconto", categorySymbol: "", kind: .transfer)
    }.padding().background(DS.surface).environment(\.colorScheme, .dark)
}
