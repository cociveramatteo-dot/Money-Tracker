import Testing
import UIKit
@testable import MoneyTracker

/// I font «Sentiero» devono essere registrati (UIAppFonts) con questi PostScript name,
/// altrimenti `Font.custom` ripiega in silenzio su SF Pro.
@Suite("Font registrati")
struct FontRegistrationTests {

    @Test("Space Grotesk e Inter sono disponibili nel bundle")
    func fontsAreRegistered() {
        let names = [
            "SpaceGrotesk-Medium", "SpaceGrotesk-SemiBold", "SpaceGrotesk-Bold",
            "Inter18pt-Regular", "Inter18pt-Medium", "Inter18pt-SemiBold",
        ]
        for name in names {
            #expect(UIFont(name: name, size: 12) != nil, "Font non registrato: \(name)")
        }
    }
}
