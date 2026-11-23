package com.bucktrail.android.security

import android.content.Context
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricManager.Authenticators.BIOMETRIC_WEAK
import androidx.biometric.BiometricManager.Authenticators.DEVICE_CREDENTIAL
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import kotlin.coroutines.resume
import kotlinx.coroutines.suspendCancellableCoroutine

/** Autenticazione locale (§4.10): biometria con ripiego sul PIN/schema/password del dispositivo (`.deviceOwnerAuthentication`). */
object Authenticator {
    private const val ALLOWED = BIOMETRIC_WEAK or DEVICE_CREDENTIAL

    /** Vero se il dispositivo ha almeno una forma di sblocco locale configurata. */
    fun isAvailable(context: Context): Boolean = BiometricManager.from(context).canAuthenticate(ALLOWED) == BiometricManager.BIOMETRIC_SUCCESS

    /** Vero solo se l'utente si autentica; falso se annulla o fallisce. */
    suspend fun authenticate(activity: FragmentActivity, title: String, reason: String): Boolean = suspendCancellableCoroutine { cont ->
        val prompt = BiometricPrompt(activity, ContextCompat.getMainExecutor(activity), object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) { if (cont.isActive) cont.resume(true) }
            override fun onAuthenticationError(errorCode: Int, errString: CharSequence) { if (cont.isActive) cont.resume(false) }
        })
        val info = BiometricPrompt.PromptInfo.Builder().setTitle(title).setSubtitle(reason).setAllowedAuthenticators(ALLOWED).build()
        prompt.authenticate(info)
        cont.invokeOnCancellation { runCatching { prompt.cancelAuthentication() } }
    }
}
