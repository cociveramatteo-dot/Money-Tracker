import Foundation

// MARK: - Currency & date formatting helpers

// Double resta usato solo dal layer di presentazione che lo richiede esplicitamente
// (assi di Swift Charts, che vuole un tipo `Plottable` — Decimal non conforma).
// Ogni importo monetario nei modelli/calcoli è invece `Decimal` (vedi estensione sotto):
// evita i micro-errori di arrotondamento binario tipici di Double sugli importi.
extension Double {

    static var activeCurrencyCode: String {
        UserDefaults.standard.string(forKey: "currencyCode") ?? "EUR"
    }

    @MainActor static var currencySymbol: String {
        FormatterCache.currencyFormatter().currencySymbol
    }

    @MainActor var currencyFormatted: String {
        let f = FormatterCache.currencyFormatter()
        return f.string(from: NSNumber(value: self)) ?? "\(Double.currencySymbol)\(self)"
    }

    @MainActor var currencyCompact: String {
        guard abs(self) >= 1000 else { return currencyFormatted }
        let sign = self < 0 ? "-" : ""
        return "\(sign)\(Double.currencySymbol)\(Int(abs(self) / 1000))k"
    }
}

extension Decimal {

    static var activeCurrencyCode: String {
        UserDefaults.standard.string(forKey: "currencyCode") ?? "EUR"
    }

    @MainActor static var currencySymbol: String {
        FormatterCache.currencyFormatter().currencySymbol
    }

    @MainActor var currencyFormatted: String {
        let f = FormatterCache.currencyFormatter()
        return f.string(from: self as NSDecimalNumber) ?? "\(Decimal.currencySymbol)\(self)"
    }

    @MainActor var currencyCompact: String {
        guard abs(self) >= 1000 else { return currencyFormatted }
        let sign = self < 0 ? "-" : ""
        let thousands = NSDecimalNumber(decimal: abs(self) / 1000).intValue
        return "\(sign)\(Decimal.currencySymbol)\(thousands)k"
    }

    /// Parsing robusto dell'input utente: accetta sia "," sia "." come separatore
    /// decimale (tastiera italiana vs. inglese), sempre normalizzato a "." prima del
    /// parsing così il risultato non dipende dal locale del dispositivo.
    static func parseAmount(_ raw: String) -> Decimal? {
        let normalized = raw.replacingOccurrences(of: ",", with: ".")
        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }

    /// Converte un Double proveniente da una sorgente esterna che non garantisce
    /// precisione decimale (es. il parametro `Double` richiesto da AppIntents/Siri) in
    /// un Decimal esatto a 2 cifre. `Decimal(_ value: Double)` erediterebbe il rumore
    /// binario del Double (es. 19.99 non è rappresentabile esattamente in base 2);
    /// passando da una stringa formattata a 2 decimali (arrotondamento corretto
    /// garantito da `%.2f`) il risultato è invece l'esatto valore in centesimi.
    init(roundedFromDouble value: Double) {
        self = Decimal(string: String(format: "%.2f", value), locale: Locale(identifier: "en_US_POSIX"))
            ?? Decimal(value)
    }

    /// Conversione esplicita a Double, isolata ai punti che la richiedono davvero
    /// (es. Swift Charts). Da non usare per nuovi calcoli finanziari.
    var asDouble: Double { NSDecimalNumber(decimal: self).doubleValue }

    /// Rappresentazione senza zeri decimali superflui per precompilare campi di editing
    /// (es. "50" invece di "50.00", ma "12.5" se il valore ha davvero dei decimali).
    /// Sempre con "." come separatore, coerente con `parseAmount` che si aspetta lo stesso.
    var editableString: String {
        let whole = NSDecimalNumber(decimal: self).intValue
        if Decimal(whole) == self { return String(whole) }
        let f = NumberFormatter()
        f.numberStyle           = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        f.usesGroupingSeparator = false
        f.decimalSeparator      = "."
        return f.string(from: self as NSDecimalNumber) ?? "\(self)"
    }

    /// Rappresentazione a 2 decimali fissi, "." come separatore, nessun raggruppamento —
    /// per export machine-readable (CSV) dove serve un formato stabile indipendente dal
    /// locale, non quello di visualizzazione (`currencyFormatted`).
    var fixedFractionString: String {
        let f = NumberFormatter()
        f.numberStyle           = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        f.usesGroupingSeparator = false
        f.decimalSeparator      = "."
        return f.string(from: self as NSDecimalNumber) ?? "\(self)"
    }
}

extension Date {
    @MainActor var monthYearFormatted: String {
        FormatterCache.monthYear.string(from: self).capitalized
    }
    @MainActor var dayMonthFormatted: String {
        if Calendar.current.isDateInToday(self) { return String(localized: "Oggi") }
        if Calendar.current.isDateInYesterday(self) { return String(localized: "Ieri") }
        return FormatterCache.dayMonth.string(from: self)
    }
    // nonisolated: funzioni pure su Calendar.current, usate anche da RecurringTransactionActor
    // in background — non devono ereditare il default @MainActor del progetto.
    nonisolated var startOfMonth: Date {
        Calendar.current.dateInterval(of: .month, for: self)?.start ?? self
    }
    nonisolated var endOfMonth: Date {
        Calendar.current.dateInterval(of: .month, for: self)?.end ?? self
    }
    nonisolated func isSameMonth(as other: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: other, toGranularity: .month)
    }
    nonisolated func isSameWeek(as other: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: other, toGranularity: .weekOfYear)
    }
    nonisolated func isSameYear(as other: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: other, toGranularity: .year)
    }
}
