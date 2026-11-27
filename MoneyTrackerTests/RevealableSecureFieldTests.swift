import Foundation
import SwiftUI
import Testing
@testable import MoneyTracker

@MainActor
@Suite("Campi segreti mostra/nascondi")
struct RevealableSecureFieldTests {

    @Test("Il campo torna nascosto quando l'app lascia il primo piano")
    func hidesOnNonActiveScenePhase() {
        #expect(!RevealableSecureField.shouldHide(on: .active))
        #expect(RevealableSecureField.shouldHide(on: .inactive))
        #expect(RevealableSecureField.shouldHide(on: .background))
    }

    @Test(arguments: ["it", "en", "de", "es", "fr", "ja", "zh-Hans"])
    func showAndHideAccessibilityLabelsExistInAllLanguages(language: String) throws {
        let folder = try #require(Bundle.main.url(forResource: language, withExtension: "lproj"))
        let file = try Data(contentsOf: folder.appending(path: "Localizable.strings"))
        let plist = try PropertyListSerialization.propertyList(from: file, format: nil)
        let strings = try #require(plist as? [String: String])
        #expect(!(strings["Mostra"]?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true))
        #expect(!(strings["Nascondi"]?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true))
    }
}
