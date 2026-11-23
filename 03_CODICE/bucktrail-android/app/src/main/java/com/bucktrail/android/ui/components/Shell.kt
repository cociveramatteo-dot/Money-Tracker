package com.bucktrail.android.ui.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.spring
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.bucktrail.android.ui.theme.Bt
import com.bucktrail.android.ui.theme.Dim
import com.bucktrail.android.ui.theme.Typo

enum class Tab(val id: String, val sfIcon: String) {
    Home("tab_home", "house"), Movements("tab_movimenti", "list.bullet"), Statistics("tab_statistiche", "chart.bar"),
    Plan("tab_pianifica", "scope"), Accounts("tab_conti", "creditcard"),
}

/** Tab bar flottante: capsula raggio 24, h 66, margini 14, offset 20, pill attiva 44x28 `accentSoft`. */
@Composable
fun FloatingTabBar(selected: Tab, labels: Map<Tab, String>, onSelect: (Tab) -> Unit, modifier: Modifier = Modifier) {
    val c = Bt.colors
    val shape = RoundedCornerShape(24.dp)
    Row(
        modifier.navigationBarsPadding().padding(horizontal = Dim.tabBarSideMargin.dp).padding(bottom = Dim.tabBarBottom.dp)
            .fillMaxWidth().height(Dim.tabBarHeight.dp)
            .tintedShadow(14.dp, shape, c.ink.copy(alpha = 0.10f)).clip(shape).background(c.surface),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Tab.entries.forEach { tab ->
            val active = tab == selected
            Column(
                Modifier.weight(1f).height(Dim.tabBarHeight.dp).testTag(tab.id)
                    .clickable(role = Role.Tab) { onSelect(tab) }.semantics { this.selected = active },
                horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center,
            ) {
                Box(
                    Modifier.size(44.dp, 28.dp).clip(RoundedCornerShape(14.dp)).background(if (active) c.accentSoft else androidx.compose.ui.graphics.Color.Transparent),
                    contentAlignment = Alignment.Center,
                ) { Icon(SfIcons.forName(tab.sfIcon), null, tint = if (active) c.ink else c.smoke, modifier = Modifier.size(20.dp)) }
                Text(labels.getValue(tab), style = if (active) Typo.tabLabelActive else Typo.tabLabel, color = if (active) c.ink else c.smoke, maxLines = 1, softWrap = false)
            }
        }
    }
}

/** FAB squircle 58x58 raggio 20, `accent`, ombra accent 35%; sparisce con scala .7 + fade. */
@Composable
fun FabButton(description: String, visible: Boolean, onClick: () -> Unit, modifier: Modifier = Modifier) {
    val c = Bt.colors
    val shape = RoundedCornerShape(Dim.fabRadius.dp)
    val haptic = LocalHapticFeedback.current
    AnimatedVisibility(
        visible = visible, modifier = modifier,
        enter = fadeIn(spring()) + scaleIn(spring(dampingRatio = 0.7f), initialScale = 0.7f),
        exit = fadeOut() + scaleOut(targetScale = 0.7f),
    ) {
        Box(
            Modifier.size(Dim.fabSize.dp).tintedShadow(12.dp, shape, c.accent.copy(alpha = 0.35f)).clip(shape).background(c.accent)
                .testTag("fabButton").semantics { contentDescription = description }
                .clickable(role = Role.Button) { haptic.performHapticFeedback(HapticFeedbackType.LongPress); onClick() },
            contentAlignment = Alignment.Center,
        ) { Icon(SfIcons.forName("plus"), null, tint = c.onAccent, modifier = Modifier.size(26.dp)) }
    }
}
