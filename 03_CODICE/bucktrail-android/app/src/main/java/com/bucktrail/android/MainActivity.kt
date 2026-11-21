package com.bucktrail.android

import android.app.Application
import android.database.sqlite.SQLiteException
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.isSystemInDarkTheme
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
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.DialogProperties
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.room.Room
import kotlinx.coroutines.launch

class BucktrailApplication : Application() {
    val ledger by lazy {
        Room.databaseBuilder(applicationContext, BucktrailDatabase::class.java, "bucktrail.db").build().ledger()
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

@Composable
private fun Bucktrail(ledger: Ledger) {
    val accounts by remember(ledger) { ledger.balances() }.collectAsStateWithLifecycle(emptyList())
    val movements by remember(ledger) { ledger.movements() }.collectAsStateWithLifecycle(emptyList())
    var page by rememberSaveable { mutableStateOf(Page.Home) }
    var editing by rememberSaveable { mutableStateOf<String?>(null) }
    var hidden by rememberSaveable { mutableStateOf(false) }
    val colors = MaterialTheme.colorScheme

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
                onClick = { editing = if (account) "account" else "movement" },
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
            if (page != Page.Accounts) {
                if (movements.isEmpty()) item { Text("I movimenti registrati compariranno qui.") }
                items(if (page == Page.Home) movements.take(5) else movements, key = { it.id }) {
                    RowItem(it.title, it.accountName, it.cents, hidden)
                }
            }
        }
    }
    editing?.let { kind ->
        EntryDialog(kind == "account", accounts, close = { editing = null }) { name, cents, accountId ->
            if (kind == "account") ledger.insert(Account(name = name, openingCents = cents))
            else ledger.insert(Movement(accountId = checkNotNull(accountId), title = name, cents = cents))
        }
    }
}

@Composable
private fun RowItem(title: String, detail: String?, cents: Long, hidden: Boolean) {
    val colors = MaterialTheme.colorScheme
    Card(colors = CardDefaults.cardColors(containerColor = colors.surface)) {
        Row(Modifier.fillMaxWidth().padding(14.dp), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Column(Modifier.weight(1f)) {
                Text(title)
                detail?.let { Text(it, color = colors.onSurfaceVariant) }
            }
            Text(
                if (hidden) "•••• €" else euros(cents),
                color = when {
                    hidden || detail == null -> colors.onSurface
                    cents < 0 -> colors.error
                    else -> colors.primary
                }
            )
        }
    }
}

@Composable
private fun EntryDialog(account: Boolean, accounts: List<AccountBalance>, close: () -> Unit,
                        save: suspend (String, Long, String?) -> Unit) {
    var name by rememberSaveable { mutableStateOf("") }
    var raw by rememberSaveable { mutableStateOf("") }
    var income by rememberSaveable { mutableStateOf(false) }
    var chosenId by rememberSaveable { mutableStateOf<String?>(null) }
    var saving by remember { mutableStateOf(false) }
    var failed by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    val chosen = accounts.firstOrNull { it.id == chosenId } ?: accounts.firstOrNull()
    val value = if (account && raw.isBlank()) 0L else parseCents(raw)
    val valid = value != null && (account || (value > 0 && chosen != null))

    AlertDialog(
        onDismissRequest = { if (!saving) close() },
        modifier = Modifier.systemBarsPadding().imePadding(),
        properties = DialogProperties(decorFitsSystemWindows = false),
        title = { Text(if (account) "Nuovo conto" else "Nuovo movimento") },
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
                        save(name.trim(), if (account || income) cents else -cents, chosen?.id)
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
