import Foundation

// MARK: - Formatter caches

// @MainActor: all formatters are created and read exclusively on the main thread
// (views, @MainActor AppIntents). This annotation makes Swift 6 concurrency formal.
@MainActor
enum FormatterCache {
    // NumberFormatter for currency — recreated when the currency code changes.
    private static var _currencyFormatter: NumberFormatter?
    private static var _currencyFormatterCode: String = ""

    // Date formatters — recreated on locale change via NSLocale.currentLocaleDidChangeNotification.
    private static var _monthYear:  DateFormatter?
    private static var _dayMonth:   DateFormatter?
    private static var _shortMonth: DateFormatter?
    private static var _csvDate:    DateFormatter?

    /// Call once at app start to wire up locale-change invalidation.
    static func registerLocaleObserver() {
        NotificationCenter.default.addObserver(
            forName: NSLocale.currentLocaleDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            // `queue: .main` garantisce esecuzione sul main thread a runtime;
            // `assumeIsolated` informa il type-checker Swift 6 in modo formale
            // (evita i warning "Main actor-isolated property can not be mutated from a Sendable closure").
            MainActor.assumeIsolated {
                _currencyFormatter     = nil
                _currencyFormatterCode = ""
                _monthYear             = nil
                _dayMonth              = nil
                _shortMonth            = nil
                _csvDate               = nil
            }
        }
    }

    static func currencyFormatter() -> NumberFormatter {
        let code = UserDefaults.standard.string(forKey: "currencyCode") ?? "EUR"
        if let cached = _currencyFormatter, _currencyFormatterCode == code {
            return cached
        }
        let f = NumberFormatter()
        f.numberStyle  = .currency
        f.currencyCode = code
        f.locale       = Locale.current
        _currencyFormatter     = f
        _currencyFormatterCode = code
        return f
    }

    static var monthYear: DateFormatter {
        if let f = _monthYear { return f }
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; f.locale = Locale.current
        _monthYear = f; return f
    }

    static var dayMonth: DateFormatter {
        if let f = _dayMonth { return f }
        let f = DateFormatter(); f.dateFormat = "d MMM"; f.locale = Locale.current
        _dayMonth = f; return f
    }

    static var shortMonth: DateFormatter {
        if let f = _shortMonth { return f }
        let f = DateFormatter(); f.dateFormat = "MMM"; f.locale = Locale.current
        _shortMonth = f; return f
    }

    /// Shared CSV date formatter (dd/MM/yyyy) — cached and locale-aware.
    static var csvDate: DateFormatter {
        if let f = _csvDate { return f }
        let f = DateFormatter(); f.dateFormat = "dd/MM/yyyy"; f.locale = Locale.current
        _csvDate = f; return f
    }
}
