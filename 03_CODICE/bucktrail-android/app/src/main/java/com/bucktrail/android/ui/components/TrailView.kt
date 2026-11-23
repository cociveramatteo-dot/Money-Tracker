package com.bucktrail.android.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.bucktrail.android.domain.BalanceTrail
import com.bucktrail.android.ui.theme.Bt
import com.bucktrail.android.ui.theme.Typo

/**
 * Il saldo come sentiero: tratto pieno verde fino a oggi, tratteggio ambra dal punto di oggi alla fine del mese.
 * Nessuna cifra (non va oscurata) e nascosta a TalkBack: l'informazione sta già nei testi.
 */
@Composable
fun TrailView(trail: BalanceTrail, firstLabel: String, todayLabel: String, lastLabel: String, modifier: Modifier = Modifier) {
    val c = Bt.colors
    Column(modifier.fillMaxWidth().clearAndSetSemantics { }, verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Canvas(Modifier.fillMaxWidth().height(56.dp)) {
            val inset = 12.dp.toPx()
            val vInset = 8.dp.toPx()
            val all = trail.actual + trail.projected
            val min = all.minOf { it.balance.toDouble() }
            val max = all.maxOf { it.balance.toDouble() }
            val span = max - min
            fun x(day: Int) = inset + (if (trail.daysInMonth > 1) (day - 1f) / (trail.daysInMonth - 1f) else 0f) * (size.width - 2 * inset)
            fun y(v: java.math.BigDecimal) =
                if (span <= 0.0) size.height / 2 else (vInset + (1 - (v.toDouble() - min) / span) * (size.height - 2 * vInset)).toFloat()

            val real = Path()
            trail.actual.forEachIndexed { i, p -> if (i == 0) real.moveTo(x(p.day), y(p.balance)) else real.lineTo(x(p.day), y(p.balance)) }
            drawPath(real, c.heroAccent, style = Stroke(2.5.dp.toPx(), cap = StrokeCap.Round, join = StrokeJoin.Round))
            val todayPoint = trail.actual.last()
            val tx = x(todayPoint.day); val ty = y(todayPoint.balance)

            if (trail.hasPlanned) {
                val dashed = Path().apply {
                    moveTo(tx, ty)
                    trail.projected.filter { it.day > trail.today }.forEach { lineTo(x(it.day), y(it.balance)) }
                    if (trail.today == trail.daysInMonth) trail.projected.lastOrNull()?.let { lineTo(x(it.day), y(it.balance)) }
                }
                drawPath(dashed, c.heroPlanned, style = Stroke(2.5.dp.toPx(), cap = StrokeCap.Round, join = StrokeJoin.Round,
                    pathEffect = PathEffect.dashPathEffect(floatArrayOf(1f, 7.dp.toPx()))))
                trail.plannedMarks.filter { it.day != trail.today && it.day != trail.daysInMonth }.forEach {
                    drawCircle(c.hero, 4.dp.toPx(), Offset(x(it.day), y(it.balance)))
                    drawCircle(c.heroPlanned, 4.dp.toPx(), Offset(x(it.day), y(it.balance)), style = Stroke(2.dp.toPx()))
                }
                trail.projected.lastOrNull()?.let { drawCircle(c.heroPlanned, 4.5.dp.toPx(), Offset(x(it.day), y(it.balance))) }
            }
            drawCircle(c.heroAccent.copy(alpha = 0.18f), 12.dp.toPx(), Offset(tx, ty))
            drawCircle(c.heroAccent, 5.5.dp.toPx(), Offset(tx, ty))
        }
        Row(Modifier.fillMaxWidth().padding(horizontal = 4.dp), horizontalArrangement = Arrangement.SpaceBetween) {
            Text(firstLabel, style = Typo.caption, color = c.heroSecondary)
            Text(todayLabel, style = Typo.caption.copy(fontWeight = FontWeight.SemiBold), color = c.heroAccent)
            Text(lastLabel, style = Typo.caption, color = c.heroSecondary)
        }
    }
}
