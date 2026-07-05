import SwiftUI
import SwiftData

// MARK: - Goal Row

struct GoalRow: View {
    let goal: Goal

    /// SF Symbol da mostrare — retrocompat: se è un emoji (non-ASCII) usa default
    private var iconName: String {
        let s = goal.emoji
        guard !s.isEmpty, s.unicodeScalars.allSatisfy({ $0.value < 128 }) else { return "target" }
        return s
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            HStack(alignment: .firstTextBaseline) {
                ZStack {
                    Circle()
                        .fill(DS.fog)
                        .frame(width: 36, height: 36)
                    Image(systemName: iconName)
                        .font(.system(size: 15))
                        .foregroundStyle(DS.smoke)
                }
                .padding(.trailing, DS.Space.xs)

                VStack(alignment: .leading, spacing: DS.Space.xs) {
                    Text(goal.name)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(DS.ink)
                    if let d = goal.deadline {
                        Text(NSLocalizedString("Entro", comment: "") + " " + d.dayMonthFormatted)
                            .font(.system(size: 12))
                            .foregroundStyle(DS.smoke)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: DS.Space.xs) {
                    HStack(alignment: .lastTextBaseline, spacing: 1) {
                        Text(String(Int(goal.progress * 100)))
                            .font(.system(size: 28, weight: .black))
                            .foregroundStyle(DS.ink)
                        Text("%")
                            .font(.system(size: 14, weight: .ultraLight))
                            .foregroundStyle(DS.smoke)
                    }
                    Text(goal.currentAmount.currencyFormatted + " / " + goal.targetAmount.currencyFormatted)
                        .font(.system(size: 11))
                        .foregroundStyle(DS.smoke)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(DS.fog).frame(height: 2)
                    Rectangle()
                        .fill(goal.isCompleted ? DS.ink : DS.smoke)
                        .frame(width: geo.size.width * goal.progress, height: 2)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: goal.progress)
                }
            }
            .frame(height: 2)

            if goal.isCompleted {
                Text("Obiettivo raggiunto")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(DS.smoke)
                    .tracking(1)
            }
        }
        .padding(.vertical, DS.Space.l)
        .opacity(goal.isCompleted ? 0.5 : 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel({
            let pctStr   = "\(Int(goal.progress * 100))%"
            let amounts  = "\(goal.currentAmount.currencyFormatted) su \(goal.targetAmount.currencyFormatted)"
            let deadline: String = {
                guard let d = goal.deadline else { return "" }
                return ", scadenza \(d.dayMonthFormatted)"
            }()
            let status = goal.isCompleted ? ", obiettivo raggiunto" : ""
            return "\(goal.name), \(pctStr)\(status), \(amounts)\(deadline)"
        }())
    }
}

// MARK: - Add / Edit Goal

struct AddGoalView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var editing: Goal? = nil

    @State private var name        = ""
    @State private var target      = ""
    @State private var current     = ""
    @State private var addSavings  = ""
    @State private var hasDeadline = false
    @State private var deadline    = Self.defaultDeadline
    @State private var selectedEmoji: String = "target"
    @State private var showEmojiPicker = false

    private static var defaultDeadline: Date {
        Calendar.current.date(byAdding: .day, value: 90, to: Date()) ?? Date()
    }

    private let goalIcons: [String] = [
        "target",            "trophy.fill",        "star.fill",          "flag.fill",
        "crown.fill",        "rosette",             "house.fill",         "car.fill",
        "airplane",          "tram.fill",           "bicycle",            "figure.walk",
        "eurosign.circle.fill","creditcard.fill",   "banknote",           "chart.line.uptrend.xyaxis",
        "building.columns.fill","cart.fill",        "graduationcap.fill", "book.fill",
        "laptopcomputer",    "iphone",              "headphones",         "paintbrush.fill",
        "heart.fill",        "figure.run",          "dumbbell.fill",      "leaf.fill",
        "fork.knife",        "bed.double.fill",     "gift.fill",          "pawprint.fill",
        "sparkles",          "camera.fill",         "music.note",         "map.fill",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.xxl) {

                    Text(LocalizedStringKey(editing == nil ? "Nuovo obiettivo" : "Modifica"))
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(DS.ink)

                    VStack(alignment: .leading, spacing: DS.Space.m) {
                        SectionLabel(text: "Icona")
                        Button { showEmojiPicker.toggle() } label: {
                            HStack(spacing: DS.Space.m) {
                                ZStack {
                                    Circle()
                                        .fill(DS.fog)
                                        .frame(width: 52, height: 52)
                                    Image(systemName: selectedEmoji)
                                        .font(.system(size: 22))
                                        .foregroundStyle(DS.ink)
                                }
                                Text("Cambia icona")
                                    .font(.system(size: 15))
                                    .foregroundStyle(DS.smoke)
                                Spacer()
                                Image(systemName: showEmojiPicker ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 11))
                                    .foregroundStyle(DS.smoke)
                            }
                        }

                        if showEmojiPicker {
                            let cols = Array(repeating: GridItem(.flexible()), count: 6)
                            LazyVGrid(columns: cols, spacing: DS.Space.m) {
                                ForEach(goalIcons, id: \.self) { icon in
                                    Button {
                                        selectedEmoji = icon
                                        showEmojiPicker = false
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .fill(selectedEmoji == icon ? DS.ink : DS.fog)
                                                .frame(width: 44, height: 44)
                                            Image(systemName: icon)
                                                .font(.system(size: 16))
                                                .foregroundStyle(selectedEmoji == icon ? DS.paper : DS.smoke)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.top, DS.Space.s)
                        }

                        ThinDivider()
                    }

                    VStack(alignment: .leading, spacing: DS.Space.m) {
                        SectionLabel(text: "Nome")
                        TextField("es. Vacanza, Auto nuova...", text: $name)
                            .font(.system(size: 22, weight: .light))
                            .foregroundStyle(DS.ink)
                        ThinDivider()
                    }

                    VStack(alignment: .leading, spacing: DS.Space.m) {
                        SectionLabel(text: "Obiettivo")
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(Double.currencySymbol)
                                .font(.system(size: 28, weight: .ultraLight))
                                .foregroundStyle(DS.smoke)
                            TextField("0", text: $target)
                                .font(.system(size: 56, weight: .black))
                                .foregroundStyle(DS.ink)
                                .keyboardType(.decimalPad)
                        }
                        ThinDivider()
                    }

                    VStack(alignment: .leading, spacing: DS.Space.m) {
                        SectionLabel(text: editing == nil ? "Già risparmiato" : "Aggiungi risparmio")
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text("+\(Double.currencySymbol)")
                                .font(.system(size: 22, weight: .ultraLight))
                                .foregroundStyle(DS.smoke)
                            TextField("0", text: editing == nil ? $current : $addSavings)
                                .font(.system(size: 40, weight: .light))
                                .foregroundStyle(DS.ink)
                                .keyboardType(.decimalPad)
                        }
                        ThinDivider()
                    }

                    VStack(alignment: .leading, spacing: DS.Space.m) {
                        SectionLabel(text: "Scadenza")
                        HStack {
                            Toggle("Imposta scadenza", isOn: $hasDeadline)
                                .font(.system(size: 15))
                                .foregroundStyle(DS.smoke)
                                .tint(DS.ink)
                        }
                        if hasDeadline {
                            DatePicker("", selection: $deadline, displayedComponents: .date)
                                .labelsHidden()
                                .tint(DS.ink)
                        }
                    }

                    PrimaryButton(title: editing == nil ? "Salva" : "Aggiorna") { save() }
                        .disabled(name.isEmpty || target.isEmpty)
                }
                .padding(.horizontal, DS.Layout.margin)
                .padding(.top, DS.Space.xl)
                .padding(.bottom, DS.Space.xxl)
            }
            .background(DS.paper)
            .scrollIndicators(.hidden)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    GhostButton(title: "Annulla") { dismiss() }
                }
            }
            .onAppear { load() }
        }
    }

    private func load() {
        guard let g = editing else {
            name          = ""
            target        = ""
            current       = ""
            addSavings    = ""
            hasDeadline   = false
            deadline      = Self.defaultDeadline
            selectedEmoji = "target"
            return
        }
        name          = g.name
        target        = g.targetAmount.editableString
        current       = g.currentAmount.editableString
        addSavings    = ""
        let stored = g.emoji
        selectedEmoji = (!stored.isEmpty && stored.unicodeScalars.allSatisfy { $0.value < 128 }) ? stored : "target"
        hasDeadline   = false
        if let d = g.deadline { hasDeadline = true; deadline = d }
        showEmojiPicker = false
    }

    private func save() {
        let t = Decimal.parseAmount(target) ?? 0
        guard t > 0 else { return }
        let c = Decimal.parseAmount(current) ?? 0
        let extra = Decimal.parseAmount(addSavings) ?? 0

        if let g = editing {
            g.name          = name
            g.targetAmount  = t
            g.emoji         = selectedEmoji
            g.currentAmount = g.currentAmount + extra
            g.deadline      = hasDeadline ? deadline : nil
            g.isCompleted   = g.currentAmount >= t
            if hasDeadline {
                SystemNotificationManager.shared.scheduleGoalDeadline(name: name, goalId: g.id.uuidString, deadline: deadline)
            } else {
                SystemNotificationManager.shared.cancelGoalDeadline(goalId: g.id.uuidString)
            }
        } else {
            let goal = Goal(
                name:          name,
                targetAmount:  t,
                currentAmount: c,
                emoji:         selectedEmoji,
                deadline:      hasDeadline ? deadline : nil
            )
            context.insert(goal)
            if hasDeadline {
                SystemNotificationManager.shared.scheduleGoalDeadline(name: name, goalId: goal.id.uuidString, deadline: deadline)
            }
        }
        context.safeSave()
        dismiss()
    }
}
