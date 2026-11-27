import Foundation

/// Normalizza l'input dei campi chiave di recupero:
/// maiuscole automatiche, rimozione spazi/trattini in incolla,
/// trattino automatico ogni 4 caratteri (mai in coda),
/// cancellazione che supera il trattino, massimo 32 caratteri utili.
enum RecoveryKeyInputFormatter {
    static let maxUsefulCharacters = 32

    static func format(
        _ newValue: String,
        previous: String = "",
        maxCharacters: Int = maxUsefulCharacters
    ) -> String {
        var useful = extractUseful(from: newValue)
        if let deletedDashIndex = singleDeletedDashIndex(newValue: newValue, previous: previous) {
            let usefulBeforeDash = extractUseful(from: String(previous[..<deletedDashIndex])).count
            if usefulBeforeDash > 0 && usefulBeforeDash <= useful.count {
                useful.remove(at: usefulBeforeDash - 1)
            }
        }
        let clamped = Array(useful.prefix(maxCharacters))
        return groupWithDashes(clamped)
    }

    private static func extractUseful(from text: String) -> [Character] {
        var result: [Character] = []
        result.reserveCapacity(text.count)
        for ch in text where ch != "-" && !ch.isWhitespace && !ch.isNewline {
            for upper in ch.uppercased() {
                result.append(upper)
            }
        }
        return result
    }

    private static func singleDeletedDashIndex(newValue: String, previous: String) -> String.Index? {
        guard !previous.isEmpty, newValue.count == previous.count - 1 else { return nil }
        var pIdx = previous.startIndex
        var nIdx = newValue.startIndex
        while pIdx < previous.endIndex && nIdx < newValue.endIndex && previous[pIdx] == newValue[nIdx] {
            pIdx = previous.index(after: pIdx)
            nIdx = newValue.index(after: nIdx)
        }
        guard pIdx < previous.endIndex, previous[pIdx] == "-" else { return nil }
        let after = previous.index(after: pIdx)
        guard String(previous[..<pIdx]) + String(previous[after...]) == newValue else { return nil }
        return pIdx
    }

    private static func groupWithDashes(_ chars: [Character]) -> String {
        guard !chars.isEmpty else { return "" }
        var output = ""
        output.reserveCapacity(chars.count + (chars.count - 1) / 4)
        for (idx, ch) in chars.enumerated() {
            if idx > 0 && idx.isMultiple(of: 4) {
                output.append("-")
            }
            output.append(ch)
        }
        return output
    }
}
