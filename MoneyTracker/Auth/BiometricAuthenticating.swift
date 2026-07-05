import Foundation
import LocalAuthentication

/// Contratto per l'autenticazione locale (Face ID / Touch ID / passcode del dispositivo).
/// Estratto in protocollo così `AppLockGate` è testabile iniettando un finto che simula
/// successo/fallimento, senza dover guidare realmente Face ID/Touch ID in un test.
@MainActor
protocol BiometricAuthenticating {
    /// true se il dispositivo ha una qualche forma di autenticazione locale configurata
    /// (Face ID, Touch ID, o almeno un passcode).
    var isAvailable: Bool { get }

    /// Richiede l'autenticazione all'utente. Ritorna `true` solo se l'utente si è
    /// autenticato con successo; `false` per fallimento o annullamento.
    func authenticate() async -> Bool
}

/// Implementazione di produzione basata su `LAContext`.
struct LAContextAuthenticator: BiometricAuthenticating {

    var isAvailable: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    func authenticate() async -> Bool {
        let context = LAContext()
        // .deviceOwnerAuthentication (non solo biometrics): fa fallback automatico al
        // passcode del dispositivo se Face ID/Touch ID non è disponibile o fallisce
        // troppe volte — evita di bloccare fuori l'utente senza via d'uscita.
        let reason = String(localized: "Sblocca MoneyTracker per vedere i tuoi dati finanziari")
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch {
            return false
        }
    }
}
