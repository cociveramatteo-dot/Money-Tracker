import SwiftUI

struct WhatIfView: View {
    let baselines: [WhatIfBaseline]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AppStorage("hideBalance") private var hideBalance: Bool = false

    @State private var selectedBaselineID: String = "all"
    @State private var items: [WhatIfHypothesis] = []
    @FocusState private var focusedAmountID: UUID?
    @FocusState private var focusedNameID: UUID?

    private var activeBaseline: WhatIfBaseline {
        baselines.first { $0.id == selectedBaselineID }
            ?? baselines.first
            ?? WhatIfBaseline(id: "all", name: nil, today: 0, endOfMonth: 0)
    }

    private var includedBaselines: [WhatIfBaseline] {
        baselines.filter { $0.name != nil && !$0.isExcludedFromTotal }
    }

    private var excludedBaselines: [WhatIfBaseline] {
        baselines.filter { $0.name != nil && $0.isExcludedFromTotal }
    }

    private var computation: (todayNow: Decimal, todayWith: Decimal, endNow: Decimal, endWith: Decimal, delta: Decimal) {
        WhatIfScenario.result(baseline: activeBaseline, items: items)
    }

    private func money(_ value: Decimal) -> String {
        hideBalance ? "•••• \(Double.currencySymbol)" : value.currencyFormatted
    }

    private func formattedDelta(_ value: Decimal) -> String {
        if value > 0 { return "+\(value.currencyFormatted)" }
        return value.currencyFormatted
    }

    private func deltaColor(_ value: Decimal) -> Color {
        if value > 0 { return DS.accent }
        if value < 0 { return DS.danger }
        return DS.smoke
    }

    var body: some View {
        let res = computation
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.l) {
                    accountMenu
                    hypothesesCard
                    addHypothesisButton

                    if dynamicTypeSize.isAccessibilitySize {
                        resultsCard(res)
                        footerNote
                    }
                }
                .padding(.horizontal, DS.Layout.margin)
                .padding(.top, DS.Space.m)
                .padding(.bottom, DS.Space.xl)
            }
            .background(DS.paper)
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                if !dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: DS.Space.s) {
                        resultsCard(res)
                        footerNote
                    }
                    .padding(.horizontal, DS.Layout.margin)
                    .padding(.top, DS.Space.s)
                    .padding(.bottom, DS.Space.m)
                    .background(DS.paper)
                }
            }
            .navigationTitle("E se…?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fine") { dismiss() }
                        .font(DS.Typo.rowName)
                        .foregroundStyle(DS.ink)
                        .accessibilityIdentifier("whatIf.done")
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Fine") {
                        focusedAmountID = nil
                        focusedNameID = nil
                    }
                    .font(DS.Typo.rowName.weight(.semibold))
                    .foregroundStyle(DS.accent)
                    .accessibilityIdentifier("whatIf.keyboardDone")
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("whatIf.sheet")
        .presentationDetents([.large])
        .presentationBackground(DS.paper)
    }

    private var accountMenu: some View {
        Menu {
            if let allBaseline = baselines.first(where: { $0.name == nil }) {
                Button {
                    selectedBaselineID = allBaseline.id
                } label: {
                    menuRowLabel(String(localized: "Tutti"), selected: activeBaseline.id == allBaseline.id)
                }
            }
            ForEach(includedBaselines) { baseline in
                Button {
                    selectedBaselineID = baseline.id
                } label: {
                    menuRowLabel(baseline.name ?? "", selected: activeBaseline.id == baseline.id)
                }
            }
            if !excludedBaselines.isEmpty {
                Section("Esclusi dal totale") {
                    ForEach(excludedBaselines) { baseline in
                        Button {
                            selectedBaselineID = baseline.id
                        } label: {
                            menuRowLabel(baseline.name ?? "", selected: activeBaseline.id == baseline.id)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: DS.Space.s) {
                Text(activeBaseline.name ?? String(localized: "Tutti"))
                    .font(DS.Typo.rowName)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(DS.Typo.caption)
                    .accessibilityHidden(true)
            }
            .foregroundStyle(DS.ink)
            .padding(.horizontal, DS.Space.l)
            .frame(minHeight: 44)
            .background(DS.surface, in: Capsule())
            .overlay(Capsule().strokeBorder(DS.fog, lineWidth: 1))
        }
        .accessibilityIdentifier("whatIf.accountMenu")
    }

    @ViewBuilder
    private func menuRowLabel(_ title: String, selected: Bool) -> some View {
        if selected {
            Label(title, systemImage: "checkmark")
        } else {
            Text(verbatim: title)
        }
    }

    private var hypothesesCard: some View {
        Card {
            if items.isEmpty {
                Text("Nessuna ipotesi: aggiungine una")
                    .font(DS.Typo.secondary)
                    .foregroundStyle(DS.smoke)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, DS.Space.xs)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        if index > 0 {
                            ThinDivider().padding(.vertical, DS.Space.m)
                        }
                        hypothesisRow(index: index, item: $items[index])
                            .contextMenu {
                                Button(role: .destructive) {
                                    removeItem(id: item.id)
                                } label: {
                                    Label("Elimina", systemImage: "trash")
                                }
                            }
                            .accessibilityAction(named: Text("Elimina")) {
                                removeItem(id: item.id)
                            }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func hypothesisRow(index: Int, item: Binding<WhatIfHypothesis>) -> some View {
        let invalid = WhatIfScenario.isInvalidInput(item.wrappedValue.amountText)
        let isOn = item.wrappedValue.isOn
        let displayName = item.wrappedValue.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let toggleValue = displayName.isEmpty ? String(localized: "Ipotesi senza nome") : displayName

        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: DS.Space.s) {
                HStack(spacing: DS.Space.s) {
                    signButton(index: index, isIncome: item.isIncome)
                    amountField(index: index, item: item, invalid: invalid, isOn: isOn)
                        .frame(maxWidth: .infinity)
                    rowToggle(index: index, isOn: item.isOn, value: toggleValue)
                }
                nameField(index: index, name: item.name, isOn: isOn, id: item.wrappedValue.id)
            }
        } else {
            HStack(spacing: DS.Space.s) {
                signButton(index: index, isIncome: item.isIncome)
                amountField(index: index, item: item, invalid: invalid, isOn: isOn)
                    .frame(minWidth: 88, maxWidth: 112)
                nameField(index: index, name: item.name, isOn: isOn, id: item.wrappedValue.id)
                    .frame(maxWidth: .infinity)
                rowToggle(index: index, isOn: item.isOn, value: toggleValue)
            }
        }
    }

    private func signButton(index: Int, isIncome: Binding<Bool>) -> some View {
        Button {
            isIncome.wrappedValue.toggle()
        } label: {
            Image(systemName: isIncome.wrappedValue ? "plus" : "minus")
                .font(DS.Typo.rowName.weight(.semibold))
                .foregroundStyle(isIncome.wrappedValue ? DS.accent : DS.danger)
                .frame(width: 44, height: 44)
                .background(isIncome.wrappedValue ? DS.accentSoft : DS.dangerSoft, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(isIncome.wrappedValue ? "Entrata" : "Spesa"))
        .accessibilityIdentifier("whatIf.row.\(index).sign")
    }

    private func amountField(index: Int, item: Binding<WhatIfHypothesis>, invalid: Bool, isOn: Bool) -> some View {
        TextField("0,00", text: item.amountText)
            .font(DS.Typo.rowAmount)
            .foregroundStyle(isOn ? DS.ink : DS.smoke)
            .multilineTextAlignment(.trailing)
            .keyboardType(.decimalPad)
            .focused($focusedAmountID, equals: item.wrappedValue.id)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(minHeight: 44)
            .background(DS.paper, in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(invalid ? DS.danger : DS.fog, lineWidth: invalid ? 1.5 : 1)
            )
            .accessibilityLabel(Text("Importo"))
            .accessibilityIdentifier("whatIf.row.\(index).amount")
    }

    private func nameField(index: Int, name: Binding<String>, isOn: Bool, id: UUID) -> some View {
        TextField("Nome (es. cena)", text: name)
            .font(DS.Typo.rowName)
            .foregroundStyle(isOn ? DS.ink : DS.smoke)
            .focused($focusedNameID, equals: id)
            .frame(minHeight: 44)
            .accessibilityIdentifier("whatIf.row.\(index).name")
    }

    private func rowToggle(index: Int, isOn: Binding<Bool>, value: String) -> some View {
        Toggle("", isOn: isOn)
            .labelsHidden()
            .tint(DS.accent)
            .accessibilityLabel(Text("Includi nel calcolo"))
            .accessibilityValue(Text(verbatim: value))
            .accessibilityIdentifier("whatIf.row.\(index).toggle")
    }

    private var addHypothesisButton: some View {
        let disabled = items.count >= WhatIfScenario.maxHypotheses
        return Button {
            addHypothesis()
        } label: {
            HStack(spacing: DS.Space.s) {
                Image(systemName: "plus")
                Text("Aggiungi ipotesi")
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(DS.Typo.rowName.weight(.semibold))
            .foregroundStyle(disabled ? DS.smoke : DS.accent)
            .padding(.horizontal, DS.Space.l)
            .padding(.vertical, DS.Space.m)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .background(DS.surface, in: RoundedRectangle(cornerRadius: DS.Layout.cardRadius))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .accessibilityIdentifier("whatIf.addHypothesis")
    }

    private func resultsCard(
        _ res: (todayNow: Decimal, todayWith: Decimal, endNow: Decimal, endWith: Decimal, delta: Decimal)
    ) -> some View {
        Card {
            VStack(alignment: .leading, spacing: DS.Space.m) {
                resultRow(
                    title: "Saldo di oggi",
                    nowText: money(res.todayNow),
                    withText: money(res.todayWith),
                    nowID: "whatIf.result.today.now",
                    withID: "whatIf.result.today.with"
                )
                resultRow(
                    title: "Saldo atteso a fine mese",
                    nowText: money(res.endNow),
                    withText: money(res.endWith),
                    nowID: "whatIf.result.end.now",
                    withID: "whatIf.result.end.with"
                )
                ThinDivider()
                HStack(alignment: .firstTextBaseline, spacing: DS.Space.s) {
                    Text("Differenza totale")
                        .font(DS.Typo.secondary)
                        .foregroundStyle(DS.smoke)
                    Spacer(minLength: DS.Space.s)
                    Text(formattedDelta(res.delta))
                        .font(DS.Typo.sectionTitle.monospacedDigit())
                        .foregroundStyle(deltaColor(res.delta))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .accessibilityIdentifier("whatIf.result.delta")
                }
                .accessibilityElement(children: .contain)
            }
        }
    }

    private func resultRow(
        title: LocalizedStringKey,
        nowText: String,
        withText: String,
        nowID: String,
        withID: String
    ) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            Text(title)
                .font(DS.Typo.secondary)
                .foregroundStyle(DS.smoke)
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: DS.Space.xs) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ora").font(DS.Typo.caption).foregroundStyle(DS.smoke)
                        Text(verbatim: nowText)
                            .font(DS.Typo.rowAmount)
                            .foregroundStyle(DS.smoke)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .accessibilityLabel(Text(verbatim: "\(String(localized: "Ora")) \(nowText)"))
                            .accessibilityIdentifier(nowID)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Con le ipotesi").font(DS.Typo.caption).foregroundStyle(DS.smoke)
                        Text(verbatim: withText)
                            .font(DS.Typo.sectionTitle.monospacedDigit())
                            .foregroundStyle(DS.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .accessibilityLabel(Text(verbatim: "\(String(localized: "Con le ipotesi")) \(withText)"))
                            .accessibilityIdentifier(withID)
                    }
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: DS.Space.s) {
                    Text(verbatim: nowText)
                        .font(DS.Typo.rowAmount)
                        .foregroundStyle(DS.smoke)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .accessibilityLabel(Text(verbatim: "\(String(localized: "Ora")) \(nowText)"))
                        .accessibilityIdentifier(nowID)
                    Text(verbatim: "→")
                        .font(DS.Typo.secondary)
                        .foregroundStyle(DS.smoke)
                        .accessibilityHidden(true)
                    Text(verbatim: withText)
                        .font(DS.Typo.sectionTitle.monospacedDigit())
                        .foregroundStyle(DS.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .accessibilityLabel(Text(verbatim: "\(String(localized: "Con le ipotesi")) \(withText)"))
                        .accessibilityIdentifier(withID)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var footerNote: some View {
        Text("Le ipotesi non vengono salvate")
            .font(DS.Typo.caption)
            .foregroundStyle(DS.smoke)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func addHypothesis() {
        guard items.count < WhatIfScenario.maxHypotheses else { return }
        let item = WhatIfHypothesis()
        items.append(item)
        focusedAmountID = item.id
    }

    private func removeItem(id: UUID) {
        items.removeAll { $0.id == id }
    }
}
