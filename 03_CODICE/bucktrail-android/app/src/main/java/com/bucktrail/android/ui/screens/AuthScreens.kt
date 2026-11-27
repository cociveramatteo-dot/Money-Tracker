package com.bucktrail.android.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.foundation.border
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import com.bucktrail.android.R
import com.bucktrail.android.sync.AuthMessage
import com.bucktrail.android.sync.SignUpResult
import com.bucktrail.android.ui.components.BtAlert
import com.bucktrail.android.ui.components.DialogStatusBarEffect
import com.bucktrail.android.ui.components.SfIcons
import com.bucktrail.android.ui.theme.Bt
import com.bucktrail.android.ui.theme.Fonts
import com.bucktrail.android.ui.theme.Typo
import kotlinx.coroutines.launch

/** Azioni di accesso (implementate da `AppViewModel`). Gli errori tornano già mappati sul messaggio da mostrare. */
class AuthActions(
    val signIn: suspend (email: String, password: String) -> AuthMessage?,
    val signUp: suspend (email: String, password: String) -> Pair<SignUpResult?, AuthMessage?>,
    val resetPassword: suspend (email: String) -> Unit,
    val onClose: () -> Unit,
)

@Composable
private fun AuthMessage.text(): String = when (this) {
    AuthMessage.InvalidCredentials -> stringResource(R.string.auth_errore_credenziali)
    AuthMessage.EmailNotConfirmed -> stringResource(R.string.auth_errore_conferma_email)
    AuthMessage.RateLimit -> stringResource(R.string.auth_errore_troppi_tentativi)
    AuthMessage.Offline -> stringResource(R.string.auth_errore_rete)
    AuthMessage.AlreadyExists -> stringResource(R.string.auth_errore_esiste)
    AuthMessage.PasswordTooShort -> stringResource(R.string.auth_errore_password_corta)
    AuthMessage.InvalidEmail -> stringResource(R.string.auth_errore_email_non_valida)
    is AuthMessage.Generic -> stringResource(R.string.auth_errore_generico, detail)
}

/** Login e Registrazione (`LoginView`/`SignUpView` iOS) su una pagina a tutto schermo. L'accesso è facoltativo su Android: «Chiudi» torna all'app. */
@Composable
fun AuthFlow(actions: AuthActions) {
    var signUp by rememberSaveable { mutableStateOf(false) }
    Dialog(onDismissRequest = { if (signUp) signUp = false else actions.onClose() }, properties = DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false)) {
        DialogStatusBarEffect()
        Column(Modifier.fillMaxSize().background(Bt.colors.paper).systemBarsPadding().imePadding()) {
            Row(Modifier.fillMaxWidth().heightIn(min = 56.dp).padding(horizontal = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                Box(
                    Modifier.size(48.dp).clickable(role = Role.Button) { if (signUp) signUp = false else actions.onClose() }.testTag(if (signUp) "btn_authBack" else "btn_authClose"),
                    contentAlignment = Alignment.Center,
                ) {
                    // iOS: la pagina «Crea account» ha il pulsante indietro circolare 44 con bordo `fog`
                    if (signUp) Box(Modifier.size(44.dp).clip(androidx.compose.foundation.shape.CircleShape).background(Bt.colors.surface).border(1.dp, Bt.colors.fog, androidx.compose.foundation.shape.CircleShape), contentAlignment = Alignment.Center) {
                        Icon(SfIcons.forName("chevron.left"), stringResource(R.string.auth_accedi), tint = Bt.colors.ink, modifier = Modifier.size(22.dp))
                    } else Icon(SfIcons.forName("xmark"), stringResource(R.string.chiudi), tint = Bt.colors.ink, modifier = Modifier.size(22.dp))
                }
                if (signUp) Text(
                    stringResource(R.string.auth_crea_account_titolo), style = Typo.rowName.copy(fontWeight = FontWeight.SemiBold), color = Bt.colors.ink,
                    textAlign = TextAlign.Center, modifier = Modifier.weight(1f).padding(end = 48.dp),
                )
            }
            if (signUp) SignUpPage(actions, onBackToLogin = { signUp = false }) else LoginPage(actions, onSignUp = { signUp = true })
        }
    }
}

@Composable
private fun LoginPage(actions: AuthActions, onSignUp: () -> Unit) {
    val c = Bt.colors
    val scope = rememberCoroutineScope()
    var email by rememberSaveable { mutableStateOf("") }
    var password by rememberSaveable { mutableStateOf("") }
    var loading by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<AuthMessage?>(null) }
    var showReset by rememberSaveable { mutableStateOf(false) }
    var resetEmail by rememberSaveable { mutableStateOf("") }
    var resetSent by rememberSaveable { mutableStateOf(false) }
    val canSubmit = email.isNotEmpty() && password.isNotEmpty()

    Column(Modifier.fillMaxWidth().verticalScroll(rememberScrollState())) {
        Column(Modifier.fillMaxWidth().padding(top = 24.dp, bottom = 40.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Icon(SfIcons.forName("chart.pie.fill"), null, tint = c.ink, modifier = Modifier.size(52.dp))
            Text(stringResource(R.string.app_name), style = Typo.sheetTitle.copy(fontFamily = Fonts.formSemibold), color = c.ink)
            Text(stringResource(R.string.auth_accedi_per_continuare), style = Typo.formOption, color = c.smoke)
        }
        Column(Modifier.padding(horizontal = 20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            AuthField(stringResource(R.string.auth_email), stringResource(R.string.auth_email_segnaposto), email, { email = it }, KeyboardType.Email, tag = "field_loginEmail")
            AuthField(stringResource(R.string.auth_password), "••••••••", password, { password = it }, KeyboardType.Password, secure = true, tag = "field_loginPassword")
        }
        error?.let { AuthErrorText(it.text()) }
        AuthButton(stringResource(R.string.auth_accedi), canSubmit, loading, Modifier.padding(horizontal = 20.dp).padding(top = 16.dp).testTag("btn_login")) {
            scope.launch { loading = true; error = null; error = actions.signIn(email.trim(), password); loading = false }
        }
        Box(Modifier.fillMaxWidth().padding(top = 12.dp), contentAlignment = Alignment.Center) {
            Box(Modifier.heightIn(min = 44.dp).clickable(role = Role.Button) { resetEmail = email; resetSent = false; showReset = true }.padding(horizontal = 12.dp).testTag("btn_forgotPassword"), contentAlignment = Alignment.Center) {
                Text(stringResource(R.string.auth_password_dimenticata), style = Typo.formOption.copy(fontSize = 14.sp), color = c.smoke)
            }
        }
        Row(Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 16.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.weight(1f).height(1.dp).background(c.fog))
            Text(stringResource(R.string.auth_oppure), style = Typo.formOptionSub.copy(fontSize = 12.sp), color = c.smoke, modifier = Modifier.padding(horizontal = 12.dp))
            Box(Modifier.weight(1f).height(1.dp).background(c.fog))
        }
        Box(
            Modifier.padding(horizontal = 20.dp).fillMaxWidth().height(50.dp).clip(RoundedCornerShape(12.dp)).background(c.fog)
                .clickable(role = Role.Button, onClick = onSignUp).testTag("btn_goSignUp"),
            contentAlignment = Alignment.Center,
        ) { Text(stringResource(R.string.auth_crea_un_account), style = Typo.formOption.copy(fontFamily = Fonts.formMedium, fontSize = 16.sp), color = c.ink) }
        Spacer(Modifier.height(48.dp))
    }

    if (showReset) {
        BtAlert(
            stringResource(R.string.auth_reset_titolo),
            stringResource(if (resetSent) R.string.auth_reset_inviata else R.string.auth_reset_messaggio),
            confirm = stringResource(if (resetSent) R.string.chiudi else R.string.auth_invia_link),
            onConfirm = {
                if (resetSent) showReset = false
                else if (resetEmail.isNotEmpty()) scope.launch { actions.resetPassword(resetEmail.trim()); resetSent = true }
            },
            onDismiss = { showReset = false }, dismissLabel = stringResource(R.string.annulla), destructive = false,
            extra = if (resetSent) null else ({
                AuthField(stringResource(R.string.auth_email), stringResource(R.string.auth_email_segnaposto), resetEmail, { resetEmail = it }, KeyboardType.Email, tag = "field_resetEmail")
            }),
        )
    }
}

@Composable
private fun SignUpPage(actions: AuthActions, onBackToLogin: () -> Unit) {
    val c = Bt.colors
    val scope = rememberCoroutineScope()
    var email by rememberSaveable { mutableStateOf("") }
    var password by rememberSaveable { mutableStateOf("") }
    var confirm by rememberSaveable { mutableStateOf("") }
    var loading by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<AuthMessage?>(null) }
    var created by rememberSaveable { mutableStateOf(false) }
    val canSubmit = email.isNotEmpty() && password.length >= 6 && password == confirm

    Column(Modifier.fillMaxWidth().verticalScroll(rememberScrollState())) {
        Column(Modifier.fillMaxWidth().padding(top = 16.dp, bottom = 32.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(stringResource(R.string.auth_benvenuto), style = Typo.sheetTitle.copy(fontFamily = Fonts.formSemibold), color = c.ink)
            Text(stringResource(R.string.auth_crea_account_sottotitolo), style = Typo.formOption, color = c.smoke)
        }
        Column(Modifier.padding(horizontal = 20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            AuthField(stringResource(R.string.auth_email), stringResource(R.string.auth_email_segnaposto), email, { email = it }, KeyboardType.Email, tag = "field_signUpEmail")
            AuthField(stringResource(R.string.auth_password), stringResource(R.string.auth_minimo_6), password, { password = it }, KeyboardType.Password, secure = true, tag = "field_signUpPassword")
            Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                AuthField(stringResource(R.string.auth_conferma_password), stringResource(R.string.auth_ripeti_password), confirm, { confirm = it }, KeyboardType.Password, secure = true, tag = "field_signUpConfirm")
                if (confirm.isNotEmpty() && confirm != password) Text(stringResource(R.string.auth_password_diverse), style = Typo.formOptionSub, color = c.danger, modifier = Modifier.padding(top = 2.dp))
            }
        }
        error?.let { AuthErrorText(it.text()) }
        if (created) Column(Modifier.fillMaxWidth().padding(horizontal = 20.dp).padding(top = 24.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Icon(SfIcons.forName("envelope.badge.checkmark.fill"), null, tint = c.accent, modifier = Modifier.size(32.dp))
            Text(stringResource(R.string.auth_account_creato), style = Typo.formOption.copy(fontSize = 14.sp), color = c.smoke, textAlign = TextAlign.Center)
            Box(Modifier.heightIn(min = 44.dp).clickable(role = Role.Button, onClick = onBackToLogin).padding(horizontal = 16.dp).testTag("btn_backToLogin"), contentAlignment = Alignment.Center) {
                Text(stringResource(R.string.auth_torna_al_login), style = Typo.formOption.copy(fontFamily = Fonts.formMedium), color = c.ink)
            }
        } else AuthButton(stringResource(R.string.auth_registrati), canSubmit, loading, Modifier.padding(horizontal = 20.dp).padding(top = 16.dp).testTag("btn_signUp")) {
            scope.launch {
                loading = true; error = null
                val (result, message) = actions.signUp(email.trim(), password)
                error = message
                if (result == SignUpResult.ConfirmationNeeded) created = true
                loading = false
            }
        }
        Spacer(Modifier.height(48.dp))
    }
}

@Composable
private fun AuthErrorText(text: String) {
    Text(text, style = Typo.formOption.copy(fontSize = 13.sp), color = Bt.colors.danger, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp).padding(top = 12.dp).testTag("auth_error"))
}

/** `AuthField` iOS: etichetta 12 medium smoke, campo su `fog` raggio 10, padding 14 (con occhio su campi sicuri). */
@Composable
fun AuthField(label: String, placeholder: String, value: String, onChange: (String) -> Unit, keyboard: KeyboardType, secure: Boolean = false, tag: String = "") {
    val c = Bt.colors
    var revealed by rememberSaveable(secure) { mutableStateOf(false) }
    if (secure) {
        val lifecycleOwner = LocalLifecycleOwner.current
        DisposableEffect(lifecycleOwner) {
            val observer = LifecycleEventObserver { _, event ->
                if (event == Lifecycle.Event.ON_STOP) revealed = false
            }
            lifecycleOwner.lifecycle.addObserver(observer)
            onDispose { lifecycleOwner.lifecycle.removeObserver(observer) }
        }
    }
    val effectiveKeyboard = if (secure && revealed && keyboard == KeyboardType.Password) KeyboardType.Text else keyboard
    val toggleLabel = stringResource(if (revealed) R.string.nascondi else R.string.mostra)
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text(label, style = Typo.formOption.copy(fontFamily = Fonts.formMedium, fontSize = 12.sp), color = c.smoke)
        BasicTextField(
            value, onChange, singleLine = true, textStyle = Typo.formOption.copy(color = c.ink), cursorBrush = SolidColor(c.ink),
            keyboardOptions = KeyboardOptions(keyboardType = effectiveKeyboard, autoCorrectEnabled = false),
            visualTransformation = if (secure && !revealed) PasswordVisualTransformation() else VisualTransformation.None,
            modifier = Modifier.fillMaxWidth().testTag(tag),
            decorationBox = { inner ->
                Row(
                    Modifier.fillMaxWidth().heightIn(min = 48.dp).clip(RoundedCornerShape(10.dp)).background(c.fog)
                        .padding(start = 14.dp, end = if (secure) 4.dp else 14.dp, top = if (secure) 2.dp else 14.dp, bottom = if (secure) 2.dp else 14.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Box(Modifier.weight(1f).padding(vertical = if (secure) 12.dp else 0.dp), contentAlignment = Alignment.CenterStart) {
                        if (value.isEmpty()) Text(placeholder, style = Typo.formOption, color = c.smoke.copy(alpha = 0.6f))
                        inner()
                    }
                    if (secure) {
                        val toggleModifier = if (tag.isNotEmpty()) Modifier.testTag("${tag}_toggle") else Modifier
                        Box(
                            toggleModifier.size(44.dp).clip(RoundedCornerShape(8.dp))
                                .clickable(role = Role.Button, onClickLabel = toggleLabel) { revealed = !revealed },
                            contentAlignment = Alignment.Center,
                        ) {
                            Icon(SfIcons.forName(if (revealed) "eye.slash" else "eye"), toggleLabel, tint = c.smoke, modifier = Modifier.size(18.dp))
                        }
                    }
                }
            },
        )
    }
}

/** Pulsante auth: h50 raggio 12, `ink` se abilitato altrimenti `fog` (come iOS), spinner durante la richiesta. */
@Composable
private fun AuthButton(text: String, enabled: Boolean, loading: Boolean, modifier: Modifier, onClick: () -> Unit) {
    val c = Bt.colors
    Box(
        modifier.fillMaxWidth().height(50.dp).clip(RoundedCornerShape(12.dp)).background(if (enabled) c.ink else c.fog)
            .clickable(enabled = enabled && !loading, role = Role.Button, onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        if (loading) CircularProgressIndicator(Modifier.size(20.dp), color = c.paper, strokeWidth = 2.dp)
        else Text(text, style = Typo.primaryButton.copy(fontSize = 16.sp), color = c.paper)
    }
}
