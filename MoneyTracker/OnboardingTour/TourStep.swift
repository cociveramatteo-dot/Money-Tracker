import SwiftUI

// MARK: - OverviewStep
//
// Livello 1 del tour: un'unica sequenza lineare che, tab per tab, mette in
// evidenza le funzioni chiave dell'app — stesso motore di spotlight
// millimetrico (anchor-based) dei mini-tour contestuali di Livello 2 (vedi
// ContextualHint.swift), non più un semplice "spotlight sull'icona della tab".
// Ogni tab espone un numero variabile di step (max 4-5, vedi `all`); la
// sequenza è dichiarata una sola volta e pilota sia la navigazione (tab e,
// per Pianifica, segmento richiesti) sia il contenuto della card.
struct OverviewStep: Identifiable, Equatable {

    /// Stabile e univoco: Identifiable.id e confronto in TourManager.
    let id: String

    /// Tab index da attivare prima di mostrare questo step (pilotato da
    /// ContentView tramite TourManager.requiredTab). nil per gli step modali
    /// a schermo intero (welcome/siriShortcuts/done) — nessun cambio tab.
    let requiredTab: Int?

    /// Segmento da attivare dentro Pianifica (0 = Budget, 1 = Obiettivi) prima
    /// di mostrare questo step. nil = non applicabile.
    let requiredSegment: Int?

    /// ID registrato via `.tourAnchor(_:)` sull'elemento da spotlightare.
    /// nil per gli step modali.
    let anchorID: String?

    let isModal: Bool

    /// La card va sopra lo spotlight quando l'elemento evidenziato è in basso
    /// nello schermo (es. il FAB) — altrimenti resta in basso, sotto al
    /// contenuto (hero, grafici, liste) che di norma occupa la parte alta.
    let cardAtTop: Bool

    let icon: String
    let titleKey: LocalizedStringKey
    let bodyKey: LocalizedStringKey
    /// CTA per gli step modali (welcome/done). Per gli step-elemento la card
    /// usa sempre `Avanti`/`Fine` (vedi TourOverlayView.StepCard).
    let ctaKey: LocalizedStringKey
    let spotlightCornerRadius: CGFloat

    /// Espande (positivo) il rettangolo dello spotlight oltre i bounds esatti
    /// dell'anchor — usato per elementi piccoli (icone) dove un ritaglio
    /// perfettamente aderente risulta visivamente troppo stretto.
    let spotlightPadding: CGFloat
    /// Sposta verticalmente lo spotlight (positivo = più in basso) senza
    /// alterarne le dimensioni — corregge un padding interno asimmetrico
    /// dell'elemento anchorato senza toccarne il layout reale.
    let spotlightYOffset: CGFloat
    /// Se presente, il bordo INFERIORE dello spotlight non è quello
    /// dell'anchor principale ma quello di questo secondo anchor (+ un margine)
    /// — usato per contenuti scrollabili (List/ScrollView) il cui anchor
    /// primario riporta l'intero frame invece della sola altezza del contenuto.
    let secondaryAnchorID: String?
    let secondaryBottomMargin: CGFloat
    /// Lo step richiede una navigazione push/pop (non solo un cambio tab o
    /// segmento) perché il suo anchor diventi disponibile — TourOverlayView
    /// applica lo stesso delay di rendering usato per i cambi tab.
    let usesNavigationPush: Bool

    static func == (lhs: OverviewStep, rhs: OverviewStep) -> Bool { lhs.id == rhs.id }

    // MARK: - Sequenza completa

    static let all: [OverviewStep] = [
        .modal(
            id: "welcome", icon: "chart.pie.fill",
            title: "tour.welcome.title", body: "tour.welcome.body", cta: "tour.startButton"
        ),

        // ── Home ─────────────────────────────────────────────────────────
        .element(
            id: "home.balance", tab: 0, anchor: "balanceHero",
            icon: "eurosign.circle.fill", title: "tour.home.balance.title", body: "tour.home.balance.body"
        ),
        .element(
            id: "home.hide", tab: 0, anchor: "eyeButton", cornerRadius: 10,
            icon: "eye.slash.fill", title: "tour.home.hide.title", body: "tour.home.hide.body"
        ),
        .element(
            id: "home.expected", tab: 0, anchor: "saldoAtteso",
            icon: "calendar.badge.clock", title: "tour.home.expected.title", body: "tour.home.expected.body"
        ),
        .element(
            id: "home.accounts", tab: 0, anchor: "accountPanel", cornerRadius: 10, spotlightPadding: 6,
            icon: "slider.horizontal.3", title: "tour.home.accounts.title", body: "tour.home.accounts.body"
        ),

        // ── Movimenti ────────────────────────────────────────────────────
        .element(
            id: "movimenti.sections", tab: 1, anchor: "filterChips", spotlightPadding: 14,
            icon: "square.grid.2x2", title: "tour.movimenti.sections.title", body: "tour.movimenti.sections.body"
        ),
        // Anchor "sectionContent": lo step apre davvero la sezione "Tutti" (push
        // di navigazione pilotato da TransactionsView in base a questo id) e
        // spotlighta il suo contenuto — richiude la sezione appena si avanza.
        .element(
            id: "movimenti.block", tab: 1, anchor: "sectionContent", cornerRadius: 14, cardAtTop: true, usesNavigationPush: true,
            icon: "list.bullet", title: "tour.movimenti.block.title", body: "tour.movimenti.block.body"
        ),
        .element(
            id: "movimenti.search", tab: 1, anchor: "searchField", cornerRadius: 12,
            icon: "magnifyingglass", title: "tour.movimenti.search.title", body: "tour.movimenti.search.body"
        ),

        // ── Statistiche ──────────────────────────────────────────────────
        .element(
            id: "statistiche.summary", tab: 2, anchor: "monthSummary", spotlightYOffset: 8,
            icon: "chart.bar.fill", title: "tour.statistiche.summary.title", body: "tour.statistiche.summary.body"
        ),
        .element(
            id: "statistiche.trend", tab: 2, anchor: "trendChart", spotlightYOffset: 8,
            icon: "chart.xyaxis.line", title: "tour.statistiche.trend.title", body: "tour.statistiche.trend.body"
        ),
        .element(
            id: "statistiche.category", tab: 2, anchor: "categoryBreakdown", cardAtTop: true,
            icon: "chart.pie", title: "tour.statistiche.category.title", body: "tour.statistiche.category.body"
        ),

        // ── Pianifica ────────────────────────────────────────────────────
        .element(
            id: "pianifica.budget", tab: 3, anchor: "budgetList", segment: 0, cardAtTop: true,
            icon: "chart.bar.doc.horizontal.fill", title: "tour.pianifica.budget.title", body: "tour.pianifica.budget.body"
        ),
        .element(
            id: "pianifica.history", tab: 3, anchor: "historyButton", segment: 0, cornerRadius: 10,
            icon: "clock.arrow.circlepath", title: "tour.pianifica.history.title", body: "tour.pianifica.history.body"
        ),
        .element(
            id: "pianifica.goals", tab: 3, anchor: "goalsList", segment: 1, cardAtTop: true,
            icon: "target", title: "tour.pianifica.goals.title", body: "tour.pianifica.goals.body"
        ),

        // ── Conti ────────────────────────────────────────────────────────
        // secondaryAnchor "accountListEnd": il bordo inferiore dello spotlight
        // segue l'ultimo conto attivo invece del frame dell'intera List (che
        // si estenderebbe ben oltre l'ultimo elemento reale).
        .element(
            id: "conti.list", tab: 4, anchor: "accountList",
            secondaryAnchor: "accountListEnd",
            icon: "creditcard.fill", title: "tour.conti.list.title", body: "tour.conti.list.body"
        ),

        .modal(
            id: "siriShortcuts", icon: "mic.fill",
            title: "tour.shortcuts.title", body: "tour.shortcuts.body", cta: "Avanti"
        ),
        .modal(
            id: "done", icon: "checkmark.circle.fill",
            title: "tour.done.title", body: "tour.done.body", cta: "tour.doneButton"
        ),
    ]

    /// Comodo per il valore iniziale di `TourManager.currentStep` e per i
    /// confronti diretti (`tour.currentStep == .welcome/.done`) in TourOverlayView.
    static var welcome: OverviewStep { all[0] }
    static var done:    OverviewStep { all[all.count - 1] }

    // MARK: - Factory

    private static func modal(
        id: String, icon: String,
        title: LocalizedStringKey, body: LocalizedStringKey, cta: LocalizedStringKey
    ) -> OverviewStep {
        OverviewStep(
            id: id, requiredTab: nil, requiredSegment: nil, anchorID: nil,
            isModal: true, cardAtTop: false,
            icon: icon, titleKey: title, bodyKey: body, ctaKey: cta, spotlightCornerRadius: 0,
            spotlightPadding: 0, spotlightYOffset: 0,
            secondaryAnchorID: nil, secondaryBottomMargin: 0, usesNavigationPush: false
        )
    }

    private static func element(
        id: String, tab: Int, anchor: String, segment: Int? = nil,
        cornerRadius: CGFloat = 16, cardAtTop: Bool = false,
        spotlightPadding: CGFloat = 0, spotlightYOffset: CGFloat = 0,
        secondaryAnchor: String? = nil, secondaryBottomMargin: CGFloat = 16,
        usesNavigationPush: Bool = false,
        icon: String, title: LocalizedStringKey, body: LocalizedStringKey
    ) -> OverviewStep {
        OverviewStep(
            id: id, requiredTab: tab, requiredSegment: segment, anchorID: anchor,
            isModal: false, cardAtTop: cardAtTop,
            icon: icon, titleKey: title, bodyKey: body, ctaKey: "Avanti", spotlightCornerRadius: cornerRadius,
            spotlightPadding: spotlightPadding, spotlightYOffset: spotlightYOffset,
            secondaryAnchorID: secondaryAnchor, secondaryBottomMargin: secondaryBottomMargin,
            usesNavigationPush: usesNavigationPush
        )
    }

    // MARK: - Progress

    static var elementSteps: [OverviewStep] { all.filter { !$0.isModal } }

    /// Posizione (1-based) e conteggio dello step corrente ALL'INTERNO della
    /// sua tab — alimenta l'indicatore "2 di 4" nella StepCard, più leggibile
    /// di una fila di puntini ora che gli step totali sono ~15.
    var tabProgress: (index: Int, count: Int)? {
        guard let tab = requiredTab else { return nil }
        let siblings = Self.elementSteps.filter { $0.requiredTab == tab }
        guard let idx = siblings.firstIndex(where: { $0.id == id }) else { return nil }
        return (idx + 1, siblings.count)
    }

    var isFirstElementStep: Bool { id == Self.elementSteps.first?.id }
    var isLastElementStep:  Bool { id == Self.elementSteps.last?.id }
}
