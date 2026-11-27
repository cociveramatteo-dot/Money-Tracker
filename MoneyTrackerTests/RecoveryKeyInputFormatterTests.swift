import Testing
import Foundation
@testable import MoneyTracker

@MainActor
@Suite("Formattazione chiave di recupero")
struct RecoveryKeyInputFormatterTests {

    @Test("Inserisce trattini ogni 4 caratteri senza trattino finale e converte in maiuscolo")
    func groupsByFourAndUppercases() {
        #expect(RecoveryKeyInputFormatter.format("abcd") == "ABCD")
        #expect(RecoveryKeyInputFormatter.format("abcde") == "ABCD-E")
        #expect(RecoveryKeyInputFormatter.format("abcd1234efgh") == "ABCD-1234-EFGH")
    }

    @Test("Incolla chiave intera con o senza trattini e spazi normalizzato")
    func normalizesPastedKey() {
        let raw = "  ab12 cd34-ef56\ngh78 jk90-mn23 pq45-rs67  "
        #expect(
            RecoveryKeyInputFormatter.format(raw)
                == "AB12-CD34-EF56-GH78-JK90-MN23-PQ45-RS67"
        )
    }

    @Test("Il tasto cancella supera il trattino senza bloccarsi")
    func backspaceCrossesDashWithoutGettingStuck() {
        // Cancellazione dell'ultimo carattere dopo il trattino
        #expect(RecoveryKeyInputFormatter.format("ABCD-", previous: "ABCD-E") == "ABCD")
        // Cancellazione diretta del trattino intermedio
        #expect(RecoveryKeyInputFormatter.format("ABCDEFGH", previous: "ABCD-EFGH") == "ABCE-FGH")
        // Cancellazione di un trattino finale residuo
        #expect(RecoveryKeyInputFormatter.format("ABCD", previous: "ABCD-") == "ABC")
    }

    @Test("Tronca al massimo a 32 caratteri utili")
    func capsAt32UsefulCharacters() {
        let over = "abcd1234efgh5678jkmn9012pqrs3456tvwx"
        let formatted = RecoveryKeyInputFormatter.format(over)
        #expect(formatted == "ABCD-1234-EFGH-5678-JKMN-9012-PQRS-3456")
        #expect(formatted.filter { $0 != "-" }.count == 32)
    }
}
