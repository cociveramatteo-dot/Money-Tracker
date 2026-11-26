import Foundation
import SwiftData
import XCTest
@testable import MoneyTracker

/// Opt-in integration test run inside the installed Debug app by prova-due-dispositivi.py.
final class TwoDeviceLiveSyncTests: XCTestCase {
    @MainActor
    func testLiveSync() async throws {
        let environment = ProcessInfo.processInfo.environment
        guard let bridge = environment["MT_LIVE_BRIDGE"], let run = environment["MT_LIVE_RUN"],
              let phase = environment["MT_LIVE_PHASE"] else {
            throw XCTSkip("Richiede lo script della prova a due dispositivi.")
        }
        let service = SyncService.shared
        let defaults = UserDefaults.standard
        let auth = SupabaseManager.shared
        let prefix = "S51b \(run)"
        let a = "\(prefix) \(phase) A"
        let b = "\(prefix) \(phase) B"

        func request(_ path: String) async throws -> Data {
            let url = try XCTUnwrap(URL(string: "\(bridge)/\(path)"))
            var request = URLRequest(url: url, timeoutInterval: 150)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            let (data, response) = try await URLSession.shared.data(for: request)
            try require((response as? HTTPURLResponse)?.statusCode == 200, "Coordinamento: \(path)")
            return data
        }

        func assertTransaction(_ name: String, cents: Int, in context: ModelContext) throws {
            let rows = try context.fetch(FetchDescriptor<Transaction>(predicate: #Predicate { $0.name == name }))
            try require(rows.count == 1, "Movimento assente o duplicato: \(name)")
            try require(rows.first?.amount == Decimal(cents) / 100, "Importo inatteso: \(name)")
        }

        func migrate(_ operation: E2EController.Operation, in context: ModelContext,
                     _ action: (E2EMigrator) async throws -> Void) async throws {
            // The simulator has no configured device credential. Only the OS prompt is bypassed.
            try await service.withE2EMigrator(context: context, authenticationReason: "",
                                              authenticateForTest: {}, protectionOperation: operation, action: action)
        }

        do {
            try require(service.e2eEnabled && !MoneyTrackerApp.usingVolatileStore, "Debug E2E o archivio iOS indisponibile")
            if environment["MT_LIVE_REOPEN"] == "YES" {
                try require(defaults.integer(forKey: "mtLiveLastProcess") != Int(ProcessInfo.processInfo.processIdentifier),
                            "Il processo iOS non è stato riavviato")
                let schema = Schema(versionedSchema: SchemaV3.self)
                let configuration = ModelConfiguration(schema: schema, url: try XCTUnwrap(SharedStore.mainStoreURL))
                let store = try ModelContainer(for: schema, migrationPlan: MoneyTrackerMigrationPlan.self,
                                               configurations: configuration)
                try assertTransaction(a, cents: 123, in: store.mainContext)
                try assertTransaction(b, cents: 456, in: store.mainContext)
                return
            }

            if phase == "prima" {
                let data = try await request("login")
                let credentials = try JSONDecoder().decode(Credentials.self, from: data)
                // A fresh simulator must import the existing account before any push.
                defaults.set(credentials.user.uuidString, forKey: SyncService.lastUserKey)
                defaults.set(credentials.user.uuidString, forKey: service.initialSyncKey)
                try await auth.signIn(email: credentials.email, password: credentials.password)
                let session = try await auth.client.auth.session
                try require(session.user.id == credentials.user, "Sessione iOS inattesa")
            }

            for _ in 0..<200 {
                if service.userId != nil, service.lastContext != nil { break }
                try await Task.sleep(for: .milliseconds(100))
            }
            let user = try XCTUnwrap(service.userId, "Sessione dell’app iOS non ripristinata")
            let context = try XCTUnwrap(service.lastContext, "Archivio dell’app iOS non avviato")
            let server = E2EServer(client: auth.client)
            if phase == "ripristino" {
                let lookup = try await server.lookup(userId: user)
                if case .row(let row) = lookup {
                    if row.state == .migrating {
                        try await migrate(.cancelEnable, in: context) { try await $0.cancelEnable() }
                    } else {
                        _ = await service.runE2ESync(.pull, context: context)
                        if case .row(let current) = try await server.lookup(userId: user), current.state == .active {
                            try await migrate(.disable, in: context) { try await $0.disable() }
                        }
                    }
                }
                guard case .absent = try await server.lookup(userId: user) else {
                    throw ProbeFailure(step: "Disattivazione di ripristino da verificare")
                }
                return
            }

            // Read in the current mode before migration or any upload that prunes remote rows.
            try require(await service.runE2ESync(.pull, context: context), "Pull iniziale iOS")
            if phase == "prima" {
                let local = try E2EVerifier.Snapshot(context: context, userId: user)
                for table in SyncTable.allCases {
                    let remoteIDs = try await service.remote.fetchIds(table: table, userId: user)
                    try require(Set(local.rows(table).map(\.id)) == remoteIDs, "Archivio iOS iniziale incompleto")
                }
            } else if phase == "protetta" {
                let phraseData = try await request("phrase")
                let phrase = try JSONDecoder().decode(String.self, from: phraseData)
                let recovery = try E2EMigrator.makeRecoveryKey()
                let confirmation = try XCTUnwrap(recovery.split(separator: "-").last)
                try await migrate(.enable, in: context) {
                    try await $0.enable(passphrase: phrase, recoveryKey: recovery, confirmation: String(confirmation))
                }
            } else if phase == "dopo" {
                try await migrate(.disable, in: context) { try await $0.disable() }
            }

            let lookup = try await server.lookup(userId: user)
            switch lookup {
            case .row(let row) where phase == "protetta" && row.state == .active:
                break
            case .absent where phase != "protetta":
                break
            default:
                throw ProbeFailure(step: "Stato della protezione inatteso su Supabase")
            }
            _ = try await request("protection-\(phase)")

            let remote: any SyncRemote
            if phase == "protetta" {
                let key = try XCTUnwrap(service.e2eKeyStore.load(userId: user))
                remote = VaultRemote(access: SupabaseVaultAccess(client: auth.client), dek: key.dek, owner: user,
                                     scopeReads: true)
            } else {
                remote = service.remote
            }
            let accounts = try context.fetch(FetchDescriptor<Account>(sortBy: [SortDescriptor(\.createdAt)]))
            let account: Account
            if let existing = accounts.first(where: { !$0.isArchived }) {
                account = existing
            } else {
                account = Account(name: "\(prefix) conto", type: .conto)
                context.insert(account)
                try context.save()
            }
            let transaction = Transaction(name: a, amount: Decimal(123) / 100, type: .uscita, account: account)
            let id = transaction.id
            context.insert(transaction)
            try context.save()
            // Let MoneyTrackerApp consume its actual didSave notification on the main run loop.
            for _ in 0..<20 {
                if service.dirtyTransactionIds.contains(id) { break }
                try await Task.sleep(for: .milliseconds(50))
            }
            try require(service.dirtyTransactionIds.contains(id), "Il salvataggio iOS non ha marcato A")
            await service.manualRefresh(context: context)
            var beforeAndroid = try await remote.fetchIds(table: .transactions, userId: user)
            for _ in 0..<12 {
                if beforeAndroid.contains(id) { break }
                try await Task.sleep(for: .seconds(1))
                beforeAndroid = try await remote.fetchIds(table: .transactions, userId: user)
            }
            try require(beforeAndroid.contains(id), "A non ricevuto da Supabase dopo l’invio iOS")
            try assertTransaction(a, cents: 123, in: context)

            _ = try await request("android-\(phase)")
            let afterAndroid = try await remote.fetchIds(table: .transactions, userId: user)
            let newIDs = afterAndroid.subtracting(beforeAndroid)
            try require(newIDs.count == 1, "B non confermato su Supabase dopo l’invio Android")
            let androidID = try XCTUnwrap(newIDs.first)

            // The app's normal refresh pushes first. Verify it also preserves a remote-only B.
            await service.manualRefresh(context: context)
            defaults.set(Int(ProcessInfo.processInfo.processIdentifier), forKey: "mtLiveLastProcess")
            let afterRefresh = try await remote.fetchIds(table: .transactions, userId: user)
            try require(afterRefresh.contains(androidID), "L’aggiornamento iOS ha rimosso B da Supabase")
            try assertTransaction(a, cents: 123, in: context)
            try assertTransaction(b, cents: 456, in: context)
        } catch let failure as ProbeFailure {
            XCTFail(failure.step)
        } catch {
            // Tool output and XCTest diagnostics must never include user-supplied secrets.
            XCTFail("Errore iOS durante la fase \(phase): \(type(of: error))")
        }
    }

    private struct Credentials: Decodable {
        let email: String
        let password: String
        let user: UUID
    }

    private struct ProbeFailure: Error {
        let step: String
    }

    private func require(_ condition: Bool, _ step: String) throws {
        guard condition else { throw ProbeFailure(step: step) }
    }
}
