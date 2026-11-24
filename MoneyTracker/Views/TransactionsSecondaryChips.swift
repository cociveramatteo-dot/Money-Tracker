import SwiftUI

struct TransactionsSecondaryChips: View {
    @Binding var selectedMonth: Date
    @Binding var selectedCat: String
    @Binding var showAdvancedFilter: Bool
    @Binding var filterMinAmount: String
    @Binding var filterMaxAmount: String
    @Binding var filterUseCustomDates: Bool
    let categories: [Category]
    let recentMonths: [Date]
    let secondaryChipHeight: CGFloat
    let activeAdvancedFilterCount: Int
    let activeFilterSummaryLabel: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                // 1. Mese ▾ (compatto con bordo tratteggiato, da mockup)
                Menu {
                    Button {
                        selectedMonth = Date()
                    } label: {
                        Label(String(localized: "Questo mese"), systemImage: "calendar")
                    }
                    Button {
                        selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                    } label: {
                        Label(String(localized: "Mese precedente"), systemImage: "chevron.left")
                    }
                    Button {
                        selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                    } label: {
                        Label(String(localized: "Mese successivo"), systemImage: "chevron.right")
                    }
                    Divider()
                    ForEach(recentMonths, id: \.self) { m in
                        Button {
                            selectedMonth = m
                        } label: {
                            HStack {
                                Text(m.monthYearFormatted)
                                if m.isSameMonth(as: selectedMonth) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("\(selectedMonth.monthYearFormatted) ▾")
                            .font(DS.Typo.secondary)
                            .foregroundStyle(DS.ink)
                    }
                    .padding(.horizontal, 12)
                    .frame(minHeight: secondaryChipHeight)
                    .background(Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(DS.filterBorder, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    )
                }
                .accessibilityIdentifier("btn_monthPicker")

                // 2. Categoria ▾ (menu pulito con icone e stato attivo)
                Menu {
                    Button {
                        selectedCat = ""
                    } label: {
                        HStack {
                            Text(String(localized: "Tutte le categorie"))
                            if selectedCat.isEmpty {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    Divider()
                    ForEach(categories) { cat in
                        Button {
                            selectedCat = (selectedCat == cat.name ? "" : cat.name)
                        } label: {
                            HStack {
                                DS.categoryText(cat.name)
                                if selectedCat == cat.name {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        if selectedCat.isEmpty {
                            Text(String(localized: "Categoria"))
                        } else {
                            DS.categoryText(selectedCat)
                        }
                        Text("▾")
                    }
                    .font(DS.Typo.secondary)
                    .fontWeight(selectedCat.isEmpty ? .regular : .semibold)
                    .foregroundStyle(selectedCat.isEmpty ? DS.ink : DS.accent)
                    .padding(.horizontal, 12)
                    .frame(minHeight: secondaryChipHeight)
                    .background(selectedCat.isEmpty ? Color.clear : DS.accentSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(selectedCat.isEmpty ? DS.filterBorder : Color.clear, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    )
                }
                .accessibilityIdentifier("btn_categoryFilter")

                // 3. Filtri avanzati attivi (chip verde soft con xmark, presente solo se attivi)
                if activeAdvancedFilterCount > 0 {
                    HStack(spacing: 6) {
                        Button {
                            showAdvancedFilter = true
                        } label: {
                            Text(activeFilterSummaryLabel)
                                .font(DS.Typo.secondary.weight(.semibold))
                                .foregroundStyle(DS.accent)
                        }
                        Button {
                            filterMinAmount = ""
                            filterMaxAmount = ""
                            filterUseCustomDates = false
                        } label: {
                            Image(systemName: "xmark")
                                .scaledFont(size: 10, weight: .bold)
                                .foregroundStyle(DS.accent)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text("Rimuovi filtri"))
                    }
                    .padding(.horizontal, 12)
                    .frame(minHeight: secondaryChipHeight)
                    .background(DS.accentSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .accessibilityIdentifier("btn_activeFilterBadge")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, DS.Space.xs)
        }
    }
}
