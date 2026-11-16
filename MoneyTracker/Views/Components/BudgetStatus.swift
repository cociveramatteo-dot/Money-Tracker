import SwiftUI

/// Soglie esclusivamente visive; nessun calcolo monetario nel componente.
struct BudgetStatus: View {
    let progress: Double
    /// Importo oltre budget già formattato e localizzato dal chiamante.
    var overage: Text? = nil

    static func color(for progress: Double) -> Color {
        progress >= 1 ? DS.danger : progress >= 0.8 ? DS.planned : DS.accent
    }

    private var foreground: Color {
        progress >= 1 ? DS.danger : progress >= 0.8 ? DS.plannedText : DS.accent
    }
    private var background: Color {
        progress >= 1 ? DS.dangerSoft : progress >= 0.8 ? DS.plannedSoft : DS.accentSoft
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            Group {
                if progress >= 1 { Text("Sforato") }
                else if progress >= 0.8 { Text("Soglia 80%") }
                else { Text(max(0, progress.isFinite ? progress : 0), format: .percent.precision(.fractionLength(0))) }
            }
            .font(DS.Typo.caption)
            .padding(.horizontal, DS.Space.s).padding(.vertical, DS.Space.xs)
            .background(background, in: Capsule())
            if progress >= 1, let overage { overage.font(DS.Typo.caption) }
        }
        .foregroundStyle(foreground)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Light") {
    HStack { BudgetStatus(progress: 0.42); BudgetStatus(progress: 0.8); BudgetStatus(progress: 1.1, overage: Text("+20 € oltre")) }
        .padding().background(DS.surface).environment(\.colorScheme, .light)
}
#Preview("Dark") {
    HStack { BudgetStatus(progress: 0.42); BudgetStatus(progress: 0.8); BudgetStatus(progress: 1.1, overage: Text("+20 € oltre")) }
        .padding().background(DS.surface).environment(\.colorScheme, .dark)
}
