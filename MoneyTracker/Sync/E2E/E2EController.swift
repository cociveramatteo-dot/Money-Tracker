import Combine
import CryptoKit
import Foundation
import LocalAuthentication
import SwiftData
import SwiftUI

@MainActor
final class E2EController: ObservableObject {
    enum Protection: Equatable {
        case off
        case active
        case locked(E2EGate.LockReason, isEnabling: Bool)
        case pending(E2EMigrationDirection, canCancel: Bool)
    }

    enum Operation: Equatable {
        case enable, disable, unlock, changePhrase, rotateKey, cancelEnable, restart
        case resume(E2EMigrationDirection)

        var direction: E2EMigrationDirection? {
            switch self {
            case .enable: .enable
            case .disable, .restart: .disable
            case .resume(let direction): direction
            default: nil
            }
        }

        var completedProtection: Protection? {
            switch self {
            case .enable: .active
            case .disable, .cancelEnable, .restart: .off
            default: nil
            }
        }
    }

    enum Issue: Equatable {
        case incorrectSecret, concurrentActivation, offline, failed

        var text: LocalizedStringKey {
            switch self {
            case .incorrectSecret: "e2e_errata"
            case .concurrentActivation: "e2e_gia_in_corso"
            case .offline: "e2e_serve_rete"
            case .failed: "e2e_errore"
            }
        }
    }

    @Published private(set) var operation: Operation?
    @Published private(set) var progress = 0

    static let shared = E2EController(service: .shared)

    private let service: SyncService
    private let authenticateForTest: (() async throws -> Void)?
    private var observations: Set<AnyCancellable> = []
    private var promptedSession: UUID?

    init(service: SyncService, authenticateForTest: (() async throws -> Void)? = nil) {
        self.service = service
        self.authenticateForTest = authenticateForTest
        service.$e2eProtection.dropFirst().sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &observations)
        service.$isMigrating.dropFirst().sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &observations)
    }

    var sessionID: UUID { service.e2eSessionGeneration }
    var protection: Protection? { service.currentE2EProtection }
    var serverSupported: Bool { protection != nil }
    var isBusy: Bool { operation != nil || service.isMigrating }

    var lockReason: E2EGate.LockReason? {
        guard case .locked(let reason, _) = protection else { return nil }
        return reason
    }

    var canCancelEnable: Bool { protection == .pending(.enable, canCancel: true) }
    var anotherDeviceIsEnabling: Bool { protection == .locked(.transition, isEnabling: true) }

    func takeUnlockPrompt() -> Bool {
        let session = sessionID
        guard lockReason != nil, promptedSession != session else { return false }
        promptedSession = session
        return true
    }

    func run<Value>(_ operation: Operation, context: ModelContext,
                    action: (E2EMigrator) async throws -> Value) async throws -> Value {
        guard !isBusy else { throw E2EMigrator.Failure.stateChanged }
        progress = 0
        self.operation = operation
        defer { self.operation = nil }
        return try await service.withE2EMigrator(
            context: context,
            authenticationReason: String(localized: "e2e_motivo_biometria"),
            checkpoint: { [weak self] step in
                guard let index = E2EMigrator.Step.allCases.firstIndex(of: step) else { return }
                let start = operation.direction == .disable ? 9 : 0
                let number = index - start + 1
                if let self, number > self.progress { self.progress = number }
            },
            authenticateForTest: authenticateForTest,
            protectionOperation: operation,
            action: action
        )
    }

    static func issue(for error: any Error, checkingSecret: Bool = false) -> Issue? {
        if error is CancellationError { return nil }
        if let authentication = error as? LAError,
           [.userCancel, .systemCancel, .appCancel, .userFallback].contains(authentication.code) {
            return nil
        }
        if let network = error as? URLError,
           [.notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotFindHost,
            .cannotConnectToHost, .dataNotAllowed].contains(network.code) { return .offline }
        if (error as? E2EMigrator.Failure) == .concurrentActivation { return .concurrentActivation }
        if checkingSecret, (error as? VaultCrypto.Failure) == .authenticationFailed
            || (error as? VaultCrypto.Failure) == .malformed
            || (error as? CryptoKitError) == .authenticationFailure { return .incorrectSecret }
        return .failed
    }
}

extension E2EMigrator {
    /// A marker written before the server transition can be cleared before retrying.
    /// A fresh recovery-key screen must never finish a migration using an older key.
    func resumeForProtectionUI(_ direction: E2EMigrationDirection,
                               allowCommitted: Bool = true) async throws -> Bool {
        guard let marker = Self.marker(in: defaults, userId: userId) else { return false }
        guard marker.direction == direction else { throw Failure.stateChanged }
        try validateSession()
        let response = try await server.lookup(userId: userId)
        try validateSession()
        switch response {
        case .unavailable:
            throw Failure.unavailable
        case .absent:
            try await resume(marker, row: nil)
            return direction == .disable
        case .row(let row):
            guard allowCommitted, row.userId == userId, row.hasSupportedParameters,
                  row.keyId == marker.keyId else {
                throw Failure.stateChanged
            }
            try await resume(marker, row: row)
            if marker.phase == .rollingBack { throw Failure.verificationFailed }
            return !(row.state == .active && direction == .disable && marker.phase == nil)
        }
    }
}
