package com.bucktrail.android.ui.components

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.ArrowForward
import androidx.compose.material.icons.automirrored.outlined.FormatListBulleted
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.automirrored.outlined.Undo
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
            "fork.knife" to Icons.Outlined.Restaurant, "cup.and.saucer.fill" to Icons.Outlined.LocalCafe,
            "cart.fill" to Icons.Outlined.ShoppingCart, "bag.fill" to Icons.Outlined.ShoppingBag,
            "takeoutbag.and.cup.and.straw.fill" to Icons.Outlined.TakeoutDining, "wineglass.fill" to Icons.Outlined.WineBar,
            "car.fill" to Icons.Outlined.DirectionsCar, "airplane" to Icons.Outlined.Flight, "tram.fill" to Icons.Outlined.Tram,
            "ferry.fill" to Icons.Outlined.DirectionsBoat, "bicycle" to Icons.Outlined.PedalBike,
            "fuelpump.fill" to Icons.Outlined.LocalGasStation, "house.fill" to Icons.Outlined.Home, "house" to Icons.Outlined.Home,
            "bolt.fill" to Icons.Outlined.Bolt, "drop.fill" to Icons.Outlined.WaterDrop,
            "flame.fill" to Icons.Outlined.LocalFireDepartment, "wifi" to Icons.Outlined.Wifi, "phone.fill" to Icons.Outlined.Call,
            "heart.fill" to Icons.Outlined.Favorite, "cross.fill" to Icons.Outlined.AddBox,
            "dumbbell.fill" to Icons.Outlined.FitnessCenter, "figure.run" to Icons.Outlined.DirectionsRun,
            "stethoscope" to Icons.Outlined.MedicalServices, "pills.fill" to Icons.Outlined.Medication,
            "gamecontroller.fill" to Icons.Outlined.SportsEsports, "film.fill" to Icons.Outlined.Movie,
            "music.note" to Icons.Outlined.MusicNote, "book.fill" to Icons.Outlined.MenuBook,
            "theatermasks.fill" to Icons.Outlined.TheaterComedy, "ticket.fill" to Icons.Outlined.ConfirmationNumber,
            "briefcase.fill" to Icons.Outlined.Work, "laptopcomputer" to Icons.Outlined.LaptopMac,
            "graduationcap.fill" to Icons.Outlined.School, "pencil.and.ruler.fill" to Icons.Outlined.Architecture,
            "doc.fill" to Icons.Outlined.Description, "printer.fill" to Icons.Outlined.Print,
            "tshirt.fill" to Icons.Outlined.Checkroom, "shoe.fill" to shoe, "eyeglasses" to Icons.Outlined.Visibility,
            "crown.fill" to Icons.Outlined.WorkspacePremium, "sparkles" to Icons.Outlined.AutoAwesome,
            "scissors" to Icons.Outlined.ContentCut, "eurosign.circle.fill" to Icons.Outlined.Euro, "eurosign.circle" to Icons.Outlined.Euro,
            "creditcard.fill" to Icons.Outlined.CreditCard, "creditcard" to Icons.Outlined.CreditCard,
            "gift.fill" to Icons.Outlined.Redeem, "arrow.left.arrow.right" to Icons.Outlined.SwapHoriz,
            "repeat.circle.fill" to Icons.Outlined.Autorenew, "circle.dotted" to dotted,
            "banknote" to Icons.Outlined.Payments, "tray.fill" to Icons.Outlined.Inbox, "tray" to Icons.Outlined.Inbox,
            "arrow.triangle.2.circlepath" to Icons.Outlined.Sync, "target" to Icons.Outlined.TrackChanges, "scope" to Icons.Outlined.TrackChanges,
            "building.columns.fill" to Icons.Outlined.AccountBalance, "building.columns" to Icons.Outlined.AccountBalance,
            // obiettivi
            "trophy.fill" to Icons.Outlined.EmojiEvents, "star.fill" to Icons.Outlined.Star, "flag.fill" to Icons.Outlined.Flag,
            "rosette" to Icons.Outlined.MilitaryTech, "figure.walk" to Icons.Outlined.DirectionsWalk,
            "chart.line.uptrend.xyaxis" to Icons.Outlined.TrendingUp, "cart" to Icons.Outlined.ShoppingCart,
            "iphone" to Icons.Outlined.Smartphone, "headphones" to Icons.Outlined.Headphones,
            "paintbrush.fill" to Icons.Outlined.Brush, "leaf.fill" to Icons.Outlined.Eco, "bed.double.fill" to Icons.Outlined.Bed,
            "pawprint.fill" to Icons.Outlined.Pets, "camera.fill" to Icons.Outlined.PhotoCamera, "map.fill" to Icons.Outlined.Map,
            // tipi conto / UI
            "tray.full" to Icons.Outlined.Inventory2, "list.bullet" to Icons.AutoMirrored.Outlined.FormatListBulleted,
            "chart.bar" to Icons.Outlined.BarChart, "eye" to Icons.Outlined.Visibility, "eye.slash" to Icons.Outlined.VisibilityOff,
            "gearshape" to Icons.Outlined.Settings, "magnifyingglass" to Icons.Outlined.Search,
            "line.3.horizontal.decrease" to Icons.Outlined.FilterList, "slider.horizontal.3" to Icons.Outlined.Tune,
            "plus" to Icons.Outlined.Add, "xmark" to Icons.Outlined.Close, "checkmark" to Icons.Outlined.Check,
            "checkmark.circle.fill" to Icons.Outlined.CheckCircle, "clock" to Icons.Outlined.Schedule,
            "repeat" to Icons.Outlined.Repeat, "trash" to Icons.Outlined.Delete, "pencil" to Icons.Outlined.Edit,
            "archivebox" to Icons.Outlined.Archive, "arrow.uturn.left" to Icons.AutoMirrored.Outlined.Undo,
            "square.and.arrow.down" to Icons.Outlined.Download, "square.and.arrow.up" to Icons.Outlined.Share,
            "lock.fill" to Icons.Outlined.Lock, "wifi.slash" to Icons.Outlined.WifiOff, "clock.arrow.circlepath" to Icons.Outlined.History,
            "envelope.badge.checkmark.fill" to Icons.Outlined.MarkEmailRead, "info.circle.fill" to Icons.Outlined.Info,
            "lightbulb.fill" to Icons.Outlined.Lightbulb, "chart.pie.fill" to Icons.Outlined.PieChart,
            "chevron.left" to Icons.AutoMirrored.Outlined.ArrowBack, "chevron.right" to Icons.AutoMirrored.Outlined.KeyboardArrowRight,
            "chevron.up" to Icons.Outlined.KeyboardArrowUp, "chevron.down" to Icons.Outlined.KeyboardArrowDown,
            "arrow.up" to Icons.Outlined.ArrowUpward, "arrow.down" to Icons.Outlined.ArrowDownward,
            "person.circle" to Icons.Outlined.AccountCircle, "plus.circle" to Icons.Outlined.AddCircleOutline,
            "pencil.circle" to Icons.Outlined.Edit, "circle" to Icons.Outlined.RadioButtonUnchecked, "line.3.horizontal" to Icons.Outlined.DragHandle, "creditcard.tab" to Icons.Outlined.CreditCard,
        )
    }

    fun forName(sfName: String): ImageVector = map[sfName] ?: dotted

    /** Nomi SF noti (per test e per i selettori icona). */
    val knownNames: Set<String> get() = map.keys
}
