import SwiftUI
import SwiftData
import Combine

// MARK: - AppTheme

enum AppTheme: String, CaseIterable, Identifiable {
    case classico = "Classico"
    case notte    = "Notte"
    case foresta  = "Foresta"
    case oceano   = "Oceano"
    case rosso    = "Rosso"
    case rosa     = "Rosa"
    case viola    = "Viola"
    case sabbia   = "Sabbia"
    case menta    = "Menta"
    case autunno  = "Autunno"

    var id: String { rawValue }

    /// SF Symbol shown in the SettingsView theme swatch
    var icon: String {
        switch self {
        case .classico: return "sun.max"
        case .notte:    return "moon.fill"
        case .foresta:  return "leaf.fill"
        case .oceano:   return "water.waves"
        case .rosso:    return "flame.fill"
        case .rosa:     return "heart.fill"
        case .viola:    return "sparkles"
        case .sabbia:   return "beach.umbrella.fill"
        case .menta:    return "snowflake"
        case .autunno:  return "sun.haze.fill"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .notte: return .dark
        default:     return .light  // tutti gli altri temi hanno sfondo chiaro — forza light mode
        }                           // così navigation title, placeholder e tab label restano scuri
    }

    var ink: Color {
        switch self {
        case .classico: return Color(hex: "111111")
        case .notte:    return Color(hex: "F0F0F0")
        case .foresta:  return Color(hex: "1A3A2A")
        case .oceano:   return Color(hex: "0C2840")
        case .rosso:    return Color(hex: "350808")
        case .rosa:     return Color(hex: "4A1A2A")
        case .viola:    return Color(hex: "28094A")
        case .sabbia:   return Color(hex: "3A2A10")
        case .menta:    return Color(hex: "082A2A")
        case .autunno:  return Color(hex: "381505")
        }
    }

    var paper: Color {
        switch self {
        case .classico: return Color(hex: "FAFAFA")
        case .notte:    return Color(hex: "111111")
        case .foresta:  return Color(hex: "F0F5F1")
        case .oceano:   return Color(hex: "EDF4F9")
        case .rosso:    return Color(hex: "FFF5F5")
        case .rosa:     return Color(hex: "FFF0F4")
        case .viola:    return Color(hex: "F6F1FF")
        case .sabbia:   return Color(hex: "FDF6E8")
        case .menta:    return Color(hex: "EFF9F8")
        case .autunno:  return Color(hex: "FDF3EC")
        }
    }

    var fog: Color {
        switch self {
        case .classico: return Color(hex: "E0E0E0")
        case .notte:    return Color(hex: "2A2A2A")
        case .foresta:  return Color(hex: "C8D8CC")
        case .oceano:   return Color(hex: "B0CCE0")
        case .rosso:    return Color(hex: "F0BBBB")
        case .rosa:     return Color(hex: "E8C8D0")
        case .viola:    return Color(hex: "CFC0E8")
        case .sabbia:   return Color(hex: "E0D0B0")
        case .menta:    return Color(hex: "A8D8D4")
        case .autunno:  return Color(hex: "E8C4A0")
        }
    }

    var smoke: Color {
        switch self {
        case .classico: return Color(hex: "888888")
        case .notte:    return Color(hex: "909090")
        case .foresta:  return Color(hex: "4A7A5A")
        case .oceano:   return Color(hex: "3A6888")
        case .rosso:    return Color(hex: "8B2020")
        case .rosa:     return Color(hex: "8A4A6A")
        case .viola:    return Color(hex: "6B3A9A")
        case .sabbia:   return Color(hex: "8A6A3A")
        case .menta:    return Color(hex: "2A7070")
        case .autunno:  return Color(hex: "A05828")
        }
    }
}

// MARK: - Color hex initializer

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - ThemeManager

// @MainActor: ThemeManager is always accessed on the main thread (via @EnvironmentObject in
// SwiftUI views). Explicit annotation removes any ambiguity and allows direct calls to
// DS.invalidateThemeCache() (also @MainActor) without crossing actor boundaries.
@MainActor
final class ThemeManager: ObservableObject {
    @Published var current: AppTheme

    init() {
        let saved = UserDefaults.standard.string(forKey: "appTheme") ?? ""
        current = AppTheme(rawValue: saved) ?? .classico
        // Sync the DS static cache immediately on launch so views that read DS.ink/paper
        // before the first ThemeManager.set() call get the correct theme colours.
        DS.invalidateThemeCache()
    }

    func set(_ theme: AppTheme) {
        current = theme
        UserDefaults.standard.set(theme.rawValue, forKey: "appTheme")
        DS.invalidateThemeCache()   // aggiorna la cache statica di DS
    }
}

// MARK: - DSIcon (used by category icon picker)

struct DSIcon: Identifiable {
    let symbol: String
    var id: String { symbol }
}

// MARK: - DS (Design System)

// @MainActor: theme-derived colors and category icons are always read on the main thread
// (views, @MainActor AppIntents). Swift 6 strict concurrency requires this annotation.
@MainActor
enum DS {

    // MARK: Spacing
    enum Space {
        static let xs:  CGFloat = 4
        static let s:   CGFloat = 8
        static let m:   CGFloat = 12
        static let l:   CGFloat = 16
        static let xl:  CGFloat = 24
        static let xxl: CGFloat = 36
    }

    // MARK: Layout constants
    enum Layout {
        static let margin:       CGFloat = 20
        static let rowVPad:      CGFloat = 14
        static let buttonHeight: CGFloat = 52
        static let buttonRadius: CGFloat = 14
        static let cardRadius:   CGFloat = 16
    }

    // MARK: Live theme colors — cached, invalidated da ThemeManager.set()
    // Evita N letture UserDefaults per render. ThemeManager chiama DS.invalidateThemeCache()
    // dopo ogni cambio tema per tenere la cache allineata.
    private static var _cachedTheme: AppTheme = {
        AppTheme(rawValue: UserDefaults.standard.string(forKey: "appTheme") ?? "") ?? .classico
    }()

    static func invalidateThemeCache() {
        _cachedTheme = AppTheme(rawValue: UserDefaults.standard.string(forKey: "appTheme") ?? "") ?? .classico
    }

    private static var activeTheme: AppTheme { _cachedTheme }

    static var ink:   Color { activeTheme.ink   }
    static var paper: Color { activeTheme.paper }
    static var fog:   Color { activeTheme.fog   }
    static var smoke: Color { activeTheme.smoke }

    // MARK: Available icons for category picker
    static let availableIcons: [DSIcon] = [
        // Cibo & bevande
        DSIcon(symbol: "fork.knife"),
        DSIcon(symbol: "cup.and.saucer.fill"),
        DSIcon(symbol: "cart.fill"),
        DSIcon(symbol: "bag.fill"),
        DSIcon(symbol: "takeoutbag.and.cup.and.straw.fill"),
        DSIcon(symbol: "wineglass.fill"),
        // Trasporti
        DSIcon(symbol: "car.fill"),
        DSIcon(symbol: "airplane"),
        DSIcon(symbol: "tram.fill"),
        DSIcon(symbol: "ferry.fill"),
        DSIcon(symbol: "bicycle"),
        DSIcon(symbol: "fuelpump.fill"),
        // Casa & vita
        DSIcon(symbol: "house.fill"),
        DSIcon(symbol: "bolt.fill"),
        DSIcon(symbol: "drop.fill"),
        DSIcon(symbol: "flame.fill"),
        DSIcon(symbol: "wifi"),
        DSIcon(symbol: "phone.fill"),
        // Salute & sport
        DSIcon(symbol: "heart.fill"),
        DSIcon(symbol: "cross.fill"),
        DSIcon(symbol: "dumbbell.fill"),
        DSIcon(symbol: "figure.run"),
        DSIcon(symbol: "stethoscope"),
        DSIcon(symbol: "pills.fill"),
        // Svago & cultura
        DSIcon(symbol: "gamecontroller.fill"),
        DSIcon(symbol: "film.fill"),
        DSIcon(symbol: "music.note"),
        DSIcon(symbol: "book.fill"),
        DSIcon(symbol: "theatermasks.fill"),
        DSIcon(symbol: "ticket.fill"),
        // Lavoro & istruzione
        DSIcon(symbol: "briefcase.fill"),
        DSIcon(symbol: "laptopcomputer"),
        DSIcon(symbol: "graduationcap.fill"),
        DSIcon(symbol: "pencil.and.ruler.fill"),
        DSIcon(symbol: "doc.fill"),
        DSIcon(symbol: "printer.fill"),
        // Shopping & abbigliamento
        DSIcon(symbol: "tshirt.fill"),
        DSIcon(symbol: "shoe.fill"),
        DSIcon(symbol: "eyeglasses"),
        DSIcon(symbol: "crown.fill"),
        DSIcon(symbol: "sparkles"),
        DSIcon(symbol: "scissors"),
        // Finanza & varie
        DSIcon(symbol: "eurosign.circle.fill"),
        DSIcon(symbol: "creditcard.fill"),
        DSIcon(symbol: "gift.fill"),
        DSIcon(symbol: "arrow.left.arrow.right"),
        DSIcon(symbol: "repeat.circle.fill"),
        DSIcon(symbol: "circle.dotted"),
    ]

    // MARK: Category → SF Symbol
    static func categoryIcon(for name: String) -> String {
        switch name {
        case "Cibo":         return "fork.knife"
        case "Trasporti":    return "car.fill"
        case "Svago":        return "gamecontroller.fill"
        case "Shopping":     return "bag.fill"
        case "Salute":       return "heart.fill"
        case "Casa":         return "house.fill"
        case "Abbonamenti":  return "repeat.circle.fill"
        case "Lavoro":       return "briefcase.fill"
        case "Istruzione":   return "book.fill"
        case "Viaggi":       return "airplane"
        case "Regali":       return "gift.fill"
        case "Giroconto":    return "arrow.left.arrow.right"
        case "Risparmio":    return "banknote"
        case "Altro":        return "tray.fill"
        default:             return "circle.dotted"
        }
    }
}

// MARK: - Theme Picker Sheet

struct ThemePickerSheet: View {
    @EnvironmentObject private var themeManager: ThemeManager

    private let columns = Array(repeating: GridItem(.flexible()), count: 5)

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.l) {

            SectionLabel(text: "Tema")

            LazyVGrid(columns: columns, spacing: DS.Space.m) {
                ForEach(AppTheme.allCases) { theme in
                    Button {
                        themeManager.set(theme)
                    } label: {
                        VStack(spacing: DS.Space.s) {
                            // Card
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(theme.paper)
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(
                                        themeManager.current == theme ? theme.ink : theme.fog,
                                        lineWidth: themeManager.current == theme ? 1.5 : 0.5
                                    )
                                VStack(spacing: 4) {
                                    Image(systemName: theme.icon)
                                        .font(.system(size: 14))
                                        .foregroundStyle(theme.ink)
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(theme.smoke)
                                        .frame(width: 18, height: 2)
                                }
                            }
                            .frame(height: 50)

                            // Nome
                            Text(LocalizedStringKey(theme.rawValue))
                                .font(.system(size: 9,
                                              weight: themeManager.current == theme ? .semibold : .regular))
                                .foregroundStyle(themeManager.current == theme ? DS.ink : DS.smoke)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, DS.Layout.margin)
        .padding(.top, DS.Space.xxl)
        .padding(.bottom, DS.Space.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(DS.paper)
    }
}

// MARK: - Theme picker toolbar button (tutti i tab)

struct ThemePickerToolbarModifier: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showPicker = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showPicker = true } label: {
                        Image(systemName: themeManager.current.icon)
                            .font(.system(size: 16))
                            .foregroundStyle(DS.ink)
                    }
                }
            }
            // Fix iOS 26 Liquid Glass: senza questi due modifier la navigation bar usa
            // lo sfondo di sistema (bianco/vetro) invece di DS.paper.
            // Effetto: blocco bianco tra search bar e filtri in TransactionsView,
            // e testo invisibile in Notte perché il vetro scuro sovrasta il contenuto.
            .toolbarBackground(DS.paper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showPicker) {
                ThemePickerSheet()
                    .presentationDetents([.height(260)])
                    .presentationDragIndicator(.visible)
                    .environmentObject(themeManager)
            }
    }
}

extension View {
    func themePickerButton() -> some View {
        modifier(ThemePickerToolbarModifier())
    }
}

// MARK: - Haptics

enum HapticStyle {
    case light, medium, soft, rigid, success
}

// Generatori pre-allocati: evitano di creare e distruggere un oggetto UIKit ad ogni tap.
// Sono variabili (non let) perché UIImpactFeedbackGenerator è una classe ObjC
// che il sistema può invalidare — var permette di re-istanziarli se necessario.
// @MainActor: UIImpactFeedbackGenerator must be accessed on the main thread.
@MainActor private var _hapticLight   = UIImpactFeedbackGenerator(style: .light)
@MainActor private var _hapticMedium  = UIImpactFeedbackGenerator(style: .medium)
@MainActor private var _hapticSoft    = UIImpactFeedbackGenerator(style: .soft)
@MainActor private var _hapticRigid   = UIImpactFeedbackGenerator(style: .rigid)
@MainActor private var _hapticNotif   = UINotificationFeedbackGenerator()

@MainActor
func haptic(_ style: HapticStyle = .light) {
    switch style {
    case .light:   _hapticLight.impactOccurred()
    case .medium:  _hapticMedium.impactOccurred()
    case .soft:    _hapticSoft.impactOccurred()
    case .rigid:   _hapticRigid.impactOccurred()
    case .success: _hapticNotif.notificationOccurred(.success)
    }
}

// MARK: - Shared UI components

struct ThinDivider: View {
    @EnvironmentObject private var themeManager: ThemeManager
    var body: some View {
        Rectangle()
            .fill(themeManager.current.fog)
            .frame(height: 0.5)
    }
}

struct SectionLabel: View {
    let text: LocalizedStringKey
    @EnvironmentObject private var themeManager: ThemeManager
    var body: some View {
        Text(text)
            .textCase(.uppercase)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(themeManager.current.smoke)
            .tracking(1.2)
    }
}

struct HeroAmount: View {
    let amount: Double
    var size:   CGFloat = 56
    var hidden: Bool    = false
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        Text(hidden ? "• • •" : amount.currencyFormatted)
            .font(.system(size: size, weight: .black))
            .foregroundStyle(themeManager.current.ink)
            .minimumScaleFactor(0.6)
            .lineLimit(1)
            .accessibilityLabel(hidden ? String(localized: "Saldo nascosto") : amount.currencyFormatted)
    }
}

struct PrimaryButton: View {
    let title:  LocalizedStringKey
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(DS.paper)
                .frame(maxWidth: .infinity)
                .frame(height: DS.Layout.buttonHeight)
                .background(DS.ink.opacity(isEnabled ? 1 : 0.3))
                .clipShape(RoundedRectangle(cornerRadius: DS.Layout.buttonRadius))
        }
    }
}

struct GhostButton: View {
    let title:  LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(DS.smoke)
        }
    }
}

// MARK: - EmptyStateView
// Reusable component for all empty-list states. Centralises icon + title + subtitle + optional CTA.

struct EmptyStateView: View {
    let icon:     String
    let title:    LocalizedStringKey
    let subtitle: LocalizedStringKey
    var cta:       LocalizedStringKey? = nil
    var ctaAction: (() -> Void)?       = nil
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: DS.Space.l) {
            Image(systemName: icon)
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundStyle(themeManager.current.fog)
            VStack(spacing: DS.Space.s) {
                Text(title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(themeManager.current.ink)
                    .multilineTextAlignment(.center)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(themeManager.current.smoke)
                    .multilineTextAlignment(.center)
            }
            if let cta, let ctaAction {
                Button(action: ctaAction) {
                    Text(cta)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(themeManager.current.ink)
                        .underline()
                }
            }
        }
        .padding(.horizontal, DS.Layout.margin * 2)
        .padding(.vertical, DS.Space.xxl)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

struct UnderlineSegment<T: Hashable & RawRepresentable>: View where T.RawValue == String {
    let options:  [T]
    @Binding var selected: T

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { opt in
                Button {
                    selected = opt
                } label: {
                    VStack(spacing: DS.Space.s) {
                        Text(LocalizedStringKey(opt.rawValue))
                            .font(.system(size: 15,
                                  weight: selected == opt ? .semibold : .regular))
                            .foregroundStyle(selected == opt ? DS.ink : DS.smoke)
                        Rectangle()
                            .fill(selected == opt ? DS.ink : Color.clear)
                            .frame(height: 1.5)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct MonthBar: View {
    @Binding var month: Date
    @EnvironmentObject private var themeManager: ThemeManager

    private var label: String {
        month.monthYearFormatted
    }

    var body: some View {
        HStack {
            Button {
                month = Calendar.current.date(byAdding: .month, value: -1, to: month) ?? month
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(themeManager.current.smoke)
            }
            Spacer()
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(themeManager.current.ink)
            Spacer()
            Button {
                month = Calendar.current.date(byAdding: .month, value: +1, to: month) ?? month
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(themeManager.current.smoke)
            }
        }
    }
}

// MARK: - DSTransactionRow
// Standard row for normal (non-fixed) transactions

struct DSTransactionRow: View {
    let transaction: Transaction
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: DS.Space.m) {
            // Category icon
            Image(systemName: transaction.categoryIcon.isEmpty ? "circle.dotted" : transaction.categoryIcon)
                .font(.system(size: 14))
                .foregroundStyle(themeManager.current.smoke)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.name)
                    .font(.system(size: 15))
                    .foregroundStyle(themeManager.current.ink)
                    .lineLimit(1)
                Text(LocalizedStringKey(transaction.category))
                    .font(.system(size: 12))
                    .foregroundStyle(themeManager.current.smoke)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(transaction.transactionType == .uscita
                     ? "−\(transaction.amount.currencyFormatted)"
                     : "+\(transaction.amount.currencyFormatted)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(themeManager.current.ink)
                Text(transaction.date.dayMonthFormatted)
                    .font(.system(size: 11))
                    .foregroundStyle(themeManager.current.smoke)
            }
        }
        .padding(.vertical, DS.Layout.rowVPad)
        .opacity(transaction.isDone ? 1 : 0.55)
        .accessibilityElement(children: .combine)
        .accessibilityLabel({
            let dir    = transaction.transactionType == .uscita
                ? String(localized: "Uscita")
                : String(localized: "Entrata")
            let prefix = transaction.transactionType == .uscita
                ? String(localized: "meno ")
                : String(localized: "più ")
            let amt    = prefix + transaction.amount.currencyFormatted
            let status = transaction.isDone ? "" : ", \(String(localized: "pianificato"))"
            return "\(transaction.name), \(dir), \(amt), \(transaction.category), \(transaction.date.dayMonthFormatted)\(status)"
        }())
    }
}

// MARK: - FixedExpenseRow
// Row for fixed/recurring expenses with a tap-to-pay toggle

struct FixedExpenseRow: View {
    let transaction: Transaction
    var paid:       Bool = false
    var isIncome:   Bool = false
    var colorCoded: Bool = false   // true solo in "Fissi del mese"
    let action: () -> Void
    @EnvironmentObject private var themeManager: ThemeManager

    private var statusText: String {
        if paid {
            let d = transaction.date.dayMonthFormatted
            let base = isIncome ? String(localized: "Ricevuta") : String(localized: "Pagata")
            return "\(base) · \(d)"
        } else {
            return isIncome ? String(localized: "Da ricevere") : String(localized: "Da pagare")
        }
    }

    private var amountText: String {
        if colorCoded {
            return isIncome
                ? "+\(transaction.amount.currencyFormatted)"
                : "−\(transaction.amount.currencyFormatted)"
        }
        return transaction.amount.currencyFormatted
    }

    private var amountColor: Color {
        guard colorCoded else { return themeManager.current.ink }
        // Usa colori semantici del tema: entrate = ink pieno, uscite = smoke
        // Per distinguere visivamente senza hardcodare verde/rosso
        return isIncome ? themeManager.current.ink : themeManager.current.smoke
    }

    var body: some View {
        HStack(spacing: DS.Space.m) {
            Button {
                haptic(.soft)
                action()
            } label: {
                ZStack {
                    Circle()
                        .strokeBorder(paid ? themeManager.current.ink : themeManager.current.fog, lineWidth: 1.5)
                        .frame(width: 18, height: 18)
                    if paid {
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(themeManager.current.ink)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: paid)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.name)
                    .font(.system(size: 15))
                    .foregroundStyle(themeManager.current.ink)
                    .lineLimit(1)
                Text(statusText)
                    .font(.system(size: 12))
                    .foregroundStyle(themeManager.current.smoke)
            }

            Spacer()

            Text(amountText)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(amountColor)
        }
        .padding(.vertical, DS.Layout.rowVPad)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel({
            let dir = isIncome
                ? String(localized: "Entrata fissa")
                : String(localized: "Spesa fissa")
            return "\(transaction.name), \(dir), \(amountText), \(statusText)"
        }())
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(paid ? "Tocca per segnare come da pagare" : "Tocca per segnare come pagata")
    }
}
