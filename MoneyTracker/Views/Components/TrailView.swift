import SwiftUI

/// Curva del saldo nel mese (solo Home). Riceve una serie già calcolata (`BalanceTrail`):
/// non ricalcola saldi. Nessuna cifra mostrata, quindi non serve oscurarla.
struct TrailView: View {
    let trail: BalanceTrail
    /// Primo e ultimo giorno del mese, per le etichette sotto la curva.
    let monthStart: Date
    let monthEnd: Date

    private let curveHeight: CGFloat = 56
    private let inset: CGFloat = 12   // spazio per l'alone del punto «oggi»

    var body: some View {
        VStack(spacing: 2) {
            Canvas { context, size in draw(in: &context, size: size) }
                .frame(height: curveHeight)
            HStack {
                Text(monthStart, format: .dateTime.day().month(.abbreviated))
                Spacer()
                Text("Oggi").foregroundStyle(DS.heroAccent).fontWeight(.semibold)
                Spacer()
                Text(monthEnd, format: .dateTime.day().month(.abbreviated))
            }
            .font(DS.Typo.caption)
            .foregroundStyle(DS.heroSecondary)
        }
        .accessibilityHidden(true)
    }

    // MARK: Disegno

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let all = trail.actual + trail.projected
        guard let minB = all.map({ $0.balance }).min(), let maxB = all.map({ $0.balance }).max() else { return }
        let lo = NSDecimalNumber(decimal: minB).doubleValue
        let hi = NSDecimalNumber(decimal: maxB).doubleValue
        let span = hi - lo
        let dayCount = max(trail.daysInMonth - 1, 1)
        let width = size.width - inset * 2
        let height = size.height - inset * 2

        func point(_ p: BalanceTrail.Point) -> CGPoint {
            let x = inset + width * CGFloat(p.day - 1) / CGFloat(dayCount)
            let value = NSDecimalNumber(decimal: p.balance).doubleValue
            let t = span > 0 ? (value - lo) / span : 0.5
            return CGPoint(x: x, y: inset + height * CGFloat(1 - t))
        }

        // Tratto reale: pieno.
        var actualPath = Path()
        for (i, p) in trail.actual.enumerated() {
            i == 0 ? actualPath.move(to: point(p)) : actualPath.addLine(to: point(p))
        }
        context.stroke(actualPath, with: .color(DS.heroAccent),
                       style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

        // Tratto proiettato: tratteggiato ambra (solo con pianificati).
        if trail.hasPlanned {
            // Il tratteggio parte SEMPRE dal punto reale di oggi (il pallino): `projected.first` può essere
            // più in basso, perché include i pianificati di oggi. Si usano solo i punti dei giorni dopo oggi.
            var route = [BalanceTrail.Point]()
            if let now = trail.actual.last { route.append(now) }
            route += trail.projected.filter { $0.day > trail.today }
            if route.count == 1, let end = trail.projected.last { route.append(end) }  // oggi = ultimo giorno
            var projectedPath = Path()
            for (i, p) in route.enumerated() {
                i == 0 ? projectedPath.move(to: point(p)) : projectedPath.addLine(to: point(p))
            }
            context.stroke(projectedPath, with: .color(DS.heroPlanned),
                           style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round, dash: [1, 7]))

            // Un cerchio vuoto per ogni movimento pianificato; pieno a fine mese.
            // (niente cerchio per i pianificati di oggi: finirebbe sotto il pallino «oggi»)
            for mark in trail.plannedMarks where mark.day != trail.daysInMonth && mark.day > trail.today {
                let c = point(mark)
                let r: CGFloat = 4
                let circle = Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
                context.fill(circle, with: .color(DS.hero))
                context.stroke(circle, with: .color(DS.heroPlanned), lineWidth: 2)
            }
            if let last = trail.projected.last {
                let c = point(last)
                let r: CGFloat = 4.5
                context.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)),
                             with: .color(DS.heroPlanned))
            }
        }

        // Punto «oggi» con alone.
        if let now = trail.actual.last {
            let c = point(now)
            context.fill(Path(ellipseIn: CGRect(x: c.x - 12, y: c.y - 12, width: 24, height: 24)),
                         with: .color(DS.heroAccent.opacity(0.18)))
            context.fill(Path(ellipseIn: CGRect(x: c.x - 5.5, y: c.y - 5.5, width: 11, height: 11)),
                         with: .color(DS.heroAccent))
        }
    }
}

#Preview("Con pianificati") {
    let cal = Calendar.current
    let now = Date()
    let trail = BalanceTrail.make(
        currentBalance: 4218,
        entries: [
            .init(date: now.addingTimeInterval(-86400 * 8), signedAmount: -300, isDone: true),
            .init(date: now.addingTimeInterval(86400 * 6), signedAmount: -400, isDone: false),
            .init(date: now.addingTimeInterval(86400 * 12), signedAmount: -178, isDone: false),
        ], now: now, calendar: cal)
    let start = cal.dateInterval(of: .month, for: now)!.start
    let end = cal.date(byAdding: .day, value: trail.daysInMonth - 1, to: start)!
    return TrailView(trail: trail, monthStart: start, monthEnd: end)
        .padding().background(DS.hero)
}

#Preview("Senza pianificati, dark") {
    let cal = Calendar.current
    let now = Date()
    let trail = BalanceTrail.make(currentBalance: 900, entries: [
        .init(date: now.addingTimeInterval(-86400 * 5), signedAmount: -100, isDone: true)], now: now, calendar: cal)
    let start = cal.dateInterval(of: .month, for: now)!.start
    let end = cal.date(byAdding: .day, value: trail.daysInMonth - 1, to: start)!
    return TrailView(trail: trail, monthStart: start, monthEnd: end)
        .padding().background(DS.hero).environment(\.colorScheme, .dark)
}
