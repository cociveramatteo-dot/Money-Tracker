import Foundation

/// Business logic contract per l'auto-categorizzazione di nome-transazione → categoria.
/// Estratta in protocollo (invece della vecchia `struct CategoryClassifier` con soli
/// membri static) così la logica finanziaria che dipende dalla categoria suggerita
/// (AddTransactionView, AddExpenseIntent) è testabile iniettando un'implementazione
/// finta, senza dover caricare né il JSON delle keyword di produzione né passare
/// dall'unico singleton statico.
protocol CategoryClassifying: Sendable {
    /// Classifica il testo dell'utente e ritorna la categoria migliore, o "Altro".
    func classify(_ name: String) -> String
}
