import SwiftUI
import SwiftData

// MARK: - Adaptive color factory
//
// Pattern nativo iOS: un singolo `Color` costruito con un dynamic provider UIKit.
// Il sistema lo risolve automaticamente in base al trait userInterfaceStyle
// corrente — light o dark — di *ogni* contesto di rendering (view, navbar,
// tabbar, sheet, widget). Nessun observer, nessuna cache, nessun re-render
// manuale: il cambio tema è istantaneo e gestito interamente da SwiftUI/UIKit.

extension Color {
    nonisolated init(lightHex: UInt32, darkHex: UInt32) {
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

    // MARK: Tipografia «Sentiero»
    // Space Grotesk (titoli, importi) e Inter (testo) sono nel bundle (Resources/Fonts,
    // UIAppFonts). `Font.custom(..., relativeTo:)` segue Dynamic Type; se un font non
    // fosse registrato SwiftUI ripiega da solo su SF Pro. Gli importi usano cifre
    // tabulari (`monospacedDigit`).
    enum Typo {
        private static func grotesk(_ weight: String, _ size: CGFloat, _ style: SwiftUI.Font.TextStyle) -> SwiftUI.Font {
            .custom("SpaceGrotesk-\(weight)", size: size, relativeTo: style)
        }
        private static func inter(_ weight: String, _ size: CGFloat, _ style: SwiftUI.Font.TextStyle) -> SwiftUI.Font {
            .custom("Inter18pt-\(weight)", size: size, relativeTo: style)
        }

        static let screenTitle   = grotesk("Bold", 30, .largeTitle)           // tracking −2%: `screenTitleTracking`
        static let wordmark      = grotesk("Bold", 26, .title)
        static let heroAmount    = grotesk("SemiBold", 44, .largeTitle).monospacedDigit()
        static let heroAmountSm  = grotesk("SemiBold", 38, .largeTitle).monospacedDigit() // Conti
        static let sectionTitle  = grotesk("SemiBold", 18, .title3)
        static let rowName       = inter("Medium", 15, .body)
        static let rowAmount     = inter("SemiBold", 15, .body).monospacedDigit()
        static let secondary     = inter("Regular", 13, .footnote)
        static let caption       = inter("Regular", 12, .caption)
        static let tabLabel      = inter("Medium", 11, .caption2)
        static let tabLabelActive = inter("SemiBold", 11, .caption2)

        /// Tracking da applicare con `.tracking(_:)` (valori in pt: −2% di 30, −3% di 44 e di 38).
        static let screenTitleTracking: CGFloat = -0.6
        static let heroAmountTracking:  CGFloat = -1.32
        static let heroAmountSmTracking: CGFloat = -1.14
    }

    // MARK: Theme colors — palette «Sentiero» (adattivi, risolti dal sistema)
    // Ogni colore incapsula la coppia light/dark: il sistema sceglie la variante
    // giusta al momento del rendering (mai `preferredColorScheme`, mai colori fissi).
    // Light: DESIGN_HANDOFF §2. Dark: mapping dell'handoff (bg #0E1210, surface #171C19,
    // testo #F1F3EF, hero #1F2622) con i verdi/ambra/rossi/blu schiariti per mantenere
    // il contrasto AA sul testo (verificato ≥ 4.5:1 su bg e surface; vedi DECISIONI.md D-005).
    //
    // Nomi storici dell'app mantenuti (un solo token per ruolo, nessun doppione):
    //   ink = testo primario · paper = sfondo schermata (bg) · fog = bordi/riempimenti
    //   neutri (border) · smoke = testo secondario (inkSecondary).
    static let ink   = Color(lightHex: 0x121614, darkHex: 0xF1F3EF)
    static let paper = Color(lightHex: 0xF3F4EF, darkHex: 0x0E1210)
    static let filterBorder = Color(lightHex: 0xB9BFB6, darkHex: 0x2A332E)
    static let fog   = Color(lightHex: 0xDCDFD8, darkHex: 0x2A332E)
    static let smoke = Color(lightHex: 0x5B635E, darkHex: 0x9AA39D)

    /// Card, liste, tab bar.
    static let surface     = Color(lightHex: 0xFFFFFF, darkHex: 0x171C19)
    /// Separatori di riga e track delle progress bar.
    static let divider     = Color(lightHex: 0xECEEE9, darkHex: 0x232A26)
    /// Entrate, FAB, link, progress OK («verde = già successo»).
    static let accent      = Color(lightHex: 0x1F7A4D, darkHex: 0x5FD19B)
    /// Testo/icona su fill `accent` (bianco in light, quasi-nero in dark per il contrasto).
    static let onAccent    = Color(lightHex: 0xFFFFFF, darkHex: 0x0E1210)
    static let accentSoft  = Color(lightHex: 0xDDEEE3, darkHex: 0x1C2E25)
    /// Pianificato / atteso («ambra = futuro»), soglia budget 80%.
    static let planned     = Color(lightHex: 0xB45309, darkHex: 0xF2A65A)
    /// Testo ambra: usare questo (non `planned`) per testo < 18 pt.
    static let plannedText = Color(lightHex: 0x8A4A0C, darkHex: 0xF2A65A)
    static let plannedSoft = Color(lightHex: 0xFBEBDD, darkHex: 0x3A2A16)
    /// Budget sforato.
    static let danger      = Color(lightHex: 0xB42318, darkHex: 0xF26B5E)
    static let dangerSoft  = Color(lightHex: 0xFBE4E1, darkHex: 0x3A1D1A)
    /// Trasferimenti.
    static let transfer    = Color(lightHex: 0x2F6FB0, darkHex: 0x6FA8E0)

    // Hero card (superficie scura in entrambi i temi) e relativi testi.
    static let hero          = Color(lightHex: 0x121614, darkHex: 0x1F2622)
    static let heroText      = Color(lightHex: 0xFFFFFF, darkHex: 0xF1F3EF)
    static let heroSecondary = Color(lightHex: 0xA9B2AC, darkHex: 0xA9B2AC)
    static let heroDivider   = Color(lightHex: 0x2A322D, darkHex: 0x323B35)
    static let heroAccent    = Color(lightHex: 0x5FD19B, darkHex: 0x5FD19B)
    static let heroPlanned   = Color(lightHex: 0xF2A65A, darkHex: 0xF2A65A)

    // Semantico positivo/negativo dei saldi: alias dei token «Sentiero»
    // (verde accent / rosso danger), unica fonte di verità per i colori.
    static let positive = accent
    static let negative = danger

    /// Verde/rosso in base al segno di un saldo, DS.ink se zero — unica fonte di
    /// verità per la colorazione "positivo/negativo" (HeroAmount, mini-saldi Home).
    static func signColor(_ amount: Decimal) -> Color {
        if amount > 0 { return positive }
        if amount < 0 { return negative }
        return ink
    }

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

    // MARK: Category name display
    // Le categorie predefinite hanno una voce in Localizable.strings e vanno
    // localizzate; i nomi delle categorie personalizzate sono testo libero
    // inserito dall'utente e non devono mai passare per LocalizedStringKey —
    // un carattere "%" nel nome verrebbe interpretato come specificatore di
    // formato, causando testo corrotto o crash a runtime.
    private static let defaultCategoryNames: Set<String> = [
        "Cibo", "Trasporti", "Svago", "Shopping", "Salute", "Casa",
        "Abbonamenti", "Lavoro", "Istruzione", "Viaggi", "Regali",
        "Giroconto", "Risparmio", "Altro"
    ]

    static func categoryText(_ name: String) -> Text {
        defaultCategoryNames.contains(name) ? Text(LocalizedStringKey(name)) : Text(name)
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
            .scaledFont(size: 11, weight: .semibold)
            .foregroundStyle(DS.smoke)
            .tracking(1.2)
    }
}

struct HeroAmount: View {
    let amount: Decimal
    var size:   CGFloat = 56
    var hidden: Bool    = false
    /// Se true, colora il testo in verde/rosso in base al segno di `amount`
    /// invece del solito DS.ink — riservato ai saldi (Home, Conti), non ai
    /// totali di categoria (es. "Uscite"/"Entrate" in Statistiche).
    var colorBySign: Bool = false
    /// Colore esplicito, ha priorità su colorBySign — per i casi in cui il
    /// significato positivo/negativo non dipende dal segno del numero (es.
    /// "Uscite"/"Entrate": sempre valori positivi, ma semanticamente l'una è
    /// una perdita e l'altra un guadagno).
    var forceColor: Color? = nil

    private var color: Color {
        if let forceColor { return hidden ? DS.ink : forceColor }
        guard colorBySign, !hidden else { return DS.ink }
        return DS.signColor(amount)
    }

    var body: some View {
        Text(hidden ? "• • •" : amount.currencyFormatted)
            .scaledFont(size: size, weight: .black)
            .foregroundStyle(color)
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
                .scaledFont(size: 17, weight: .semibold)
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
                .scaledFont(size: 15)
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
                .scaledFont(size: 40, weight: .ultraLight)
                .foregroundStyle(DS.fog)
            VStack(spacing: DS.Space.s) {
                Text(title)
                    .scaledFont(size: 17, weight: .medium)
                    .foregroundStyle(DS.ink)
                    .multilineTextAlignment(.center)
                Text(subtitle)
                    .scaledFont(size: 13)
                    .foregroundStyle(DS.smoke)
                    .multilineTextAlignment(.center)
            }
            if let cta, let ctaAction {
                Button(action: ctaAction) {
                    Text(cta)
                        .scaledFont(size: 15, weight: .medium)
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
                            .scaledFont(size: 15, weight: selected == opt ? .semibold : .regular)
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
                    .scaledFont(size: 14, weight: .medium)
                    .foregroundStyle(DS.smoke)
            }
            Spacer()
            Text(label)
                .font(DS.Typo.rowName)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
                .foregroundStyle(DS.ink)
            Spacer()
            Button {
                month = Calendar.current.date(byAdding: .month, value: +1, to: month) ?? month
            } label: {
                Image(systemName: "chevron.right")
                    .scaledFont(size: 14, weight: .medium)
                    .foregroundStyle(DS.smoke)
            }
        }
    }
}

// MARK: - DSTransactionRow
// Standard row for normal (non-fixed) transactions

struct DSTransactionRow: View {
    let transaction: Transaction

    // I trasferimenti tra propri conti non sono né un guadagno né una perdita
    // reale — restano neutri, solo uscite/entrate vere prendono colore.
    private var amountColor: Color {
        guard !transaction.isTransfer else { return DS.ink }
        return transaction.transactionType == .uscita ? DS.negative : DS.positive
    }

    var body: some View {
        HStack(spacing: DS.Space.m) {
            // Category icon
            Image(systemName: transaction.categoryIcon.isEmpty ? "circle.dotted" : transaction.categoryIcon)
                .scaledFont(size: 14)
                .foregroundStyle(DS.smoke)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.name)
                    .scaledFont(size: 15)
                    .foregroundStyle(DS.ink)
                    .lineLimit(1)
                DS.categoryText(transaction.category)
                    .scaledFont(size: 12)
                    .foregroundStyle(DS.smoke)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(transaction.transactionType == .uscita
                     ? "−\(transaction.amount.currencyFormatted)"
                     : "+\(transaction.amount.currencyFormatted)")
                    .scaledFont(size: 14, weight: .medium)
                    .foregroundStyle(amountColor)
                Text(transaction.date.dayMonthFormatted)
                    .scaledFont(size: 11)
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
        isIncome
            ? "+\(transaction.amount.currencyFormatted)"
            : "−\(transaction.amount.currencyFormatted)"
    }

    private var amountColor: Color { isIncome ? DS.positive : DS.negative }

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
                            .scaledFont(size: 8, weight: .semibold)
                            .foregroundStyle(DS.ink)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: paid)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.name)
                    .scaledFont(size: 15)
                    .foregroundStyle(DS.ink)
                    .lineLimit(1)
                Text(statusText)
                    .scaledFont(size: 12)
                    .foregroundStyle(DS.smoke)
            }

            Spacer()

            Text(amountText)
                .scaledFont(size: 14, weight: .medium)
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

// MARK: - RecurringSeriesCard
// Card riassuntiva per una serie ricorrente rilevata automaticamente (vedi
// RecurringSeriesDetector): conteggio/storico + proiezione di costo se l'importo
// è costante, media/ultimo/totale se varia (es. lo stipendio).

struct RecurringSeriesCard: View {
    let series: RecurringSeries
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var frequencyLabel: String {
        switch series.frequency {
        case "settimanale": return String(localized: "Settimanale")
        case "mensile":     return String(localized: "Mensile")
        case "annuale":     return String(localized: "Annuale")
        default:            return String(localized: "Irregolare")
        }
    }

    private var isExpense: Bool { series.transactionType == .uscita }

    // "Speso"/"Ricevuto" comunica già la direzione — il prefisso +/- sarebbe ridondante.
    private var totalLine: String {
        let label = isExpense ? String(localized: "Speso finora") : String(localized: "Ricevuto finora")
        return "\(label): \(series.totalAmount.currencyFormatted)"
    }

    @ViewBuilder
    private var detailLine: some View {
        if series.isVariableAmount {
            Text("\(String(localized: "Media")): \(series.average.currencyFormatted) · \(String(localized: "Ultimo")): \(series.lastAmount.currencyFormatted)")
        } else {
            let amt = series.average
            switch series.frequency {
            case "settimanale":
                Text("\(String(localized: "Settimana")) \(amt.currencyFormatted) · \(String(localized: "Mese")) ≈\((amt * 4.33).currencyFormatted) · \(String(localized: "Anno")) \((amt * 52).currencyFormatted)")
            case "mensile":
                Text("\(String(localized: "Mese")) \(amt.currencyFormatted) · \(String(localized: "Anno")) \((amt * 12).currencyFormatted)")
            case "annuale":
                Text("\(String(localized: "Anno")) \(amt.currencyFormatted)")
            default:
                EmptyView()
            }
        }
    }

    var body: some View {
        let tint = CategoryTint.tint(for: series.category)
        let iconName = series.categoryIcon.isEmpty ? DS.categoryIcon(for: series.category) : series.categoryIcon

        VStack(alignment: .leading, spacing: DS.Space.s) {
            HStack(spacing: DS.Space.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: DS.Space.m)
                        .fill(tint.background)
                        .frame(width: 38, height: 38)
                    Image(systemName: iconName)
                        .scaledFont(size: 16)
                        .foregroundStyle(tint.foreground)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(series.name)
                        .font(DS.Typo.rowName)
                        .foregroundStyle(DS.ink)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                    Text("\(series.count) \(String(localized: "volte")) · \(String(localized: "dal")) \(series.firstDate.dayMonthFormatted)")
                        .font(DS.Typo.caption)
                        .foregroundStyle(DS.smoke)
                }
                Spacer()
                if !dynamicTypeSize.isAccessibilitySize {
                    Text(frequencyLabel)
                        .font(DS.Typo.caption)
                        .foregroundStyle(DS.smoke)
                }
            }
            if dynamicTypeSize.isAccessibilitySize {
                Text(frequencyLabel).font(DS.Typo.caption).foregroundStyle(DS.smoke)
            }
            Text(totalLine)
                .font(DS.Typo.rowAmount)
                .foregroundStyle(isExpense ? DS.ink : DS.positive)
                .monospacedDigit()
            detailLine
                .font(DS.Typo.caption)
                .foregroundStyle(DS.smoke)
                .monospacedDigit()
        }
        .padding(DS.Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(DS.fog))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - FixedTotalTile
// Mini card that shows a single fixed-items total (spese/entrate fisse del
// mese). Used in pairs on the Home dashboard, each independently toggleable
// from Impostazioni → Home.

struct FixedTotalTile: View {
    let title: LocalizedStringKey
    let amount: Decimal
    let color: Color
    var hidden: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            Text(title)
                .scaledFont(size: 12)
                .foregroundStyle(DS.smoke)
            Text(hidden ? "• • •" : amount.currencyFormatted)
                .scaledFont(size: 20, weight: .semibold)
                .foregroundStyle(hidden ? DS.ink : color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(DS.Space.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.fog.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Font di sistema che segue Dynamic Type

/// Come `.font(.system(size:weight:))` ma scala con la dimensione del testo scelta dall'utente.
/// Alla dimensione standard il risultato è identico; lo stile di riferimento dipende dal corpo.
private struct ScaledSystemFont: ViewModifier {
    @ScaledMetric private var size: CGFloat
    let weight: Font.Weight

    init(size: CGFloat, weight: Font.Weight) {
        let style: Font.TextStyle = switch size {
        case ..<11.5: .caption2
        case ..<12.5: .caption
        case ..<14: .footnote
        case ..<16: .subheadline
        case ..<18: .body
        case ..<23: .title3
        case ..<29: .title2
        case ..<35: .title
        default: .largeTitle
        }
        _size = ScaledMetric(wrappedValue: size, relativeTo: style)
        self.weight = weight
    }

    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: weight))
    }
}

extension View {
    func scaledFont(size: CGFloat, weight: Font.Weight = .regular) -> some View {
        modifier(ScaledSystemFont(size: size, weight: weight))
    }
}
