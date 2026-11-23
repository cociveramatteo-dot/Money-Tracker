package com.bucktrail.android.shortcuts

import android.os.Bundle
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.fragment.app.FragmentActivity
import com.bucktrail.android.BucktrailApplication
import com.bucktrail.android.R
import com.bucktrail.android.data.QuickAddOps
import com.bucktrail.android.security.AppLockGate
import com.bucktrail.android.ui.components.BarAction
import com.bucktrail.android.ui.theme.Bt
import com.bucktrail.android.ui.theme.BucktrailTheme
import com.bucktrail.android.ui.theme.Typo
import kotlinx.coroutines.flow.first

/**
 * «Controlla saldo» (scorciatoia «Saldo conti», link `bucktrail://balance`): stesso testo dell'App Intent iOS.
 * Mostra gli importi, quindi passa dal blocco app e rispetta «oscura importi».
 */
class BalanceActivity : FragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { BucktrailTheme { AppLockGate { BalanceCard { finish() } } } }
    }
}

@androidx.compose.runtime.Composable
private fun BalanceCard(onClose: () -> Unit) {
    val c = Bt.colors
    val context = LocalContext.current
    val text by produceState<String?>(null) {
        val app = context.applicationContext as BucktrailApplication
        value = QuickAddOps.balanceText(context, hidden = app.prefs.state.first().hideBalance)
    }
    Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.45f)).clickable(onClick = onClose).systemBarsPadding(), contentAlignment = Alignment.BottomCenter) {
        Column(
            Modifier.fillMaxWidth().padding(12.dp).clip(RoundedCornerShape(24.dp)).background(c.paper).clickable(enabled = false) {}.navigationBarsPadding().padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Text(stringResource(R.string.saldo_conti), style = Typo.sectionTitle, color = c.ink)
            Column(Modifier.verticalScroll(rememberScrollState())) { Text(text.orEmpty(), style = Typo.formOption, color = c.ink, modifier = Modifier.testTag("balance_text")) }
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) { BarAction(stringResource(R.string.chiudi), onClose, Modifier.testTag("btn_closeBalance")) }
        }
    }
}
