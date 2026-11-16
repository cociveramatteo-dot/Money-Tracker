import Foundation
import Testing

@Suite("Days remaining plurals")
struct DaysRemainingPluralTests {
    @Test("Localized resources render 0, 1 and 2 correctly in all seven languages")
    func pluralForms() throws {
        let cases: [(String, [String])] = [
            ("it", ["Mancano 0 giorni", "Manca 1 giorno", "Mancano 2 giorni"]),
            ("en", ["0 days left", "1 day left", "2 days left"]),
            ("de", ["Noch 0 Tage", "Noch 1 Tag", "Noch 2 Tage"]),
            ("es", ["Faltan 0 días", "Falta 1 día", "Faltan 2 días"]),
            ("fr", ["Plus que 0 jours", "Plus que 1 jour", "Plus que 2 jours"]),
            ("ja", ["残り0日", "残り1日", "残り2日"]),
            ("zh-Hans", ["还剩0天", "还剩1天", "还剩2天"])
        ]
        for (language, expected) in cases {
            let path = try #require(Bundle.main.path(forResource: language, ofType: "lproj"))
            let bundle = try #require(Bundle(path: path))
            let format = bundle.localizedString(forKey: "Mancano %lld giorni", value: nil, table: nil)
            for count in 0...2 {
                #expect(String.localizedStringWithFormat(format, Int64(count)) == expected[count],
                        "\(language), count \(count)")
            }
        }
    }
}
