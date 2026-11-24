package com.bucktrail.android.ui.components

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.ArrowForward
import androidx.compose.material.icons.automirrored.outlined.FormatListBulleted
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.automirrored.outlined.Logout
import androidx.compose.material.icons.automirrored.outlined.Undo
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathFillType
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.path
import androidx.compose.ui.unit.dp
import kotlin.math.cos
import kotlin.math.sin

/**
 * Mappa dei nomi SF Symbol (salvati nei dati e sincronizzati) verso vettori Android (§1.5).
 * Un nome sconosciuto ricade su `circle.dotted`.
 */
object SfIcons {
    private fun ImageVector.Builder.ring(cx: Float, cy: Float, r: Float, w: Float) {
        path(fill = null, stroke = SolidColor(Color.Black), strokeLineWidth = w) {
            moveTo(cx - r, cy); arcToRelative(r, r, 0f, true, true, 2 * r, 0f); arcToRelative(r, r, 0f, true, true, -2 * r, 0f); close()
        }
    }

    /** SF `lock.fill`: corpo pieno con angoli morbidi e arco sottile (disegno proprio, non il glifo Apple). */
    private val lockFill: ImageVector by lazy {
        ImageVector.Builder("lock.fill", 24.dp, 24.dp, 24f, 24f).apply {
            path(fill = null, stroke = SolidColor(Color.Black), strokeLineWidth = 1.9f, strokeLineCap = androidx.compose.ui.graphics.StrokeCap.Round) {
                moveTo(7.9f, 10.8f); lineTo(7.9f, 8f); arcTo(4.1f, 4.1f, 0f, false, true, 16.1f, 8f); lineTo(16.1f, 10.8f)
            }
            path(fill = SolidColor(Color.Black)) {
                moveTo(7.2f, 10f); lineTo(16.8f, 10f); arcTo(2.2f, 2.2f, 0f, false, true, 19f, 12.2f); lineTo(19f, 18.8f)
                arcTo(2.2f, 2.2f, 0f, false, true, 16.8f, 21f); lineTo(7.2f, 21f); arcTo(2.2f, 2.2f, 0f, false, true, 5f, 18.8f)
                lineTo(5f, 12.2f); arcTo(2.2f, 2.2f, 0f, false, true, 7.2f, 10f); close()
            }
        }.build()
    }

    /** SF `chart.pie.fill`: tre quarti di torta e un quarto staccato in alto a destra (disegno proprio). */
    private val chartPieFill: ImageVector by lazy {
        ImageVector.Builder("chart.pie.fill", 24.dp, 24.dp, 24f, 24f).apply {
            path(fill = SolidColor(Color.Black)) {
                moveTo(10.5f, 13.5f); lineTo(10.5f, 5f); arcTo(8.5f, 8.5f, 0f, true, false, 19f, 13.5f); close()
            }
            path(fill = SolidColor(Color.Black)) {
                moveTo(12.5f, 11.5f); lineTo(12.5f, 3f); arcTo(8.5f, 8.5f, 0f, false, true, 21f, 11.5f); close()
            }
        }.build()
    }

    /** SF `target`: tre cerchi concentrici (il pallino centrale pieno). */
    private val target: ImageVector by lazy {
        ImageVector.Builder("target", 24.dp, 24.dp, 24f, 24f).apply {
            ring(12f, 12f, 9.5f, 1.8f); ring(12f, 12f, 5.5f, 1.8f)
            path(fill = SolidColor(Color.Black)) { moveTo(9.6f, 12f); arcToRelative(2.4f, 2.4f, 0f, true, true, 4.8f, 0f); arcToRelative(2.4f, 2.4f, 0f, true, true, -4.8f, 0f); close() }
        }.build()
    }

    /** SF `scope`: cerchio con quattro tacche del mirino che entrano. */
    private val scope: ImageVector by lazy {
        ImageVector.Builder("scope", 24.dp, 24.dp, 24f, 24f).apply {
            ring(12f, 12f, 7.5f, 1.8f)
            path(fill = null, stroke = SolidColor(Color.Black), strokeLineWidth = 1.8f, strokeLineCap = androidx.compose.ui.graphics.StrokeCap.Round) {
                moveTo(12f, 1.8f); lineTo(12f, 7f); moveTo(12f, 17f); lineTo(12f, 22.2f); moveTo(1.8f, 12f); lineTo(7f, 12f); moveTo(17f, 12f); lineTo(22.2f, 12f)
            }
            path(fill = SolidColor(Color.Black)) { moveTo(10.6f, 12f); arcToRelative(1.4f, 1.4f, 0f, true, true, 2.8f, 0f); arcToRelative(1.4f, 1.4f, 0f, true, true, -2.8f, 0f); close() }
        }.build()
    }

    private val dotted: ImageVector by lazy {
        ImageVector.Builder("circle.dotted", 24.dp, 24.dp, 24f, 24f).apply {
            for (i in 0 until 12) {
                val a = Math.toRadians(i * 30.0)
                val cx = (12 + 8.5 * cos(a)).toFloat()
                val cy = (12 + 8.5 * sin(a)).toFloat()
                path(fill = SolidColor(Color.Black), pathFillType = PathFillType.NonZero) {
                    moveTo(cx - 1.3f, cy)
                    arcToRelative(1.3f, 1.3f, 0f, true, true, 2.6f, 0f)
                    arcToRelative(1.3f, 1.3f, 0f, true, true, -2.6f, 0f)
                    close()
                }
            }
        }.build()
    }

    private val shoe: ImageVector by lazy {
        ImageVector.Builder("shoe", 24.dp, 24.dp, 24f, 24f).apply {
            path(fill = SolidColor(Color.Black)) {
                moveTo(3f, 17f); lineTo(3f, 11f); curveTo(5.5f, 11f, 7f, 10f, 8f, 8f)
                lineTo(10f, 9.5f); lineTo(12f, 8.5f); curveTo(13f, 11f, 16f, 12f, 21f, 13.5f)
                lineTo(21f, 17f); close()
            }
        }.build()
    }

    private val map: Map<String, ImageVector> by lazy {
        mapOf(
            "fork.knife" to Icons.Outlined.Restaurant, "cup.and.saucer.fill" to Icons.Filled.LocalCafe,
            "cart.fill" to Icons.Filled.ShoppingCart, "bag.fill" to Icons.Filled.ShoppingBag,
            "takeoutbag.and.cup.and.straw.fill" to Icons.Filled.TakeoutDining, "wineglass.fill" to Icons.Filled.WineBar,
            "car.fill" to Icons.Filled.DirectionsCar, "airplane" to Icons.Outlined.Flight, "tram.fill" to Icons.Filled.Tram,
            "ferry.fill" to Icons.Filled.DirectionsBoat, "bicycle" to Icons.Outlined.PedalBike,
            "fuelpump.fill" to Icons.Filled.LocalGasStation, "house.fill" to Icons.Filled.Home, "house" to Icons.Outlined.Home,
            "bolt.fill" to Icons.Filled.Bolt, "drop.fill" to Icons.Filled.WaterDrop,
            "flame.fill" to Icons.Filled.LocalFireDepartment, "wifi" to Icons.Outlined.Wifi, "phone.fill" to Icons.Filled.Call,
            "heart.fill" to Icons.Filled.Favorite, "cross.fill" to Icons.Filled.AddBox,
            "dumbbell.fill" to Icons.Filled.FitnessCenter, "figure.run" to Icons.Outlined.DirectionsRun,
            "stethoscope" to Icons.Outlined.MedicalServices, "pills.fill" to Icons.Filled.Medication,
            "gamecontroller.fill" to Icons.Filled.SportsEsports, "film.fill" to Icons.Filled.Movie,
            "music.note" to Icons.Outlined.MusicNote, "book.fill" to Icons.Filled.MenuBook,
            "theatermasks.fill" to Icons.Filled.TheaterComedy, "ticket.fill" to Icons.Filled.ConfirmationNumber,
            "briefcase.fill" to Icons.Filled.Work, "laptopcomputer" to Icons.Outlined.LaptopMac,
            "graduationcap.fill" to Icons.Filled.School, "pencil.and.ruler.fill" to Icons.Filled.Architecture,
            "doc.fill" to Icons.Filled.Description, "printer.fill" to Icons.Filled.Print,
            "tshirt.fill" to Icons.Filled.Checkroom, "shoe.fill" to shoe, "eyeglasses" to Icons.Outlined.Visibility,
            "crown.fill" to Icons.Filled.WorkspacePremium, "sparkles" to Icons.Outlined.AutoAwesome,
            "scissors" to Icons.Outlined.ContentCut, "eurosign.circle.fill" to Icons.Filled.Euro, "eurosign.circle" to Icons.Outlined.Euro,
            "creditcard.fill" to Icons.Filled.CreditCard, "creditcard" to Icons.Outlined.CreditCard,
            "gift.fill" to Icons.Filled.Redeem, "arrow.left.arrow.right" to Icons.Outlined.SwapHoriz,
            "repeat.circle.fill" to Icons.Filled.Autorenew, "circle.dotted" to dotted,
            "banknote" to Icons.Outlined.Payments, "tray.fill" to Icons.Filled.Inbox, "tray" to Icons.Outlined.Inbox,
            "arrow.triangle.2.circlepath" to Icons.Outlined.Sync, "target" to target, "scope" to scope,
            "building.columns.fill" to Icons.Filled.AccountBalance, "building.columns" to Icons.Outlined.AccountBalance,
            // obiettivi
            "trophy.fill" to Icons.Filled.EmojiEvents, "star.fill" to Icons.Filled.Star, "flag.fill" to Icons.Filled.Flag,
            "rosette" to Icons.Outlined.MilitaryTech, "figure.walk" to Icons.Outlined.DirectionsWalk,
            "chart.line.uptrend.xyaxis" to Icons.Outlined.TrendingUp, "cart" to Icons.Outlined.ShoppingCart,
            "iphone" to Icons.Outlined.Smartphone, "headphones" to Icons.Outlined.Headphones,
            "paintbrush.fill" to Icons.Filled.Brush, "leaf.fill" to Icons.Filled.Eco, "bed.double.fill" to Icons.Filled.Bed,
            "pawprint.fill" to Icons.Filled.Pets, "camera.fill" to Icons.Filled.PhotoCamera, "map.fill" to Icons.Filled.Map,
            // tipi conto / UI
            "tray.full" to Icons.Outlined.Inventory2, "list.bullet" to Icons.AutoMirrored.Outlined.FormatListBulleted,
            "chart.bar" to Icons.Outlined.BarChart, "eye" to Icons.Outlined.Visibility, "eye.slash" to Icons.Outlined.VisibilityOff,
            "gearshape" to Icons.Outlined.Settings, "magnifyingglass" to Icons.Outlined.Search,
            "line.3.horizontal.decrease" to Icons.Outlined.FilterList, "slider.horizontal.3" to Icons.Outlined.Tune,
            "plus" to Icons.Outlined.Add, "xmark" to Icons.Outlined.Close, "checkmark" to Icons.Outlined.Check,
            "checkmark.circle.fill" to Icons.Filled.CheckCircle, "clock" to Icons.Outlined.Schedule,
            "repeat" to Icons.Outlined.Repeat, "trash" to Icons.Outlined.Delete, "pencil" to Icons.Outlined.Edit,
            "archivebox" to Icons.Outlined.Archive, "arrow.uturn.left" to Icons.AutoMirrored.Outlined.Undo,
            "square.and.arrow.down" to Icons.Outlined.Download, "square.and.arrow.up" to Icons.Outlined.Share,
            "lock.fill" to lockFill, "wifi.slash" to Icons.Outlined.WifiOff, "clock.arrow.circlepath" to Icons.Outlined.History,
            "envelope.badge.checkmark.fill" to Icons.Filled.MarkEmailRead, "info.circle.fill" to Icons.Filled.Info,
            "lightbulb.fill" to Icons.Filled.Lightbulb, "chart.pie.fill" to chartPieFill,
            "chevron.left" to Icons.AutoMirrored.Outlined.KeyboardArrowLeft, "chevron.up.chevron.down" to Icons.Outlined.UnfoldMore, "chevron.right" to Icons.AutoMirrored.Outlined.KeyboardArrowRight,
            "chevron.up" to Icons.Outlined.KeyboardArrowUp, "chevron.down" to Icons.Outlined.KeyboardArrowDown,
            "arrow.right" to Icons.AutoMirrored.Outlined.ArrowForward, "arrowtriangle.down.fill" to Icons.Filled.ArrowDropDown, "arrow.up" to Icons.Outlined.ArrowUpward, "arrow.down" to Icons.Outlined.ArrowDownward,
            "person.circle" to Icons.Outlined.AccountCircle, "plus.circle" to Icons.Outlined.AddCircleOutline,
            "pencil.circle" to Icons.Outlined.Edit, "circle" to Icons.Outlined.RadioButtonUnchecked, "line.3.horizontal" to Icons.Outlined.DragHandle, "creditcard.tab" to Icons.Outlined.CreditCard, "rectangle.portrait.and.arrow.right" to Icons.AutoMirrored.Outlined.Logout,
        )
    }

    fun forName(sfName: String): ImageVector = map[sfName] ?: dotted

    /** Nomi SF noti (per test e per i selettori icona). */
    val knownNames: Set<String> get() = map.keys
}
