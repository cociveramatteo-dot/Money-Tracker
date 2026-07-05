import Testing
import Foundation
@testable import MoneyTracker

/// Verifica `Account.currentBalance`/`futureBalance` (Decimal, via AccountBalanceCache) su
/// oggetti @Model non gestiti (mai inseriti in un ModelContext). SwiftData permette di
/// costruire e leggere `Account`/`Transaction` come normali oggetti Swift prima
/// dell'inserimento: usarli così evita di aprire un ModelContainer per un test che
/// riguarda solo aritmetica Decimal, rendendolo più veloce e isolato da qualunque
/// ModelContainer reale aperto altrove nel processo di test (es. l'app host).
@Suite("Account balance", .serialized)
@MainActor
struct AccountBalanceTests {

    @Test("currentBalance somma solo le transazioni isDone, futureBalance tutte")
    func balancesReflectDoneVsPlanned() {
        AccountBalanceCache.shared.invalidateAll()

        let account = Account(name: "Conto", type: .conto, initialBalance: Decimal(100))
        let done = Transaction(name: "Spesa", amount: Decimal(30), type: .uscita, isDone: true, account: account)
        let planned = Transaction(name: "Affitto pianificato", amount: Decimal(50), type: .uscita, isDone: false, account: account)
        account.transactions = [done, planned]

        #expect(account.currentBalance == Decimal(70))   // 100 - 30 (solo isDone)
        #expect(account.futureBalance  == Decimal(20))   // 100 - 30 - 50 (tutte)
        #expect(account.plannedDelta   == Decimal(-50))
    }

    @Test("La cache si invalida esplicitamente e riflette il nuovo importo")
    func cacheInvalidatesOnDemand() {
        AccountBalanceCache.shared.invalidateAll()

        let account = Account(name: "Conto", type: .conto, initialBalance: Decimal(0))
        #expect(account.currentBalance == Decimal(0))

        let tx = Transaction(name: "Entrata", amount: Decimal(500), type: .entrata, isDone: true, account: account)
        account.transactions = [tx]
        // PERF-04: la cache è keyed per persistentModelID e non sa che `transactions` è
        // cambiato sotto di lei — invalidateAll() è lo stesso meccanismo usato da
        // ModelContext.safeSave() in produzione dopo ogni mutazione reale.
        AccountBalanceCache.shared.invalidateAll()

        #expect(account.currentBalance == Decimal(500))
    }

    @Test("Decimal evita gli errori di arrotondamento binario tipici di Double")
    func decimalAvoidsBinaryRoundingErrors() {
        AccountBalanceCache.shared.invalidateAll()

        let account = Account(name: "Conto", type: .conto, initialBalance: Decimal(0))
        // 0.1 + 0.2 in Double binario dà 0.30000000000000004, non 0.3 esatto.
        let t1 = Transaction(name: "A", amount: Decimal(string: "0.1")!, type: .entrata, isDone: true, account: account)
        let t2 = Transaction(name: "B", amount: Decimal(string: "0.2")!, type: .entrata, isDone: true, account: account)
        account.transactions = [t1, t2]

        #expect(account.currentBalance == Decimal(string: "0.3")!)
    }
}
