import SwiftUI

// MARK: - TourOverlayView

/// Full-screen overlay che disegna sia il tour di panoramica (Livello 1,
/// `OverviewStep`) sia i mini-tour contestuali (Livello 2, `ContextualHint`) —
/// stesso motore di spotlight/tap-absorbing, stesso stile di card, cambia solo
/// cosa/quando viene mostrato. Instantiated by MoneyTrackerApp via
/// `overlayPreferenceValue(TourAnchorKey.self)`.
struct TourOverlayView: View {

    @ObservedObject var tour = TourManager.shared

    /// Anchors passed in by `overlayPreferenceValue` — updated by SwiftUI whenever
    /// any child view's `.tourAnchor(_:)` changes (new tab load, layout shift, etc.)
    let anchors: [String: Anchor<CGRect>]

    // ── Animated spotlight rect ────────────────────────────────────────────
    // Updated via withAnimation so SwiftUI interpolates each property per frame.
    @State private var spotX: CGFloat = 0
    @State private var spotY: CGFloat = 0
    @State private var spotW: CGFloat = 0
    @State private var spotH: CGFloat = 0
    @State private var spotR: CGFloat = 0

    // ── Live anchor cache ──────────────────────────────────────────────────
    // task(id:) closures capture anchors by value at creation time.
    // Storing them in @State ensures the task always reads the freshest snapshot.
    @State private var liveAnchors: [String: Anchor<CGRect>] = [:]

    private var cardAtTop: Bool {
        if let hint = tour.activeHint { return hint.cardAtTop }
        return tour.currentStep.cardAtTop
    }

    private var showsSpotlight: Bool {
        if tour.activeHint != nil { return true }
        return tour.isActive && !tour.currentStep.isModal
    }

    /// Lo step-elemento richiede un cambio di tab o di segmento (Pianifica)
    /// rispetto allo step precedente nella sequenza? Se sì, la vista di
    /// destinazione ha bisogno di un istante per renderizzare e registrare i
    /// propri `.tourAnchor(_:)` prima che lo spotlight possa posizionarcisi.
    private var needsTransitionDelay: Bool {
        let all = OverviewStep.all
        guard let idx = all.firstIndex(where: { $0.id == tour.currentStep.id }), idx > 0 else { return false }
        let previous = all[idx - 1]
        let current  = tour.currentStep
        return current.requiredTab != previous.requiredTab
            || current.requiredSegment != previous.requiredSegment
            || current.usesNavigationPush || previous.usesNavigationPush
    }

    var body: some View {
        GeometryReader { geo in

            ZStack(alignment: cardAtTop ? .top : .bottom) {

                // ── 1. Dark overlay + animated spotlight cutout ────────────
                if showsSpotlight {
                    spotlightOverlay
                        .ignoresSafeArea()
                }

                if let hint = tour.activeHint {
                    // ── 2a. Mini-tour contestuale (Livello 2) ───────────────
                    HintCard(hint: hint)
                        .padding(.horizontal, 12)
                        .padding(hint.cardAtTop ? .top : .bottom, 72)
                        .transition(.opacity)

                } else if tour.isActive {
                    if tour.currentStep.isModal {
                        // ── 2b. Modale a schermo intero (welcome/siri/done) ──
                        Color.black.opacity(0.85)
                            .ignoresSafeArea()
                            .transition(.opacity)
                        ModalCard()
                            .padding(.horizontal, 28)
                            .frame(maxHeight: .infinity, alignment: .center)
                            .transition(.scale(scale: 0.92).combined(with: .opacity))
                    } else {
                        // ── 2c. Card dello step-elemento (Livello 1) ────────
                        StepCard()
                            .padding(.horizontal, 12)
                            .padding(tour.currentStep.cardAtTop ? .top : .bottom, 72)
                            .transition(.opacity)
                    }
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: tour.currentStep)
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: tour.activeHint)

            // Keep liveAnchors in sync — fires whenever SwiftUI re-collects
            // anchors (new view appears, tab switches, layout changes, etc.)
            .onAppear {
                liveAnchors = anchors
                updateSpot(geo: geo, from: anchors)
            }
            .onChange(of: anchors) { _, fresh in
                liveAnchors = fresh
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    updateSpot(geo: geo, from: fresh)
                }
            }

            // Primary driver per la panoramica: re-runs ad ogni cambio di step.
            // Delay SOLO quando lo step richiede un cambio tab/segmento rispetto
            // al precedente, per dare tempo a:
            //   (a) ContentView/PianificaView di applicare il cambio
            //   (b) La nuova vista di renderizzare e registrare i propri anchor
            //   (c) liveAnchors di aggiornarsi via onChange(of: anchors)
            // Step successivi nella STESSA tab/segmento → nessuna attesa.
            .task(id: tour.currentStep) {
                if needsTransitionDelay {
                    try? await Task.sleep(nanoseconds: 480_000_000)   // 480 ms
                }
                let snapshot = liveAnchors
                withAnimation(.spring(response: 0.3, dampingFraction: 0.88)) {
                    updateSpot(geo: geo, from: snapshot)
                }
            }
            // Primary driver per i mini-tour: re-runs ad ogni nuovo hint mostrato.
            // Nessun cambio tab coinvolto (l'hint scatta quando l'utente è già
            // sulla schermata giusta), quindi nessuna attesa necessaria.
            .task(id: tour.activeHint) {
                guard tour.activeHint != nil else { return }
                let snapshot = liveAnchors
                withAnimation(.spring(response: 0.3, dampingFraction: 0.88)) {
                    updateSpot(geo: geo, from: snapshot)
                }
            }
        }
    }

    // MARK: - Spotlight overlay

    /// Dark overlay with a transparent cut-out at the highlighted element.
    /// Uses mask + .blendMode(.destinationOut) for a true alpha cutout that
    /// animates smoothly via @State properties driven by `withAnimation`.
    @ViewBuilder private var spotlightOverlay: some View {
        ZStack {
            // Semi-transparent dark screen
            Color.black.opacity(0.82)
                .mask {
                    ZStack {
                        // White = show the dark overlay
                        Rectangle().fill(.white)
                        // Cutout: punch a hole where the spotlight is
                        if spotW > 0 {
                            RoundedRectangle(cornerRadius: spotR)
                                .frame(width: spotW, height: spotH)
                                .position(x: spotX + spotW / 2, y: spotY + spotH / 2)
                                .blendMode(.destinationOut)
                        }
                    }
                    .compositingGroup()
                }

            // Highlight ring
            if spotW > 0 {
                RoundedRectangle(cornerRadius: spotR)
                    .stroke(.white.opacity(0.28), lineWidth: 1.5)
                    .frame(width: spotW, height: spotH)
                    .position(x: spotX + spotW / 2, y: spotY + spotH / 2)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { /* absorb taps so background elements aren't activated */ }
    }

    // MARK: - Spotlight positioning
    //
    // Motore unico, anchor-based, condiviso da Livello 1 (step-elemento) e
    // Livello 2 (hint contestuali) — entrambi si riducono a "un anchorID e un
    // corner radius", la precisione del ritaglio è quella nativa di
    // GeometryReader/Anchor<CGRect>, quindi millimetrica sull'elemento reale.

    private func updateSpot(geo: GeometryProxy, from a: [String: Anchor<CGRect>]) {
        if let hint = tour.activeHint {
            applySpot(anchorID: hint.anchorID, cornerRadius: hint.spotlightCornerRadius, geo: geo, from: a)
            return
        }
        guard tour.isActive, !tour.currentStep.isModal, let anchorID = tour.currentStep.anchorID else {
            spotW = 0; spotH = 0
            return
        }
        let step = tour.currentStep
        applySpot(
            anchorID: anchorID, cornerRadius: step.spotlightCornerRadius, geo: geo, from: a,
            padding: step.spotlightPadding, yOffset: step.spotlightYOffset,
            secondaryAnchorID: step.secondaryAnchorID, secondaryBottomMargin: step.secondaryBottomMargin
        )
    }

    private func applySpot(
        anchorID: String, cornerRadius: CGFloat, geo: GeometryProxy, from a: [String: Anchor<CGRect>],
        padding: CGFloat = 0, yOffset: CGFloat = 0,
        secondaryAnchorID: String? = nil, secondaryBottomMargin: CGFloat = 0
    ) {
        guard let anchor = a[anchorID] else {
            spotW = 0; spotH = 0
            return
        }
        var rect = geo[anchor]

        // Bordo inferiore preso da un secondo anchor (es. l'ultima riga di una
        // List, il cui anchor primario riporterebbe l'intero frame scrollabile
        // invece della sola altezza del contenuto reale).
        if let secondaryID = secondaryAnchorID, let secondaryAnchor = a[secondaryID] {
            let secondaryRect = geo[secondaryAnchor]
            rect.size.height = (secondaryRect.maxY + secondaryBottomMargin) - rect.minY
        }

        if padding != 0 { rect = rect.insetBy(dx: -padding, dy: -padding) }
        rect.origin.y += yOffset

        spotX = rect.minX
        spotY = rect.minY
        spotW = rect.width
        spotH = rect.height
        spotR = cornerRadius
    }
}

// MARK: - ModalCard

/// Full-screen centered card for welcome, shortcuts, and done steps.
private struct ModalCard: View {
    @ObservedObject private var tour = TourManager.shared

    var body: some View {
        VStack(spacing: 0) {

            Image(systemName: tour.currentStep.icon)
                .font(.system(size: 44, weight: .ultraLight))
                .foregroundStyle(DS.ink)
                .padding(.bottom, DS.Space.l)

            Text(tour.currentStep.titleKey)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(DS.ink)
                .multilineTextAlignment(.center)
                .padding(.bottom, DS.Space.s)

            Text(tour.currentStep.bodyKey)
                .font(.system(size: 14))
                .foregroundStyle(DS.smoke)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.bottom, DS.Space.xl)

            // Primary CTA
            Button {
                if tour.currentStep == .done { tour.complete() }
                else                         { tour.next()     }
            } label: {
                Text(tour.currentStep.ctaKey)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DS.paper)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(DS.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 13))
            }

            // Skip link (welcome step only)
            if tour.currentStep == .welcome {
                Button { tour.skip() } label: {
                    Text("tour.skipButton", comment: "Skip tour button label")
                        .font(.system(size: 13))
                        .foregroundStyle(DS.smoke.opacity(0.55))
                        .padding(.top, 14)
                }
            }
        }
        .padding(28)
        .background(DS.paper)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.14), radius: 24, y: 6)
    }
}

// MARK: - StepCard

/// Compact tooltip card per gli step-elemento della panoramica (Livello 1).
private struct StepCard: View {
    @ObservedObject private var tour = TourManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Header: icon + title
            HStack(spacing: DS.Space.s) {
                Image(systemName: tour.currentStep.icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(DS.ink)
                    .frame(width: 30, height: 30)
                    .background(DS.fog)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(tour.currentStep.titleKey)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DS.ink)
            }
            .padding(.bottom, DS.Space.s)

            // Body description
            Text(tour.currentStep.bodyKey)
                .font(.system(size: 12))
                .foregroundStyle(DS.smoke)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 14)

            // Footer: progresso "X di Y" (nella tab corrente) + navigazione
            HStack(spacing: 0) {
                if let progress = tour.currentStep.tabProgress {
                    Text(String(
                        format: NSLocalizedString("tour.stepProgress", comment: "Step progress within a tab, e.g. \"2 of 4\""),
                        progress.index, progress.count
                    ))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(DS.smoke)
                }
                Spacer()

                // Navigation buttons
                HStack(spacing: 6) {
                    if !tour.currentStep.isFirstElementStep {
                        Button { tour.previous() } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(DS.smoke)
                                .frame(width: 32, height: 28)
                                .background(DS.fog)
                                .clipShape(RoundedRectangle(cornerRadius: 7))
                        }
                    }

                    Button {
                        tour.next()
                    } label: {
                        Text(tour.currentStep.isLastElementStep ? "Fine" : tour.currentStep.ctaKey)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(DS.paper)
                            .padding(.horizontal, 16)
                            .frame(height: 28)
                            .background(DS.ink)
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                    }
                }
            }
        }
        .padding(14)
        .background(DS.paper)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 4)
    }
}

// MARK: - HintCard

/// Card di un singolo mini-tour contestuale (Livello 2): niente indietro/avanti,
/// niente pallini di progresso — solo un pulsante "Ho capito" che chiude e marca
/// l'hint come visto.
private struct HintCard: View {
    @ObservedObject private var tour = TourManager.shared
    let hint: ContextualHint

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: DS.Space.s) {
                Image(systemName: hint.icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(DS.ink)
                    .frame(width: 30, height: 30)
                    .background(DS.fog)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(hint.titleKey)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DS.ink)
            }
            .padding(.bottom, DS.Space.s)

            Text(hint.bodyKey)
                .font(.system(size: 12))
                .foregroundStyle(DS.smoke)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 14)

            Button {
                tour.dismissHint()
            } label: {
                Text("hint.gotIt")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DS.paper)
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
                    .background(DS.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(14)
        .background(DS.paper)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 4)
    }
}
