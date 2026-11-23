package com.bucktrail.android.sync

import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class AuthManagerTest {
    private class MemorySessionStore(var session: Session? = null) : SessionStore {
        override fun load() = session
        override fun save(session: Session?) { this.session = session }
    }

    private class ScriptedApi : SupabaseApi {
        var now = 1_000L
        var signInResult: () -> Session = { throw ApiException(ErrorKind.Client, 400, "Invalid login credentials") }
        var signUpResult: () -> Session? = { null }
        var refreshResult: (String) -> Session = { throw ApiException(ErrorKind.Network, 0, "down") }
        var signOutFails = false
        val log = mutableListOf<String>()
        override suspend fun signIn(email: String, password: String) = signInResult().also { log += "signIn" }
        override suspend fun signUp(email: String, password: String) = signUpResult().also { log += "signUp" }
        override suspend fun refresh(refreshToken: String) = refreshResult(refreshToken).also { log += "refresh:$refreshToken" }
        override suspend fun signOut(accessToken: String) { log += "signOut"; if (signOutFails) throw ApiException(ErrorKind.Network, 0, "down") }
        override suspend fun recover(email: String) { log += "recover" }
        override suspend fun selectAll(table: String, userId: String, token: String, columns: String) = emptyList<kotlinx.serialization.json.JsonObject>()
        override suspend fun upsert(table: String, rows: List<kotlinx.serialization.json.JsonObject>, token: String) = Unit
        override suspend fun deleteIn(table: String, ids: List<String>, userId: String, token: String) = Unit
        override suspend fun rpc(function: String, token: String) { log += "rpc:$function:$token" }
    }

    private fun session(access: String = "AT", refresh: String = "RT", expiresAt: Long = 10_000) = Session(access, refresh, expiresAt, USER, "a@b.it")
    private val api = ScriptedApi()

    @Test fun bootstrapRestoresTheStoredSessionWithoutTheNetwork() {
        val store = MemorySessionStore(session())
        val auth = AuthManager(api, store) { 1_000 }
        assertTrue(auth.isLoading.value); auth.bootstrap()
        assertFalse(auth.isLoading.value); assertEquals("a@b.it", auth.email); assertTrue(api.log.isEmpty())
    }

    @Test fun signInStoresTheSessionAndWrongPasswordKeepsItEmpty() = runBlocking {
        val store = MemorySessionStore(); val auth = AuthManager(api, store) { 1_000 }; auth.bootstrap()
        try { auth.signIn("a@b.it", "bad") } catch (e: ApiException) { assertEquals(AuthMessage.InvalidCredentials, AuthErrors.login(e)) }
        assertNull(auth.session.value); assertNull(store.session)
        api.signInResult = { session() }
        auth.signIn("a@b.it", "ok")
        assertEquals(USER, auth.userId); assertEquals("AT", store.session!!.accessToken)
    }

    @Test fun signUpWithConfirmationLeavesNoSession() = runBlocking {
        val auth = AuthManager(api, MemorySessionStore()) { 1_000 }; auth.bootstrap()
        assertEquals(SignUpResult.ConfirmationNeeded, auth.signUp("a@b.it", "secret1")); assertFalse(auth.isLoggedIn)
        api.signUpResult = { session() }
        assertEquals(SignUpResult.SignedIn, auth.signUp("a@b.it", "secret1")); assertTrue(auth.isLoggedIn)
    }

    @Test fun anExpiringTokenIsRefreshedBeforeUse() = runBlocking {
        val store = MemorySessionStore(session(expiresAt = 1_030)) // scade tra 30 s: sotto il margine di 60 s
        api.refreshResult = { session("NEW", "RT2", 9_999) }
        val auth = AuthManager(api, store) { 1_000 }; auth.bootstrap()
        assertEquals("NEW", auth.authed { it })
        assertEquals("RT2", store.session!!.refreshToken)
    }

    @Test fun aValidTokenIsNotRefreshed() = runBlocking {
        val auth = AuthManager(api, MemorySessionStore(session(expiresAt = 9_000))) { 1_000 }; auth.bootstrap()
        assertEquals("AT", auth.authed { it }); assertTrue(api.log.isEmpty())
    }

    @Test fun a401RetriesOnceWithAFreshToken() = runBlocking {
        api.refreshResult = { session("NEW", "RT2", 9_999) }
        val auth = AuthManager(api, MemorySessionStore(session(expiresAt = 9_000))) { 1_000 }; auth.bootstrap()
        var attempts = 0
        val result = auth.authed { token -> attempts++; if (token == "AT") throw ApiException(ErrorKind.Unauthorized, 401, "JWT expired") else token }
        assertEquals("NEW", result); assertEquals(2, attempts)
    }

    @Test fun rejectedRefreshClosesTheSessionButNeverTouchesData() = runBlocking {
        val store = MemorySessionStore(session(expiresAt = 500))
        api.refreshResult = { throw ApiException(ErrorKind.Client, 400, "Invalid Refresh Token: Already Used") }
        val auth = AuthManager(api, store) { 1_000 }; auth.bootstrap()
        try { auth.authed { it }; org.junit.Assert.fail() } catch (e: ApiException) { /* atteso */ }
        assertNull(auth.session.value); assertNull(store.session)
    }

    @Test fun refreshFailingForNetworkKeepsTheSession() = runBlocking {
        val store = MemorySessionStore(session(expiresAt = 500))
        val auth = AuthManager(api, store) { 1_000 }; auth.bootstrap() // refreshResult di default = errore di rete
        try { auth.authed { it }; org.junit.Assert.fail() } catch (e: ApiException) { assertEquals(ErrorKind.Network, e.kind) }
        assertNotNull(auth.session.value); assertNotNull(store.session)
    }

    @Test fun authedWithoutSessionThrows() = runBlocking {
        val auth = AuthManager(api, MemorySessionStore()) { 1_000 }; auth.bootstrap()
        try { auth.authed { it }; org.junit.Assert.fail() } catch (e: NotSignedInException) { /* atteso */ }
    }

    @Test fun signOutClosesTheLocalSessionEvenIfTheServerIsUnreachable() = runBlocking {
        val store = MemorySessionStore(session()); api.signOutFails = true
        val auth = AuthManager(api, store) { 1_000 }; auth.bootstrap()
        auth.signOut()
        assertNull(auth.session.value); assertNull(store.session); assertEquals(listOf("signOut"), api.log)
    }

    @Test fun deleteAccountCallsTheRpcWithTheSessionToken() = runBlocking {
        val auth = AuthManager(api, MemorySessionStore(session())) { 1_000 }; auth.bootstrap()
        auth.deleteAccount()
        assertEquals(listOf("rpc:delete_own_account:AT"), api.log)
    }

    @Test fun sessionJsonRoundTrip() {
        val s = session(); assertEquals(s, Session.fromJson(s.toJson()))
        assertNull(Session.fromJson("not json")); assertNull(Session.fromJson("{}"))
    }

    @Test fun genericAndMessageMappingFollowTheIosSubstringRules() {
        fun login(msg: String) = AuthErrors.login(ApiException(ErrorKind.Client, 400, msg))
        assertEquals(AuthMessage.InvalidCredentials, login("Invalid login credentials"))
        assertEquals(AuthMessage.InvalidCredentials, login("INVALID EMAIL OR PASSWORD"))
        assertEquals(AuthMessage.RateLimit, login("email rate limit exceeded"))
        assertEquals(AuthMessage.RateLimit, login("Too many requests"))
        assertEquals(AuthMessage.Generic("boom"), login("boom"))
        assertEquals(AuthMessage.Offline, AuthErrors.login(ApiException(ErrorKind.Network, 0, "Unable to resolve host")))
    }
}
