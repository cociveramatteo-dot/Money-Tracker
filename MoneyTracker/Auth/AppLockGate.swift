import SwiftUI
import Combine

// MARK: - AppLockState

/// Stato del blocco applicativo (Face ID / Touch ID / passcode). Non sostituisce il
/// login Supabase: si applica DOPO — protegge i dati finanziari già caricati quando
/// l'app torna in foreground o al cold start, così un dispositivo sbloccato ma
/// "prestato" non espone conti/transazioni senza un secondo fattore locale.
@MainActor
final class AppLockState: ObservableObject {
    @Published private(set) var isLocked: Bool

    private let authenticator: BiometricAuthenticating
    private static let enabledKey = "appLockEnabled"

    init(authenticator: BiometricAuthenticating = LAContextAuthenticator()) {
        self.authenticator = authenticator
        let enabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
        self.isLocked = enabled && authenticator.isAvailable
    }

    /// Richiamato quando l'app va in background: blocca solo se l'utente ha attivato
    /// l'opzione nelle Impostazioni e il dispositivo supporta un metodo di sblocco locale.
    func lock() {
        guard UserDefaults.standard.bool(forKey: Self.enabledKey), authenticator.isAvailable else { return }
        isLocked = true
    }

    /// Richiamato al cold start e al ritorno in foreground. No-op se non è bloccato.
    func unlockIfNeeded() async {
        guard isLocked else { return }
        if await authenticator.authenticate() {
            isLocked = false
        }
    }
}

// MARK: - AppLockGate (view modifier)

struct AppLockGate: ViewModifier {
    @StateObject private var lockState: AppLockState
    @Environment(\.scenePhase) private var scenePhase

    init(authenticator: BiometricAuthenticating = LAContextAuthenticator()) {
        _lockState = StateObject(wrappedValue: AppLockState(authenticator: authenticator))
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                if lockState.isLocked {
                    LockOverlay { Task { await lockState.unlockIfNeeded() } }
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: lockState.isLocked)
            .task { await lockState.unlockIfNeeded() }
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .background: lockState.lock()
                case .active:      Task { await lockState.unlockIfNeeded() }
                default:           break
                }
            }
    }
}

private struct LockOverlay: View {
    let onUnlock: () -> Void

    var body: some View {
        ZStack {
            DS.paper.ignoresSafeArea()
            VStack(spacing: DS.Space.l) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(DS.ink)
                Text("MoneyTracker è bloccato")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(DS.ink)
                Button(action: onUnlock) {
                    Text("Sblocca")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(minWidth: 160, minHeight: DS.Layout.buttonHeight)
                }
                .buttonStyle(.borderedProminent)
                .tint(DS.ink)
            }
        }
    }
}

extension View {
    /// Applica il gate di blocco biometrico. Va applicato solo al contenuto autenticato
    /// (dopo il login), non alla schermata di login stessa.
    func appLockGate() -> some View {
        modifier(AppLockGate())
    }
}
