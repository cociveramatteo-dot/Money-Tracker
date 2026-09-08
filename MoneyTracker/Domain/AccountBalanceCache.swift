import Foundation
import SwiftData

// MARK: - Account Balance Cache (PERF-04)

/// Cache in-memory (mai persistita) dei saldi calcolati di ogni `Account`.
///
/// PRIMA: `Account.currentBalance`/`futureBalance` erano computed property che
/// iteravano `transactions` (O(n)) ad ogni singola lettura. SwiftUI rivaluta `body`
/// molto più spesso di quanto i dati cambino (scroll, animazioni, cambi di tab), quindi
/// con N account e M transazioni per account il costo reale a schermo era O(N×M) per
/// frame — su Dashboard/AccountsView, che leggono più saldi nello stesso render.
///
/// DOPO: il risultato viene memoizzato per `PersistentIdentifier` e invalidato in blocco
/// da `ModelContext.safeSave()`, l'unico punto di salvataggio usato da quasi tutta l'app.
/// Il ricalcolo O(n) avviene quindi una volta per salvataggio, non una volta per frame.
///
/// Non è isolata al `@MainActor`: `RecurringTransactionActor` (background `@ModelActor`,
/// vedi Domain/RecurringTransactionEngine.swift) deve poter invalidare/leggere la stessa
/// cache dal proprio executor senza dover fare `await` verso il main actor. La classe è
/// quindi un semplice singleton thread-safe protetto da lock, non un attore: legge solo
/// tipi valore (`PersistentIdentifier`, `Double`) sotto lock, mai il modello stesso.
// nonisolated: il progetto ha SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor, quindi ogni
// dichiarazione non annotata sarebbe implicitamente @MainActor. Questa cache deve invece
// restare accessibile sia dal main actor (le view) sia da RecurringTransactionActor
// (background @ModelActor) senza `await` — da qui l'opt-out esplicito.
nonisolated final class AccountBalanceCache: @unchecked Sendable {
    static let shared = AccountBalanceCache()
    private init() {}

    private let lock = NSLock()
    private var currentByID: [PersistentIdentifier: Decimal] = [:]
    private var futureByID:  [PersistentIdentifier: Decimal] = [:]
    // Bumped da invalidateAll(): permette a currentBalance/futureBalance di accorgersi
    // se un'invalidazione (es. save concorrente su RecurringTransactionActor) è avvenuta
    // mentre stavano ricalcolando, ed evitare di re-inserire in cache un valore ormai
    // stantio calcolato da uno snapshot pre-invalidazione (TOCTOU tra il calcolo fuori
    // lock e la scrittura in cache sotto lock).
    private var generation = 0

    func invalidateAll() {
        lock.lock()
        currentByID.removeAll(keepingCapacity: true)
        futureByID.removeAll(keepingCapacity: true)
        generation += 1
        lock.unlock()
    }

    func currentBalance(for account: Account) -> Decimal {
        let id = account.persistentModelID
        lock.lock()
        if let cached = currentByID[id] { lock.unlock(); return cached }
        let generationAtRead = generation
        lock.unlock()

        let done = account.transactions.filter { $0.isDone }
        let value = account.initialBalance + done.reduce(Decimal(0)) { $0 + $1.signedAmount }

        lock.lock()
        if generation == generationAtRead { currentByID[id] = value }
        lock.unlock()
        return value
    }

    func futureBalance(for account: Account) -> Decimal {
        let id = account.persistentModelID
        lock.lock()
        if let cached = futureByID[id] { lock.unlock(); return cached }
        let generationAtRead = generation
        lock.unlock()

        let value = account.initialBalance + account.transactions.reduce(Decimal(0)) { $0 + $1.signedAmount }

        lock.lock()
        if generation == generationAtRead { futureByID[id] = value }
        lock.unlock()
        return value
    }
}
