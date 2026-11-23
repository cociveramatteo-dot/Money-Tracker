package com.bucktrail.android.sync

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/** Dove vive la sessione (Android: Keystore, `KeystoreSessionStore`; nei test: memoria). */
interface SessionStore {
    fun load(): Session?
    fun save(session: Session?)
}

class NotSignedInException : Exception("not signed in")

/** Esito della registrazione: sessione aperta, oppure account creato in attesa di conferma via email. */
enum class SignUpResult { SignedIn, ConfirmationNeeded }

/**
 * `SupabaseManager` iOS: sessione osservabile, `isLoading` finché non è letta, accesso/registrazione/uscita/reset/eliminazione.
 * I token si rinnovano da soli; se il rinnovo viene rifiutato la sessione si chiude SENZA toccare i dati locali (come iOS).
 */
class AuthManager(
    private val api: SupabaseApi, private val store: SessionStore,
    private val nowSeconds: () -> Long = { System.currentTimeMillis() / 1000 },
) : SyncEngine.AuthGateway {
    private val _session = MutableStateFlow<Session?>(null)
    val session: StateFlow<Session?> = _session.asStateFlow()
    private val _isLoading = MutableStateFlow(true)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()
    private val lock = Mutex()

    val isLoggedIn: Boolean get() = _session.value != null
    override val userId: String? get() = _session.value?.userId
    val email: String? get() = _session.value?.email

    /** Carica la sessione salvata (nessuna rete). */
    fun bootstrap() {
        _session.value = runCatching { store.load() }.getOrNull()
        _isLoading.value = false
    }

    private fun set(s: Session?) { _session.value = s; runCatching { store.save(s) } }

    suspend fun signIn(email: String, password: String) { set(api.signIn(email, password)) }

    suspend fun signUp(email: String, password: String): SignUpResult {
        val s = api.signUp(email, password)
        return if (s != null) { set(s); SignUpResult.SignedIn } else SignUpResult.ConfirmationNeeded
    }

    suspend fun resetPassword(email: String) = api.recover(email)

    /** Esce: chiama il server se può, ma la sessione locale si chiude comunque. */
    suspend fun signOut() {
        val s = _session.value
        set(null)
        if (s != null) runCatching { api.signOut(s.accessToken) }
    }

    /** Diritto all'oblio: RPC lato database che agisce sull'utente della sessione. */
    suspend fun deleteAccount() { authed { api.rpc("delete_own_account", it) } }

    private suspend fun validToken(forceRefresh: Boolean = false): String = lock.withLock {
        val s = _session.value ?: throw NotSignedInException()
        if (!forceRefresh && !s.isExpiring(nowSeconds())) return s.accessToken
        try {
            val fresh = api.refresh(s.refreshToken)
            set(fresh)
            fresh.accessToken
        } catch (e: ApiException) {
            // rifiuto esplicito = sessione scaduta: si esce senza cancellare i dati. Errori di rete/server: si tiene la sessione.
            if (e.kind == ErrorKind.Unauthorized || e.kind == ErrorKind.Client) set(null)
            throw e
        }
    }

    /** Esegue `block` con un token valido; su 401 rinnova una volta e riprova. */
    override suspend fun <T> authed(block: suspend (token: String) -> T): T {
        val token = validToken()
        return try {
            block(token)
        } catch (e: ApiException) {
            if (e.kind != ErrorKind.Unauthorized) throw e
            block(validToken(forceRefresh = true))
        }
    }
}

/** Messaggio da mostrare per un errore di accesso/registrazione. La mappatura è sul testo in minuscolo (substring), come iOS. */
sealed interface AuthMessage {
    data object InvalidCredentials : AuthMessage
    data object EmailNotConfirmed : AuthMessage
    data object RateLimit : AuthMessage
    data object Offline : AuthMessage
    data object AlreadyExists : AuthMessage
    data object PasswordTooShort : AuthMessage
    data object InvalidEmail : AuthMessage
    data class Generic(val detail: String) : AuthMessage
}

object AuthErrors {
    private fun raw(e: Throwable) = if (e is ApiException && e.kind == ErrorKind.Network) "network" else (e.message ?: e.toString())

    fun login(e: Throwable): AuthMessage {
        val r = raw(e).lowercase()
        return when {
            r.contains("invalid login") || r.contains("invalid credentials") || r.contains("invalid email or password") -> AuthMessage.InvalidCredentials
            r.contains("email not confirmed") -> AuthMessage.EmailNotConfirmed
            r.contains("rate limit") || r.contains("too many") -> AuthMessage.RateLimit
            r.contains("network") || r.contains("connection") -> AuthMessage.Offline
            else -> AuthMessage.Generic(raw(e))
        }
    }

    fun signUp(e: Throwable): AuthMessage {
        val r = raw(e).lowercase()
        return when {
            r.contains("already registered") || r.contains("already exists") || r.contains("user already") -> AuthMessage.AlreadyExists
            r.contains("password") && r.contains("6") -> AuthMessage.PasswordTooShort
            r.contains("invalid email") -> AuthMessage.InvalidEmail
            r.contains("rate limit") || r.contains("too many") -> AuthMessage.RateLimit
            r.contains("network") || r.contains("connection") -> AuthMessage.Offline
            else -> AuthMessage.Generic(raw(e))
        }
    }
}
