import Foundation
import Testing

struct E2ELocalizationTests {
    // S-50 §5.3 defines the same identifiers for iOS and Android.
    private static let expected = Set("""
    e2e_titolo
    e2e_sottotitolo
    e2e_stato_attiva
    e2e_stato_disattivata
    e2e_intro
    e2e_metadati
    e2e_avviso_perdita
    e2e_avviso_aggiorna
    e2e_attiva
    e2e_frase_titolo
    e2e_frase_aiuto
    e2e_frase_campo
    e2e_frase_ripeti
    e2e_frase_corta
    e2e_frase_diverse
    e2e_chiave_titolo
    e2e_chiave_testo
    e2e_copia
    e2e_condividi
    e2e_chiave_conferma
    e2e_chiave_salvata
    e2e_in_corso
    e2e_fatto
    e2e_cambia_frase
    e2e_nuova_chiave
    e2e_nuova_chiave_nota
    e2e_disattiva
    e2e_disattiva_titolo
    e2e_disattiva_testo
    e2e_disattivazione_in_corso
    e2e_pausa
    e2e_sblocca_titolo
    e2e_sblocca_testo
    e2e_sblocca
    e2e_usa_chiave
    e2e_chiave_campo
    e2e_errata
    e2e_perse_entrambe
    e2e_ricomincia_titolo
    e2e_ricomincia_testo
    e2e_ricomincia
    e2e_altro_dispositivo
    e2e_errore
    e2e_annulla_attivazione
    e2e_riprova
    e2e_gia_in_corso
    e2e_serve_rete
    e2e_motivo_biometria
    e2e_frase_cambiata
    """.split(separator: "\n").map(String.init))

    @Test(arguments: ["it", "en", "de", "es", "fr", "ja", "zh-Hans"])
    func containsEverySharedKey(language: String) throws {
        let folder = try #require(Bundle.main.url(forResource: language, withExtension: "lproj"))
        let file = try Data(contentsOf: folder.appending(path: "Localizable.strings"))
        let plist = try PropertyListSerialization.propertyList(from: file, format: nil)
        let strings = try #require(plist as? [String: String])
        let e2e = strings.filter { $0.key.hasPrefix("e2e_") }
        #expect(Set(e2e.keys) == Self.expected)
        for (key, value) in e2e {
            #expect(!value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "\(language)/\(key)")
            #expect(!value.contains("%"), "\(language)/\(key) must have no format placeholders")
        }
    }
}
