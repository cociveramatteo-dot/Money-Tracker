import SwiftUI
import SwiftData

// MARK: - Adaptive color factory
//
// Pattern nativo iOS: un singolo `Color` costruito con un dynamic provider UIKit.
// Il sistema lo risolve automaticamente in base al trait userInterfaceStyle
// corrente — light o dark — di *ogni* contesto di rendering (view, navbar,
// tabbar, sheet, widget). Nessun observer, nessuna cache, nessun re-render
// manuale: il cambio tema è istantaneo e gestito interamente da SwiftUI/UIKit.

private extension Color {
    init(lightHex: UInt32, darkHex: UInt32) {
        self.init(uiColor: UIColor { trait in
            let hex = trait.userInterfaceStyle == .dark ? darkHex : lightHex
            return UIColor(
                red:   CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8)  & 0xFF) / 255,
                blue:  CGFloat(hex         & 0xFF) / 255,
                alpha: 1
            )
        })
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

    // MARK: Theme colors (adattivi, risolti dal sistema)
    // Ogni colore incapsula la coppia light/dark: il sistema sceglie la variante
    // giusta al momento del rendering. Valori identici alla palette originale.
    static let ink   = Color(lightHex: 0x111111, darkHex: 0xF0F0F0)
    static let paper = Color(lightHex: 0xFAFAFA, darkHex: 0x111111)
    static let fog   = Color(lightHex: 0xE0E0E0, darkHex: 0x2A2A2A)
    static let smoke = Color(lightHex: 0x888888, darkHex: 0x909090)

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

// MARK: - Navbar background modifier
//
// Applica lo sfondo corretto alla navigation bar per evitare il "Liquid Glass"
// di iOS 26 che userebbe lo sfondo di sistema invece di DS.paper.

struct ThemeNavBarModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbarBackground(DS.paper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}

extension View {
    /// Applica lo sfondo corretto alla navigation bar (tema sistema).
    func themedNavBar() -> some View {
        modifier(ThemeNavBarModifier())
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
    var body: some View {
        Rectangle()
            .fill(DS.fog)
            .frame(height: 0.5)
    }
}

struct SectionLabel: View {
    let text: LocalizedStringKey
    var body: some View {
        Text(text)
            .textCase(.uppercase)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(DS.smoke)
            .tracking(1.2)
    }
}

struct HeroAmount: View {
    let amount: Decimal
    var size:   CGFloat = 56
    var hidden: Bool    = false

    var body: some View {
        Text(hidden ? "• • •" : amount.currencyFormatted)
            .font(.system(size: size, weight: .black))
            .foregroundStyle(DS.ink)
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

    var body: some View {
        VStack(spacing: DS.Space.l) {
            Image(systemName: icon)
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundStyle(DS.fog)
            VStack(spacing: DS.Space.s) {
                Text(title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(DS.ink)
                    .multilineTextAlignment(.center)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(DS.smoke)
                    .multilineTextAlignment(.center)
            }
            if let cta, let ctaAction {
                Button(action: ctaAction) {
                    Text(cta)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(DS.ink)
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
                    .foregroundStyle(DS.smoke)
            }
            Spacer()
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(DS.ink)
            Spacer()
            Button {
                month = Calendar.current.date(byAdding: .month, value: +1, to: month) ?? month
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(DS.smoke)
            }
        }
    }
}

// MARK: - DSTransactionRow
// Standard row for normal (non-fixed) transactions

struct DSTransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: DS.Space.m) {
            // Category icon
            Image(systemName: transaction.categoryIcon.isEmpty ? "circle.dotted" : transaction.categoryIcon)
                .font(.system(size: 14))
                .foregroundStyle(DS.smoke)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.name)
                    .font(.system(size: 15))
                    .foregroundStyle(DS.ink)
                    .lineLimit(1)
                Text(LocalizedStringKey(transaction.category))
                    .font(.system(size: 12))
                    .foregroundStyle(DS.smoke)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(transaction.transactionType == .uscita
                     ? "−\(transaction.amount.currencyFormatted)"
                     : "+\(transaction.amount.currencyFormatted)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(DS.ink)
                Text(transaction.date.dayMonthFormatted)
                    .font(.system(size: 11))
                    .foregroundStyle(DS.smoke)
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
        guard colorCoded else { return DS.ink }
        // Usa colori semantici del tema: entrate = ink pieno, uscite = smoke
        // Per distinguere visivamente senza hardcodare verde/rosso
        return isIncome ? DS.ink : DS.smoke
    }

    var body: some View {
        HStack(spacing: DS.Space.m) {
            Button {
                haptic(.soft)
                action()
            } label: {
                ZStack {
                    Circle()
                        .strokeBorder(paid ? DS.ink : DS.fog, lineWidth: 1.5)
                        .frame(width: 18, height: 18)
                    if paid {
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(DS.ink)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: paid)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.name)
                    .font(.system(size: 15))
                    .foregroundStyle(DS.ink)
                    .lineLimit(1)
                Text(statusText)
                    .font(.system(size: 12))
                    .foregroundStyle(DS.smoke)
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
