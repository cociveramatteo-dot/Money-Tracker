// @preconcurrency: sopprime l'inferenza di @MainActor da UIKit (iOS 26 annota UIFont/UIColor
// come @MainActor), così generate() resta nonisolated e può girare in Task.detached.
@preconcurrency import UIKit
import OSLog

private let pdfLogger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "pdf")

// MARK: - PDFTxSnapshot
//
// Lightweight Sendable snapshot of a Transaction — avoids carrying @MainActor
// SwiftData models across actor boundaries into the background PDF renderer.

struct PDFTxSnapshot: Sendable {
    let name:     String
    let amount:   Double
    let date:     Date
    let isIncome: Bool   // true = entrata, false = uscita
    let isDone:   Bool
    let category: String
}

// MARK: - PDFReportGenerator

// Runs on any thread: UIGraphicsPDFRenderer writes to file (not screen) so it is thread-safe.
// Uses its own local formatters instead of the shared FormatterCache to avoid data races.
struct PDFReportGenerator {

    private static let pageW: CGFloat = 595.2
    private static let pageH: CGFloat = 841.8
    private static let margin: CGFloat = 44
    private static var contentW: CGFloat { pageW - 2 * margin }

    // iOS 26: UIColor è Sendable → nonisolated(unsafe) non più necessario.
    private static let inkColor   = UIColor(white: 0.07, alpha: 1)
    private static let smokeColor = UIColor(white: 0.53, alpha: 1)
    private static let fogColor   = UIColor(white: 0.88, alpha: 1)

    // MARK: - Entry point

    static func generate(
        month: Date,
        transactions: [PDFTxSnapshot],
        prevMonthSpent: Double
    ) -> URL? {

        // Local formatters — created per-call so they're safe on any thread.
        let currFmt: NumberFormatter = {
            let f = NumberFormatter()
            f.numberStyle        = .currency
            f.locale             = Locale.current
            f.currencyCode       = Locale.current.currency?.identifier
            return f
        }()
        let dayMonthFmt: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "d MMM"
            f.locale     = Locale.current
            return f
        }()
        let monthYearFmt: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "MMMM yyyy"
            f.locale     = Locale.current
            return f
        }()

        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageW, height: pageH),
            format: {
                let fmt = UIGraphicsPDFRendererFormat()
                fmt.documentInfo = [
                    kCGPDFContextTitle as String:   monthYearFmt.string(from: month).capitalized,
                    kCGPDFContextCreator as String: "MoneyTracker"
                ]
                return fmt
            }()
        )

        let fileName = "report_\(monthFileLabel(month)).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        // Rimuovi un eventuale file parziale da un run precedente (idempotenza).
        try? FileManager.default.removeItem(at: url)

        do {
            try renderer.writePDF(to: url) { ctx in
                renderPages(
                    ctx: ctx, month: month, transactions: transactions,
                    prevSpent: prevMonthSpent,
                    currFmt: currFmt, dayMonthFmt: dayMonthFmt, monthYearFmt: monthYearFmt
                )
            }
            // Protezione crittografica iOS: il file è inaccessibile a disco quando il
            // dispositivo è bloccato dopo il primo sblocco post-riavvio.
            // FileManager.setAttributes è l'unica API che permette di scrivere NSFileProtectionKey
            // su un file esistente — URLResourceValues.fileProtection è read-only.
            try? FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                ofItemAtPath: url.path
            )
            return url
        } catch {
            pdfLogger.error("writePDF failed: \(error, privacy: .public)")
            return nil
        }
    }

    // MARK: - Page rendering

    private static func renderPages(
        ctx: UIGraphicsPDFRendererContext,
        month: Date,
        transactions: [PDFTxSnapshot],
        prevSpent: Double,
        currFmt: NumberFormatter,
        dayMonthFmt: DateFormatter,
        monthYearFmt: DateFormatter
    ) {
        let done    = transactions.filter { $0.isDone }
        let uscite  = done.filter { !$0.isIncome }.reduce(0) { $0 + $1.amount }
        let entrate = done.filter {  $0.isIncome }.reduce(0) { $0 + $1.amount }

        var catMap: [String: Double] = [:]
        for t in done where !t.isIncome {
            catMap[t.category, default: 0] += t.amount
        }
        let cats = catMap.sorted { $0.value > $1.value }

        ctx.beginPage()
        let cg = ctx.cgContext
        var y = margin

        y = drawHeader(cg: cg, month: month, y: y, monthYearFmt: monthYearFmt)
        y += 24
        y = drawDivider(cg: cg, y: y)
        y += 20

        y = drawSummary(cg: cg, uscite: uscite, entrate: entrate, prevSpent: prevSpent, y: y, currFmt: currFmt)
        y += 24
        y = drawDivider(cg: cg, y: y)
        y += 20

        y = drawCategorySection(cg: cg, ctx: ctx, cats: cats, total: uscite, y: y, currFmt: currFmt)
        y += 20
        y = drawDivider(cg: cg, y: y)
        y += 20

        drawTransactions(
            cg: cg, ctx: ctx,
            transactions: transactions.sorted { $0.date > $1.date },
            y: y, currFmt: currFmt, dayMonthFmt: dayMonthFmt
        )
    }

    // MARK: - Header

    private static func drawHeader(cg: CGContext, month: Date, y: CGFloat, monthYearFmt: DateFormatter) -> CGFloat {
        drawText("MONEYTRACKER", at: CGPoint(x: margin, y: y),
                 font: .systemFont(ofSize: 10, weight: .semibold),
                 color: smokeColor, letterSpacing: 1.5)

        let mStr = monthYearFmt.string(from: month).capitalized
        let mAttr = NSAttributedString(string: mStr, attributes: [
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
            .foregroundColor: smokeColor
        ])
        let mSize = mAttr.size()
        mAttr.draw(at: CGPoint(x: pageW - margin - mSize.width, y: y))

        let bigY = y + 20
        drawText(mStr.uppercased(), at: CGPoint(x: margin, y: bigY),
                 font: .systemFont(ofSize: 28, weight: .black),
                 color: inkColor)

        return bigY + 36
    }

    // MARK: - Summary

    private static func drawSummary(cg: CGContext, uscite: Double, entrate: Double, prevSpent: Double, y: CGFloat, currFmt: NumberFormatter) -> CGFloat {
        let colW = contentW / 3
        var curY = y

        drawText(String(localized: "Uscite").uppercased(), at: CGPoint(x: margin, y: curY),
                 font: .systemFont(ofSize: 9, weight: .semibold),
                 color: smokeColor, letterSpacing: 1.2)
        drawText(String(localized: "Entrate").uppercased(), at: CGPoint(x: margin + colW, y: curY),
                 font: .systemFont(ofSize: 9, weight: .semibold),
                 color: smokeColor, letterSpacing: 1.2)
        drawText(String(localized: "Netto").uppercased(), at: CGPoint(x: margin + colW * 2, y: curY),
                 font: .systemFont(ofSize: 9, weight: .semibold),
                 color: smokeColor, letterSpacing: 1.2)
        curY += 16

        let netto = entrate - uscite
        drawText(currFmt.fmt(uscite),  at: CGPoint(x: margin, y: curY),
                 font: .systemFont(ofSize: 22, weight: .black), color: inkColor)
        drawText(currFmt.fmt(entrate), at: CGPoint(x: margin + colW, y: curY),
                 font: .systemFont(ofSize: 22, weight: .black), color: inkColor)
        drawText(currFmt.fmt(netto),   at: CGPoint(x: margin + colW * 2, y: curY),
                 font: .systemFont(ofSize: 22, weight: .black), color: inkColor)
        curY += 30

        if prevSpent > 0 {
            let delta = uscite - prevSpent
            let sign  = delta >= 0 ? "+" : "−"
            let pct   = abs(delta / prevSpent * 100)
            let label = "\(sign)\(String(format: "%.0f", pct))% \(String(localized: "rispetto al mese precedente"))"
            drawText(label, at: CGPoint(x: margin, y: curY),
                     font: .systemFont(ofSize: 11), color: smokeColor)
            curY += 16
        }

        return curY
    }

    // MARK: - Category Breakdown

    private static func drawCategorySection(
        cg: CGContext,
        ctx: UIGraphicsPDFRendererContext,
        cats: [(key: String, value: Double)],
        total: Double,
        y: CGFloat,
        currFmt: NumberFormatter
    ) -> CGFloat {
        var curY = y
        drawText(String(localized: "Uscite per categoria").uppercased(), at: CGPoint(x: margin, y: curY),
                 font: .systemFont(ofSize: 9, weight: .semibold),
                 color: smokeColor, letterSpacing: 1.2)
        curY += 16

        let barH: CGFloat  = 2
        let rowH: CGFloat  = 28
        let maxBars = min(cats.count, 8)

        for i in 0..<maxBars {
            let cat = cats[i]
            let pct = total > 0 ? min(cat.value / total, 1.0) : 0

            if curY + rowH > pageH - margin {
                ctx.beginPage()
                curY = margin
            }

            drawText(cat.key, at: CGPoint(x: margin, y: curY),
                     font: .systemFont(ofSize: 13), color: inkColor)

            let pctStr = String(format: "%.0f%%", pct * 100)
            let amtStr = currFmt.fmt(cat.value) + "  \(pctStr)"
            let amtAttr = NSAttributedString(string: amtStr, attributes: [
                .font: UIFont.systemFont(ofSize: 11, weight: .medium),
                .foregroundColor: smokeColor
            ])
            let amtSize = amtAttr.size()
            amtAttr.draw(at: CGPoint(x: pageW - margin - amtSize.width, y: curY + 2))

            curY += 16

            let bgRect = CGRect(x: margin, y: curY, width: contentW, height: barH)
            cg.setFillColor(fogColor.cgColor)
            cg.fill(bgRect)

            let fillW = contentW * pct
            if fillW > 0 {
                let fillRect = CGRect(x: margin, y: curY, width: fillW, height: barH)
                cg.setFillColor(inkColor.cgColor)
                cg.fill(fillRect)
            }
            curY += barH + 8
        }

        return curY
    }

    // MARK: - Transaction List

    private static func drawTransactions(
        cg: CGContext,
        ctx: UIGraphicsPDFRendererContext,
        transactions: [PDFTxSnapshot],
        y: CGFloat,
        currFmt: NumberFormatter,
        dayMonthFmt: DateFormatter
    ) {
        var curY = y
        drawText(String(localized: "Movimenti").uppercased(), at: CGPoint(x: margin, y: curY),
                 font: .systemFont(ofSize: 9, weight: .semibold),
                 color: smokeColor, letterSpacing: 1.2)
        curY += 16

        let rowH: CGFloat = 22

        for t in transactions {
            if curY + rowH > pageH - margin {
                ctx.beginPage()
                curY = margin
            }

            drawText(dayMonthFmt.string(from: t.date), at: CGPoint(x: margin, y: curY),
                     font: .systemFont(ofSize: 11), color: smokeColor)

            drawText(t.name, at: CGPoint(x: margin + 52, y: curY),
                     font: .systemFont(ofSize: 11), color: inkColor,
                     maxWidth: contentW - 110)

            let prefix = t.isIncome ? "+" : "−"
            let amtStr = "\(prefix)\(currFmt.fmt(t.amount))"
            let amtAttr = NSAttributedString(string: amtStr, attributes: [
                .font: UIFont.systemFont(ofSize: 11, weight: .medium),
                .foregroundColor: (t.isDone ? inkColor : smokeColor) as Any
            ])
            let amtSize = amtAttr.size()
            amtAttr.draw(at: CGPoint(x: pageW - margin - amtSize.width, y: curY))

            curY += rowH

            cg.setStrokeColor(fogColor.cgColor)
            cg.setLineWidth(0.5)
            cg.move(to: CGPoint(x: margin, y: curY - 1))
            cg.addLine(to: CGPoint(x: pageW - margin, y: curY - 1))
            cg.strokePath()
        }
    }

    // MARK: - Drawing helpers

    @discardableResult
    private static func drawDivider(cg: CGContext, y: CGFloat) -> CGFloat {
        cg.setStrokeColor(fogColor.cgColor)
        cg.setLineWidth(0.5)
        cg.move(to: CGPoint(x: margin, y: y))
        cg.addLine(to: CGPoint(x: pageW - margin, y: y))
        cg.strokePath()
        return y
    }

    private static func drawText(
        _ string: String,
        at point: CGPoint,
        font: UIFont,
        color: UIColor,
        letterSpacing: CGFloat = 0,
        maxWidth: CGFloat? = nil
    ) {
        var attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        if letterSpacing != 0 { attrs[.kern] = letterSpacing }

        let attr = NSAttributedString(string: string, attributes: attrs)

        if let maxW = maxWidth {
            let bounds = CGRect(x: point.x, y: point.y, width: maxW, height: font.lineHeight + 4)
            attr.draw(with: bounds, options: .usesLineFragmentOrigin, context: nil)
        } else {
            attr.draw(at: point)
        }
    }

    // MARK: - Date formatting helpers

    // iOS 26: DateFormatter è Sendable → nonisolated(unsafe) non più necessario.
    private static let fileLabelFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        return f
    }()

    private static func monthFileLabel(_ date: Date) -> String {
        fileLabelFormatter.string(from: date)
    }
}

// MARK: - NumberFormatter helper (local to PDF — not shared, so thread-safe)

private extension NumberFormatter {
    func fmt(_ value: Double) -> String {
        string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
