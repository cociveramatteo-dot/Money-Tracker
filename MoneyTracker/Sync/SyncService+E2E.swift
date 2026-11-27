import Foundation
import OSLog
import Supabase
import SwiftData

extension SyncService {
    // MARK: - E2E operations

    enum E2EOperation {
        case push, foreground, refresh, login, pull
    }

    var currentE2EProtection: E2EController.Protection? {
        e2eProtectionUser == userId ? e2eProtection : nil
    }

    /// Publishes only real changes: every sync resolves the gate again.
    private func setE2EServerSupported(_ value: Bool?) {
        if e2eServerSupported != value { e2eServerSupported = value }
    }

    private func setE2ELockReason(_ value: E2EGate.LockReason?) {
        if e2eLockReason != value { e2eLockReason = value }
    }

    func clearE2ESession(userId: UUID?) {
        e2eSessionGeneration = UUID()
        e2eTask?.work.cancel()
        e2eTask = nil
        debounceTask?.cancel()
        retryTask?.cancel()
        e2eRetryOperation = nil
        lastContext = nil
        hasPendingChanges = false
        dirtyTransactionIds = []
        consecutiveFailures = 0
        status = .idle
        e2eLockReason = nil
        e2eServerSupported = nil
        e2eProtectionUser = nil
        e2eProtection = nil
        e2eMigrationToResume = nil
        defaults.removeObject(forKey: E2EMigrationMarker.defaultsKey)
        defaults.removeObject(forKey: initialSyncKey)
        do {
            try FileManager.default.removeItem(at: e2eBackupDirectory)
        } catch let error as CocoaError where error.code == .fileNoSuchFile {
            // No migration backup on this device.
        } catch {
            Logger.persistence.error("SyncService: E2E backup removal failed")
        }
        if let userId { removeE2EKey(userId: userId) }
    }

    func removeE2EKey(userId: UUID) {
        do { try e2eKeyStore.remove(userId: userId) }
        catch { Logger.persistence.error("SyncService: E2E key removal failed") }
    }

    private func prepareE2ELogin(userId: UUID, context: ModelContext) -> Bool {
        let previousUser = lastSyncedUser
        guard previousUser != userId else { return true }
        clearE2ESession(userId: previousUser)
        guard clearLocalStore(context: context) else { return false }
        // A failed deletion must never allow the old store to be uploaded
        // under new credentials.
        do {
            guard try context.fetchCount(FetchDescriptor<Account>()) == 0,
                  try context.fetchCount(FetchDescriptor<Transaction>()) == 0,
                  try context.fetchCount(FetchDescriptor<Budget>()) == 0,
                  try context.fetchCount(FetchDescriptor<Goal>()) == 0,
                  try context.fetchCount(FetchDescriptor<RecurringRule>()) == 0 else {
                Logger.persistence.error("SyncService: E2E login stopped because local data remains")
                return false
            }
        } catch {
            Logger.persistence.error("SyncService: E2E login could not verify the local store")
            return false
        }
        defaults.set(userId.uuidString, forKey: Self.lastUserKey)
        return true
    }

    @discardableResult
    func runE2ESync(_ operation: E2EOperation, context: ModelContext) async -> Bool {
        guard !closingAccount, !isMigrating, !isUsingVolatileStore, !defaults.bool(forKey: Self.demoModeKey),
              let userId else { return false }
        if operation == .login, !prepareE2ELogin(userId: userId, context: context) { return false }
        guard lastSyncedUser == userId else { return false }

        let generation = e2eSessionGeneration
        let previous = e2eTask?.work
        let id = UUID()
        let work = Task { @MainActor in
            _ = await previous?.value
            return await performE2ESync(operation, context: context, userId: userId, generation: generation)
        }
        e2eTask = (id, work)
        let success = await work.value
        if e2eTask?.id == id { e2eTask = nil }
        return success
    }

    /// Throws when the signed-in user or the E2E session changed since `generation`.
    private func sessionValidator(userId: UUID, generation: UUID) -> () throws -> Void {
        {
            guard self.userId == userId, self.e2eSessionGeneration == generation else { throw CancellationError() }
            try Task.checkCancellation()
        }
    }

    /// The live Supabase session must still belong to `userId` (skipped with an injected transport).
    private func requireLiveSession(userId: UUID) async throws {
        guard injectedRemote == nil else { return }
        let session = try await auth.client.auth.session
        guard session.user.id == userId else { throw CancellationError() }
    }

    private func performE2ESync(_ operation: E2EOperation, context: ModelContext,
                                userId: UUID, generation: UUID) async -> Bool {
        let validateSession = sessionValidator(userId: userId, generation: generation)
        guard (try? validateSession()) != nil else { return false }
        guard let backend = e2eBackend else { return false }
        let (server, vault) = backend

        retryTask?.cancel()
        e2eRetryOperation = nil
        lastContext = context
        status = .syncing
        let gate = E2EGate(server: server, keyStore: e2eKeyStore)
        let marker = E2EMigrator.marker(in: defaults, userId: userId)
        var retryOperation = operation
        if operation == .login { defaults.set(userId.uuidString, forKey: initialSyncKey) }

        do {
            try await requireLiveSession(userId: userId)
            try validateSession()
            let resolution = try await gate.resolve(userId: userId, enabled: e2eEnabled,
                                                     marker: marker, validateSession: validateSession)
            try validateSession()
            applyGateEffects(resolution, marker: marker, userId: userId)
            if try await resumeE2E(resolution, marker: marker, context: context, userId: userId,
                                   backend: backend, validateSession: validateSession) { return true }

            guard let selectedRemote = e2eRemote(for: resolution, plain: remote, vault: vault, userId: userId)
            else { return pauseE2ESync() }
            var initialSync = defaults.string(forKey: initialSyncKey) == userId.uuidString
            var didPush = false

            do {
                if initialSync {
                    didPush = try await initialE2ESync(context: context, remote: selectedRemote,
                                                     userId: userId, validateSession: validateSession)
                } else if operation != .pull {
                    try await upload(context: context, remote: selectedRemote, userId: userId,
                                     validateSession: validateSession)
                    didPush = true
                }
            } catch where E2EServer.blockedPlainWrite(error) {
                try validateSession()
                let refreshed = try await gate.resolve(userId: userId, enabled: e2eEnabled,
                                                        marker: marker, validateSession: validateSession)
                try validateSession()
                applyGateEffects(refreshed, marker: marker, userId: userId)
                if try await resumeE2E(refreshed, marker: marker, context: context, userId: userId,
                                       backend: backend, validateSession: validateSession) { return true }
                guard let refreshedRemote = e2eRemote(for: refreshed, plain: remote, vault: vault, userId: userId)
                else { return pauseE2ESync() }
                guard case .vault = refreshed.mode else { throw error }
                defaults.set(userId.uuidString, forKey: initialSyncKey)
                initialSync = true
                didPush = try await initialE2ESync(context: context, remote: refreshedRemote,
                                                 userId: userId, validateSession: validateSession)
            }

            try validateSession()
            if didPush { hasPendingChanges = !dirtyTransactionIds.isEmpty }
            if initialSync {
                defaults.removeObject(forKey: initialSyncKey)
            } else if operation == .pull || operation == .refresh || (operation == .foreground && shouldPull) {
                retryOperation = .pull
                try await downloadE2E(context: context, remote: selectedRemote, userId: userId,
                                      validateSession: validateSession)
            }
            try validateSession()
            consecutiveFailures = 0
            status = .idle
            if initialSync, !didPush, !dirtyTransactionIds.isEmpty {
                schedulePush(context: context)
            }
            return didPush || operation != .push
        } catch is CancellationError {
            return false
        } catch E2EMigrator.Failure.verificationFailed {
            return pauseE2ESync()
        } catch {
            guard (try? validateSession()) != nil else { return false }
            if E2EServer.operationStateChanged(error) {
                let refreshed = await refreshE2EProtection(server: server, userId: userId, validateSession: validateSession)
                guard (try? validateSession()) != nil else { return false }
                if let refreshed {
                    if e2eRemote(for: refreshed, plain: remote, vault: vault, userId: userId) == nil {
                        return pauseE2ESync()
                    }
                }
            }
            Logger.persistence.error("SyncService: E2E sync operation failed")
            hasPendingChanges = true
            consecutiveFailures += 1
            scheduleRetry(context: context, e2eOperation: retryOperation)
            return false
        }
    }

    private typealias E2EBackend = (any E2EServerAccess, any VaultAccess)

    private var e2eBackend: E2EBackend? {
        if let injectedRemote {
            guard let backend = injectedRemote as? (any E2EServerAccess & VaultAccess) else { return nil }
            return (backend, backend)
        }
        return (E2EServer(client: auth.client), SupabaseVaultAccess(client: auth.client))
    }

    // Settings actions and automatic resume share the same service and transport.
    // UI supplies the localized device-authentication reason (K48).
    func withE2EMigrator<T>(context: ModelContext, authenticationReason: String,
                           checkpoint: @escaping (E2EMigrator.Step) throws -> Void = { _ in },
                           authenticateForTest: (() async throws -> Void)? = nil,
                           protectionOperation: E2EController.Operation? = nil,
                           action: (E2EMigrator) async throws -> T) async throws -> T {
        guard e2eEnabled, !closingAccount, !isMigrating, !isUsingVolatileStore,
              !defaults.bool(forKey: Self.demoModeKey), let userId, let backend = e2eBackend,
              lastSyncedUser == userId else {
            throw E2EMigrator.Failure.unavailable
        }
        let generation = e2eSessionGeneration
        let validateSession = sessionValidator(userId: userId, generation: generation)
        while let previous = e2eTask {
            _ = await previous.work.value
            if e2eTask?.id == previous.id { e2eTask = nil }
            try validateSession()
        }
        guard !closingAccount, !isMigrating else { throw E2EMigrator.Failure.stateChanged }
        isMigrating = true
        status = .syncing
        retryTask?.cancel()
        e2eRetryOperation = nil
        defer {
            isMigrating = false
            if e2eSessionGeneration == generation { status = .idle }
        }
        try await requireLiveSession(userId: userId)
        try validateSession()
        #if DEBUG
        let authenticate = authenticateForTest ?? { try await E2EMigrator.authenticateDevice(reason: authenticationReason) }
        #else
        let authenticate = { try await E2EMigrator.authenticateDevice(reason: authenticationReason) }
        #endif
        let migrator = makeMigrator(context: context, userId: userId, backend: backend,
                                    validateSession: validateSession, checkpoint: checkpoint, authenticate: authenticate)
        let result: Result<T, any Error>
        do { result = .success(try await action(migrator)) }
        catch where E2EServer.operationStateChanged(error) { result = .failure(E2EMigrator.Failure.stateChanged) }
        catch { result = .failure(error) }
        try validateSession()
        if let operation = protectionOperation {
            if case .success = result, let protection = operation.completedProtection {
                e2eServerSupported = true
                publishE2EProtection(protection, userId: userId)
            } else if operation != .rotateKey && operation != .changePhrase {
                await refreshE2EProtection(server: backend.0, userId: userId, validateSession: validateSession)
                try validateSession()
            }
        }
        let value = try result.get()
        e2eLockReason = nil
        if hasPendingChanges { schedulePush(context: context) }
        return value
    }

    private func makeMigrator(context: ModelContext, userId: UUID, backend: E2EBackend,
                              validateSession: @escaping () throws -> Void,
                              checkpoint: @escaping (E2EMigrator.Step) throws -> Void = { _ in },
                              authenticate: @escaping () async throws -> Void = {
                                  throw E2EMigrator.Failure.authenticationRequired
                              }) -> E2EMigrator {
        let plain: any SyncRemote = injectedRemote ?? PlainRemote(client: auth.client, forMigration: true)
        return E2EMigrator(userId: userId, defaults: defaults, keyStore: e2eKeyStore,
                           server: backend.0, vault: backend.1, plain: plain,
                           backupDirectory: e2eBackupDirectory, checkpoint: checkpoint,
                           validateSession: validateSession, authenticate: authenticate,
                           snapshot: { try PullRows(context: context, userId: userId) },
                           push: { remote, mode in
                               self.hasPendingChanges = true
                               try await self.upload(context: context, remote: remote, userId: userId,
                                                     validateSession: validateSession, mode: mode)
                           }, pull: { rows, reconcile in
                               try validateSession()
                               let saved = try await self.download(context: context, remote: plain, userId: userId,
                                                                   snapshot: rows, forMigration: true,
                                                                   reconcileMigration: reconcile)
                               if reconcile && !saved { throw E2EMigrator.Failure.verificationFailed }
                           }, initialSync: { remote in
                               self.defaults.set(userId.uuidString, forKey: self.initialSyncKey)
                               let pushed = try await self.initialE2ESync(context: context, remote: remote,
                                                                         userId: userId, validateSession: validateSession,
                                                                         uploadMode: .migrationCopy(pruningOrphans: false))
                               try validateSession()
                               if pushed { self.hasPendingChanges = !self.dirtyTransactionIds.isEmpty }
                               self.defaults.removeObject(forKey: self.initialSyncKey)
                           })
    }

    private func resumeE2E(_ resolution: E2EGate.Resolution, marker: E2EMigrationMarker?,
                           context: ModelContext, userId: UUID, backend: E2EBackend,
                           validateSession: @escaping () throws -> Void) async throws -> Bool {
        guard let marker else { return false }
        if let row = resolution.row, !marker.owns(row) {
            defaults.removeObject(forKey: E2EMigrationMarker.defaultsKey)
            return false
        }
        switch resolution.mode {
        case .resume(let direction):
            e2eMigrationToResume = direction
        case .plain where resolution.serverSupported == true && marker.direction == .enable:
            // A2 without A3, or rollback completed on the server.
            defaults.removeObject(forKey: E2EMigrationMarker.defaultsKey)
            return false
        case .vault where marker.direction == .disable && marker.phase == nil:
            // D2 without D3.
            defaults.removeObject(forKey: E2EMigrationMarker.defaultsKey)
            return false
        default:
            return false
        }
        isMigrating = true
        defer { isMigrating = false }
        setE2EServerSupported(resolution.serverSupported)
        publishE2EProtection(resolution, userId: userId)
        let migrator = makeMigrator(context: context, userId: userId, backend: backend,
                                    validateSession: validateSession)
        do {
            try await migrator.resume(marker, row: resolution.row)
        } catch {
            await refreshE2EProtection(server: backend.0, userId: userId, validateSession: validateSession)
            throw error
        }
        try validateSession()
        await refreshE2EProtection(server: backend.0, userId: userId, validateSession: validateSession)
        try validateSession()
        setE2ELockReason(nil)
        e2eMigrationToResume = nil
        // This operation completed the first exchange itself. Keep edits made
        // during migration queued for the next push in the destination mode.
        defaults.removeObject(forKey: initialSyncKey)
        consecutiveFailures = 0
        status = .idle
        if hasPendingChanges { schedulePush(context: context) }
        return true
    }

    private func e2eRemote(for resolution: E2EGate.Resolution, plain: any SyncRemote,
                           vault: any VaultAccess, userId: UUID) -> (any SyncRemote)? {
        setE2EServerSupported(resolution.serverSupported)
        publishE2EProtection(resolution, userId: userId)
        let lock: E2EGate.LockReason? = if case .locked(let reason) = resolution.mode { reason } else { nil }
        setE2ELockReason(lock)
        e2eMigrationToResume = nil
        switch resolution.mode {
        case .plain: return plain
        case .vault(let dek): return VaultRemote(access: vault, dek: dek, owner: userId, scopeReads: true)
        case .locked: break
        case .resume(let direction): e2eMigrationToResume = direction
        }
        return nil
    }

    @discardableResult
    private func refreshE2EProtection(server: any E2EServerAccess, userId: UUID,
                                      validateSession: () throws -> Void) async -> E2EGate.Resolution? {
        let gate = E2EGate(server: server, keyStore: e2eKeyStore)
        let marker = E2EMigrator.marker(in: defaults, userId: userId)
        guard (try? validateSession()) != nil,
              let resolution = try? await gate.resolve(userId: userId, enabled: e2eEnabled,
                                                       marker: marker, validateSession: validateSession),
              (try? validateSession()) != nil else { return nil }
        applyGateEffects(resolution, marker: marker, userId: userId)
        setE2EServerSupported(resolution.serverSupported)
        publishE2EProtection(resolution, userId: userId)
        return resolution
    }

    /// Local side effects of a gate decision without a server row. The first
    /// plain exchange pulls before pushing and never deletes remote rows; a
    /// disable marker that led to plain or `protectionRemoved` is finished.
    private func applyGateEffects(_ resolution: E2EGate.Resolution, marker: E2EMigrationMarker?, userId: UUID) {
        if resolution.needsPlainInitialSync { defaults.set(userId.uuidString, forKey: initialSyncKey) }
        guard resolution.row == nil, let marker, marker.direction == .disable else { return }
        switch resolution.mode {
        case .plain, .locked(.protectionRemoved):
            defaults.removeObject(forKey: E2EMigrationMarker.defaultsKey)
        default:
            break
        }
    }

    /// The user confirmed that protection was turned off on purpose (`protectionRemoved`):
    /// forget the DEK and sync again in plain, pulling before any push.
    @discardableResult
    func continueWithoutE2EProtection(context: ModelContext) async -> Bool {
        guard e2eEnabled, e2eLockReason == .protectionRemoved, !closingAccount, !isMigrating,
              let userId, lastSyncedUser == userId else { return false }
        // Pull-before-push is armed first: even if the app stops right after the
        // key removal, the next plain exchange never deletes remote rows.
        defaults.set(userId.uuidString, forKey: initialSyncKey)
        do { try e2eKeyStore.remove(userId: userId) }
        catch {
            Logger.persistence.error("SyncService: E2E key removal failed")
            return false
        }
        return await runE2ESync(.refresh, context: context)
    }

    private func publishE2EProtection(_ resolution: E2EGate.Resolution, userId: UUID) {
        let protection: E2EController.Protection? = if resolution.serverSupported != true {
            nil
        } else {
            switch resolution.mode {
            case .plain: .off
            case .vault: .active
            case .locked(let reason): .locked(reason, isEnabling: resolution.row?.state == .migrating)
            case .resume(let direction): .pending(direction, canCancel: resolution.row?.state == .migrating)
            }
        }
        publishE2EProtection(protection, userId: userId)
    }

    private func publishE2EProtection(_ protection: E2EController.Protection?, userId: UUID) {
        e2eProtectionUser = userId
        if e2eProtection != protection { e2eProtection = protection }
    }

    private func pauseE2ESync() -> Bool {
        consecutiveFailures = 0
        hasPendingChanges = true
        status = .idle
        return false
    }

    private func downloadE2E(context: ModelContext, remote: any SyncRemote, userId: UUID,
                             validateSession: () throws -> Void) async throws {
        // Finish all reads before touching SwiftData: a bad vault row or a
        // stale session must not look like a remote deletion.
        let snapshot = try await PullRows(remote: remote, userId: userId)
        guard let encrypted = remote as? VaultRemote, let (server, vault) = e2eBackend else {
            try validateSession()
            try await download(context: context, remote: remote, userId: userId, snapshot: snapshot)
            return
        }
        let keyId = try VaultCrypto.keyId(dek: encrypted.dek)
        func requireActiveKey() async throws {
            try validateSession()
            guard try await server.hasActiveVaultKey(userId: userId, keyId: keyId) else {
                throw VaultRemote.Failure.wrongKey
            }
            try validateSession()
        }
        // With scoped reads a replacement mid-pull can otherwise look like missing rows.
        try await requireActiveKey()
        if try await download(context: context, remote: remote, userId: userId, snapshot: snapshot) {
            try await vault.retryDeadVaultCleanup(userId: userId, liveKey: keyId,
                                                 validateSession: validateSession, requireCurrent: requireActiveKey)
        }
    }

    private func initialE2ESync(context: ModelContext, remote: any SyncRemote, userId: UUID,
                                validateSession: () throws -> Void,
                                uploadMode: UploadMode = .incremental) async throws -> Bool {
        for table in SyncTable.allCases {
            let ids = try await remote.fetchIds(table: table, userId: userId)
            try validateSession()
            if !ids.isEmpty {
                try await downloadE2E(context: context, remote: remote, userId: userId,
                                      validateSession: validateSession)
                return false
            }
        }
        try await upload(context: context, remote: remote, userId: userId,
                         validateSession: validateSession, mode: uploadMode)
        return true
    }
}
