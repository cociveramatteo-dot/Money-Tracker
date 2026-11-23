package com.bucktrail.android.security

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.bucktrail.android.BucktrailApplication
import com.bucktrail.android.R
import com.bucktrail.android.ui.components.DialogStatusBarEffect
import com.bucktrail.android.ui.components.SfIcons
import com.bucktrail.android.ui.theme.Bt
import com.bucktrail.android.ui.theme.Typo

/**
 * Blocco app (§4.10): se attivo e il dispositivo ha uno sblocco locale, copre l'app al primo avvio e dopo ogni passaggio in
 * background finché l'utente non si autentica (biometria o PIN). Il velo è anche una finestra propria, così copre i fogli aperti.
 */
@Composable
fun AppLockGate(content: @Composable () -> Unit) {
    val context = LocalContext.current
    val app = context.applicationContext as BucktrailApplication
    val prefs by app.prefs.state.collectAsStateWithLifecycle(initialValue = null)
    val enabled by rememberUpdatedState(prefs?.appLockEnabled == true)
    var locked by remember { mutableStateOf<Boolean?>(null) }
    var request by remember { mutableIntStateOf(0) }
    var prompting by remember { mutableStateOf(false) }
    val owner = LocalLifecycleOwner.current
    val activity = context as? FragmentActivity
    val appName = stringResource(R.string.app_name)
    val reason = stringResource(R.string.blocco_motivo)

    LaunchedEffect(prefs != null) { if (prefs != null && locked == null) locked = enabled && Authenticator.isAvailable(context) }
    DisposableEffect(owner) {
        val observer = LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_STOP -> if (enabled && !prompting && Authenticator.isAvailable(context)) locked = true
                Lifecycle.Event.ON_START -> if (!prompting) request++
                else -> Unit
            }
        }
        owner.lifecycle.addObserver(observer)
        onDispose { owner.lifecycle.removeObserver(observer) }
    }
    LaunchedEffect(locked, request) {
        if (locked == true && activity != null && !prompting) {
            prompting = true
            try { if (Authenticator.authenticate(activity, appName, reason)) locked = false } finally { prompting = false }
        }
    }

    Box(Modifier.fillMaxSize().background(Bt.colors.paper)) {
        if (locked != null) content()
        AnimatedVisibility(locked != false, enter = fadeIn(tween(200)), exit = fadeOut(tween(200))) { LockOverlay { request++ } }
    }
    if (locked == true) Dialog(
        onDismissRequest = {},
        properties = DialogProperties(dismissOnBackPress = false, dismissOnClickOutside = false, usePlatformDefaultWidth = false, decorFitsSystemWindows = false),
    ) {
        DialogStatusBarEffect()
        LockOverlay { request++ }
    }
}

@Composable
private fun LockOverlay(onUnlock: () -> Unit) {
    val c = Bt.colors
    Box(Modifier.fillMaxSize().background(c.paper), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(16.dp)) {
            Icon(SfIcons.forName("lock.fill"), null, tint = c.ink, modifier = Modifier.size(44.dp))
            Text(stringResource(R.string.blocco_titolo), style = Typo.rowName.copy(fontSize = 17.sp), color = c.ink)
            Box(
                Modifier.widthIn(min = 160.dp).heightIn(min = 52.dp).clip(RoundedCornerShape(14.dp)).background(c.ink)
                    .clickable(role = Role.Button, onClick = onUnlock).padding(horizontal = 24.dp).testTag("btn_unlock"),
                contentAlignment = Alignment.Center,
            ) { Text(stringResource(R.string.blocco_sblocca), style = Typo.rowName.copy(fontSize = 15.sp, fontWeight = FontWeight.SemiBold), color = c.surface) }
        }
    }
}
