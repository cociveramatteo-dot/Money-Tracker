import Foundation
import Testing
@testable import MoneyTracker

@Suite("Last used category")
struct LastUsedCategoryTests {
    private func movement(_ name: String = "Mc", _ category: String = "Cibo", at: Double = 1,
                          done: Bool = true, transfer: Bool = false) -> LastUsedCategory.Movement {
        .init(name: name, category: category, createdAt: Date(timeIntervalSince1970: at),
              isDone: done, isTransfer: transfer)
    }
    private func suggest(_ name: String, _ history: [LastUsedCategory.Movement],
                         categories: Set<String> = ["Cibo", "Svago", "Altro"]) -> String? {
        LastUsedCategory.suggest(for: name, history: history, availableCategories: categories)
    }
    @Test func emptyHistory() { #expect(suggest("Mc", []) == nil) }
    @Test func newNameAndExactMatching() {
        #expect(suggest("Nuovo", [movement()]) == nil)
        #expect(suggest("M", [movement()]) == nil)
        #expect(suggest("Mcc", [movement()]) == nil)
        #expect(suggest("  ", [movement(" ")]) == nil)
    }
    @Test func caseAccentsAndWhitespace() {
        #expect(suggest("  CAFE\u{301}   del\tPORTO ", [movement("Café del Porto")]) == "Cibo")
    }
    @Test func latestWinsRegardlessOfInputOrder() {
        let history = [movement("Mc", "Svago", at: 3), movement("Mc", "Cibo", at: 1)]
        #expect(suggest("mc", history) == "Svago")
        #expect(suggest("mc", history.reversed()) == "Svago")
    }
    @Test func plannedAndTransfersIgnored() {
        #expect(suggest("Mc", [movement(), movement("Mc", "Svago", at: 3, done: false),
                                   movement("Mc", "Svago", at: 4, transfer: true)]) == "Cibo")
        #expect(suggest("Mc", [movement(done: false), movement(transfer: true)]) == nil)
    }
    @Test func deletedCategoryDoesNotResurrectOlderChoice() {
        #expect(suggest("Mc", [movement(), movement("Mc", "Eliminata", at: 2)]) == nil)
        #expect(suggest("Mc", [movement()], categories: []) == nil)
    }
    @Test func explicitAltroIsRemembered() {
        #expect(suggest("Mc", [movement("Mc", "Altro")]) == "Altro")
    }
}
