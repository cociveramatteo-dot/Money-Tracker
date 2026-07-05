import Testing
@testable import MoneyTracker

/// Testa l'algoritmo di classificazione con un dizionario minimo esplicito, non con le
/// ~3600 keyword di produzione — questo è esattamente il beneficio dell'estrazione a
/// protocollo (Domain/CategoryClassifying.swift): l'algoritmo è testabile in isolamento
/// dal dataset reale e dal bundle dell'app.
@Suite("KeywordCategoryClassifier")
struct KeywordCategoryClassifierTests {

    private func makeClassifier() -> KeywordCategoryClassifier {
        KeywordCategoryClassifier(keywords: [
            "Cibo":      ["pizza", "supermercato", "ristorante"],
            "Trasporti": ["benzina", "treno", "autobus"],
            "Svago":     ["cinema", "netflix"],
        ])
    }

    @Test("Match esatto ritorna la categoria corretta")
    func exactMatch() {
        let classifier = makeClassifier()
        #expect(classifier.classify("pizza") == "Cibo")
        #expect(classifier.classify("benzina") == "Trasporti")
    }

    @Test("Testo che contiene una keyword nota classifica correttamente")
    func containsKeyword() {
        let classifier = makeClassifier()
        #expect(classifier.classify("Pizza da Mario") == "Cibo")
        #expect(classifier.classify("Netflix abbonamento mensile") == "Svago")
    }

    @Test("Testo senza match ritorna Altro")
    func noMatchFallsBackToAltro() {
        let classifier = makeClassifier()
        #expect(classifier.classify("xyz123 sconosciuto") == "Altro")
    }

    @Test("Input vuoto o solo spazi ritorna Altro")
    func emptyInputFallsBackToAltro() {
        let classifier = makeClassifier()
        #expect(classifier.classify("") == "Altro")
        #expect(classifier.classify("   ") == "Altro")
    }

    @Test("Plurale italiano matcha via stemming")
    func italianStemMatches() {
        let classifier = makeClassifier()
        // "ristoranti" (plurale) deve matchare la keyword singolare "ristorante" via lo stemmer.
        #expect(classifier.classify("Cena al ristoranti del porto") == "Cibo")
    }

    @Test("Dizionario vuoto classifica sempre Altro")
    func emptyDictionaryAlwaysAltro() {
        let classifier = KeywordCategoryClassifier(keywords: [:])
        #expect(classifier.classify("pizza") == "Altro")
    }
}
