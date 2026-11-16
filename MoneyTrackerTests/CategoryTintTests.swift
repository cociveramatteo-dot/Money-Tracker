import Testing
@testable import MoneyTracker

@Suite("CategoryTint")
@MainActor
struct CategoryTintTests {

    @Test("Le 14 categorie predefinite hanno una tinta fissa")
    func defaultsAreFixed() {
        #expect(CategoryTint.tint(for: "Cibo") == .amber)
        #expect(CategoryTint.tint(for: "Trasporti") == .blue)
        #expect(CategoryTint.tint(for: "Svago") == .violet)
        #expect(CategoryTint.tint(for: "Salute") == .green)
        #expect(CategoryTint.tint(for: "Giroconto") == .blue)
    }

    @Test("Hash FNV-1a stabile: valori noti (non dipendono dall'avvio)")
    func hashIsStable() {
        #expect(CategoryTint.stableHash("") == 2166136261)
        #expect(CategoryTint.stableHash("a") == 0xE40C292C)
        #expect(CategoryTint.stableHash("foobar") == 0xBF9CF968)
    }

    @Test("Una categoria personalizzata ha sempre la stessa tinta")
    func customIsDeterministic() {
        let names = ["Animali", "Palestra", "Hobby 🎸", "Caffè", ""]
        for name in names {
            #expect(CategoryTint.tint(for: name) == CategoryTint.tint(for: name))
        }
        #expect(CategoryTint.tint(for: "Animali") == CategoryTint.allCases[Int(CategoryTint.stableHash("Animali") % 4)])
    }
}
