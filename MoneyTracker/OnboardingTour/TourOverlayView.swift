import SwiftUI

// MARK: - TourOverlayView

/// Full-screen overlay that renders the spotlight + step card / modal card.
/// Instantiated by ContentView via `overlayPreferenceValue(TourAnchorKey.self)`.
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

    var body: some View {
        GeometryReader { geo in

            ZStack(alignment: tour.currentStep.cardAtTop ? .top : .bottom) {

                // ── 1. Dark overlay + animated spotlight cutout ────────────
                if !tour.currentStep.isModal {
                    spotlightOverlay
                        .ignoresSafeArea()
                }

                // ── 2a. Full-screen modal (welcome / siri / done) ─────────
                if tour.currentStep.isModal {
                    Color.black.opacity(0.85)
                        .ignoresSafeArea()
                        .transition(.opacity)
                    ModalCard()
                        .padding(.horizontal, 28)
                        .frame(maxHeight: .infinity, alignment: .center)
                        .transition(.scale(scale: 0.92).combined(with: .opacity))

                // ── 2b. Tooltip card (element steps) ──────────────────────
                } else {
                    StepCard()
                        .padding(.horizontal, 12)
                        .padding(tour.currentStep.cardAtTop ? .top : .bottom, 72)
                        .transition(.opacity)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: tour.currentStep)

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
            // Re-position when TabBarFrameCapture delivers the UIKit frame.
            // Fires once shortly after the view appears (async UIKit layout).
            .onChange(of: tour.tabBarFrame) { _, _ in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    updateSpot(geo: geo, from: liveAnchors)
                }
            }

            // Primary driver: re-runs each time the current step changes.
            // Delay SOLO quando si cambia tab (requiredTab > 0) per dare tempo a:
            //   (a) ContentView.onChange di switchare il tab
            //   (b) La nuova tab di renderizzare e registrare i propri anchor
            //   (c) liveAnchors di aggiornarsi via onChange(of: anchors)
            // Tab Home (requiredTab == 0) e step modali (nil) → nessuna attesa.
            .task(id: tour.currentStep) {
                if let tab = tour.currentStep.requiredTab, tab > 0 {
                    try? await Task.sleep(nanoseconds: 480_000_000)   // 480 ms
                }
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

    private func updateSpot(geo: GeometryProxy, from a: [String: Anchor<CGRect>]) {
        // Special case: tab bar step uses the UIKit frame captured by TabBarFrameCapture.
        // This gives pixel-perfect alignment regardless of iOS version.
        // The UIKit frame is in screen-point coordinates, which matches the GeometryReader
        // at the App root (with .ignoresSafeArea) — same origin, no conversion needed.
        if tour.currentStep == .tabBar, tour.tabBarFrame != .zero {
            spotX = tour.tabBarFrame.minX
            spotY = tour.tabBarFrame.minY
            spotW = tour.tabBarFrame.width
            spotH = tour.tabBarFrame.height
            // Always use our tuned constant — UIKit reports the container's
            // cornerRadius, not the iOS 26 visual pill's actual corner radius.
            spotR = tour.currentStep.spotlightCornerRadius
            return
        }

        // All other steps — use SwiftUI anchor preferences.
        guard
            let id     = tour.currentStep.anchorID,
            let anchor = a[id]
        else {
            spotW = 0; spotH = 0
            return
        }
        let rect = geo[anchor]
        let pad  = tour.currentStep.spotlightPadding
        spotX = rect.minX  - pad
        spotY = rect.minY  - pad
        spotW = rect.width + pad * 2
        spotH = rect.height + pad * 2
        spotR = tour.currentStep.spotlightCornerRadius
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

/// Compact tooltip card shown alongside the spotlight for element steps.
private struct StepCard: View {
    @ObservedObject private var tour = TourManager.shared
    private var elementSteps: [TourStep] { TourStep.elementSteps }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Section breadcrumb — shown only for cross-tab steps so the user
            // always knows which area of the app the tour is currently describing.
            if let tab = tour.currentStep.tabLabel {
                HStack(spacing: 4) {
                    Image(systemName: tab.icon)
                        .font(.system(size: 10, weight: .medium))
                    Text(tab.name)
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(DS.smoke)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(DS.fog)
                .clipShape(Capsule())
                .padding(.bottom, DS.Space.s)
                .transition(.opacity.combined(with: .scale(scale: 0.92)))
            }

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

            // Footer: progress dots + navigation buttons
            HStack(spacing: 0) {
                // Dot indicators
                HStack(spacing: 4) {
                    ForEach(elementSteps) { step in
                        let active = (step == tour.currentStep)
                        RoundedRectangle(cornerRadius: 2.5)
                            .fill(active ? DS.ink : DS.fog)
                            .frame(width: active ? 14 : 5, height: 5)
                            .animation(.spring(response: 0.35), value: active)
                    }
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
                        Text(tour.currentStep.isLastElementStep ? "Fine" : "Avanti")
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
