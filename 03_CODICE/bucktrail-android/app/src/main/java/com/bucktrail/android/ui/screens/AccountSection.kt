package com.bucktrail.android.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.fragment.app.FragmentActivity
import com.bucktrail.android.R
import com.bucktrail.android.security.Authenticator
import com.bucktrail.android.ui.components.BtAlert
import com.bucktrail.android.ui.components.SectionLabel
import com.bucktrail.android.ui.components.SfIcons
import com.bucktrail.android.ui.components.ThinDivider
import com.bucktrail.android.ui.theme.Bt
import com.bucktrail.android.ui.theme.Fonts
import com.bucktrail.android.ui.theme.Typo
import kotlinx.coroutines.launch

/** Impostazioni → Account (§4.9 punto 10). `email == null` = nessun account: l'app funziona offline come sempre. */
class AccountSettings(
    val email: String?, val configured: Boolean,
    val onSignIn: () -> Unit, val onSignOut: suspend () -> Unit,
    /** Ritorna `null` se tutto è andato bene, altrimenti il dettaglio dell'errore. */
    val onDelete: suspend () -> String?,
)

@Composable
fun AccountSection(account: AccountSettings) {
    val c = Bt.colors
    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    var confirmLogout by remember { mutableStateOf(false) }
    var warning by remember { mutableStateOf(false) }
    var confirmDelete by remember { mutableStateOf(false) }
    var typed by remember { mutableStateOf("") }
    var deleting by remember { mutableStateOf(false) }
    var deleteError by remember { mutableStateOf<String?>(null) }
    val keyword = stringResource(R.string.auth_parola_conferma)
    val appName = stringResource(R.string.app_name)
    val lockReason = stringResource(R.string.blocco_motivo)

    Column(Modifier.padding(vertical = 18.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
        SectionLabel(stringResource(R.string.auth_account))
        if (account.email == null) {
            Text(
                stringResource(if (account.configured) R.string.auth_non_connesso else R.string.auth_non_configurata),
                style = Typo.formOption.copy(fontSize = 13.sp), color = c.smoke,
            )
            if (account.configured) Row(
                Modifier.fillMaxWidth().heightIn(min = 48.dp).clip(RoundedCornerShape(12.dp)).background(c.fog).clickable(role = Role.Button, onClick = account.onSignIn).padding(horizontal = 14.dp).testTag("btn_openAuth"),
                verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Icon(SfIcons.forName("person.circle"), null, tint = c.ink, modifier = Modifier.size(20.dp))
                Text(stringResource(R.string.auth_accedi_o_crea), style = Typo.formOption.copy(fontFamily = Fonts.formMedium), color = c.ink)
            }
        } else {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Icon(SfIcons.forName("person.circle"), null, tint = c.smoke, modifier = Modifier.size(20.dp))
                Text(account.email, style = Typo.formOption, color = c.ink, modifier = Modifier.testTag("account_email"))
            }
            ThinDivider(color = c.fog)
            Row(
                Modifier.fillMaxWidth().heightIn(min = 48.dp).clickable(role = Role.Button) { confirmLogout = true }.testTag("btn_logout"),
                verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Icon(SfIcons.forName("rectangle.portrait.and.arrow.right"), null, tint = c.danger, modifier = Modifier.size(16.dp))
                Text(stringResource(R.string.auth_esci), style = Typo.formOption.copy(fontFamily = Fonts.formMedium), color = c.danger)
            }
            Row(
                Modifier.fillMaxWidth().heightIn(min = 48.dp).clickable(role = Role.Button, enabled = !deleting) { warning = true }.testTag("btn_deleteAccount"),
                verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Icon(SfIcons.forName("trash"), null, tint = c.danger, modifier = Modifier.size(16.dp))
                Text(stringResource(R.string.auth_elimina_account), style = Typo.formOption.copy(fontFamily = Fonts.formMedium), color = c.danger)
            }
            if (deleting) Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                CircularProgressIndicator(Modifier.size(16.dp), color = c.smoke, strokeWidth = 2.dp)
                Text(stringResource(R.string.auth_eliminazione_in_corso), style = Typo.formOption.copy(fontSize = 13.sp), color = c.smoke)
            }
            deleteError?.let { Text(stringResource(R.string.auth_errore_eliminazione, it), style = Typo.formOptionSub.copy(fontSize = 12.sp), color = c.danger) }
        }
    }

    if (confirmLogout) BtAlert(
        stringResource(R.string.auth_esci_titolo), stringResource(R.string.auth_esci_messaggio), stringResource(R.string.auth_esci_conferma),
        onConfirm = { confirmLogout = false; scope.launch { account.onSignOut() } }, onDismiss = { confirmLogout = false },
        dismissLabel = stringResource(R.string.annulla),
    )
    if (warning) BtAlert(
        stringResource(R.string.auth_elimina_titolo), stringResource(R.string.auth_elimina_messaggio), stringResource(R.string.auth_continua),
        onConfirm = { warning = false; typed = ""; confirmDelete = true }, onDismiss = { warning = false }, dismissLabel = stringResource(R.string.annulla),
    )
    if (confirmDelete) BtAlert(
        stringResource(R.string.auth_conferma_eliminazione), stringResource(R.string.auth_conferma_eliminazione_msg, keyword), stringResource(R.string.auth_elimina_definitivamente),
        confirmEnabled = typed == keyword,
        onConfirm = {
            confirmDelete = false
            scope.launch {
                // azione irreversibile: nuova autenticazione del dispositivo, se disponibile (come iOS)
                var host = context
                while (host is android.content.ContextWrapper && host !is FragmentActivity) host = host.baseContext
                val activity = host as? FragmentActivity
                val ok = !Authenticator.isAvailable(context) || activity == null || Authenticator.authenticate(activity, appName, lockReason)
                if (ok) { deleting = true; deleteError = null; deleteError = account.onDelete(); deleting = false }
            }
        },
        onDismiss = { confirmDelete = false; typed = "" }, dismissLabel = stringResource(R.string.annulla),
        extra = {
            BasicTextField(
                typed, { typed = it }, singleLine = true, textStyle = Typo.formOption.copy(color = c.ink), cursorBrush = SolidColor(c.ink),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Text, autoCorrectEnabled = false),
                modifier = Modifier.fillMaxWidth().testTag("field_deleteConfirm"),
                decorationBox = { inner ->
                    androidx.compose.foundation.layout.Box(Modifier.fillMaxWidth().heightIn(min = 48.dp).clip(RoundedCornerShape(10.dp)).background(c.fog).padding(14.dp), contentAlignment = Alignment.CenterStart) {
                        if (typed.isEmpty()) Text(stringResource(R.string.auth_scrivi_parola, keyword), style = Typo.formOption, color = c.smoke.copy(alpha = 0.6f))
                        inner()
                    }
                },
            )
        },
    )
}
