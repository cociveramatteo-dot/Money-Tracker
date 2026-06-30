import SwiftUI
import UIKit

/// Searches the UIWindow's entire subview tree for UITabBar, then finds the
/// visual "pill" subview inside it for pixel-perfect spotlight alignment.
///
/// Place as `.background` on the TabView in ContentView.
struct TabBarFrameCapture: UIViewRepresentable {

    /// Called on the main thread with (windowSpaceFrame, cornerRadius).
    var onCapture: (_ frame: CGRect, _ cornerRadius: CGFloat) -> Void

    func makeUIView(context: Context) -> CapView { CapView(onCapture: onCapture) }

    func updateUIView(_ uiView: CapView, context: Context) {
        uiView.onCapture = onCapture
    }

    // MARK: - CapView

    final class CapView: UIView {

        var onCapture: (_ frame: CGRect, _ cornerRadius: CGFloat) -> Void

        init(onCapture: @escaping (_ frame: CGRect, _ cornerRadius: CGFloat) -> Void) {
            self.onCapture = onCapture
            super.init(frame: .zero)
            isUserInteractionEnabled = false
            backgroundColor = .clear
        }
        required init?(coder: NSCoder) { fatalError() }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard window != nil else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.capture()
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            capture()
        }

        // MARK: - Search

        func capture() {
            guard let win = window else { return }
            guard let bar = findTabBar(in: win) else { return }
            report(bar, in: win)
        }

        private func findTabBar(in view: UIView) -> UITabBar? {
            if let bar = view as? UITabBar { return bar }
            for sub in view.subviews {
                if let found = findTabBar(in: sub) { return found }
            }
            return nil
        }

        // MARK: - Frame calculation

        private func report(_ bar: UITabBar, in win: UIWindow) {
            // First try to find the visual pill — a subview of UITabBar that is
            // narrower than the full bar (has horizontal insets) or has a corner radius.
            // iOS 26 liquid-glass tab bar uses such a subview for the floating pill.
            if let (pillRect, pillRadius) = pillFrame(in: bar, win: win) {
                DispatchQueue.main.async { [weak self] in
                    self?.onCapture(pillRect, pillRadius)
                }
                return
            }

            // Fallback: use UITabBar frame, crop home-indicator safe area.
            let rect        = bar.convert(bar.bounds, to: nil)
            let safeBottom  = win.safeAreaInsets.bottom
            let gapToBottom = win.bounds.height - rect.maxY
            let finalRect: CGRect
            if gapToBottom >= safeBottom - 4 {
                finalRect = rect
            } else {
                finalRect = CGRect(
                    x:      rect.minX,
                    y:      rect.minY,
                    width:  rect.width,
                    height: max(rect.height - safeBottom, 40)
                )
            }
            let radius = bar.layer.cornerRadius
            DispatchQueue.main.async { [weak self] in
                self?.onCapture(finalRect, radius)
            }
        }

        /// Searches direct subviews of UITabBar for the visual pill:
        /// a visible view that is narrower than the bar OR has a corner radius,
        /// and is tall enough to be the pill (≥ 20 pt).
        /// Returns (windowSpaceRect, cornerRadius) of the best candidate.
        private func pillFrame(in bar: UITabBar, win: UIWindow) -> (CGRect, CGFloat)? {
            let barWidth = bar.bounds.width
            var best: (rect: CGRect, radius: CGFloat, area: CGFloat)? = nil

            for sub in bar.subviews {
                guard !sub.isHidden, sub.alpha > 0.01 else { continue }
                let r      = sub.convert(sub.bounds, to: nil)
                let radius = sub.layer.cornerRadius
                let isNarrower = r.width < barWidth - 4   // has horizontal margin
                let hasRadius  = radius > 2
                guard (isNarrower || hasRadius), r.height >= 20 else { continue }

                let area = r.width * r.height
                if best == nil || area > best!.area {
                    best = (r, radius, area)
                }
            }
            return best.map { ($0.rect, $0.radius) }
        }

    }
}
