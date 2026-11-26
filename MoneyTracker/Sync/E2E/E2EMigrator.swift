import CryptoKit
import Foundation
import LocalAuthentication
import OSLog
import Security
import Supabase
import SwiftData

@MainActor
struct E2EMigrator {
    enum Step: String, CaseIterable {
        case a0, a1, a2, a3, a4, a5, a6, a7, a8
        case d0, d1, d2, d3, d4, d5, d6, d7
    }

    enum Failure: Error, Equatable {
        case unavailable, stateChanged, concurrentActivation, verificationFailed
        case invalidPassphrase, recoveryNotConfirmed, authenticationRequired
    }

    enum Secret {
        case passphrase(String)
        case recovery(String, newPassphrase: String)
    }

    typealias Snapshot = E2EVerifier.Snapshot
    let userId: UUID
    let defaults: UserDefaults
    let keyStore: E2EKeyStore
    let server: any E2EServerAccess
    let vault: any VaultAccess
    let plain: any SyncRemote
    let backupDirectory: URL
    let checkpoint: (Step) throws -> Void
    let validateSession: () throws -> Void
    let authenticate: () async throws -> Void
    let snapshot: () throws -> Snapshot
    let push: (any SyncRemote, _ deleteOrphans: Bool, _ allTransactions: Bool) async throws -> Void
    let pull: (Snapshot) async throws -> Void
    let initialSync: (any SyncRemote) async throws -> Void

    static var backupDirectory: URL {
        URL.applicationSupportDirectory.appending(path: "E2EBackup", directoryHint: .isDirectory)
    }

    static func authenticateDevice(reason: String) async throws {
        let context = LAContext()
        guard try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) else {
            throw Failure.authenticationRequired
        }
    }

    static func makeRecoveryKey() throws -> String {
        try RecoveryKey.format(RecoveryKey.generate())
    }

    static func marker(in defaults: UserDefaults, userId: UUID) -> E2EMigrationMarker? {
        guard let data = defaults.data(forKey: E2EMigrationMarker.defaultsKey),
              let marker = try? JSONDecoder().decode(E2EMigrationMarker.self, from: data),
              marker.userId == userId else { return nil }
        return marker
    }

    func enable(passphrase: String, recoveryKey: String, confirmation: String) async throws {
        guard E2EFeature.allowNewActivations else { throw Failure.unavailable }
        try Self.validatePassphrase(passphrase)
        let recoveryBytes = try RecoveryKey.parse(recoveryKey)
        let canonical = try RecoveryKey.format(recoveryBytes)
        guard let lastGroup = canonical.split(separator: "-").last,
              String(lastGroup).caseInsensitiveCompare(confirmation) == .orderedSame else {
            throw Failure.recoveryNotConfirmed
        }
        guard case .absent = try await lookup() else { throw Failure.stateChanged }
        guard Self.marker(in: defaults, userId: userId) == nil else { throw Failure.stateChanged }

        let aligned = try await synchronize(plain, deleteOrphans: false)
        try checkpoint(.a0)
        try backup(aligned)
        try checkpoint(.a1)

        let dek = SymmetricKey(size: .bits256)
        let keyId = try VaultCrypto.keyId(dek: dek)
        let (salt, wrapped) = try await passphraseWrap(passphrase, dek: dek)
        let recoveryWrap = try wrapRecovery(dek, bytes: recoveryBytes)
        try validateSession()
        let generation = Self.newGeneration()
        let row = E2EServerRow(userId: userId, state: .migrating, version: 1, kdf: "pbkdf2-sha256",
                               kdfIterations: VaultCrypto.defaultIterations, salt: salt,
                               wrappedKeyPassphrase: wrapped, wrappedKeyRecovery: recoveryWrap,
                               keyId: keyId, updatedAt: generation)
        let marker = try begin(.enable, keyId: keyId, generation: generation)
        try keyStore.save(dek, userId: userId)
        try checkpoint(.a2)

        do {
            try await server.insert(row)
        } catch {
            try validateSession()
            if (error as? PostgrestError)?.code == "23505" || (error as? HTTPError)?.response.statusCode == 409 {
                try finish()
                throw Failure.concurrentActivation
            }
            throw error
        }
        try validateSession()
        try checkpoint(.a3)
        try await activate(row: row, marker: marker, dek: dek)
    }

    func disable() async throws {
        let row = try await requireRow(state: .active)
        guard Self.marker(in: defaults, userId: userId) == nil else { throw Failure.stateChanged }
        let dek = try requireKey(row)
        try await authenticate()
        try validateSession()
        try checkpoint(.d0)
        try await requirePlainEmpty(whileActive: row)
        let encrypted = encryptedRemote(dek)
        let aligned = try await synchronize(encrypted, deleteOrphans: true)
        _ = try E2EVerifier.verify(local: aligned, remote: try await read(encrypted))
        try checkpoint(.d1)
        try backup(aligned)
        let marker = try begin(.disable, keyId: row.keyId, generation: row.updatedAt)
        try checkpoint(.d2)
        try await setState(.disabling, from: row)
        try checkpoint(.d3)
        var disabling = row
        disabling.state = .disabling
        try await deactivate(row: disabling, marker: marker, dek: dek)
    }

    func resume(_ marker: E2EMigrationMarker, row: E2EServerRow?) async throws {
        try validateSession()
        switch (marker.direction, row?.state, marker.phase) {
        case (.enable, nil, _):
            try finish()
        case (.disable, nil, .rollingBack):
            throw Failure.stateChanged
        case (.disable, nil, .resetting):
            try await clearVault(keyId: marker.keyId, whileCurrent: nil, verifiedIDs: [:])
            try await initialSync(plain)
            try finish()
        case (.disable, nil, _):
            try await finishDisable(marker)
        case (.disable, .active, .resetting):
            guard let row, marker.owns(row) else { throw Failure.stateChanged }
            try await reset(row)
        default:
            guard let row, marker.owns(row) else { throw Failure.stateChanged }
            let dek = try requireKey(row)
            switch (marker.direction, row.state, marker.phase) {
            case (.enable, .migrating, .rollingBack):
                try await rollbackEnable(row)
            case (.enable, .migrating, _):
                try await activate(row: row, marker: marker, dek: dek)
            case (.enable, .active, .verified):
                try await finishEnable(row, dek: dek)
            case (.disable, .disabling, .rollingBack), (.disable, .active, .rollingBack):
                try await rollbackDisable(row, dek: dek)
            case (.disable, .disabling, _):
                try await deactivate(row: row, marker: marker, dek: dek)
            case (.disable, .active, nil):
                try save(nil)
            default:
                throw Failure.stateChanged
            }
        }
    }

    func cancelEnable() async throws {
        let row = try await requireRow(state: .migrating)
        guard let marker = Self.marker(in: defaults, userId: userId),
              marker.direction == .enable, marker.owns(row) else { throw Failure.stateChanged }
        _ = try requireKey(row)
        try save(marker, phase: .rollingBack)
        try await rollbackEnable(row)
    }

    func unlock(_ secret: Secret) async throws {
        let row = try await requireRow()
        let dek: SymmetricKey
        switch secret {
        case .passphrase(let passphrase):
            let salt = try VaultCrypto.decodeBase64URL(row.salt)
            let kek = try await Self.derive(passphrase, salt: salt, iterations: row.kdfIterations)
            dek = try VaultCrypto.unwrap(row.wrappedKeyPassphrase, key: kek,
                                         aad: VaultCrypto.wrapAAD(.passphrase, userID: userId))
        case .recovery(let recovery, let newPassphrase):
            let kek = try VaultCrypto.recoveryKEK(RecoveryKey.parse(recovery))
            dek = try VaultCrypto.unwrap(row.wrappedKeyRecovery, key: kek,
                                         aad: VaultCrypto.wrapAAD(.recovery, userID: userId))
            guard try VaultCrypto.keyId(dek: dek) == row.keyId else { throw Failure.stateChanged }
            try await updatePassphrase(newPassphrase, dek: dek, row: row)
        }
        guard try VaultCrypto.keyId(dek: dek) == row.keyId else { throw Failure.stateChanged }
        try await requireCurrent(row)
        try keyStore.save(dek, userId: userId)
        if let marker = Self.marker(in: defaults, userId: userId), marker.owns(row) {
            try await resume(marker, row: row)
        } else if row.state == .active {
            try await initialSync(encryptedRemote(dek))
        } else {
            let source = try await read(row.state == .migrating ? plain : encryptedRemote(dek))
            let local = try snapshot()
            if SyncTable.allCases.allSatisfy({ local.rows($0).isEmpty }) {
                try await pull(source)
                _ = try E2EVerifier.verify(local: source, remote: snapshot())
            } else {
                _ = try E2EVerifier.verify(local: source, remote: local)
            }
            try await requireCurrent(row)
            try backup(source)
            let generation = Self.newGeneration(after: row.updatedAt)
            let marker = try begin(row.state == .migrating ? .enable : .disable,
                                   keyId: row.keyId, generation: generation)
            try await patch(E2EServerPatch(updatedAt: generation), from: row)
            let claimed = try await requireRow(state: row.state)
            guard marker.owns(claimed) else { throw Failure.stateChanged }
            try await resume(marker, row: claimed)
        }
    }

    func changePassphrase(_ passphrase: String) async throws {
        let row = try await requireRow(state: .active)
        let dek = try requireKey(row)
        try await authenticate()
        try await updatePassphrase(passphrase, dek: dek, row: row)
    }

    func rotateRecoveryKey() async throws -> String {
        let row = try await requireRow(state: .active)
        let dek = try requireKey(row)
        try await authenticate()
        let bytes = try RecoveryKey.generate()
        let wrapped = try wrapRecovery(dek, bytes: bytes)
        try await patch(E2EServerPatch(wrappedKeyRecovery: wrapped), from: row)
        return try RecoveryKey.format(bytes)
    }

    func restartFromDevice() async throws {
        let row = try await requireRow(state: .active)
        guard try keyStore.load(userId: userId)?.keyId != row.keyId else { throw Failure.stateChanged }
        try await authenticate()
        try await requirePlainEmpty(whileActive: row)
        try begin(.disable, keyId: row.keyId, phase: .resetting, generation: row.updatedAt)
        try await reset(row)
    }

    private func activate(row: E2EServerRow, marker: E2EMigrationMarker, dek: SymmetricKey) async throws {
        try await requireCurrent(row)
        // Once the trigger freezes the plaintext, check for writes that won
        // the race between A0 and A3 before accepting this copy as the source.
        let frozen = try await read(plain)
        let backup = try loadBackup(marker)
        do {
            _ = try E2EVerifier.verify(local: backup, remote: frozen, allowingMissingRemoteTransactions: true)
        } catch is E2EVerifier.Failure {
            try save(marker, phase: .rollingBack)
            try await rollbackEnable(row)
            throw Failure.verificationFailed
        }
        let encrypted = encryptedRemote(dek)
        guard let verified = try await copyAndVerify(to: encrypted, whileCurrent: row, deleteOrphans: true,
                                                     uploadStep: .a4, verifyStep: .a5, required: frozen) else {
            try save(marker, phase: .rollingBack)
            try await rollbackEnable(row)
            throw Failure.verificationFailed
        }
        let generation = Self.newGeneration(after: row.updatedAt)
        var cleanup = marker
        cleanup.activationGeneration = generation
        try save(cleanup, phase: .verified)
        let counts = Dictionary(uniqueKeysWithValues: SyncTable.allCases.map { ($0.kind, verified.rows($0).count) })
        try validateSession()
        guard try await server.activate(ifCurrent: row, generation: generation, counts: counts) else {
            throw Failure.stateChanged
        }
        try validateSession()
        try checkpoint(.a6)
        var active = row
        active.state = .active
        active.updatedAt = generation
        try await finishEnable(active, dek: dek)
    }

    private func deactivate(row: E2EServerRow, marker: E2EMigrationMarker, dek: SymmetricKey) async throws {
        // A plaintext orphan is a failed verification. The only plaintext
        // delete path is cleanup after the vault has been verified and is active.
        try await requireCurrent(row)
        let verified = try await copyAndVerify(to: plain, whileCurrent: row, deleteOrphans: false, uploadStep: .d4, verifyStep: .d5)
        guard verified != nil else {
            try await verifyRollbackCopy(marker, dek: dek)
            try save(marker, phase: .rollingBack)
            try await rollbackDisable(row, dek: dek)
            throw Failure.verificationFailed
        }
        try validateSession()
        guard try await server.delete(ifCurrent: row) else { throw Failure.stateChanged }
        try validateSession()
        try checkpoint(.d6)
        try await finishDisable(marker)
    }

    private func copyAndVerify(to remote: any SyncRemote, whileCurrent row: E2EServerRow, deleteOrphans: Bool,
                               uploadStep: Step, verifyStep: Step, required: Snapshot? = nil) async throws -> Snapshot? {
        let guarded = GenerationGuardedRemote(remote: remote, check: { try await requireCurrent(row) })
        for _ in 0..<2 {
            try await requireCurrent(row)
            let local = try snapshot()
            if let required {
                do { try requireSubset(required, of: local) }
                catch is E2EVerifier.Failure { continue }
            }
            try await push(guarded, deleteOrphans, true)
            try checkpoint(uploadStep)
            do {
                let uploaded = try await read(remote)
                _ = try E2EVerifier.verify(local: local, remote: uploaded)
            } catch is E2EVerifier.Failure {
                continue
            } catch is DecodingError {
                continue
            } catch is VaultCrypto.Failure {
                continue
            } catch is VaultRemote.Failure {
                continue
            } catch is CryptoKitError {
                continue
            }
            try checkpoint(verifyStep)
            return local
        }
        return nil
    }

    private func finishEnable(_ row: E2EServerRow, dek: SymmetricKey) async throws {
        try await clearPlain(whileActive: row, dek: dek)
        try checkpoint(.a7)
        try save(nil)
        try checkpoint(.a8)
    }

    private func rollbackEnable(_ row: E2EServerRow) async throws {
        try await clearVault(keyId: row.keyId, whileCurrent: row)
        try validateSession()
        guard try await server.delete(ifCurrent: row) else { throw Failure.stateChanged }
        try validateSession()
        try finish()
    }

    private func verifyRollbackCopy(_ marker: E2EMigrationMarker, dek: SymmetricKey) async throws {
        let encrypted = try await read(encryptedRemote(dek))
        _ = try E2EVerifier.verify(local: loadBackup(marker), remote: encrypted)
    }

    private func rollbackDisable(_ row: E2EServerRow, dek: SymmetricKey) async throws {
        guard let marker = Self.marker(in: defaults, userId: userId), marker.phase == .rollingBack else {
            throw Failure.stateChanged
        }
        try await verifyRollbackCopy(marker, dek: dek)
        let backup = try loadBackup(marker)
        if row.state == .disabling { try await setState(.active, from: row) }
        var active = row
        active.state = .active
        try await clearPlain(whileActive: active, dek: dek, coveredBy: backup)
        try save(nil)
    }

    private func finishDisable(_ marker: E2EMigrationMarker) async throws {
        guard case .absent = try await lookup(),
              let key = try keyStore.load(userId: userId), key.keyId == marker.keyId else {
            throw Failure.stateChanged
        }
        let remaining = try await read(encryptedRemote(key.dek))
        _ = try E2EVerifier.verify(local: loadBackup(marker), remote: remaining, allowingRemoteSubset: true)
        let verifiedIDs = Dictionary(uniqueKeysWithValues: SyncTable.allCases.map { table in
            (table, Set(remaining.rows(table).map(\.id)))
        })
        try await clearVault(keyId: marker.keyId, whileCurrent: nil, verifiedIDs: verifiedIDs)
        try checkpoint(.d7)
        try finish()
    }

    private func reset(_ row: E2EServerRow) async throws {
        try await clearVault(keyId: row.keyId, whileCurrent: row)
        try validateSession()
        guard try await server.delete(ifCurrent: row) else { throw Failure.stateChanged }
        try validateSession()
        try await initialSync(plain)
        try finish()
    }

    private func clearPlain(whileActive row: E2EServerRow, dek: SymmetricKey,
                            coveredBy backup: Snapshot? = nil) async throws {
        guard row.state == .active,
              let marker = Self.marker(in: defaults, userId: userId),
              marker.owns(row),
              (marker.direction == .enable && marker.phase == .verified)
                  || (marker.direction == .disable && marker.phase == .rollingBack) else { throw Failure.stateChanged }

        try await requireCurrent(row)
        let encrypted = try await read(encryptedRemote(dek))
        _ = try E2EVerifier.verify(local: encrypted, remote: encrypted)

        // Check all plaintext IDs before deleting any. The vault can change
        // after A5, including when cleanup resumes on a later launch.
        let tables: [SyncTable] = [.transactions, .budgets, .recurringRules, .goals, .accounts]
        var idsByTable: [SyncTable: Set<UUID>] = [:]
        for table in tables {
            try await requireCurrent(row)
            let ids = try await plain.fetchIds(table: table, userId: userId)
            guard ids.isSubset(of: Set(encrypted.rows(table).map(\.id))) else {
                throw Failure.verificationFailed
            }
            if let backup, !ids.isSubset(of: Set(backup.rows(table).map(\.id))) {
                throw Failure.verificationFailed
            }
            idsByTable[table] = ids
        }
        // Dependent rows first to keep cascading account deletes out of the copy window.
        for table in tables {
            let ids = idsByTable[table, default: []].sorted { $0.uuidString < $1.uuidString }
            for offset in stride(from: 0, to: ids.count, by: 100) {
                try await requireCurrent(row)
                try await plain.delete(ids: Array(ids[offset..<min(offset + 100, ids.count)]),
                                       table: table, userId: userId)
            }
        }
        try await requirePlainEmpty(whileActive: row)
    }

    private func requirePlainEmpty(whileActive row: E2EServerRow) async throws {
        for table in SyncTable.allCases {
            try await requireCurrent(row)
            guard try await plain.fetchIds(table: table, userId: userId).isEmpty else {
                throw Failure.verificationFailed
            }
        }
        try validateSession()
    }

    private func clearVault(keyId: String, whileCurrent row: E2EServerRow?,
                            verifiedIDs: [SyncTable: Set<UUID>] = [:]) async throws {
        func checkState() async throws {
            if let row {
                try await requireCurrent(row)
            } else {
                guard case .absent = try await lookup() else { throw Failure.stateChanged }
            }
        }
        for table in SyncTable.allCases {
            try await checkState()
            let current = try await vault.vaultIds(table: table, userId: userId, keyId: keyId)
            if row == nil, !current.isSubset(of: verifiedIDs[table, default: []]) {
                throw Failure.verificationFailed
            }
            let ids = current.sorted { $0.uuidString < $1.uuidString }
            for offset in stride(from: 0, to: ids.count, by: 100) {
                try await checkState()
                try await vault.deleteVault(ids: Array(ids[offset..<min(offset + 100, ids.count)]),
                                            table: table, userId: userId, keyId: keyId)
            }
            try await checkState()
            guard try await vault.vaultIds(table: table, userId: userId, keyId: keyId).isEmpty else {
                throw Failure.verificationFailed
            }
        }
        try validateSession()
    }

    private func synchronize(_ remote: any SyncRemote, deleteOrphans: Bool) async throws -> Snapshot {
        let before = try snapshot()
        try await push(remote, deleteOrphans, false)
        let remoteRows = try await read(remote)
        let current = try snapshot()
        _ = try E2EVerifier.verify(local: before, remote: current)
        try requireSubset(remoteRows, of: current)
        let uploadedKinds = deleteOrphans ? SyncTable.allCases : SyncTable.allCases.filter { $0 != .transactions }
        try requireSubset(current, of: remoteRows, tables: uploadedKinds)
        try await pull(remoteRows)
        return try snapshot()
    }

    private func requireSubset(_ subset: Snapshot, of superset: Snapshot,
                               tables: [SyncTable] = SyncTable.allCases) throws {
        for table in tables {
            guard Set(subset.rows(table).map(\.id)).isSubset(of: Set(superset.rows(table).map(\.id))) else {
                throw E2EVerifier.Failure.ids(table)
            }
        }
    }

    private func read(_ remote: any SyncRemote) async throws -> Snapshot {
        let rows = try await Snapshot(remote: remote, userId: userId)
        try validateSession()
        return rows
    }

    private func lookup() async throws -> E2EServerLookup {
        try validateSession()
        let result = try await server.lookup(userId: userId)
        try validateSession()
        if case .unavailable = result { throw Failure.unavailable }
        return result
    }

    private func requireRow(state: E2EServerState? = nil) async throws -> E2EServerRow {
        guard case .row(let row) = try await lookup(), row.userId == userId,
              row.hasSupportedParameters, state == nil || row.state == state else {
            throw Failure.stateChanged
        }
        return row
    }

    private func requireCurrent(_ expected: E2EServerRow) async throws {
        let row = try await requireRow(state: expected.state)
        guard row.keyId == expected.keyId,
              E2EServerRow.sameGeneration(row.updatedAt, expected.updatedAt) else { throw Failure.stateChanged }
    }

    private func setState(_ state: E2EServerState, from row: E2EServerRow) async throws {
        try await patch(E2EServerPatch(state: state), from: row)
    }

    private func patch(_ changes: E2EServerPatch, from row: E2EServerRow) async throws {
        try validateSession()
        guard try await server.patch(changes, ifCurrent: row) else { throw Failure.stateChanged }
        try validateSession()
    }

    private func requireKey(_ row: E2EServerRow) throws -> SymmetricKey {
        guard let entry = try keyStore.load(userId: userId), entry.keyId == row.keyId else {
            throw Failure.stateChanged
        }
        return entry.dek
    }

    private func encryptedRemote(_ dek: SymmetricKey) -> VaultRemote {
        VaultRemote(access: vault, dek: dek, owner: userId, scopeReads: true)
    }

    @discardableResult
    private func begin(_ direction: E2EMigrationDirection, keyId: String,
                       phase: E2EMigrationMarker.Phase? = nil, generation: String?) throws -> E2EMigrationMarker {
        var marker = E2EMigrationMarker(direction: direction, userId: userId, keyId: keyId,
                                        startedAt: Int64(Date().timeIntervalSince1970 * 1_000))
        marker.phase = phase
        marker.generation = generation
        try save(marker)
        return marker
    }

    private static func newGeneration(after previous: String? = nil) -> String {
        let base = max(Date(), E2EServerRow.generationDate(previous) ?? .distantPast)
        let micros = Int64((base.timeIntervalSince1970 * 1_000_000).rounded())
            + Int64.random(in: 1...999_999)
        let seconds = Date(timeIntervalSince1970: Double(micros / 1_000_000))
        let fraction = String(format: "%06lld", micros % 1_000_000)
        return seconds.ISO8601Format().dropLast() + "." + fraction + "Z"
    }

    private func save(_ marker: E2EMigrationMarker?, phase: E2EMigrationMarker.Phase? = nil) throws {
        try validateSession()
        if var marker {
            if let phase { marker.phase = phase }
            defaults.set(try JSONEncoder().encode(marker), forKey: E2EMigrationMarker.defaultsKey)
        } else {
            defaults.removeObject(forKey: E2EMigrationMarker.defaultsKey)
        }
    }

    private func finish() throws {
        try validateSession()
        try keyStore.remove(userId: userId)
        try save(nil)
    }

    private func backup(_ rows: Snapshot) throws {
        try validateSession()
        let url = backupDirectory.appending(path: "backup-\(Int64(Date().timeIntervalSince1970 * 1_000)).json")
        let files = FileManager.default
        try files.createDirectory(at: backupDirectory, withIntermediateDirectories: true,
                                  attributes: [.protectionKey: FileProtectionType.complete])
        var directory = backupDirectory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try directory.setResourceValues(values)
        try VaultJSON.encoder.encode(rows).write(to: url, options: [.atomic, .completeFileProtection])
        for old in try files.contentsOfDirectory(at: backupDirectory, includingPropertiesForKeys: nil)
            where old != url {
            try files.removeItem(at: old)
        }
        for table in SyncTable.allCases {
            let ids = rows.rows(table).map { $0.id.uuidString.lowercased() }.sorted()
            let hash = E2EVerifier.digest(Data(ids.joined(separator: "\n").utf8))
            Logger.persistence.info("E2E backup \(table.kind, privacy: .public): \(ids.count) rows, ids \(hash, privacy: .private)")
        }
    }

    private func loadBackup(_ marker: E2EMigrationMarker) throws -> Snapshot {
        let files = try FileManager.default.contentsOfDirectory(at: backupDirectory, includingPropertiesForKeys: nil)
        guard files.count == 1, let url = files.first,
              let timestamp = Int64(url.deletingPathExtension().lastPathComponent.dropFirst("backup-".count)),
              timestamp <= marker.startedAt else { throw Failure.verificationFailed }
        let data = try Data(contentsOf: url)
        return try VaultJSON.decoder.decode(Snapshot.self, from: data)
    }

    private static func validatePassphrase(_ passphrase: String) throws {
        guard passphrase.count >= 10 else { throw Failure.invalidPassphrase }
    }

    private static func derive(_ passphrase: String, salt: Data, iterations: Int) async throws -> SymmetricKey {
        try await Task.detached {
            try VaultCrypto.deriveKEK(passphrase: passphrase, salt: salt, iterations: iterations)
        }.value
    }

    private func passphraseWrap(_ passphrase: String, dek: SymmetricKey) async throws -> (String, String) {
        try Self.validatePassphrase(passphrase)
        var salt = Data(repeating: 0, count: VaultCrypto.saltByteCount)
        let status = salt.withUnsafeMutableBytes { buffer -> OSStatus in
            guard let base = buffer.baseAddress else { return errSecParam }
            return SecRandomCopyBytes(kSecRandomDefault, buffer.count, base)
        }
        guard status == errSecSuccess else { throw VaultCrypto.Failure.operationFailed }
        let kek = try await Self.derive(passphrase, salt: salt, iterations: VaultCrypto.defaultIterations)
        let wrapped = try VaultCrypto.wrap(dek, key: kek, aad: VaultCrypto.wrapAAD(.passphrase, userID: userId))
        return (VaultCrypto.encodeBase64URL(salt), wrapped)
    }

    private func updatePassphrase(_ passphrase: String, dek: SymmetricKey, row: E2EServerRow) async throws {
        let (salt, wrapped) = try await passphraseWrap(passphrase, dek: dek)
        try await patch(E2EServerPatch(kdfIterations: VaultCrypto.defaultIterations, salt: salt,
                                       wrappedKeyPassphrase: wrapped), from: row)
    }

    private func wrapRecovery(_ dek: SymmetricKey, bytes: Data) throws -> String {
        let key = try VaultCrypto.recoveryKEK(bytes)
        return try VaultCrypto.wrap(dek, key: key, aad: VaultCrypto.wrapAAD(.recovery, userID: userId))
    }
}

// Recheck ownership before individual writes in the sync engine's push.
private struct GenerationGuardedRemote: SyncRemote {
    let remote: any SyncRemote
    let check: () async throws -> Void

    func fetchIds(table: SyncTable, userId: UUID) async throws -> Set<UUID> {
        try await remote.fetchIds(table: table, userId: userId)
    }

    func select<Row: SyncRow>(table: SyncTable, userId: UUID) async throws -> [Row] {
        try await remote.select(table: table, userId: userId)
    }

    func upsert<Row: SyncRow>(_ rows: [Row], table: SyncTable, userId: UUID) async throws {
        try await check()
        try await remote.upsert(rows, table: table, userId: userId)
    }

    func delete(ids: [UUID], table: SyncTable, userId: UUID) async throws {
        try await check()
        try await remote.delete(ids: ids, table: table, userId: userId)
    }
}
