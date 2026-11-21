package com.bucktrail.android

import android.app.Application
import android.app.DatePickerDialog
import android.database.sqlite.SQLiteException
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.List
import androidx.compose.material.icons.outlined.AccountBox
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.DialogProperties
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.repeatOnLifecycle
import androidx.room.Room
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.math.BigDecimal
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter

class BucktrailApplication : Application() {
    val ledger by lazy {
        Room.databaseBuilder(applicationContext, BucktrailDatabase::class.java, "bucktrail.db")
            .addMigrations(migration1To2).build().ledger()
    }
}

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            val dark = isSystemInDarkTheme()
            val scheme = if (dark) darkColorScheme(
                primary = Color(0xFF5FD19B), onPrimary = Color(0xFF0E1210),
                background = Color(0xFF0E1210), onBackground = Color(0xFFF1F3EF),
                surface = Color(0xFF171C19), onSurface = Color(0xFFF1F3EF),
                primaryContainer = Color(0xFF1C2E25),
            ) else lightColorScheme(
                primary = Color(0xFF1F7A4D), onPrimary = Color.White,
                background = Color(0xFFF3F4EF), onBackground = Color(0xFF121614),
                surface = Color.White, onSurface = Color(0xFF121614),
                primaryContainer = Color(0xFFDDEEE3),
            )
            MaterialTheme(colorScheme = scheme, typography = sentieroType) {
                Bucktrail((application as BucktrailApplication).ledger)
            }
        }
    }
}

private val heading = FontFamily(Font(R.font.space_grotesk_bold))
private val body = FontFamily(Font(R.font.inter_regular))
private val sentieroType = Typography(
    headlineMedium = TextStyle(fontFamily = heading, fontSize = 30.sp),
    titleMedium = TextStyle(fontFamily = heading, fontSize = 18.sp),
    displaySmall = TextStyle(fontFamily = heading, fontSize = 38.sp, fontFeatureSettings = "tnum"),
    bodyMedium = TextStyle(fontFamily = body, fontSize = 15.sp),
)

private enum class Page(val label: String) { Home("Home"), Movements("Movimenti"), Accounts("Conti") }
private enum class Editor { Account, NewMovement, EditMovement }
private val entryDateFormat = DateTimeFormatter.ofPattern("dd/MM/uuuu")

private fun localDay(): Pair<LocalDate, ZoneId> {
    val zone = ZoneId.systemDefault()
    return LocalDate.now(zone) to zone
}

@Composable
private fun Bucktrail(ledger: Ledger) {
    val entries by remember(ledger) { ledger.observe() }.collectAsStateWithLifecycle(emptyList())
    val owner = LocalLifecycleOwner.current
    val clock by produceState(localDay(), owner) {
        owner.lifecycle.repeatOnLifecycle(Lifecycle.State.STARTED) {
            while (true) {
                value = localDay()
                delay(30_000)
            }
        }
    }
    val (today, zone) = clock
    val snapshot = remember(entries, today, zone) { summarize(entries, today, zone) }
    val accounts = snapshot.accounts
    var page by rememberSaveable { mutableStateOf(Page.Home) }
    var editing by rememberSaveable { mutableStateOf<Editor?>(null) }
    var editingId by rememberSaveable { mutableStateOf<String?>(null) }
    var hidden by rememberSaveable { mutableStateOf(false) }
    val colors = MaterialTheme.colorScheme
    val openMovement: (MovementLine) -> Unit = {
        editingId = it.entry.id
        editing = Editor.EditMovement
    }

    Scaffold(
        containerColor = colors.background,
        bottomBar = {
            NavigationBar(containerColor = colors.surface) {
                Page.entries.forEach { destination ->
                    NavigationBarItem(
                        selected = page == destination, onClick = { page = destination },
                        icon = {
                            val icon = when (destination) {
                                Page.Home -> Icons.Outlined.Home
                                Page.Movements -> Icons.AutoMirrored.Outlined.List
                                Page.Accounts -> Icons.Outlined.AccountBox
                            }
                            Icon(icon, contentDescription = null)
                        },
                        label = { Text(destination.label) },
                        colors = NavigationBarItemDefaults.colors(indicatorColor = colors.primaryContainer)
                    )
                }
            }
        },
        floatingActionButton = {
            val account = page == Page.Accounts || accounts.isEmpty()
            FloatingActionButton(
                onClick = { editing = if (account) Editor.Account else Editor.NewMovement },
                containerColor = colors.primary, contentColor = colors.onPrimary
            ) { Icon(Icons.Outlined.Add, if (account) "Aggiungi conto" else "Aggiungi movimento") }
        }
    ) { insets ->
        LazyColumn(
            modifier = Modifier.padding(insets),
            contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 12.dp, bottom = 88.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            item {
                Text(if (page == Page.Home) "Bucktrail" else page.label, style = MaterialTheme.typography.headlineMedium)
            }
            if (page == Page.Home) {
                item {
                    val hero = if (isSystemInDarkTheme()) Color(0xFF1F2622) else Color(0xFF121614)
                    Card(colors = CardDefaults.cardColors(containerColor = hero, contentColor = Color(0xFFF1F3EF))) {
                        Column(Modifier.fillMaxWidth().padding(20.dp)) {
                            Text("Saldo attuale", color = Color(0xFFA9B2AC))
                            Text(
                                if (hidden) "•••• €" else euros(accounts.sumOf { it.cents }),
                                style = MaterialTheme.typography.displaySmall
                            )
                            if (snapshot.planned.any { it.date.year == today.year && it.date.month == today.month }) {
                                Text(
                                    "Saldo atteso a fine mese · " +
                                        if (hidden) "•••• €" else euros(snapshot.expectedBalance),
                                    color = Color(0xFFF2A65A)
                                )
                            }
                            TextButton(onClick = { hidden = !hidden }) {
                                Text(if (hidden) "Mostra importi" else "Oscura importi", color = Color(0xFF5FD19B))
                            }
                        }
                    }
                }
                item { Text("Conti", style = MaterialTheme.typography.titleMedium) }
            }
            if (page != Page.Movements) {
                if (accounts.isEmpty()) item { Text("Aggiungi il primo conto per iniziare.") }
                items(accounts, key = { it.id }) { RowItem(it.name, null, it.cents, hidden) }
            }
            if (page == Page.Home) item { Text("Ultimi movimenti", style = MaterialTheme.typography.titleMedium) }
            if (page == Page.Movements && snapshot.planned.isNotEmpty()) {
                item { Text("In arrivo", style = MaterialTheme.typography.titleMedium) }
                items(snapshot.planned, key = { it.entry.id }) { MovementRow(it, hidden, openMovement) }
                if (snapshot.booked.isNotEmpty()) item {
                    Text("Effettuati", style = MaterialTheme.typography.titleMedium)
                }
            }
            if (page != Page.Accounts) {
                if (snapshot.booked.isEmpty() && (page == Page.Home || snapshot.planned.isEmpty()))
                    item { Text("I movimenti effettuati compariranno qui.") }
                val visible = if (page == Page.Home) snapshot.booked.take(5) else snapshot.booked
                items(visible, key = { it.entry.id }) { MovementRow(it, hidden, openMovement) }
            }
        }
    }
    editing?.let { kind ->
        val original = if (kind == Editor.EditMovement)
            (snapshot.booked + snapshot.planned).firstOrNull { it.entry.id == editingId }
        else null
        if (kind != Editor.EditMovement || original != null) {
            EntryDialog(kind == Editor.Account, accounts, original, today, close = { editing = null }) { name, cents, accountId, date, planned ->
                if (kind == Editor.Account) ledger.insert(Account(name = name, openingCents = cents))
                else {
                    val movement = (original?.entry ?: Movement(accountId = checkNotNull(accountId), title = name, cents = cents))
                        .copy(accountId = checkNotNull(accountId), title = name, cents = cents, entryDay = date.toEpochDay(), planned = planned)
                    if (original == null) ledger.insert(movement) else ledger.update(movement)
                }
            }
        }
    }
}

@Composable
private fun MovementRow(row: MovementLine, hidden: Boolean, open: (MovementLine) -> Unit) {
    RowItem(
        row.entry.title, "${row.accountName} · ${row.date.format(entryDateFormat)}", row.entry.cents, hidden,
        planned = row.planned, onClick = { open(row) }
    )
}

@Composable
private fun RowItem(title: String, detail: String?, cents: Long, hidden: Boolean,
                    planned: Boolean = false, onClick: (() -> Unit)? = null) {
    val colors = MaterialTheme.colorScheme
    val rowModifier = if (onClick == null) Modifier else Modifier.clickable(onClick = onClick)
    Card(modifier = rowModifier, colors = CardDefaults.cardColors(containerColor = colors.surface)) {
        Row(Modifier.fillMaxWidth().padding(14.dp), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Column(Modifier.weight(1f)) {
                Text(title)
                detail?.let { Text(it, color = colors.onSurfaceVariant) }
            }
            Text(
                if (hidden) "•••• €" else euros(cents),
                color = when {
                    hidden || detail == null -> colors.onSurface
                    planned -> if (isSystemInDarkTheme()) Color(0xFFF2A65A) else Color(0xFF8A4A0C)
                    cents < 0 -> colors.error
                    else -> colors.primary
                }
            )
        }
    }
}

@Composable
private fun EntryDialog(account: Boolean, accounts: List<AccountBalance>, original: MovementLine?,
                        today: LocalDate, close: () -> Unit,
                        save: suspend (String, Long, String?, LocalDate, Boolean) -> Unit) {
    var name by rememberSaveable { mutableStateOf(original?.entry?.title.orEmpty()) }
    var raw by rememberSaveable {
        mutableStateOf(original?.entry?.let { BigDecimal.valueOf(it.cents, 2).abs().toPlainString().replace('.', ',') }.orEmpty())
    }
    var income by rememberSaveable { mutableStateOf((original?.entry?.cents ?: 0) > 0) }
    var chosenId by rememberSaveable { mutableStateOf(original?.entry?.accountId) }
    var date by rememberSaveable { mutableStateOf(original?.date ?: today) }
    var planned by rememberSaveable { mutableStateOf(original?.entry?.planned ?: false) }
    var saving by remember { mutableStateOf(false) }
    var failed by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    val chosen = accounts.firstOrNull { it.id == chosenId } ?: accounts.firstOrNull()
    val value = if (account && raw.isBlank()) 0L else parseCents(raw)
    val valid = value != null && (account || (value > 0 && chosen != null))

    AlertDialog(
        onDismissRequest = { if (!saving) close() },
        modifier = Modifier.systemBarsPadding().imePadding(),
        properties = DialogProperties(decorFitsSystemWindows = false),
        title = { Text(if (account) "Nuovo conto" else if (original == null) "Nuovo movimento" else "Modifica movimento") },
        text = {
            LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                if (!account) item {
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        FilterChip(selected = !income, onClick = { income = false }, label = { Text("Uscita") })
                        FilterChip(selected = income, onClick = { income = true }, label = { Text("Entrata") })
                    }
                }
                item {
                    OutlinedTextField(name, { name = it.take(80) }, singleLine = true,
                        label = { Text(if (account) "Nome del conto" else "Descrizione") })
                }
                item {
                    OutlinedTextField(raw, { raw = it.take(15) }, singleLine = true,
                        isError = raw.isNotBlank() && !valid,
                        keyboardOptions = KeyboardOptions(keyboardType = if (account) KeyboardType.Text else KeyboardType.Decimal),
                        supportingText = if (raw.isNotBlank() && !valid) {
                            { Text(if (account) "Usa al massimo due decimali." else "Inserisci un importo positivo con al massimo due decimali.") }
                        } else null,
                        label = { Text(if (account) "Saldo iniziale (€)" else "Importo (€)") })
                }
                if (!account) item {
                    TextButton(onClick = {
                        DatePickerDialog(context, { _, year, month, day ->
                            date = LocalDate.of(year, month + 1, day)
                        }, date.year, date.monthValue - 1, date.dayOfMonth).show()
                    }) { Text("Data · ${date.format(entryDateFormat)}") }
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                        Text("Pianificato")
                        Switch(checked = planned || date > today, enabled = date <= today && !saving,
                            modifier = Modifier.semantics { contentDescription = "Pianificato" },
                            onCheckedChange = { planned = it })
                    }
                    if (date > today) Text("Le date future restano tra i movimenti pianificati.")
                }
                if (!account) items(accounts, key = { it.id }) {
                    FilterChip(selected = chosen?.id == it.id, onClick = { chosenId = it.id }, label = { Text(it.name) })
                }
                if (failed) item { Text("Impossibile salvare. Riprova.", color = MaterialTheme.colorScheme.error) }
            }
        },
        dismissButton = { TextButton(onClick = close, enabled = !saving) { Text("Annulla") } },
        confirmButton = {
            TextButton(enabled = !saving && valid && name.isNotBlank(), onClick = {
                if (saving) return@TextButton
                val cents = checkNotNull(value)
                saving = true
                scope.launch {
                    try {
                        save(name.trim(), if (account || income) cents else -cents, chosen?.id, date, planned || date > today)
                        close()
                    } catch (_: SQLiteException) {
                        failed = true
                    } finally {
                        saving = false
                    }
                }
            }) { Text("Salva") }
        }
    )
}
