import SwiftUI

struct ProgressBar: View {
    let progress: Double
    var onHero = false

    private var fraction: Double { progress.isFinite ? min(1, max(0, progress)) : 0 }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(onHero ? DS.heroDivider : DS.divider)
                Capsule().fill(BudgetStatus.color(for: progress))
                    .frame(width: geometry.size.width * fraction)
                if onHero {
                    Rectangle().fill(DS.heroText).frame(width: 2)
                        .offset(x: max(0, geometry.size.width * 0.8 - 1))
                }
            }
        }
        .frame(height: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityValue(Text(fraction, format: .percent.precision(.fractionLength(0))))
    }
}

#Preview("Light") {
    VStack(spacing: DS.Space.l) { ProgressBar(progress: 0.5); ProgressBar(progress: 0.85); ProgressBar(progress: 1.1) }
        .padding().background(DS.surface).environment(\.colorScheme, .light)
}
#Preview("Dark") {
    ProgressBar(progress: 0.85, onHero: true).padding().background(DS.hero).environment(\.colorScheme, .dark)
}
