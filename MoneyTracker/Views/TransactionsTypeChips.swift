import SwiftUI

struct TransactionsTypeChips: View {
    let typeChipHeight: CGFloat
    @Binding var selectedType: TxFilter
    @Binding var navPath: [TxFilter]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach([TxFilter.tutti, .fisse, .trasf, .uscite, .entrate, .ricorrenti], id: \.self) { f in
                    Button {
                        if f == .ricorrenti {
                            navPath.append(.ricorrenti)
                        } else {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedType = f
                            }
                        }
                    } label: {
                        Text(LocalizedStringKey(f.rawValue))
                            .font(DS.Typo.secondary.weight(selectedType == f ? .semibold : .medium))
                            .foregroundStyle(selectedType == f ? DS.surface : DS.ink)
                            .padding(.horizontal, 14)
                            .frame(minHeight: typeChipHeight)
                            .background(selectedType == f ? DS.ink : DS.surface, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(selectedType == f ? Color.clear : DS.fog))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selectedType == f ? [.isSelected] : [])
                    .accessibilityIdentifier("txFilterBlock_\(f.rawValue)")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, DS.Space.s)
        }
        .accessibilityIdentifier("tx_typeChips")
    }
}
