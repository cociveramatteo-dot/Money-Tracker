import SwiftUI

struct TransactionsAdvancedFilterSheet: View {
    @Binding var filterMinAmount: String
    @Binding var filterMaxAmount: String
    @Binding var filterUseCustomDates: Bool
    @Binding var filterFromDate: Date
    @Binding var filterToDate: Date
    @Binding var showAdvancedFilter: Bool
    let activeAdvancedFilterCount: Int

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.xxl) {

                    VStack(alignment: .leading, spacing: DS.Space.m) {
                        SectionLabel(text: "Importo")
                        HStack(spacing: DS.Space.l) {
                            VStack(alignment: .leading, spacing: DS.Space.s) {
                                Text("Minimo")
                                    .scaledFont(size: 12)
                                    .foregroundStyle(DS.smoke)
                                HStack(spacing: 4) {
                                    Text(Double.currencySymbol)
                                        .scaledFont(size: 16, weight: .light)
                                        .foregroundStyle(DS.smoke)
                                    TextField("0", text: $filterMinAmount)
                                        .scaledFont(size: 20, weight: .medium)
                                        .foregroundStyle(DS.ink)
                                        .keyboardType(.decimalPad)
                                }
                                ThinDivider()
                            }
                            VStack(alignment: .leading, spacing: DS.Space.s) {
                                Text("Massimo")
                                    .scaledFont(size: 12)
                                    .foregroundStyle(DS.smoke)
                                HStack(spacing: 4) {
                                    Text(Double.currencySymbol)
                                        .scaledFont(size: 16, weight: .light)
                                        .foregroundStyle(DS.smoke)
                                    TextField("∞", text: $filterMaxAmount)
                                        .scaledFont(size: 20, weight: .medium)
                                        .foregroundStyle(DS.ink)
                                        .keyboardType(.decimalPad)
                                }
                                ThinDivider()
                            }
                        }
                    }

                    ThinDivider()

                    VStack(alignment: .leading, spacing: DS.Space.m) {
                        SectionLabel(text: "Periodo")
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Periodo personalizzato")
                                    .scaledFont(size: 15)
                                    .foregroundStyle(DS.ink)
                                Text("Sostituisce il filtro mese")
                                    .scaledFont(size: 11)
                                    .foregroundStyle(DS.smoke)
                            }
                            Spacer()
                            Toggle("", isOn: $filterUseCustomDates)
                                .tint(DS.ink)
                                .labelsHidden()
                        }

                        if filterUseCustomDates {
                            HStack {
                                VStack(alignment: .leading, spacing: DS.Space.xs) {
                                    Text("Da")
                                        .scaledFont(size: 12)
                                        .foregroundStyle(DS.smoke)
                                    DatePicker("", selection: $filterFromDate, displayedComponents: .date)
                                        .labelsHidden()
                                        .tint(DS.ink)
                                }
                                Spacer()
                                VStack(alignment: .leading, spacing: DS.Space.xs) {
                                    Text("A")
                                        .scaledFont(size: 12)
                                        .foregroundStyle(DS.smoke)
                                    DatePicker("", selection: $filterToDate,
                                               in: filterFromDate...,
                                               displayedComponents: .date)
                                        .labelsHidden()
                                        .tint(DS.ink)
                                }
                            }
                            .padding(.top, DS.Space.xs)
                        }
                    }

                    ThinDivider()

                    if activeAdvancedFilterCount > 0 {
                        Button {
                            filterMinAmount = ""
                            filterMaxAmount = ""
                            filterUseCustomDates = false
                        } label: {
                            HStack {
                                Image(systemName: "xmark.circle")
                                    .scaledFont(size: 14)
                                Text("Rimuovi tutti i filtri")
                                    .scaledFont(size: 15)
                            }
                            .foregroundStyle(DS.smoke)
                        }
                    }
                }
                .padding(.horizontal, DS.Layout.margin)
                .padding(.top, DS.Space.xl)
                .padding(.bottom, DS.Space.xxl)
            }
            .background(DS.paper)
            .scrollIndicators(.hidden)
            .navigationTitle("Filtri")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fine") { showAdvancedFilter = false }
                        .scaledFont(size: 15, weight: .medium)
                        .foregroundStyle(DS.ink)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
