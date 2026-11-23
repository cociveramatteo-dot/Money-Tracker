# Parità Android ↔ iOS — inventario e checklist

> Specifica e checklist per i costruttori Android. **Fonte di verità = codice iOS al ramo `redesign-sentiero` (commit 38fe495)**, letto il 2026-11-23, più `02_RISORSE/originali/bucktrail-redesign/` (DESIGN_HANDOFF + mockup `reference/*.dc.html`, che contengono i valori CSS esatti di padding/gap: aprirli nel browser per ogni schermata).
> Dove il codice iOS e l'handoff divergono vale **il codice** (è ciò che Matteo vede). Dove non sono sicuro: `[DA VERIFICARE]`. Segnalo come `⚠ quirk` i comportamenti iOS strani: sono elencati in §4.99, vanno decisi con Matteo prima di replicarli.
> Percorsi iOS abbreviati: `V/` = `MoneyTracker/Views/`, `D/` = `MoneyTracker/Domain/`. Android = `03_CODICE/bucktrail-android` (app/src/main/java/com/bucktrail/android: solo `MainActivity.kt` 345 righe e `Ledger.kt` 137 righe, 2 test JVM).
> Obiettivo di Matteo: Android **identica** a iOS per grafica e funzioni.

Indice: 1 Token grafici · 2 Modello dati · 3 Logica di dominio · 4 Schermate · 5 Auth/Sync/Intents/Notifiche/Export · 6 Localizzazione · 7 Checklist F-xxx · 8 Blocchi di costruzione.

---

## 1. Token grafici

### 1.1 Colori (hex, light / dark) — `V/Theme.swift` `DS`
Tema = segue il sistema (mai scelta manuale, mai colori fissi). Android: `lightColorScheme/darkColorScheme` **non bastano** (servono ~25 token): creare un oggetto `BucktrailColors` in `CompositionLocal`.

| Token iOS | Light | Dark | Uso |
|---|---|---|---|
| `ink` | #121614 | #F1F3EF | testo primario, pulsante primario, chip attivo |
| `paper` (bg) | #F3F4EF | #0E1210 | sfondo schermata |
| `surface` | #FFFFFF | #171C19 | card, liste, tab bar, sheet |
| `fog` (border/riempimenti neutri) | #DCDFD8 | #2A332E | bordi, track segmented, chip contorno, campi login |
| `filterBorder` | #B9BFB6 | #2A332E | bordo tratteggiato chip secondari / riga «Archiviati» |
| `smoke` (inkSecondary) | #5B635E | #9AA39D | testo secondario |
| `divider` | #ECEEE9 | #232A26 | separatori riga, track progress bar |
| `accent` | #1F7A4D | #5FD19B | entrate, FAB, link, progress OK |
| `onAccent` | #FFFFFF | #0E1210 | testo/icona su accent |
| `accentSoft` | #DDEEE3 | #1C2E25 | pill tab attiva, badge OK, chip filtro avanzato attivo |
| `planned` | #B45309 | #F2A65A | pianificato, soglia 80%, bordo tratteggiato icona |
| `plannedText` | #8A4A0C | #F2A65A | testo ambra (< 18pt) |
| `plannedSoft` | #FBEBDD | #3A2A16 | badge soglia, banner demo |
| `danger` (= `negative`) | #B42318 | #F26B5E | sforato, importi negativi |
| `dangerSoft` | #FBE4E1 | #3A1D1A | badge sforato |
| `transfer` | #2F6FB0 | #6FA8E0 | trasferimenti |
| `positive` | = accent | = accent | alias |
| `hero` | #121614 | #1F2622 | card scura (scura in entrambi i temi) |
| `heroText` | #FFFFFF | #F1F3EF | |
| `heroSecondary` | #A9B2AC | #A9B2AC | |
| `heroDivider` | #2A322D | #323B35 | separatori e track su hero |
| `heroAccent` | #5FD19B | #5FD19B | verde su hero |
| `heroPlanned` | #F2A65A | #F2A65A | ambra su hero |

`signColor(x)`: >0 positive, <0 negative, 0 ink.
**Tinte categoria** (`V/CategoryTint.swift`): sfondo/icona — green `#E3EFE7/#1F7A4D` (dark `#1C2E25/#5FD19B`), amber `#FBEBDD/#8A4A0C` (dark `#3A2A16/#F2A65A`), blue `#E4ECF6/#2F6FB0` (dark `#1B2A3B/#6FA8E0`), violet `#ECE8F6/#5A4AA3` (dark `#2A2540/#A99BE0`).
Mappa fissa: Cibo=amber, Trasporti=blue, Svago=violet, Shopping=amber, Salute=green, Casa=blue, Abbonamenti=violet, Lavoro=green, Istruzione=violet, Viaggi=blue, Regali=amber, Giroconto=blue, Risparmio=green, Altro=green. Altre categorie: indice = **FNV-1a 32 bit** (offset 2166136261, prime 16777619, byte UTF-8 del nome) `% 4` su ordine [green, amber, blue, violet]. (Test iOS: `CategoryTintTests`.) «Rettifica saldo» → hash.
Tinte per tipo conto (riga in Conti, `AccountsView`): contanti/investimento=violet, carta=amber, conto=green, risparmio=blue. Colore pallino conto in Home: conto=accent, risparmio=transfer, carta=planned, contanti=smoke, investimento=ink.

### 1.2 Tipografia
Font nel bundle iOS (`MoneyTracker/Resources/Fonts/`, OFL): SpaceGrotesk Medium/SemiBold/Bold, Inter 18pt Regular/Medium/SemiBold. **Android ha solo `space_grotesk_bold.ttf` e `inter_regular.ttf`** → copiare gli altri 4 (licenze OFL già in `assets/licenses`). Tutti gli importi con cifre tabulari (`fontFeatureSettings="tnum"`). I testi seguono il font scale di sistema (sp); il layout «accessibility size» di iOS (MovementRow verticale, chip/righe che vanno a capo) ≈ `fontScale ≥ 1.5` `[DA VERIFICARE]`.

| Ruolo `DS.Typo` | Font | Size / peso | Note |
|---|---|---|---|
| screenTitle | Space Grotesk Bold | 30 | tracking −0.6pt (−2%) |
| wordmark | Space Grotesk Bold | 26 | tracking −0.5 in Home |
| heroAmount | Space Grotesk SemiBold | 44 | tracking −1.32pt (−3%), tabular |
| heroAmountSm | Space Grotesk SemiBold | 38 | solo Conti, tracking −1.14 |
| sectionTitle | Space Grotesk SemiBold | 18 | |
| rowName | Inter Medium | 15 | |
| rowAmount | Inter SemiBold | 15 | tabular |
| secondary | Inter Regular | 13 | |
| caption | Inter Regular | 12 | |
| tabLabel / tabLabelActive | Inter Medium / SemiBold | 11 | |

**Schermate-form e sheet NON usano i font Sentiero**: usano il font di sistema (SF Pro) con dimensioni fisse: titolo sheet `28 semibold`; importo `56 black` con simbolo `28 ultraLight` (prefisso `−€`/`+€`); descrizione `22 light`; note `15 light`; label sezione `SectionLabel` = 11 semibold MAIUSCOLO, tracking 1.2, colore smoke; valore secondario riga opzione `15` + sottotitolo `11` smoke; PrimaryButton `17 semibold`; GhostButton `15`; EmptyState titolo `17 medium` / sottotitolo `13` / CTA `15 medium` sottolineato. Settings, Auth, Lock, BudgetHistory, Categorie, AuditLog sono in questo stile (SF). **Decisione per l'architetto**: su Android SF non esiste → usare Inter (variabile, OFL, pesi 100–900) per questi stili così da avere ultraLight/light/black; la gerarchia dimensione/peso resta quella sopra. `[DA VERIFICARE]` con Matteo che vada bene.

### 1.3 Spaziature e misure (`DS.Space`, `DS.Layout`)
`xs 4 · s 8 · m 12 · l 16 · xl 24 · xxl 36`. Margine schermata 20 (header e titoli) / 16 (card e liste). `rowVPad 14`, `buttonHeight 52`, `buttonRadius 14`, `cardRadius 16`.

| Elemento | Misura |
|---|---|
| Hero card Home | raggio 26, padding 20/20/16 (top/lato/bottom) |
| Hero card Conti / Pianifica / `HeroCard` | raggio 24, padding 24 |
| Card (Card.swift, FixedTotalTile 12) | raggio 16 (`cardRadius`), padding 16 |
| Card account Home | larghezza **148**, raggio 18, padding h14 v12, gap 8 |
| Card budget/obiettivo/serie (`Planning*`, `RecurringSeriesCard`, `ProgrammedRuleCard`) | raggio 18, padding h16 v14; serie: bordo `fog` |
| Lista «Ultimi movimenti» Home | raggio 20 (card unica con separatori `divider`), margini 16 |
| Gruppi Movimenti | card per giorno raggio 18 (primo/ultimo raggio solo agli estremi), margini 16, spazio sezioni 12 |
| Card «Per categoria» Statistiche | raggio 22, padding 16 |
| Tile Uscite/Entrate/Netto | raggio 16, Netto sfondo `hero` |
| Icona riga (MovementRow/serie) | quadrato **38×38**, raggio 12 (`Space.m`); pianificato: niente fill, bordo 1pt tratteggiato [3,3] `planned` |
| Icona riga Conti | 38×38 raggio 13; icona Obiettivo 42×42 raggio 14 |
| Pulsanti icona (header, +, filtri) | 44×44, raggio 14, bordo `fog` 1pt, sfondo `surface` |
| Campo ricerca | h min 46, raggio 16, bordo `fog`, padding h20 |
| Chip tipo Movimenti | raggio 12, h 34, padding h14, attivo fill `ink` testo `surface` SemiBold, inattivo `surface`+bordo `fog` |
| Chip secondari (mese/categoria) | raggio 10, h 32, padding h12, bordo tratteggiato [3,3] `filterBorder`; categoria attiva: fill `accentSoft`, testo `accent` SemiBold, senza bordo |
| `FilterChip` (pagina Ricorrenti) | capsula, h min 44, padding h16; style secondary = bordo tratteggiato |
| SegmentedPill | track `fog` capsula padding 4, segmento attivo `surface` + ombra (ink 8%, r3, y1), h min 44 |
| Tab bar flottante | capsula raggio 24, **h 66**, margini orizzontali 14, offset dal fondo 20, sfondo `surface`, ombra `ink` 10% raggio 14 y8; pill attiva 44×28 `accentSoft`; icona 17 (semibold se attiva); label 11; area riservata ai contenuti = 66+20+8 = 94 |
| FAB | **58×58, raggio 20 (squircle)**, `accent`, `+` 24 semibold `onAccent`, ombra accent 35% r12 y6; trailing 22, bottom 100 |
| ProgressBar | h 8 capsula, track `divider` (su hero `heroDivider`), riempimento colore stato; su hero tacca bianca 2pt all'80% |
| Anello obiettivi | cerchio 74 (+5 padding), stroke 10 round, `heroAccent` su `heroDivider`, parte da ore 12 |
| Barre statistica per categoria | h 6 capsula, track `divider`, riempimento = tinta cat, larghezza relativa alla categoria massima |
| Grafico Andamento | h 130, barre larghezza 65% raggio 4, asse Y nascosto |
| Badge conteggio filtri | cerchio min 18, `accent`, testo `onAccent` 11 semibold, offset (+6,−6) |
| Touch target minimo | 44×44 |

**Ombre**: tab bar `ink@10% r14 y8`; FAB `accent@35% r12 y6` (applicata fuori dall'etichetta); segmented attivo sopra; banner sync `black@14% r5 y2`; banner demo `ink@12% r6 y2`. Su Android (minSdk 26) usare `Modifier.shadow(ambientColor/spotColor)` (API 28+) o `drawBehind` con `BlurMaskFilter` per < 28.
**Stato selezione/animazioni**: spring (response .25–.4, damping .7–.8) per spunta, FAB, segmented; fade .2s per lock; haptic: `soft`=conferma/modifica, `medium`=elimina/FAB/azioni distruttive, `success` non usato nei flussi → `HapticFeedbackConstants` (CONTEXT_CLICK / CONFIRM / LONG_PRESS).

### 1.4 Componenti riutilizzabili (Compose)
`Card`, `HeroCard`, `HomeHeroCard`, `TrailView`, `MovementRow`, `ProgressBar`, `BudgetStatus`, `SegmentedPill`, `FilterChip`, `FloatingTabBar`, `FabButton`(+menu), `EmptyStateView`, `SectionLabel`, `ThinDivider`(0.5pt `fog`), `PrimaryButton`/`GhostButton`, `UnderlineSegment` (Uscita/Entrata: testo 15 semibold ink / regular smoke + riga 1.5pt ink sotto), `MonthBar` (‹ mese anno ›, chevron 14 medium smoke, mese `rowName`), `FixedTotalTile`, `FixedExpenseRow`(non più usata in Home), `RecurringSeriesCard`, `ProgrammedRuleCard`, `VirtualOccurrenceRow`, `PlanningBudgetCard`, `PlanningGoalCard`, `PlanningProgressRing`, `AccountRow`, `HeroAmount`(legacy 56 black), `CategoryRow`, `SyncBanner`, `DemoBanner`, `LockOverlay`.

Dettagli di comportamento:
- **MovementRow**: `kind` expense/income/transfer. Colore importo: pianificato=`plannedText`; expense=`ink`; income=`accent`; transfer=`transfer`. Segno: `−`/`+`/nessuno (U+2212). Icona: transfer = `arrow.left.arrow.right` blu; altrimenti simbolo categoria in tinta; pianificato: icona `plannedText` con bordo tratteggiato. Titolo `rowName` + icona `repeat` caption smoke se la riga appartiene a una serie. Riga compatta (Movimenti) padding v10 invece di 14. Importo `fixedSize`, priorità layout alta, 1 riga. Layout accessibilità: colonna (titolo / metadata / importo a destra).
- **BudgetStatus** (badge): progress ≥1 → «Sforato» (danger su dangerSoft); ≥0.8 → «Soglia 80%» (plannedText su plannedSoft); altrimenti «NN%» (accent su accentSoft). Badge capsula padding h8 v4, caption. Colore barra: ≥1 danger, ≥0.8 planned, altrimenti accent. NB: il `progress` passato dalle card è già clampato a 1.0.
- **EmptyStateView**: icona SF 40 ultraLight `fog`, titolo, sottotitolo, CTA opzionale sottolineata; padding h40 v36; centrato.
- **Banner sync**: capsula `ink@85%`, testo `paper` 11 medium, icona 10 semibold o spinner 0.65, in alto (padding top 8). Stati: syncing «Sincronizzazione…», waitingForRetry «Sincronizzazione in sospeso» (icona `clock.arrow.circlepath`), offline «Offline — riprenderà automaticamente» (icona `wifi.slash`); idle = nascosto; mai rosso, mai alert. Non cliccabile.
- **Banner demo**: capsula `plannedSoft`, testo `plannedText`, icona `eye.fill` 10 bold + «MODALITÀ DEMO» monospaced 11 bold kerning 0.5; riserva l'altezza sopra il contenuto.

### 1.5 Icone (SF Symbols → Android)
I nomi SF Symbol **sono dati salvati** (`Category.icon`, `Transaction.categoryIcon`, `Budget.categoryIcon`, `Goal.emoji`, `RecurringRule.categoryIcon`) e viaggiano su Supabase: Android deve **conservare la stringa SF** e mapparla a un vettore per la visualizzazione (Material Symbols Rounded/Outlined consigliato). Se un nome è sconosciuto → `circle.dotted`.
Selettore categorie (`DS.availableIcons`, 48): `fork.knife`→restaurant · `cup.and.saucer.fill`→local_cafe · `cart.fill`→shopping_cart · `bag.fill`→shopping_bag · `takeoutbag.and.cup.and.straw.fill`→takeout_dining · `wineglass.fill`→wine_bar · `car.fill`→directions_car · `airplane`→flight · `tram.fill`→tram · `ferry.fill`→directions_boat · `bicycle`→pedal_bike · `fuelpump.fill`→local_gas_station · `house.fill`→home · `bolt.fill`→bolt · `drop.fill`→water_drop · `flame.fill`→local_fire_department · `wifi`→wifi · `phone.fill`→call · `heart.fill`→favorite · `cross.fill`→add_box/medical_services · `dumbbell.fill`→fitness_center · `figure.run`→directions_run · `stethoscope`→stethoscope · `pills.fill`→medication · `gamecontroller.fill`→sports_esports · `film.fill`→movie · `music.note`→music_note · `book.fill`→menu_book · `theatermasks.fill`→theater_comedy · `ticket.fill`→confirmation_number · `briefcase.fill`→work · `laptopcomputer`→laptop_mac · `graduationcap.fill`→school · `pencil.and.ruler.fill`→architecture · `doc.fill`→description · `printer.fill`→print · `tshirt.fill`→checkroom · `shoe.fill`→(custom vector) · `eyeglasses`→eyeglasses · `crown.fill`→(custom/workspace_premium) · `sparkles`→auto_awesome · `scissors`→content_cut · `eurosign.circle.fill`→euro · `creditcard.fill`→credit_card · `gift.fill`→redeem · `arrow.left.arrow.right`→swap_horiz · `repeat.circle.fill`→autorenew · `circle.dotted`→(custom cerchio tratteggiato).
Altre categorie/icone dati: `banknote`→payments · `tray.fill`→inbox · `arrow.triangle.2.circlepath`→sync (Rettifica saldo) · `target`→track_changes · `building.columns.fill`→account_balance.
Icone obiettivo (36, `GoalsView.goalIcons`): target, `trophy.fill`→emoji_events, `star.fill`, `flag.fill`, crown, `rosette`→military_tech, house, car, airplane, tram, bicycle, `figure.walk`→directions_walk, eurosign.circle, creditcard, banknote, `chart.line.uptrend.xyaxis`→trending_up, building.columns, cart, graduationcap, book, laptopcomputer, `iphone`→smartphone, `headphones`, `paintbrush.fill`→brush, heart, figure.run, dumbbell, `leaf.fill`→eco, fork.knife, `bed.double.fill`→bed, gift, `pawprint.fill`→pets, sparkles, `camera.fill`→photo_camera, music.note, `map.fill`→map. (Un valore non-ASCII in `Goal.emoji` = vera emoji legacy: mostrata come testo nel quadrato della card; nell'editor ricade su `target`.)
Icone UI: tab `house`/`list.bullet`/`chart.bar`/`scope`/`creditcard` → home / format_list_bulleted / bar_chart / adjust (o my_location) / credit_card; `eye`/`eye.slash`→visibility/_off; `gearshape`→settings; `magnifyingglass`→search; `line.3.horizontal.decrease`→filter_list; `slider.horizontal.3`→tune; `plus`, `xmark`, `chevron.*`, `checkmark`; `clock`; `repeat`→repeat; `trash`; `pencil`; `archivebox`→archive; `arrow.uturn.left`→undo; `square.and.arrow.down/up`→download/share; `lock.fill`; `wifi.slash`→wifi_off; `clock.arrow.circlepath`→history; `envelope.badge.checkmark.fill`→mark_email_read; `info.circle.fill`; `lightbulb.fill`; `chart.pie.fill` (logo login/splash)→pie_chart.
Icone tipo conto (`AccountRow`): contanti `banknote`, carta `creditcard`, conto `building.columns`, risparmio `tray.full`→inventory_2, investimento `chart.line.uptrend.xyaxis`. Emoji tipo conto (solo Shortcut «saldo»): 💵 💳 🏦 🐷 📈.

---

## 2. Modello dati (SwiftData SchemaV3 → Room)

Tutte le entità hanno `id: UUID`. Store iOS: `default.store` (reale, nel container App Group) e `demo.store` (demo, separato). **Importi: `Decimal`** (sempre a 2 decimali per input utente; `parseAmount` arrotonda `.plain` a 2). Tutte le date: `Date` (istante); le occorrenze ricorrenti sono ancorate alle **12:00 locali** del giorno.

### 2.1 Entità
| Entità | Campi (tipo, default) | Relazioni |
|---|---|---|
| **Account** | id UUID · name String · type String (raw `AccountType`) · initialBalance Decimal (0) · colorHex String ("000000", non usato in UI) · createdAt Date · isArchived Bool (false) · isExcludedFromTotal Bool (false) | `transactions` (cascade, inverse `Transaction.account`), `budgets` (cascade, inverse `Budget.account`) |
| **Transaction** | id · name · amount Decimal (**sempre positivo**) · type String (`"Uscita"`/`"Entrata"`) · category String (nome, testo libero) · categoryIcon String (SF) · date Date · isDone Bool (true; false = pianificato) · isFixed Bool (false) · isTransfer Bool (false) · transferGroupId String ("" ) · notes String · recurringFrequency String ("" legacy; `settimanale/mensile/annuale`) · templateId String ("" = non da serie; altrimenti **UUID della RecurringRule, maiuscolo**) · createdAt Date | `account: Account?` |
| **Budget** | id · category String (`"Tutti"` oppure nomi separati da `,` **ordinati alfabeticamente**) · categoryIcon String ("circle.dotted") · monthlyLimit Decimal · month Int · year Int · createdAt | `account: Account?` (nullify) |
| **Goal** | id · name · emoji String (**nome SF Symbol**, default "target") · targetAmount · currentAmount Decimal (0) · deadline Date? · isCompleted Bool (false) · createdAt | — |
| **Category** | id · name · icon (SF) · isDefault Bool · sortOrder Int · createdAt | **non sincronizzata** |
| **RecurringRule** | id · name · type String · category · categoryIcon · notes · amount Decimal · isFixed Bool · accountId UUID? (**non** relazione) · frequency String · startDate Date (12:00) · endDate Date? (12:00, inclusivo) · exceptionsJSON String ("{}") · materializedThrough Date? · createdAt | — |

Enum: `TransactionType` raw `"Uscita"`, `"Entrata"` (maiuscola iniziale; localizzati solo in visualizzazione). `AccountType` raw `"Contanti"`, `"Carta"`, `"Conto Bancario"`, `"Risparmio"`, `"Investimento"` (default `conto` se sconosciuto; ordine in editor = ordine dichiarazione). Frequenze: stringhe minuscole `settimanale|mensile|annuale` (+ `irregolare` solo dal detector).

**Categorie predefinite** (seed se tabella vuota; per utenti esistenti si aggiungono le mancanti e si riallineano le icone; `isDefault=true`, non modificabili/eliminabili): Cibo `fork.knife` 0 · Trasporti `car.fill` 1 · Svago `gamecontroller.fill` 2 · Shopping `bag.fill` 3 · Salute `heart.fill` 4 · Casa `house.fill` 5 · Abbonamenti `repeat.circle.fill` 6 · Lavoro `briefcase.fill` 7 · Istruzione `book.fill` 8 · Viaggi `airplane` 9 · Regali `gift.fill` 10 · Risparmio `banknote` 11 · Giroconto `arrow.left.arrow.right` 12 · Altro `tray.fill` 13 · Rettifica saldo `arrow.triangle.2.circlepath` 14. Nomi canonici **in italiano** salvati nel DB; mostrati localizzati se nel set `defaultCategoryNames` (14, **senza** «Rettifica saldo»), altrimenti testo grezzo. Fallback icona per nome (`DS.categoryIcon(for:)`): mappa dei 14 sopra (Altro=`tray.fill`, Risparmio=`banknote`), default `circle.dotted`.

### 2.2 Proposta Room v3 (migrazione dal v2 attuale)
Android oggi: `Account(id String, name, openingCents Long)` e `Movement(id, accountId FK RESTRICT, title, cents Long con segno, recordedAt, entryDay Long?, planned)`. Divergenze da sanare con **migrazione 2→3** (script `Migration(2,3)` + test su `schemas/…/2.json`):

```kotlin
// importi: BigDecimal nel dominio, Long "centesimi" nelle colonne (scala 2, come parseAmount)
@Entity(tableName="accounts") data class AccountEntity(
  @PrimaryKey val id: String /*UUID lowercase interno*/, val name: String, val type: String /*"Conto Bancario"…*/,
  val initialBalanceCents: Long, val colorHex: String = "000000", val createdAt: Long,
  val isArchived: Boolean = false, val isExcludedFromTotal: Boolean = false)
@Entity(tableName="transactions", foreignKeys=[FK(AccountEntity, accountId, onDelete=CASCADE /*iOS: cascade dal conto*/)], indices=[accountId, date, templateId, transferGroupId])
data class TransactionEntity(@PrimaryKey val id: String, val accountId: String?, val name: String,
  val amountCents: Long /*>0*/, val type: String /*"Uscita"|"Entrata"*/, val category: String, val categoryIcon: String,
  val date: Long /*epoch ms, istante*/, val isDone: Boolean = true, val isFixed: Boolean = false, val isTransfer: Boolean = false,
  val transferGroupId: String = "", val notes: String = "", val recurringFrequency: String = "", val templateId: String = "", val createdAt: Long)
@Entity(tableName="budgets") data class BudgetEntity(id, accountId?, category, categoryIcon, monthlyLimitCents, month, year, createdAt) // FK account SET_NULL? iOS: nullify ma account cascade elimina i budget del conto → CASCADE
@Entity(tableName="goals") data class GoalEntity(id, name, emoji, targetCents, currentCents, deadline: Long?, isCompleted, createdAt)
@Entity(tableName="categories") data class CategoryEntity(id, name, icon, isDefault, sortOrder, createdAt)
@Entity(tableName="recurring_rules") data class RecurringRuleEntity(id, name, type, category, categoryIcon, notes, amountCents, isFixed, accountId: String? /*no FK*/, frequency, startDate: Long, endDate: Long?, exceptionsJson: String="{}", materializedThrough: Long?, createdAt)
```
Migrazione dati Android esistenti: `cents` con segno → `type` (cents<0 Uscita, ≥0 Entrata) + `amountCents=abs`; `planned` → `isDone = !planned` (le righe future erano «pianificate per data»: lasciare `isDone=false` se `entryDay > oggi` alla migrazione); `entryDay` (giorno) → `date` = 12:00 locale di quel giorno; `title`→`name`; `category="Altro"`/`categoryIcon="tray.fill"`; `openingCents`→`initialBalanceCents`, `type="Conto Bancario"`; FK `RESTRICT`→`CASCADE`. **Attenzione**: Android oggi considera «pianificato» anche `entryDay > oggi` con `planned=false` (derivato), iOS no: lì `isDone` è esplicito e una data futura con `isDone=true` è possibile (non succede dall'UI, ma succede dai pull). Allineare a iOS: pianificato ⇔ `!isDone`; l'UI di inserimento con data futura deve proporre `isDone=false` (vedi §4.4).
Decisione per l'architetto: `BigDecimal`+TEXT (come Decimal) vs `Long` cents. Consiglio **Long cents** nelle colonne (SUM in SQL, indici) e `BigDecimal.movePointLeft(2)` ai bordi; i soli importi non a 2 decimali possibili sono quelli arrivati da override JSON (`"112.40"`) e da Supabase `numeric`: al pull arrotondare `HALF_UP` a 2 `[DA VERIFICARE se esistono importi >2 decimali sul cloud]`.
**Preferenze locali** (UserDefaults → DataStore Preferences; non sincronizzate): `currencyCode`="EUR", `notificationsEnabled`=true (se assente al primo avvio → chiede permesso), `monthlyReportEnabled`=false, `demoModeEnabled`=false, `appLockEnabled`=false, `hideBalance`=false, `homeAccountOrderedShown`="" (UUID separati da virgola), `showFixedExpensesTotal`=true, `showFixedIncomeTotal`=true, `txFilterMin`/`txFilterMax`="" (stringhe grezze), `txFilterUseDates`=false, `balanceThreshold_<accountId>` (stringa `fixedFractionString`, "0.00"=disattivo), `demoSeedVersion` (6), chiavi sync (`syncService.lastPull`, `.lastUserId`, `.hasPendingChanges`, `.dirtyTransactionIds` JSON Set<UUID>).
**Audit log**: file append-only `audit-log.jsonl` (una riga JSON per evento `{id, timestamp, entityType, action, summary}`), vedi §4.15.
**Seed categoria**: all'avvio del container reale e demo. **Pulizia al logout**: cancella Transaction, RecurringRule, Budget, Goal, Account (non Category), lastPull, audit log.

---

## 3. Logica di dominio da portare identica

Regola: portare le funzioni **pure** in un modulo Kotlin senza Android (`domain/`), con test JUnit che replicano i test iOS in `MoneyTrackerTests/` (AccountBalance, BalanceTrail, CategoryTint, CurrencyFormatting, DaysRemainingPlural, KeywordCategoryClassifier, LastUsedCategory, RecurrenceCalculator, RecurringCollision, RecurringDecimalRoundTrip, RecurringMaterializer, RecurringSeriesEditor, RecurringRuleSync, StrictAmountParsing, StrictRecurrenceAmount, DemoDataSeeder). Usare quei file come vettori di test (copiare i valori attesi).

### 3.1 Importi e valuta (`Formatting/`)
- `parseAmount(raw)`: sostituisce `,`→`.`; accetta **solo** regex `^[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)$` (tutta la stringa); poi arrotonda a 2 decimali `.plain` (= HALF_UP lontano da zero). Altrimenti `null`. Limiti UI: importo valido se `0 < v ≤ 1_000_000_000`. Android oggi: regex diversa (max 10 cifre intere, max 2 decimali, rifiuta più decimali): **sostituire**.
- `editableString`: intero senza decimali ("50"), altrimenti max 2 decimali, **punto** come separatore, senza raggruppamento. `fixedFractionString`: sempre 2 decimali, punto, senza raggruppamento (CSV, soglie, audit).
- `Decimal(roundedFromDouble:)` (Intent): da `String.format("%.2f")` locale POSIX.
- Valuta: `currencyCode` in prefs (default EUR). `currencyFormatted` = `NumberFormat` currency con `currencyCode` scelto e **locale di sistema** (⇒ simbolo e posizione dipendono dal locale; es. it «1.250,00 €»). Android: `NumberFormat.getCurrencyInstance(Locale.getDefault()).apply{currency=Currency.getInstance(code)}`. `Double.currencySymbol` = simbolo di quel formatter (usato nei prefissi dei campi importo). Elenco selezionabile (15): EUR €, USD $, GBP £, CHF ₣, JPY ¥, CAD CA$, AUD A$, SEK kr, NOK kr, DKK kr, PLN zł, RON lei, HRK kn, CZK Kč, HUF Ft; etichetta menu = `simbolo  + nome localizzato della valuta`. Cambio valuta: **solo simbolo**, importi invariati, con sheet di conferma (§4.14). Android oggi: hardcoded `Locale.ITALY`.
- Oscuramento: Home usa `"•••• €"` (letterale, anche con altra valuta); Conti/`HeroAmount`/`FixedTotalTile`/`AccountRow` usano `"• • •"`. `[⚠ quirk, vedi 4.99 #6]`.
- Date: `dayMonthFormatted`: «Oggi»/«Ieri»/`d MMM` (locale); `monthYearFormatted`: `MMMM yyyy` **capitalizzato** («Novembre 2026»); `shortMonthFormatted`: prime 3 lettere capitalizzate del mese breve; CSV `dd/MM/yyyy`; intestazione Home `weekday(.wide) day month(.wide)`; confronti «stesso mese/settimana/anno» sul calendario corrente.

### 3.2 Saldo (`AccountBalanceCache`)
`signedAmount = (Entrata ? +amount : −amount)`.
`currentBalance(account) = initialBalance + Σ signedAmount di transazioni con isDone`.
`futureBalance = initialBalance + Σ signedAmount di TUTTE` (incluse pianificate di qualsiasi mese). `plannedDelta = future − current`.
I trasferimenti partecipano al saldo dei due conti (due gambe, una Uscita e una Entrata) ma **non** a totali Uscite/Entrate, statistiche, budget, subtotali giorno, PDF totali.
Totale Home/Conti = Σ `currentBalance` dei conti **non archiviati e non esclusi**; Conti mostra anche Σ `futureBalance` («A conti fatti»). Cache invalidata a ogni salvataggio (in Android: query reattive Room, nessuna cache necessaria; attenzione alle performance con `SUM`).

### 3.3 «Saldo atteso» e curva (BalanceTrail, `D/BalanceTrail.swift`) — competenza mensile S-41
Input: `currentBalance` (= totale Home), lista `entries(date, signedAmount, isDone)`, `now = inizio giornata di oggi`.
Entries della Home (`DashboardView.monthlyProjection`): per **ogni** transazione con conto tra gli *included* (non archiviati, non esclusi; transazioni senza conto escluse): **saltare** le spese fisse singole non fatte `isFixed && Uscita && !isTransfer && templateId=="" && recurringFrequency=="" && !isDone` la cui data **non** è nel mese di oggi (competenza: una spesa fissa futura entra nel proprio mese, non nel saldo atteso di questo). Tutte le altre (fatte e pianificate, anche di altri mesi) sono entries. `plannedByAccount[account]` = Σ signed delle entries non fatte (stessa esclusione).
Algoritmo `make`: `daysInMonth`, `today` (1-based, clamp). `day(of:)`: stesso mese → giorno; data prima del mese → 1; dopo → ultimo giorno. Fatte: ancorate a `min(day, today)`; pianificate: `max(day, today)`.
- `actual`: per d da today a 1: punto (d, saldo a fine giorno) con `running=current`, poi `running -= doneByDay[d]` → serie crescente per giorno; ultimo punto = saldo attuale.
- `plannedDelta = Σ plannedByDay`; `projected` (solo se esiste ≥1 pianificata): da today a daysInMonth, `cumulative` parte da `current` e somma `plannedByDay[d]`; `plannedMarks` = un punto per ogni movimento pianificato (giorno, saldo di fine giorno) ordinati per giorno; `plannedCount`; `expectedBalance = current + plannedDelta`.
- Hero mostra «Saldo atteso a fine mese» e il riassunto solo se `|plannedDelta| > 0.001`. Riassunto: «1 movimento pianificato» / «N movimenti pianificati» + a capo `[+]importo` (segno `+` solo se delta>0 e importi non oscurati).
- Home mostra per ogni conto: `saldo` e, se `|plannedDelta account| > 0.001`, riga ambra `→ saldo+delta`, altrimenti «nessun movimento». ⚠ Android oggi: «atteso» = Σ saldi + pianificati del **solo mese corrente** (senza clamp/esclusione) → riscrivere.
- **Conti** (tab): `futureBalance` include tutto (differisce dalla Home per le fisse singole di altri mesi).

### 3.4 Ricorrenze (serie virtuali, D-008/D-009) — `D/RecurrenceCalculator.swift`, `RecurringMaterializer`, `RecurringSeriesEditor`
**Calcolo occorrenze** `occurrences(rule, interval[start,end))` (intervallo semiaperto; calendario Gregoriano nel fuso corrente; tutte le date a 12:00):
- settimanale: `start + 7k giorni`; mensile: ogni mese dal mese di start, giorno = `min(giorno_di_start, giorni_del_mese)`; annuale: come mensile con passo 12 mesi.
- scarta occorrenze con `original < start` o `original > endDate` (endDate inclusivo, giorno civile).
- chiave eccezione = `"yyyy-MM-dd"` dell'**originale**. Eccezione `skip` → nessuna occorrenza. Override data: valido solo se nello **stesso mese** dell'originale, altrimenti ignorato; la selezione nell'intervallo usa la data effettiva.
- override importo: stringa validata con la stessa regex (senza arrotondare); override campi `name,notes,category,categoryIcon,type,isFixed`; `accountId` override solo se `overridesAccount==true`.
- ordinamento: data effettiva poi chiave. `isOverridden = eccezione presente`.
**ID occorrenza deterministico** = UUIDv5 (RFC 9562): `SHA-1( 16 byte del UUID regola ‖ UTF-8 della chiave "yyyy-MM-dd" )`, primi 16 byte, `byte6=(b6&0x0f)|0x50`, `byte8=(b8&0x3f)|0x80`. **Deve coincidere bit a bit con iOS** (Transaction.id = occurrence.id): test con vettori generati da iOS (`RecurrenceCalculatorTests`).
**exceptionsJSON** (colonna `exceptions` su Supabase): oggetto `{ "yyyy-MM-dd": {skip, amount?, date?, name?, notes?, category?, categoryIcon?, type?, isFixed?, accountId?, overridesAccount?} }`, chiavi ordinate. Formato Swift `Codable` di default: **`skip` è sempre presente** (`true/false`: se Android lo omette, iOS non decodifica e perde TUTTE le eccezioni → scrivere sempre `"skip":false`); gli opzionali nil sono omessi; **`date` è un numero = secondi (Double) dal 2001-01-01T00:00:00Z** (`timeIntervalSinceReferenceDate`, non ISO); `amount` è stringa (es. `"112.40"`); `accountId` UUID **MAIUSCOLO**. Decodifica fallita ⇒ `{}`.
**Materializzazione** (`materializeDue(now)`) — chiamata: dopo login/sync, ritorno in foreground, cambio giorno/fuso/ora (`significantTimeChange`), anche offline e in demo; **solo sul main context**; tutto in un'unica transazione:
- per ogni regola con frequenza valida: `watermark = materializedThrough` (mese) oppure, se nil, «mese precedente al max(mese di start, mese corrente)» (una regola nuova non genera mai storico prima del mese corrente). Se `watermark >= mese corrente`: nulla (se nil, imposta watermark).
- cursore = max(mese di start, mese corrente−35, watermark+1 mese); per ogni mese fino al corrente genera le occorrenze **non ancora esistenti** (esistenza = Transaction con `templateId == ruleId` e stesso id) come `isDone=false`, `isFixed=occ.isFixed`, `recurringFrequency=""`, `templateId=ruleId.uuidString`, conto = quello con `id == occ.accountId` (null se mancante). Poi `materializedThrough = mese corrente`. Mai modifica copie esistenti (anche modificate/completate). Se il salvataggio fallisce: ripristina watermark e cancella le inserite, errore visibile.
**Editor** (`RecurringSeriesEditor.apply(action, rule, originalDate)`): `originalDate` = data **originale** dell'occorrenza (identifica anche quelle spostate/saltate); deve appartenere alla serie. Azioni:
- `edit(onlyThis)`: data deve restare nello stesso mese (altrimenti errore «La data deve restare nello stesso mese.»); scrive eccezione completa (amount, date, name, notes, category, categoryIcon, type, isFixed, accountId, overridesAccount=true) e aggiorna la copia reale se esiste.
- `edit(following)`: la regola vecchia termina il giorno prima (`endDate = originale−1g`, eccezioni con chiave < originale mantenute); nuova regola con valori nuovi da `startDate=originale`; le copie reali da quella data in poi (anche già fatte) sono aggiornate/spostate (`rescheduledDay`: stessa posizione ordinale nella nuova cadenza), **re-identificate** (nuovo UUIDv5 con la nuova regola, `templateId` nuovo); copie pianificate oltre la nuova `endDate` cancellate; poi `reconcile`.
- `edit(all)`: assegna i campi alla regola; eccezioni: se stessa cadenza e stessa data di ancoraggio restano solo gli `skip`, altrimenti `{}`; tutte le copie riallineate (stessa logica), copie pianificate oltre endDate cancellate; `reconcile`.
- `reconcile`: per il mese corrente ricalcola le occorrenze desiderate; cancella copie **pianificate** del mese non più desiderate; aggiorna/crea le altre; porta il watermark almeno al mese corrente (se la regola è già iniziata).
- `delete(onlyThis)` = eccezione `skip` + rimuove la copia pianificata; `delete(following)` = `endDate=originale−1g` + rimuove pianificate da lì; `delete(all)` = rimuove tutte le copie **pianificate** e la regola (le fatte restano come movimenti normali con templateId orfano).
- `skipMonth`: `skip` per tutte le occorrenze di quel mese + rimuove copie pianificate del mese. `terminate(afterThis:false)` = `endDate=originale−1g`; `(true)` = `endDate=originale`; rimuove pianificate successive.
- Validazioni `edit`: frequenza in {mensile,settimanale,annuale}, tipo valido, importo ≥ 0, `endDate ≥ (following? originale : startDate)`; errore «I valori della ricorrenza non sono validi.». Rollback completo se il salvataggio fallisce; messaggio «Impossibile aggiornare le ricorrenze. Riprova.» + dettaglio in alert «Ricorrenze».
- `anchorForSeriesEdit(rule, originalDate, date)`: se la data scelta è lo stesso giorno dell'originale → ancora invariata; settimanale → sposta l'ancora dello stesso numero di giorni; mensile/annuale → sposta di N mesi e giorno `min(giorno scelto, giorni mese)`. Usata quando si modifica dall'AddTransactionView una copia generata da serie.
**RecurrenceSelection.resolve(transaction, rules)**: regola con `id.uuidString == transaction.templateId` (confronto **maiuscolo**; Android: confrontare case-insensitive ma **scrivere sempre maiuscolo**), poi trova l'occorrenza originale con id uguale all'id della transazione (calcolo sull'intervallo da start fino a un mese dopo max(data tx, start, watermark)). Nil se non appartiene.
**Serie rilevate** (`RecurringSeriesDetector`): candidati = `isDone && !isTransfer`; gruppo per `"{nome trim lowercase}|{category}|{type}"`; serve ≥2 elementi e ≥2 mesi distinti; `average = totale/n`; `isVariableAmount` se importi non tutti uguali; frequenza = `recurringFrequency` esplicito di un elemento, altrimenti dal gap medio in giorni tra consecutivi: ≤10 settimanale, ≤45 mensile, ≤200 irregolare, altrimenti annuale; ordinate per |totale| decrescente; nome/categoria/icona dall'occorrenza più recente.
**Proiezioni nella card serie** (`RecurringSeriesCard`): variabile → «Media X · Ultimo Y»; costante: settimanale «Settimana X · Mese ≈X·4,33 · Anno X·52», mensile «Mese X · Anno X·12», annuale «Anno X»; riga totale «Speso finora/Ricevuto finora: …».
**Occorrenze virtuali** (mesi futuri): in Movimenti, se il mese selezionato è **successivo** al corrente, si mostrano le occorrenze calcolate dalle regole (ID non già reale), filtrate per categoria/ricerca/tipo, ordinate per data; non entrano in totali, saldi, filtri importo, statistiche.

### 3.5 Budget (`PianificaView`, notifiche)
`spent(budget)` = Σ amount delle transazioni `isDone && Uscita && !isTransfer` nel **mese selezionato** con categoria nel set del budget (vuoto se `"Tutti"` = tutte) e (budget.account==null ⇒ tutti i conti, altrimenti stesso conto). `progress = min(spent/limit, 1)` (0 se limit ≤ 0). `remaining = limit − spent`; `over = spent > limit` (⚠ lo stato «Sforato» scatta con progress==1 cioè spent ≥ limit, mentre «Sforato di …» nel testo solo se spent > limit). Hero Budget: `used = Σ spent per budget del mese` (somma per budget: categorie sovrapposte contano due volte), `total = Σ limiti`, `pct = min(used/total,1)`; «Mancano N giorni» = giorni da adesso a fine del mese selezionato (≥0; plural). Soglia notifica: `spent/limit ≥ 0.8` (non clampato).
Nome mostrato: categorie → nomi localizzati separati da «, » (storico: « + »); `"Tutti"` → nome conto o «Tutti». Sottotitolo: «Conto · Mensile» / «Categoria · Mensile» / «Multi-categoria · Mensile» (+ riga nome conto se categoria+conto). `categoryIcon` salvata: icona scelta o prima categoria o `building.columns.fill` se solo conto.

### 3.6 Obiettivi
`progress = min(current/target, 1)` (0 se target ≤ 0); `remaining = max(target−current, 0)`. Progresso complessivo = `min(Σcurrent/Σtarget,1)` su tutti gli obiettivi (0 se nessuno). Modifica: «Aggiungi risparmio» **somma** a `currentAmount`; `isCompleted = current ≥ target` ricalcolato solo al salvataggio di modifica (alla creazione è sempre false, ⚠ quirk #3); notifica scadenza 7 giorni prima.

### 3.7 Trasferimenti
Due transazioni con stesso `transferGroupId` (UUID maiuscolo): Uscita «Trasferimento → {conto A}» sul conto Da e Entrata «Trasferimento ← {conto Da}» sul conto A; `category="Giroconto"`, icona `arrow.left.arrow.right`, `isTransfer=true`, `isFixed=false`. Modifica: aggiorna entrambe le gambe (nome, importo, data, note, isDone, conto). Conferma/«Pianificato» da swipe: cambia `isDone` su entrambe. Eliminazione: confermata, rimuove entrambe. Le gambe si accoppiano per `transferGroupId` e id diverso.

### 3.8 Classificatore categorie (`KeywordCategoryClassifier` + `Resources/CategoryKeywords.json`, 65 KB)
JSON `{categoria: [keyword,…]}` (16 chiavi: 14 predefinite senza Risparmio/Altro + Stipendio 108, Bollette 126, Animali 140, Bambini 145; ~3600 voci, 11 lingue) → **copiare tale e quale in `assets/`**. Algoritmo `classify(nome)` (restituisce nome categoria o `"Altro"`):
1. trim; vuoto → Altro. Normalizza: lowercase + rimozione diacritici (NFD). Token input = split sui non-lettere, lunghezza ≥ 2; nessun token → Altro.
2. keyword ordinate per lunghezza decrescente. Per ogni keyword: se multi-parola (contiene spazio) → se il testo normalizzato **contiene** la frase: punteggio `len(kw) × 3.0`. Se singola: `best = max sui token di tier(token, kw)`; punteggio `best × len(kw)`.
3. `tier`: T1 uguale → 4.0; T2 `kw.hasPrefix(token) && len(token) ≥ 3`: se `len(token)/len(kw) ≥ 0.60` → 2.5, altrimenti se `len(token) ≥ 5` → 1.5, altrimenti 0; T3 `token.hasPrefix(kw)`: ratio `len(kw)/len(token) ≥ 0.60` → 3.0 altrimenti 0; T4 stem italiano (suffissi dal più lungo: abilita, abilità, issimo/a/i/e, azione/i, amento/i, imento/i, mente, arsi, ersi, irsi, ando, endo, are, ere, ire, ato/a/i/e, uto/a/i/e, ito/a/i/e, eria, erie, ario, aria, ino/a/i/e, one, oni, gli, he, hi, le, li, i, e, a, o; si toglie solo se resta ≥3 caratteri): `len(stem(token)) ≥ 3` e (`stem(token)==stem(kw)` oppure `token==stem(kw)` oppure `stem(token)==kw`) → 2.0; T5 Levenshtein = 1 con entrambi ≥5 caratteri e differenza lunghezza ≤2 → 1.5; altrimenti 0.
4. somma punteggi per categoria; vince il massimo; **soglia ≥ 6.0** altrimenti Altro. Cache risultati (max 2000).
Uso: `AddTransactionView` (debounce 280 ms), Intents. `LastUsedCategory.suggest(name, history, availableCategories)`: normalizza (case+diacritici-insensitive, spazi multipli → uno); tra i movimenti `isDone && !isTransfer` con nome normalizzato uguale prende il **più recente per `createdAt`** (a parità l'ultimo inserito); restituisce la sua categoria **solo se esiste ancora** tra le categorie, altrimenti null (non ripiega su una più vecchia). La cronologia è prefiltrata su `nome contiene la prima parola` (localizedStandard).

### 3.9 Statistiche
Vedi §4.5: tutti i totali usano `isDone && !isTransfer`. Media mensile 12 mesi = media sui soli mesi con valore > 0 (non su 12 fissi), calcolata dai 12 mesi che finiscono al **mese di oggi** (non il selezionato). Totali annuali: somma dei mesi dell'anno corrente (a oggi) e precedente.

### 3.10 Ordinamenti
Movimenti, Home: `date` decrescente (`Transaction`). Categorie: `sortOrder`. Conti Home (nessuna lista salvata): i 3 con saldo maggiore; con lista salvata: nell'ordine salvato, solo gli ancora inclusi.

---

## 4. Schermata per schermata

### 4.0 Struttura app e navigazione (`ContentView`, `MoneyTrackerApp`)
- **Flusso di avvio**: splash (logo `chart.pie.fill` 52 ultraLight + «MoneyTracker» 22 semibold su `paper`, finché non è letta la sessione) → se non loggato `LoginView` → altrimenti app con `AppLockGate`. Fade .25s al cambio login.
- **5 tab** (floating bar): Home(0) · Movimenti(1) · Statistiche(2) · Pianifica(3) · Conti(4), id test `tab_home|tab_movimenti|tab_statistiche|tab_pianifica|tab_conti`. Ogni tab ha la sua `NavigationStack`, barra nativa nascosta. Spazio riservato sotto i contenuti 94 + bottom padding liste 100.
- **FAB contestuale** (id `fabButton`, label a11y per tab): tab 0 e 1 → **menu** («Spesa / Entrata» `plus.circle` id `fabMenu_addTransaction`; «Trasferimento tra conti» `arrow.left.arrow.right` id `fabMenu_addTransfer`); tab 3 → «Nuovo budget» (segmento Budget) o «Nuovo obiettivo» (Obiettivi); tab 4 → «Nuovo conto»; tab 2 (Statistiche) → **nessun FAB**. Nascosto (fade/scala .7) quando in Movimenti la ricerca è attiva (testo o focus) e non si è in una sotto-pagina. Haptic medium.
- Sheet: spesa/entrata e trasferimento (a pagina intera con sfondo `paper`), Impostazioni (da ingranaggio di ogni tab, tranne Home che ha il suo), filtri avanzati (medium/large + indicatore), conferma valuta (altezza 272, non chiudibile a swipe).
- Pull-to-refresh su Home, Movimenti, Statistiche, Pianifica, Conti = `manualRefresh` (solo se loggato e non demo: push resiliente, poi pull se push ok, ignora il cooldown).
- Stati che si propagano: `hideBalance` (Home, Conti), demo (container diverso, ricrea tutto l'albero).

### 4.1 Home (`V/DashboardView.swift`)
Header (padding h20): a sinistra data (13 smoke, «venerdì 13 novembre» locale) + wordmark «Bucktrail» 26; a destra due pulsanti 44×44 gap 8: occhio (`eye`/`eye.slash`, label «Oscura importi»/«Mostra importi», anima .2s) e ingranaggio (apre Impostazioni). Poi, in ScrollView verticale senza indicatori:
1. **HomeHeroCard** (margini 16): «Saldo attuale» (13, heroSecondary) → importo `heroAmount` (1 riga, scala min .6) → **TrailView** (padding top 12) → se `|plannedDelta|>0.001`: divisore `heroDivider` 1pt, riga «Saldo atteso a fine mese» (caption) + importo `sectionTitle` colore `heroPlanned` a sinistra, riassunto pianificati caption allineato a destra. Importi oscurati con `"•••• €"` (anche l'atteso e il delta).
   - **TrailView**: canvas h 56 + etichette sotto (caption heroSecondary): giorno1 mese-abbreviato · «Oggi» (heroAccent semibold) · ultimo giorno. Inset 12. x = proporzionale al giorno `(d−1)/(daysInMonth−1)`; y = scala lineare tra min e max di tutti i saldi (`actual`+`projected`); se span=0 → metà. Tratto reale: linea piena `heroAccent` 2.5 round. Se `hasPlanned`: tratto tratteggiato `heroPlanned` 2.5, dash [1,7], round, che parte **sempre dal punto reale di oggi** e passa per i punti proiettati dei giorni > oggi (se oggi = ultimo giorno, aggiunge l'ultimo punto proiettato); cerchi per ogni pianificato (r4, fill `hero`, bordo 2 `heroPlanned`; **non** per quelli di oggi né dell'ultimo giorno); cerchio pieno r4.5 `heroPlanned` sul punto finale. Punto «oggi»: alone r12 `heroAccent`@18% + punto r5.5 `heroAccent`. Nascosta a TalkBack. Non mostra cifre (non va oscurata).
2. **Conti** (sezione visibile solo se `topAccounts` non vuoto): titolo 18 + a destra pulsante 44×44 `slider.horizontal.3` (label «Conti in home» → apre `HomeAccountOrderSheet`) e link «Gestisci» (13 semibold accent, h44 → va al tab Conti). Scroll orizzontale di card (vedi 1.3): pallino 10×10 raggio 3 colore per tipo + nome (13 smoke), saldo `rowAmount` (scala .7), riga ambra «→ saldo futuro» (se delta≠0) o «nessun movimento» (caption smoke).
3. **Fissi del mese** (visibile se almeno uno dei due toggle Impostazioni → Home è attivo): titolo «Fissi del mese» 18; due `FixedTotalTile` affiancati gap 12: «Spese fisse» (importo `negative`) e «Entrate fisse» (`positive`); sfondo `fog@50%` raggio 12 padding 12; importo 20 semibold (scala .7); oscurati = `"• • •"` colore ink. Totali = Σ amount delle transazioni `isFixed && !isTransfer` del tipo giusto con `date` nel **mese corrente** (fatte o no).
4. **Ultimi movimenti**: titolo + chevron collassabile (`chevron.up/down`, 44×44, spring) + link «Vedi tutti» (→ tab Movimenti). Se vuoto: EmptyState `tray` «Nessun movimento» / «Premi + per aggiungere la tua prima spesa.». Altrimenti card unica (raggio 20, `surface`) con le prime **4** transazioni con `!isFixed && !isTransfer && recurringFrequency==""` (incluse le pianificate non fisse, resa «pianificato») ordinate per data desc: `MovementRow` con metadata «{Categoria localizzata} · {Conto} · {Oggi/Ieri/d MMM}», importo oscurabile. Tap = modifica (sheet `AddTransactionView`); swipe a sinistra = Elimina (haptic medium, nessuna conferma); long-press menu: Modifica / Elimina.
- Spazio finale 72. La proiezione si aggiorna al cambio dei dati, a foreground e al cambio giorno.
**HomeAccountOrderSheet** («Conti in home», `NavigationStack`, sfondo `paper`): lista di tutti i conti inclusi (ordinati per saldo desc) con cerchio check (`checkmark.circle.fill` ink / `circle` smoke), nome 15 medium + tipo 12; drag-reorder sempre attivo; non si può deselezionare l'ultimo selezionato; selezionare un conto lo sposta dopo l'ultimo selezionato; «Annulla» / «Fine» salva la lista degli selezionati nell'ordine (`homeAccountOrderedShown`). Se la lista salvata è vuota: parte con tutti selezionati.

### 4.2 Movimenti (`V/TransactionsView.swift` + `TransactionsTypeChips/SecondaryChips/SearchField/AdvancedFilterSheet`)
Pagina fissa in alto: titolo «Movimenti» (screenTitle) + pulsante filtri avanzati 44×44 raggio 14 (id `btn_advancedFilter`, badge numerico = n filtri attivi, label «Filtri») + ingranaggio (id `btn_openSettings`). Campo ricerca (`tf_searchTransactions`, placeholder «Cerca per nome», lente, ✕ per svuotare, `submitLabel done`). Chip tipo (scroll orizzontale, id `tx_typeChips`, ognuno `txFilterBlock_<Raw>`): **Tutti · Fisse · Trasf. · Uscite · Entrate · Ricorrenti**. Poi riga chip secondari: menu **Mese ▾** (id `btn_monthPicker`: «Questo mese», «Mese precedente», «Mese successivo», separatore, ±6 mesi da oggi con check sul selezionato), menu **Categoria ▾** (id `btn_categoryFilter`: «Tutte le categorie» + tutte le categorie con check; selezionando la stessa si deseleziona), e se ci sono filtri avanzati chip verde `activeFilterSummaryLabel` (id `btn_activeFilterBadge`) con ✕ che azzera: solo min → «≥ X €», solo max → «≤ X €», min+max senza date → «X–Y €», altrimenti «Filtri (N)».
**Filtro lista** (`filtered(for:)`), tutti in AND: se «periodo personalizzato» attivo → `date ∈ [inizio giorno Da, inizio giorno dopo A)` (sostituisce il mese); altrimenti se la ricerca è vuota → stesso mese del selezionato (se c'è testo di ricerca il filtro mese è **ignorato**: cerca in tutto lo storico); nome contiene query (case/diacritici-insensitive, locale); tipo: Fisse=`isFixed`, Trasf.=`isTransfer`, Uscite=Uscita non trasferimento, Entrate=Entrata non trasferimento; categoria uguale; importo ≥ min e ≤ max (parse con `parseAmount`).
**Lista** (`List` grouped, margini 16, refresh): 
- se esistono occorrenze virtuali (mese selezionato > mese corrente): sezione «Serie programmate» con `VirtualOccurrenceRow` (icona categoria con bordo tratteggiato, nome, importo, data, nota «Virtuale · esclusa dai totali»; tap → `RecurrenceEditorView`). ⚠ quirk #1 (filtro tipo).
- sezione «In arrivo · pianificati» (intestazione ambra con totale: Σ signed non-trasferimenti; solo se ci sono `!isDone` nel set filtrato, **a prescindere dalla data**, ordinati per data desc).
- poi i movimenti `isDone` raggruppati per **stringa** `dayMonthFormatted` (Oggi/Ieri/«d MMM»; ⚠ quirk #5) con header: titolo `secondary` semibold smoke (+ totale giorno a destra `rowAmount`, Σ signed escludendo i trasferimenti); ogni gruppo = card `surface` con angoli 18 solo sul primo/ultimo; separatori `divider` rientrati di 14; spacer finale 100.
- **Riga** (`MovementRow` compatta, padding h14, id `txRow_<uuid>`, a11y value «Fatto»/«Pianificato»): metadata se fatto: «{Categoria loc.} · {Conto}»; se pianificato: «{Fissa|Categoria} · {data}»; importo = `amount` formattato senza segno nel componente (segno applicato dal componente); `kind`: transfer / income / expense; `isRecurring` se esiste una regola con id == templateId. Tap: trasferimento → `AddTransferView(editing)`, altro → `AddTransactionView(editing)`. Long-press menu: «Ricorrenza» (solo se appartiene a una serie → `RecurrenceEditorView`) + «Elimina».
- **Swipe sinistra** (trailing, full swipe, id `btn_deleteTransaction`, haptic medium): Elimina → se appartiene a una serie apre l'editor ricorrenza (non elimina direttamente); se trasferimento con gruppo → dialog «Elimina trasferimento» (messaggio «Questo trasferimento è composto da due movimenti collegati. Verranno eliminati entrambi.», azioni «Elimina entrambi i movimenti»/«Annulla»); altrimenti elimina. **Swipe destra** (leading, full swipe): solo se `isFixed || !isDone`: «Conferma» (verde `accent`, `checkmark.circle.fill`) se non fatto, «Pianificato» (`smoke`, `clock`) se fatto → toggle `isDone` (anche gamba gemella del trasferimento), haptic soft.
- **Stato vuoto**: `tray` «Nessun movimento» / «I movimenti di questo periodo appariranno qui.»; con ricerca: `magnifyingglass` «Nessun risultato» / «Nessun movimento corrisponde alla ricerca.».
**Pagina «Ricorrenti»** (push, titolo nav «Ricorrenti», barra nativa visibile): campo ricerca (id `tf_sectionSearch`), chip categorie (secondari «Tutte le categorie» + tutte), se vuoto (nessuna regola e nessuna serie): `arrow.triangle.2.circlepath` «Nessuna serie ricorrente» / «I pagamenti che si ripetono per almeno 2 mesi appariranno qui.». Altrimenti: label «Serie programmate» + `ProgrammedRuleCard` per ogni regola (filtrata per categoria/nome) poi `RecurringSeriesCard` per ogni serie rilevata (tap → `RecurringSeriesDetailView`). Resetta ricerca e categoria all'uscita.
**ProgrammedRuleCard**: icona categoria in tinta 38 raggio 12, nome + importo (in riga o su due righe se stretto), frequenza («Mensile/Annuale/Settimanale»), stato («Attiva» / «Termina il {data}» / «Terminata»), divisore, riga «Prossima occorrenza · {data}» con chevron (id `editRecurrence_<name>`, apre l'editor con quell'occorrenza; cerca la prossima nei 2 anni successivi a oggi); se non c'è prossima: pulsante «Modifica» sulla prima occorrenza.
**RecurringSeriesDetailView** (sheet «Fine»): card serie + sezione «Storico» con le occorrenze (più recenti prima, `MovementRow`), tap = modifica, swipe sinistra = elimina (senza conferma); se la serie sparisce: stato «Serie eliminata».
**RecurrenceEditorView** (Form, titolo «Ricorrenza», id `recurrence_*`): selettore «Ambito» (Solo questa / Questa e le successive / Tutte, `recurrence_scope`), Descrizione, Importo (decimale), Note, Data (con ambito «Solo questa» limitata al mese dell'occorrenza + nota «La data deve restare nello stesso mese.»; con «Questa e le successive» la data è bloccata sull'originale), «Ricorrenza» (Settimanale/Mensile/Annuale, solo se ambito ≠ solo questa), Tipo (Uscita/Entrata), Categoria, Conto («Nessuno» + conti), «Fissa»; sezione azioni: «Salta mese», «Termina da qui» (destr.), «Termina dopo questa» (destr.), «Elimina» (con dialog «Eliminare le occorrenze selezionate?» sull'ambito scelto). «Salva» disabilitato se descrizione vuota o importo ≤0/>1e9. Il cambio ambito ricarica i campi (da occorrenza o da regola).
**Filtri avanzati** (sheet «Filtri», medium/large, «Fine»): sezione «Importo» con due campi (`Minimo` placeholder «0», `Massimo` placeholder «∞», simbolo valuta, 20 medium, tastiera decimale); sezione «Periodo»: toggle «Periodo personalizzato» (sottotitolo «Sostituisce il filtro mese»); se attivo due date picker «Da»/«A» (A ≥ Da; default Da = oggi−1 mese, A = oggi); pulsante «Rimuovi tutti i filtri» (se ≥1 attivo). Persistenza: min, max, useDates in prefs (non le date). Conteggio badge = (min non vuoto) + (max non vuoto) + (periodo attivo).

### 4.3 Aggiungi / modifica movimento (`V/AddTransactionView.swift`)
Sheet con `UnderlineSegment` Uscita/Entrata (ricostruito da `TransactionType`), poi sezioni (spaziatura 36):
- **Importo**: label, simbolo `−€`/`+€` 28 ultraLight + campo 56 black (`tf_amount`, placeholder «0», decimale, `next` → focus descrizione), linea.
- **Descrizione** (`tf_name`, placeholder «es. Affitto, Netflix, Pizza...», 22 light, `done`): onChange con debounce 280 ms → suggerimento categoria (vedi sotto); `done` con dati validi **salva**.
- **Categoria** (`btn_categoryPicker`): riga con icona 14, nome (o «Scegli...»), se coincide col suggerimento «· suggerita» o «· Ultima usata», chevron → `CategoryPickerView`.
- **Conto** (solo se ci sono conti non archiviati): chip testuali scroll orizzontale (selezionato semibold + riga 1pt ink; `accountChip_<name>`); toccare il selezionato lo **deseleziona** (conto nil ammesso); default = primo conto attivo; in modifica = conto della transazione.
- **Opzioni**: toggle «Spesa fissa»/«Entrata fissa» (sottotitolo «Appare in 'Fissi del mese' nella home», `toggle_isFixed`): attivarlo imposta `isDone=false`, disattivarlo `isDone=true`; se fisso appare «Già effettuato» («Togli la spunta se è pianificata ma non ancora fatta», `toggle_isDone`); **solo in creazione** «Ricorrenza» (picker menu Nessuna/Settimanale/Mensile/Annuale, `picker_recurrence`, sottotitolo «Crea automaticamente al prossimo periodo»); «Data» (date picker solo data); poi «Note» (`tf_notes`, max 3 righe) e **PrimaryButton** «Salva»/«Aggiorna» (`btn_saveTransaction`, h52, raggio 14, sfondo `ink`@30% se disabilitato). Annulla (ghost, `btn_cancelAddTransaction`).
- **Valido** se nome non vuoto e `0 < importo ≤ 1e9`. Nessun campo che consenta Uscita/Entrata + «Già effettuato» fuori dal ramo fisso: per movimento non fisso `isDone=true` sempre; **con data futura resta `isDone=true`** su iOS (⚠ differenza con Android che forza pianificato per data futura).
- **Suggerimento categoria** (`applySuggestion`): se l'utente non ha scelto a mano; nome vuoto → azzera categoria; altrimenti storico (`isDone && !isTransfer`, nome contiene la prima parola, esclusa la transazione in modifica) → `LastUsedCategory.suggest`; se nessuno e il nome ha >2 caratteri → classificatore; se risultato ≠ Altro (o viene da storico) **e** la categoria esiste → selezionata e marcata; altrimenti nessuna categoria selezionata (⇒ al salvataggio `Altro`/`circle.dotted`). Scelta manuale diversa dal suggerimento blocca i successivi suggerimenti (`categoryManuallyOverridden`).
- **Salvataggio**: categoria = scelta o `"Altro"` con icona `circle.dotted`.
  - *Modifica copia di serie* (`templateId` di una regola esistente): applica `edit(.all)` all'intera serie con i nuovi valori (nome, importo, tipo, categoria, conto, isFixed, note; data → `anchorForSeriesEdit`), `isDone` applicato alla copia; se fallisce ripristina `isDone`.
  - *Modifica normale*: aggiorna campi (tipo, categoria, icona, conto, data, isDone, isFixed, note).
  - *Nuovo senza ricorrenza*: inserisce `Transaction` (`recurringFrequency=""`).
  - *Nuovo con ricorrenza*: crea `RecurringRule` (isFixed, conto, frequenza, `startDate=data`) e la prima transazione con `id = occurrenceID(rule, key(data))` e `templateId = rule.id`; poi `materializeDue`; se fallisce annulla tutto.
  Dopo il salvataggio: se Uscita e fatta → `checkBudgets(mese della data)`; se conto selezionato e fatta → `checkBalanceThreshold`. Poi chiude. Errore di salvataggio → resta aperta.
**CategoryPickerView** (sheet, titolo «Categoria»): elenco di tutte le categorie (icona 16 smoke, nome loc., check sul selezionato; id `categoryRow_<name>`), «Chiudi» (`btn_closeCategoryPicker`) e «Gestisci» (`btn_manageCategories`) → `CategoryManagementView`.

### 4.4 Aggiungi / modifica trasferimento (`V/AddTransferView.swift`)
Titolo «Trasferimento»/«Modifica trasferimento» (28 semibold). Importo (come sopra, simbolo valuta, `amountFocused`), sezioni «Da» e «A» (chip testuali come Conto; il conto scelto nell'altro è escluso; se nessun altro: «Nessun altro conto»), riga riepilogo «Da → A» (sfondo `fog` raggio 10), Opzioni: «Già effettuato» («Togli la spunta se il trasferimento è pianificato»), «Data», «Note (opzionale)»; bottone: «Trasferisci» (nuovo, fatto) / «Pianifica» (nuovo, non fatto) / «Aggiorna». Valido: `0<importo≤1e9`, Da≠A, entrambi scelti. Default: primi due conti attivi (Da=1°, A=2°). In modifica: Da = conto della gamba Uscita, A = della gamba Entrata. Salvataggio vedi §3.7.

### 4.5 Statistiche (`V/StatisticsView.swift`)
Header (h20): «Statistiche» + pulsante «PDF» (icona `square.and.arrow.down` o spinner + «PDF», secondary, raggio 12 bordo `fog`, id `statistics_pdf`, haptic soft; mentre genera è disabilitato) + ingranaggio. `MonthBar` mese (indipendente da Movimenti; h min 44). Tre tile gap 8: **Uscite** (valore `ink`), **Entrate** (`accent`), **Netto** (tile `hero`, label heroSecondary, valore `heroAccent`) — mese selezionato, `isDone && !isTransfer`; Netto = entrate − uscite. Valori `rowAmount` 1 riga scala .65.
Card **Andamento**: titolo «Andamento» + segmented compatto `6M | 12M` (id `statistics_range_6/12`, ogni segmento min 44×44, raggio 8, track `divider` raggio 10 padding 3, attivo `surface`); legenda «Uscite» (quadratino `ink` 12×8 r2) / «Entrate» (`heroAccent`); grafico a barre affiancate per mese (ultimi 6 o 12 mesi che finiscono al **mese selezionato**, dal più vecchio): uscite `ink`, entrate `heroAccent`; etichette asse X = mese breve (a 12M solo la **prima lettera**), l'ultimo (mese selezionato) in grassetto; senza dati: «Nessun dato disponibile.». Footer separato da `divider`: «Uscite medie» + importo (media su 12 mesi, ⚠ quirk #15, caption smoke/ink). A11y: riepilogo testuale per mese.
Card **Per categoria** (id `statistics_categories_title`, raggio 22): per ogni categoria con uscite del mese, ordinate per importo desc: nome loc. (secondary), % sul totale uscite del mese (`%.0f%%`), importo `rowAmount`, barra h6 in tinta categoria larga `amount/maxAmount`; vuoto: «Nessuna uscita questo mese.». Se `prevSpent>0`: riga freccia `arrow.up/down` + |Δ| + «rispetto al mese scorso» (rosso se più spesa, verde se meno; Δ = uscite mese − uscite mese precedente, calcolate su `isDone && !isTransfer`).
Sezione «Media mensile — ultimi 12 mesi» (SectionLabel): due tile `fog@50%` raggio 12: «Uscite medie» (`negative`) / «Entrate medie» (`positive`) 22 semibold, o «Dati insufficienti.» se entrambe 0. Poi divisore e «Anno {Y} vs {Y−1}»: righe «Uscite»/«Entrate» con totale anno corrente e, se l'anno precedente >0, `↑/↓ ±N% vs {Y−1}` (verde se uscite scendono / entrate salgono) o «Dati insufficienti.» se uscite di entrambi gli anni sono 0.
**Export PDF**: genera in background e apre lo share sheet di sistema con il file `report_AAAA-MM.pdf`; cambiando mese l'ultimo PDF viene scartato. Layout (A4 595.2×841.8 pt, margine 44, font di sistema, colori neutri: ink 0.07 / smoke 0.53 / fog 0.88): intestazione «MONEYTRACKER» (10 semibold, kern 1.5) + mese a destra, mese in maiuscolo 28 black; riga riepilogo a 3 colonne Uscite/Entrate/Netto (label 9 semibold kern 1.2, valore 22 black) + «±N% rispetto al mese precedente» (se prev>0); sezione «Uscite per categoria» (max 8, nome 13, importo+% 11 medium a destra, barra 2pt `fog` con riempimento `ink`); sezione «Movimenti» (tutte le transazioni `isDone` del mese, **trasferimenti inclusi**, ordinate desc: data `d MMM` 11 smoke, nome 11, importo con segno 11 medium a destra, linea 0.5); paginazione automatica (nuova pagina se non entra la riga). Totali escludono i trasferimenti e le non fatte. Valuta del PDF = `Locale.current.currency` (⚠ quirk #4). Android: `PdfDocument` + `FileProvider` + `Intent.ACTION_SEND`.

### 4.6 Pianifica (`V/PianificaView.swift`, `BudgetView.swift`, `GoalsView.swift`, `Components/PlanningCards.swift`)
Header: «Pianifica» + (solo segmento Budget) pulsante 44×44 `clock.arrow.circlepath` («Storico Budget») + ingranaggio. Segmented a due pillole (`planning_budget`, `planning_goals`; sfondo track `fog`, attivo `surface` raggio 11; spring). Contenuto sotto; spazio finale 100+.
**Budget**: `MonthBar` (mese proprio); **hero** `hero` raggio 24: «Budget usato» (secondary heroSecondary) + percentuale `screenTitle` `heroPlanned` tabular; riga «X € / Y €» (`rowAmount` heroText); `ProgressBar(onHero)` con tacca 80%; riga «Mancano N giorni» · «Avviso all’80%» (caption heroSecondary, si impila se stretto). Se nessun budget del mese: EmptyState `chart.bar` «Nessun budget» / «Imposta un limite mensile per categoria o conto.» + CTA «Aggiungi budget». Altrimenti una `PlanningBudgetCard` per budget (gap 8; id `budgetRow_<uuid>`; long-press → «Elimina» `btn_deleteBudget`, senza conferma): nome + «tipo · Mensile» + (nome conto) a sinistra, `BudgetStatus` a destra; `ProgressBar` 8; riga «speso / limite» e a destra «{rimasto} rimasti» (smoke) o «Sforato di {x}» (danger).
**AddBudgetView** (sheet «Nuovo budget», 28 semibold): sezione «Categoria (opzionale)» — «Lascia vuoto per un budget globale sul conto.» — griglia 2 colonne di chip (icona 12 + nome 13 medium, selezionata fill `ink`/testo `paper`, altrimenti `fog`; multi-selezione); se ≥2 categorie: sezione «Icona budget» con cerchi icona delle categorie scelte (scelta icona); «Conto (opzionale)» («Lascia vuoto per applicarlo a tutti i conti.») chip testuali «Tutti» + conti attivi; «Limite mensile» (importo grande `tf_budgetLimit`); avviso «Seleziona almeno una categoria o un conto.»; «Salva» (`btn_saveBudget`) valido se limite>0 e (≥1 categoria o un conto). Salva: `category` = nomi ordinati uniti da «,» o `"Tutti"`; mese/anno = mese visualizzato in Pianifica.
**BudgetHistorySheet** («Storico Budget», titolo large, stile pre-Sentiero SF): ultimi 6 mesi incluso l'attuale, in ordine cronologico; per mese: titolo «Novembre 2026» 13 semibold, poi per budget: icona 12 + nome (14) + «spesa / limite» 12 + `NN%` semibold + barra sottile 2pt (`fog`, riempimento `danger` se sforato altrimenti `smoke`) e `ThinDivider`; vuoto: «Nessun budget». Calcolo come §3.5 (budget del mese m, spesa del mese m).
**Obiettivi**: hero `hero` raggio 24 con `PlanningProgressRing` (74) + «Progresso complessivo» (secondary) + % `screenTitle` `heroAccent` + «salvato / totale» (secondary heroText). Vuoto: `target` «Nessun obiettivo» / «Imposta un obiettivo di risparmio e tieni traccia dei tuoi progressi.» + CTA «Aggiungi obiettivo». Card (`goalRow_<uuid>`; tap o long-press «Modifica» `btn_editGoal` / «Elimina» `btn_deleteGoal`, senza conferma): quadrato 42 `accentSoft` raggio 14 con icona (SF `accent` o emoji legacy), nome `rowAmount`, «Entro {data}» o «Nessuna scadenza», pulsante `+` 44×44 (`goal_add_<uuid>`, apre l'editor), barra verde 8, «salvato / target» + `NN%` `rowAmount` accent, e «Obiettivo raggiunto» (caption accent) se `isCompleted`.
**AddGoalView** («Nuovo obiettivo» / «Modifica»): «Icona» (cerchio 22 + «Cambia icona» + griglia 6 colonne delle 36 icone), «Nome» (`tf_goalName`, «es. Vacanza, Auto nuova...»), «Obiettivo» importo (`tf_goalTarget`), «Già risparmiato» (creazione, `+€` 40 light) **oppure** «Aggiungi risparmio» (modifica: somma), «Scadenza» (toggle «Imposta scadenza» + date picker, default oggi+90 giorni). «Salva»/«Aggiorna» (`btn_saveGoal`) disabilitato se nome o target vuoti (e comunque `target>0`).

### 4.7 Conti (`V/AccountsView.swift`)
Header «Conti» (screenTitle) + ingranaggio. **Hero** (raggio 24, `hero`): «Patrimonio totale» + importo `heroAmountSm` (id `accounts_total`; oscurato `"• • •"`) + divisore + «A conti fatti» (secondary) + `totalFuture` `rowAmount` `heroPlanned`. Totali sui conti non archiviati e non esclusi.
Vuoto: `creditcard` «Nessun conto» / «Aggiungi un conto per iniziare a tracciare le tue finanze.» + CTA «Aggiungi conto». Altrimenti due gruppi (solo se non vuoti): **«Liquidità»** (contanti, carta, conto) e **«Risparmio e investimenti»** (risparmio, investimento), ognuno con intestazione `secondary` semibold smoke + totale gruppo (esclude i conti esclusi) e card `surface` raggio 20 con righe (prima gli inclusi poi gli esclusi, dentro il gruppo), separatori `divider`.
**AccountRow** (id `accountRow_<name>`): icona tinta per tipo (38×38 r13), nome `rowName`, sottotitolo caption: «Escluso dal totale» (smoke) > «Sotto la soglia di {X}» (plannedText semibold; solo se importi non oscurati, soglia>0 e saldo<soglia) > nome tipo localizzato; a destra saldo `rowAmount` e, se `|future−current|>0.001` e non oscurato, «→ {futuro}» (caption `plannedText`). Archiviata: colori smoke.
Interazioni: tap → modifica (sheet); **swipe sinistra** → Elimina (haptic medium, id `btn_deleteAccount`) → alert «Eliminare "{nome}"?» con azione «Elimina (N movimenti)» (`btn_confirmDeleteAccount`) / «Annulla» (elimina conto + movimenti + budget del conto); long-press: Modifica (`account_edit`), «Escludi dal totale»/«Includi nel totale» (`account_exclude`), «Archivia» (`account_archive`), Elimina. Riga tratteggiata «Archiviati» + conteggio + chevron (`accounts_archived`, bordo tratteggiato [5,4] `filterBorder`, raggio 16) espande la sezione «Archiviati»: righe con long-press «Ripristina» (`account_restore`) / «Elimina definitivamente» (nessuna conferma).
**AddAccountView** («Nuovo conto»/«Modifica conto»): «Tipo» (5 righe testuali con check, `AccountType.allCases`), «Nome» (`tf_accountName`, «es. Carta Unicredit, Portafoglio...»), «Saldo attuale» («Inserisci il saldo che hai adesso su questo conto.», `tf_accountBalance`; in modifica mostra il **saldo reale** `currentBalance`, vuoto se 0), Opzioni: «Escludi dal totale» («Non viene contato nel saldo totale dei conti») e «Avviso saldo basso» (soglia, simbolo valuta, `0`; vuoto = disabilitato; persistita come `fixedFractionString` in prefs). Bottone «Aggiungi»/«Salva» (`btn_saveAccount`) disabilitato se nome vuoto. Salvataggio modifica: se il conto non ha transazioni → `initialBalance = valore`, altrimenti `delta = nuovo − currentBalance`; se `delta≠0` crea una transazione «Rettifica saldo» (categoria «Rettifica saldo», icona dalla categoria, `entrata` se delta>0 altrimenti `uscita`, importo |delta|, data oggi, fatta, conto). Nuovo conto non escluso: aggiunto in testa a `homeAccountOrderedShown` (⚠ quirk #2). Il conto nuovo ha `colorHex="000000"`.

### 4.8 Gestione categorie (`V/CategoryManagementView.swift`)
Raggiunta da CategoryPicker → «Gestisci». Titolo «Categorie» (large) + `+` (`btn_addCategory`). Sezioni «Predefinite» (righe con badge «predefinita»; tap → alert «Categoria predefinita»: «Le categorie predefinite non possono essere modificate o eliminate.») e «Personalizzate» (vuoto: «Nessuna categoria personalizzata.\nPremi + per aggiungerne una.»; riga con chevron, tap = modifica, long-press Modifica/Elimina; id `categoryManageRow_<name>`). `CategoryRow`: cerchio `fog` + icona, nome loc., (chevron).
**AddCategoryView** («Nuova categoria»/«Modifica categoria»): «Icona» (cerchio + «Cambia icona» + griglia 6 colonne di `availableIcons`), «Nome» (`tf_categoryName`, «es. Musica, Sport, Palestra...»), avviso «Esiste già una categoria con questo nome.» (confronto case-insensitive, escludendo se stessa); salva `btn_saveCategory`. **Rinomina** → riscrive `category` in tutte le transazioni e nei budget (nomi ordinati, ri-uniti). **Elimina** → alert «Elimina "nome"» con messaggio a seconda di quante transazioni la usano («Sei sicuro di voler eliminare questa categoria?» / «1 transazione usa questa categoria. L'icona tornerà a quella predefinita. Continuare?» / «%d transazioni …»); le transazioni mantengono il nome e riprendono l'icona predefinita per nome; la categoria sparisce solo dall'elenco.

### 4.9 Impostazioni (`V/SettingsView.swift`, sheet «Impostazioni» large, «Chiudi» `btn_closeSettings`; sezioni separate da `ThinDivider`)
1. **Lingua**: testo «La lingua dell'app segue le preferenze di sistema.» + riga «Apri Impostazioni iOS» (↗). → Android: `Settings.ACTION_APP_LOCALE_SETTINGS` (API 33+) / impostazioni app.
2. **Valuta**: picker a menu delle 15 valute; la scelta apre sheet di conferma (simbolo grande + nome + «Il simbolo verrà aggiornato ovunque nell'app. Gli importi restano invariati.» + Annulla/Conferma, non chiudibile a swipe); Annulla ripristina il picker.
3. **Notifiche**: toggle «Avvisi automatici» («Budget quasi esaurito, fissi in scadenza, obiettivi vicini»): ON → richiede permesso; OFF → cancella tutte le notifiche programmate e spegne il report mensile. Toggle «Report mensile PDF» («Promemoria il 1° di ogni mese per generare il report PDF», disabilitato e al 40% se avvisi spenti) → programma/cancella il promemoria.
4. **Sicurezza**: toggle «Blocco con Face ID» (testo: se disponibile «Richiede Face ID, Touch ID o il codice del dispositivo all'apertura» altrimenti «Nessun metodo di sblocco configurato su questo dispositivo»; disabilitato se non disponibile); **spegnerlo richiede autenticazione** (se disponibile); riga «Cronologia modifiche» → `AuditLogView`.
5. **Home**: toggle «Spese fisse mensili» e «Entrate fisse mensili» («Mostra il totale … del mese in home»).
6. **Esportazione dati**: «Esporta tutte le transazioni in formato CSV, compatibile con Excel e Numbers.» → «Genera CSV» (poi «Condividi CSV», file `transazioni.csv`); separatore; «Oppure esporta l'intero tuo profilo (conti, budget e obiettivi inclusi) in un unico file JSON.» → «Esporta tutti i dati (JSON)» (poi «Condividi tutti i dati (JSON)», file `i-miei-dati-moneytracker.json`). Formati in §5.6.
7. **Modalità Demo**: spiegazione + toggle «Attiva modalità demo» («I tuoi dati reali restano intatti e privati», `toggle_demoMode`, tint arancione) + riquadro info «L'app si riavvierà con dati demo. Per tornare ai tuoi dati basta disattivare il toggle.».
8. **Siri & Shortcut**: testo + «Apri Shortcut» + suggerimento (tocco posteriore). → Android: sezione «Scorciatoie» che spiega e porta alle scorciatoie dell'app/Widget/Tile (§5.4).
9. **Info**: «Versione» (CFBundleShortVersionString, oggi "1.0"), «Transazioni totali» (conteggio).
10. **Account** (in fondo): se loggato email con icona `person.circle`; «Esci dall'account» (dialog «Esci dall'account?» / msg «Dovrai effettuare di nuovo il login la prossima volta.» → push resiliente, `signOut`, `clearLocalData`); «Elimina account» (dialog «Eliminare l'account?» con testo che avvisa che vengono cancellati conti, movimenti, budget e obiettivi su dispositivo e cloud, irreversibile → «Continua» → alert «Conferma eliminazione»: campo «Scrivi ELIMINA» (esatto, maiuscolo) + «Elimina definitivamente» abilitato solo se uguale → autenticazione dispositivo se disponibile → RPC `delete_own_account`, `clearLocalData`, `signOut`; stato «Eliminazione in corso…»; errore «Impossibile eliminare l'account: %@»).
- Nessuna scelta tema; nessun tour (rimosso, step 0).

### 4.10 Auth (`Auth/LoginView.swift`, `SignUpView.swift`)
**Login**: hero (padding top 64, bottom 48): `chart.pie.fill` 52 ultraLight, «MoneyTracker» 28 semibold, «Accedi per continuare» 15 smoke; campi `AuthField` (label 12 medium, campo su `fog` raggio 10, no autocapitalize/autocorrect) «Email» (placeholder `nome@email.com`, tastiera email) e «Password» (`••••••••`, secure); errore sotto (centrato); bottone «Accedi» (h52 raggio 12, `ink` se compilato altrimenti `fog`, spinner); «Password dimenticata?» → alert «Reimposta password» con campo email precompilato, «Invia link»/«Annulla» (messaggio «Inserisci la tua email e ti mandiamo un link per reimpostare la password.», dopo l'invio «Email inviata! Controlla la tua casella.»; l'esito non mostra mai errori); separatore «oppure»; «Crea un account» (sfondo `fog` raggio 12) → push `SignUpView`. Abilitato se email e password non vuote. Errori (stringhe italiane **hardcoded**, non in stringsdict `[DA VERIFICARE se localizzate]`): «Email o password non corretti.», «Conferma la tua email prima di accedere.», «Troppi tentativi. Aspetta qualche minuto e riprova.», «Nessuna connessione. Controlla la rete e riprova.», «Errore: {dettaglio}». Mappatura sul testo dell'errore in minuscolo (substring).
**Registrazione** (titolo nav «Crea account»): «Benvenuto» / «Crea il tuo account per iniziare»; Email, Password («Minimo 6 caratteri»), Conferma password («Ripeti la password», avviso «Le password non coincidono»); «Registrati» abilitato se email non vuota, password ≥6 e uguali; dopo `signUp` se non c'è sessione (conferma email attiva): messaggio «Account creato! Controlla la tua email e clicca il link di conferma per accedere.» con icona `envelope.badge.checkmark.fill` e «Torna al login». Errori: «Esiste già un account con questa email.», «La password deve avere almeno 6 caratteri.», «Indirizzo email non valido.», rate limit, «Errore: …».
**Blocco app** (`AppLockGate`, solo contenuto autenticato): se `appLockEnabled` e il dispositivo ha un metodo di sblocco → overlay a tutto schermo `paper`: `lock.fill` 44 light, «MoneyTracker è bloccato» 17 medium, bottone «Sblocca» (`borderedProminent` tint ink, min 160×52). Si blocca quando l'app va in background; richiede autenticazione al cold start e al ritorno attivo; fade .2s; motivo richiesta «Sblocca MoneyTracker per vedere i tuoi dati finanziari»; autenticazione = biometria **con fallback al passcode** del dispositivo (`BiometricPrompt` + `DEVICE_CREDENTIAL`; per API <30 usare `KeyguardManager`).

### 4.11 Audit log (`V/AuditLogView.swift`)
Sheet «Cronologia modifiche» (inline, «Chiudi»): vuoto → `clock.arrow.circlepath` «Nessuna modifica registrata» / «Ogni modifica ai tuoi dati finanziari apparirà qui.»; elenco più recenti prima: icona (`plus.circle` creato / `pencil.circle` modificato / `trash` eliminato), riga 1 = summary (o etichetta entità se «—»), riga 2 = «{Creato|Modificato|Eliminato} · {data abbreviata ora}». Eventi generati da ogni salvataggio del contesto reale per `Transaction`, `Account`, `Budget`, `Goal` (non Category/RecurringRule): summary creato/modificato: Transaction «{nome} — {importo 2dec} ({Uscita|Entrata})», Account «{nome} — saldo iniziale {x}», Budget «{categoria} — {limite}/mese», Goal «{nome} — obiettivo {x}»; eliminato: summary «—». Etichette entità: Movimento/Conto/Budget/Obiettivo. File append-only, cancellato a logout/eliminazione account/cambio utente. Android: tabella Room append-only (o jsonl) con trigger nel repository.

### 4.12 Modalità demo e dati demo (`Debug/DemoDataSeeder.swift`)
Container separato (`demo.store`) sempre seminato all'avvio (categorie + dati; `seedVersion=6`: si ri-semina se versione < 6 o nessun conto). In demo: nessun sync (push/pull/refresh disattivati), banner «MODALITÀ DEMO», toggling ricrea l'intera UI. Dati: 4 conti (conto 2.900 `1F7A4D` · risparmi 6.200 `2F6FB0` · carta 4.800 `5A4AA3` · contanti 650 `B45309`), 9 serie mensili reali con `isFixed` (stipendio 2.850 entrata giorno 1; affitto 780 g3; bolletta 86 «oggi» con override a 112,40 nel mese corrente; internet 29 g9; streaming 15,99 g12; music 10,99 g6; palestra 45 «oggi»; assicurazione 64 g23; rata 125 g10), partenza 7 mesi fa con watermark = inizio mese corrente, spese ricorrenti per 8 mesi (supermercato×4, carburante, ristorante, cinema, farmacia, shopping, corso, regalo, altro; viaggi/dentista/bonus in mesi specifici; interessi; giroconto 180 conto→risparmi), 2 pianificati non seriali, 5 budget × 8 mesi (Cibo 300, Svago 90, Trasporti 240, Salute 180, Shopping 170), 4 obiettivi (vacanza 2.800/1.960 con scadenza +2 mesi `airplane`; emergenza 15.000/6.640 `banknote`; computer 2.499/640 +8 mesi `laptopcomputer`; fotografia 450/450 `camera.fill`). Nomi dei dati demo localizzati con chiavi `demo.*` (33 chiavi in `*.lproj/Localizable.strings`). Replicare i numeri **esattamente** (screenshot social/QA li usano): sorgente di verità = `DemoDataSeeder.swift`, test `DemoDataSeederTests`.

### 4.13 Notifiche e permessi — vedi §5.5. Banner sync/demo — vedi §1.4.

### 4.99 ⚠ Comportamenti iOS anomali (da decidere con Matteo; di default NON replicare i bug evidenti)
1. Occorrenze virtuali in Movimenti: il filtro tipo confronta `$0.type == "uscita"/"entrata"` (minuscolo) ma il valore salvato è `"Uscita"/"Entrata"` → con chip Uscite/Entrate le virtuali spariscono sempre. [DA VERIFICARE se voluto]
2. Creando un conto non escluso quando `homeAccountOrderedShown` è vuoto, la lista diventa **solo quel conto** (nasconde gli altri in Home).
3. `Goal.isCompleted` alla creazione è sempre false anche se `current ≥ target`; si aggiorna solo alla modifica.
4. PDF: valuta = `Locale.current.currency`, non la valuta scelta in Impostazioni.
5. Raggruppamento per giorno usa la stringa «d MMM»: date di anni diversi con stesso giorno/mese si fondono in un gruppo.
6. Oscuramento: Home `"•••• €"` vs altrove `"• • •"`; la Home non oscura i tile «Fissi» col simbolo €.
7. Il pull non azzera `transaction.account`/`budget.account` se il remoto ha `account_id` null (aggiorna solo se non nullo).
8. Le categorie personalizzate non sono sincronizzate (le transazioni portano nome+icona): su un altro dispositivo la categoria compare nelle righe ma non negli elenchi/menu finché non la si ricrea.
9. «Rettifica saldo» non è nell'elenco nomi localizzabili: appare in italiano grezzo nelle liste (menu categoria compreso).
10. Il progress dei budget è clampato a 1: nelle card la differenza tra «Sforato» (≥100%) e «Sforato di» (>100%) coincide solo oltre il limite esatto.
11. Il budget globale somma per budget (categorie sovrapposte contate 2 volte).
12. Le gambe del trasferimento hanno nomi fissi italiani «Trasferimento → X» / «← X» (non localizzati, salvati nel DB).
13. Importi anomali: nessun limite di decimali sul cloud (parse locale arrotonda a 2).
14. Campi accessibilità in italiano hardcoded in alcuni punti (es. Goal/Budget label, «Tocca per segnare come pagata»).
15. «Uscite medie» nella card Andamento è sempre la media a 12 mesi anche con toggle 6M.
16. Versione app mostrata «1.0» (MARKETING_VERSION) mentre il changelog è v3.23.
17. L'app mostra «MoneyTracker» (splash/login/blocco/PDF/notifica report) e «Bucktrail» (Home, icona); Android ha `app_name=Bucktrail`. Decidere il nome mostrato.

---

## 5. Auth, sync, Intents, notifiche, export

### 5.1 Auth Supabase (`Auth/SupabaseManager.swift`, `SupabaseConfig.swift`)
- Backend: progetto Supabase `https://zblpzufsikxhuzdtcucg.supabase.co` (URL e chiave **anon/public** in `MoneyTracker/Auth/SupabaseConfig.swift`; la chiave è pubblica per design ma **non copiarla in questo documento**: leggerla da quel file e metterla in `local.properties`/`BuildConfig`, non nel repo se si può). Protezione dati = Row Level Security (`user_id = auth.uid()`). **Per i test Android usare un progetto/ambiente Supabase di test** (da PIANO.md «Proposte prodotto»): `[DA VERIFICARE se esiste]`; non provare push/pull sul progetto reale di Matteo prima dell'ok.
- Metodi: `signUp(email,password)`, `signIn`, `signOut`, `resetPasswordForEmail`, `rpc("delete_own_account")` (funzione DB «gdpr_right_to_erasure», agisce solo sull'utente di sessione; il codice SQL **non è nel repo** `[DA VERIFICARE]`). Sessione persistita (iOS: Keychain; opzione `emitLocalSessionAsInitialSession`), stato osservato (`authStateChanges`), `isLoading` finché non letta. Android: `supabase-kt` (`auth-kt`, `postgrest-kt`) con session storage cifrato (EncryptedSharedPreferences/DataStore+Keystore).
- Link email di conferma/reset: nessun deep link configurato in iOS `[DA VERIFICARE URL redirect lato Supabase]`.

### 5.2 Tabelle Supabase e DTO (`Sync/SyncService.swift`, snake_case, tutte con `user_id`)
| Tabella | Colonne |
|---|---|
| `mt_accounts` | id, user_id, name, type, initial_balance, color_hex, created_at, is_archived, is_excluded_from_total |
| `mt_transactions` | id, user_id, account_id (nullable), name, amount, type, category, category_icon, date, is_done, is_fixed, is_transfer, transfer_group_id, notes, recurring_frequency, template_id, created_at |
| `mt_budgets` | id, user_id, account_id (nullable), category, category_icon, monthly_limit, month, year, created_at |
| `mt_goals` | id, user_id, name, emoji, target_amount, current_amount, deadline (nullable), is_completed, created_at |
| `mt_recurring_rules` | id, user_id, name, type, category, category_icon, notes, amount, is_fixed, account_id, frequency, start_date, end_date, **exceptions** (= exceptionsJSON, stringa), materialized_through, created_at |
Nessuna tabella per categorie. Tipi: UUID (iOS invia `uuidString` maiuscolo; il DB restituisce minuscolo), `numeric` (Decimal; serializzare come numero JSON senza perdita di precisione con serializer BigDecimal), `timestamptz` per le date (Swift SDK codifica `Date` come ISO‑8601 `[DA VERIFICARE formato esatto]`), `exceptions` come **stringa** JSON. Nel push le regole codificano anche i nil come NULL (account_id/end_date/materialized_through azzerabili).
**Regole di compatibilità cruciali** (se violate iOS si rompe): (a) `template_id` e `transfer_group_id` e gli `accountId` dentro `exceptions` si **scrivono in MAIUSCOLO** (`UUID.toString().uppercase()`); in lettura confrontare ignorando le maiuscole; (b) ID occorrenza = UUIDv5 §3.4; (c) formato `exceptions` §3.4 (`skip` sempre presente, `date` = secondi dal 2001); (d) `type` = `Uscita|Entrata` / `Conto Bancario…`; (e) `categoryIcon`/`emoji` = nomi SF Symbol.

### 5.3 Strategia di sync (`SyncService`)
- **Quando**: login/sessione ripristinata (`syncOnLogin`); app in background → `pushResilient`; ritorno in foreground → `syncOnForeground` (push, poi pull **solo se push ok e cooldown 5 min scaduto**); salvataggi → `schedulePush` con debounce **1,5 s**; pull-to-refresh (`manualRefresh`: push, se ok pull, senza cooldown); rientro della rete con modifiche pendenti → push immediato. Nulla in demo, né con store volatile (fallback in-memory).
- **syncOnLogin**: se `lastUserId` ≠ utente corrente → `clearLocalData` (isolamento multi-utente); salva `lastUserId`; legge gli id di `mt_accounts`: **se remoto vuoto → push, altrimenti → pull** (il cloud è fonte di verità). Se la lettura fallisce → push.
- **push** (SwiftData → Supabase), in quest'ordine: accounts (upsert tutti, poi delete orfani), transactions (upsert **solo gli id «sporchi»**, poi delete orfani confrontando TUTTI gli id locali con quelli remoti), budgets, goals, rules (upsert completo + delete orfani). `deleteOrphans` = `select id` remoti dell'utente, differenza, **una sola** `delete().in(id, …).eq(user_id)`. Se un passo fallisce → tutto `false`. ⚠ Il push **cancella dal cloud ciò che non esiste in locale**: Android non deve mai fare push con DB vuoto/parziale prima di un pull riuscito quando il cloud ha dati.
- **dirty tracking** (solo `Transaction`): a ogni salvataggio gli id inseriti/modificati vanno in un Set persistito; tolti solo dopo upsert riuscito. Le azioni App Intent (processo diverso) devono marcare a mano (`markTransactionDirty`) e impostare `hasPendingChanges`.
- **pull** (Supabase → locale): ordine accounts → transactions → budgets → goals → rules; per ogni riga remota: se esiste localmente aggiorna **campo per campo solo se diverso** (la riga remota vince; regola: `materialized_through` = max(locale, remoto) mai indietro; `account` aggiornato solo se `account_id` non nullo), altrimenti inserisce con id/createdAt remoti; poi **cancella i locali assenti sul remoto** (cascade sui conti), **tranne** le transazioni ancora «sporche». Guardie: se `mt_accounts` è vuoto ma il locale ha conti → **interrompe il pull**; stessa guardia per le regole. Un errore a metà → nessun `lastPull`. Salva una volta alla fine e imposta `lastPull`. Android: **un'unica transazione Room**.
- **Conflitti**: nessun timestamp per riga; vince l'ultimo che fa push (full upsert) / il remoto sul pull; nessun merge per campo. Replicare tale e quale (§5.3 è la specifica), non inventare merge più sofisticati senza decisione.
- **Resilienza**: stato osservabile `idle|syncing|waitingForRetry(n)|offline`; push fallito → `hasPendingChanges=true` (persistito) e retry con backoff `min(2^n, 60) s`; monitor di rete (NWPathMonitor → `ConnectivityManager.NetworkCallback`): offline → stato `offline`; rete tornata + pendenti → retry immediato; una nuova modifica azzera i fallimenti. Banner §1.4.
- **Logout**: push resiliente → signOut → `clearLocalData` (Transaction, RecurringRule, Budget, Goal, Account, lastPull, audit log). **Eliminazione account**: RPC → clear → signOut.
- Ricorrenze: dopo sync si esegue `materializeDue` (coda unica: login → foreground → cambio data).

### 5.4 Intents Apple → equivalenti Android (`Intents/AddExpenseIntent.swift`)
Tre App Intent (processo separato, **senza aprire l'app**, scrivono nello store condiviso tramite App Group; senza gruppo l'intent fallisce con errore «Il database non è disponibile. Apri l'app per risolvere il problema.»):
| Intent | Parametri | Comportamento | Risposta |
|---|---|---|---|
| **Aggiungi spesa** | Nome (testo), Importo (Double), Conto (opz., per nome), Categoria (opz.) | valida: importo >0 finito ≤ 1e9 («L'importo deve essere un numero positivo (max 1 miliardo)»), nome non vuoto («Inserisci una descrizione per la spesa»); conto = per nome esatto, altrimenti **il primo** conto; categoria: classificatore se ≠ Altro, altrimenti quella fornita, altrimenti Altro; icona dalla tabella categorie o per nome; Transaction Uscita, `isDone=true`, data = adesso, importo `Decimal(roundedFromDouble)`; salva, invalida cache, **marca dirty** | «💸 %.2f per {nome}[ su {conto}] — salvato!» |
| **Aggiungi entrata** | Nome, Importo, Conto (opz.) | stesse validazioni («Inserisci una descrizione per l'entrata»); categoria: classificatore se ≠ Altro, altrimenti «Lavoro» (o la prima categoria o «Lavoro»); Entrata fatta | «💰 +%.2f {nome}[ su {conto}] — salvato!» |
| **Controlla saldo** | — | conti non archiviati; vuoto: «Nessun conto trovato. Apri l'app per aggiungerne uno.»; totale = Σ saldi dei conti **non esclusi** | «💰 Saldo totale: {totale}» + una riga per conto «{emoji tipo} {nome}: {saldo}» |
Frasi Siri (italiano): «Aggiungi spesa su {app}», «Nuova spesa {app}», «Ho speso con {app}»; «Aggiungi entrata su {app}», «Ho ricevuto soldi con {app}»; «Controlla saldo {app}», «Quanto ho su {app}». Titoli breve: «Aggiungi spesa» (`minus.circle.fill`), «Aggiungi entrata» (`plus.circle.fill`), «Saldo conti» (`creditcard.fill`). Suggerimenti opzioni: conti non archiviati; categorie = personalizzate + predefinite non presenti. Uso documentato: Shortcut, widget Shortcuts, **Tocco posteriore** iOS. (iOS **non ha** una WidgetKit extension propria: il «widget» è quello di Comandi.)
**Equivalenti Android proposti** (Matteo chiede widget e Assistant: sono *aggiunte* rispetto a iOS, da collaudare con lui):
1. **Scorciatoie statiche/dinamiche** (`ShortcutManager` / `res/xml/shortcuts.xml`, long-press sull'icona): «Aggiungi spesa», «Aggiungi entrata», «Saldo conti» → `QuickAddActivity` (tema dialog/bottom sheet, nome+importo+conto+categoria, stessa logica 1:1 dell'Intent, nessun apertura dell'app completa), `CheckBalance` → dialog/notifica con il testo iOS.
2. **Widget** (Jetpack Glance): «Saldo» (totale oscurabile, tocca → app) e «Aggiungi spesa» (apre QuickAdd); aggiornamento a ogni modifica.
3. **Quick Settings Tile** «Aggiungi spesa» (equivale al Tocco posteriore).
4. **Google Assistant App Actions** (`shortcuts.xml` con capabilities) per le tre frasi `[DA VERIFICARE copertura IT/lingue]`.
5. Stessa regola dirty/sync: l'inserimento rapido passa dallo stesso repository e marca la transazione dirty.

### 5.5 Notifiche (`Domain/NotificationManager.swift`, `NotificationScheduling`)
Master switch = pref `notificationsEnabled` (default true; al **primo avvio** se la chiave non esiste → chiede il permesso). `requestPermission` imposta la pref a true solo se concesso. Tutte le funzioni escono se non abilitato. Android: canale «Avvisi MoneyTracker» (importance default), `POST_NOTIFICATIONS` runtime (API 33+), `AlarmManager.setExactAndAllowWhileIdle`/WorkManager per quelle programmate + `BOOT_COMPLETED` per ripianificare.
| ID | Quando | Titolo / testo (chiavi stringa) | Trigger |
|---|---|---|---|
| `budget_<budgetId>` | dopo salvataggio di una Uscita **fatta** (mese della data); per ogni budget del mese con `spent/limit ≥ 0.8` | <100%: «Budget quasi esaurito» / «"%@" — %d%% utilizzato»; ≥100%: «Budget sforato» / «Hai superato il limite per "%@"» (nome = categorie loc. unite con « + », o nome conto/«Budget») | dopo 2 s, una volta; sostituisce la pendente con lo stesso id |
| `fixed_reminder` | all'avvio app (`scheduleFixedReminderIfNeeded`) e quando si cambiano le fisse | «Spese fisse del mese» / «Hai 1 spesa fissa da segnare come pagata» o «Hai %d spese fisse da segnare come pagate» (conta le `isFixed && !isDone` nel mese corrente; se 0 cancella) | ogni **1° del mese alle 09:00**, ripetuta |
| `goal_<goalId>` | salvataggio obiettivo con scadenza | «Obiettivo in scadenza» / «"%@" scade tra 7 giorni» | 7 giorni prima della scadenza (stessa ora della data scelta), una volta, solo se futura; cancellata se si toglie la scadenza |
| `balance_<accountId>` | dopo salvataggio di movimento fatto su un conto con soglia>0 (pref `balanceThreshold_<id>`) | «Saldo basso» / «Il conto "%@" è sceso sotto la soglia impostata.» | dopo 1 s, solo se `saldo < soglia` (altrimenti cancella la pendente) |
| `monthly_report` | toggle report mensile | «Il tuo report mensile è pronto» / «Apri MoneyTracker per generare e condividere il PDF del mese scorso.» | ogni **1° del mese alle 10:00**, ripetuta (richiede avvisi attivi) |
Disattivare gli avvisi = `cancelAll` + report mensile off.

### 5.6 Export
- **CSV** (`transazioni.csv`, UTF-8, `\n`): intestazione localizzata `Data,Descrizione,Importo,Tipo,Categoria,Conto,Fatto,Ricorrenza` (tutti i campi tra virgolette); righe ordinate per data desc su **tutte** le transazioni (anche pianificate e trasferimenti): data `dd/MM/yyyy`, nome, importo `fixedFractionString` (punto, 2 decimali, **positivo**), Tipo localizzato, categoria localizzata (nome predefinito) o grezza, nome conto o vuoto, «Sì»/«No» localizzato, `recurringFrequency`. Escape: `"` raddoppiato; **anti-formula**: se il campo inizia con `= + - @ TAB CR LF` si antepone `'`.
- **JSON** (`i-miei-dati-moneytracker.json`): `{exportedAt (ISO‑8601), userEmail, accounts[{id,name,type,initialBalance,isArchived,isExcludedFromTotal,createdAt}], transactions[{id,name,type,category,notes,amount,date,createdAt,isDone,isFixed,isTransfer,accountName}], budgets[{id,category,monthlyLimit,month,year,accountName}], goals[{id,name,targetAmount,currentAmount,deadline,isCompleted}]}` — `prettyPrinted`, chiavi ordinate, date ISO‑8601. (Non include regole/categorie.)
- **PDF** §4.5. Condivisione: `FileProvider` + `ACTION_SEND` (o `ShareLauncher`); file in cache temporanea, non in storage condiviso.

---

## 6. Localizzazione (7 lingue: it, en, de, es, fr, ja, zh-Hans)

- iOS: `MoneyTracker/<lang>.lproj/Localizable.strings` (non String Catalog) + `Localizable.stringsdict` (1 sola voce plurale: «Mancano %lld giorni», zero/one/other; one = «Manca %lld giorno»). **La chiave è il testo italiano**; `it.lproj` è quasi vuoto (89 righe, quasi tutte `demo.*`): serve solo a dichiarare il locale. en/de/es/fr/ja/zh-Hans hanno 395 chiavi ciascuna (incl. 33 `demo.*`). I testi senza traduzione ricadono sull'italiano. La lingua segue **quella di sistema** (nessun selettore in app).
- Android: **non** esiste nel repo una pipeline. Proposta: script `scripts/ios-strings-to-android.py` (da scrivere, deterministico, rieseguibile) che: (1) legge `en.lproj/Localizable.strings` come elenco canonico delle chiavi (il testo italiano = la chiave stessa → `values/strings.xml` italiano); (2) per ogni chiave genera un nome risorsa stabile `s_<slug-ascii-del-testo>_<crc6>` e un file `strings-map.json` chiave→nome; (3) emette `values/` (it, **lingua di default**), `values-en`, `values-de`, `values-es`, `values-fr`, `values-ja`, `values-b+zh+Hans` (verificare che risolva su Android 8+); (4) converte i segnaposto `%@`→`%s`, `%lld`/`%d`→`%d`, `%%`→`%%`, escape `'`→`\'`, `"`→`\"`, `&`/`<` XML, a capo `\n`; (5) `Mancano %lld giorni` → `<plurals>` (it/en/de/es/fr: one/other; ja/zh: other; attenzione al `zero` iOS che Android non supporta fuori da pochi locali: per 0 usare `other`); (6) chiavi `demo.*` e nomi categoria predefinita come stringhe normali; (7) fallisce (exit≠0) se un segnaposto differisce tra lingue.
- Regole d'uso: nel codice **mai** letterali italiani: sempre `stringResource`. Per i **dati** (non UI) restano le stringhe canoniche italiane (`"Uscita"`, `"Cibo"`, `"Conto Bancario"`, `"settimanale"`, ecc.): si traducono solo in visualizzazione tramite mappa nome-canonico → risorsa (come `NSLocalizedString(name)`); nomi di categorie personalizzate e di conti non si traducono mai e non passano per `String.format`. Le stringhe composte iOS (`"\(label): \(x)"`) vanno rese con segnaposto nel resource, non concatenate.
- Stringhe iOS **non nel catalogo** (italiano hardcoded; da censire con grep e completare nelle 7 lingue su Android): messaggi di errore Auth/SignUp, etichette a11y («Tocca per segnare come…», label Budget/Goal), `"Fissa"`, `"Multi-categoria"`/`"Categoria"`/`"Conto"`/`"Mensile"` in `PlanningBudgetCard` (verificare se presenti nelle 395), `"MODALITÀ DEMO"`, «Trasferimento → …». `[DA VERIFICARE]` con script di confronto chiavi usate nel codice vs `en.lproj`.
- Layout: i testi tedeschi sono lunghi (verifica obbligatoria su chip, tab, header). Formati data/numero/valuta dal locale di sistema; `ja` e `zh` senza plurali; `zh-Hans` → locale `zh-CN`.
- Android 13+: dichiarare `locales_config.xml` (it, en, de, es, fr, ja, zh-Hans) e `android:localeConfig` così Impostazioni di sistema offre la lingua per-app; sotto API 33 segue il sistema.
- Test: confrontare a coppie le schermate (stessa lingua) con simulatore iOS; `Localizable` mancanti = bug.

---

## 7. Checklist funzioni (F-xxx)

Colonna **Android** = confronto con `03_CODICE/bucktrail-android` al 2026-11-21 (commit b68820c): **sì** = presente e uguale · **parziale** = esiste ma diverso/incompleto · **no** = assente. Nota Android: UI tutta in `MainActivity.kt`, 3 tab (Home/Movimenti/Conti), Material `NavigationBar` standard, FAB Material standard, dialog Material per i form, solo EUR/Locale.ITALY, stringhe italiane hardcoded, nessuna categoria, nessun delete.

### Fondamenta e design
| ID | Funzione | Android |
|---|---|---|
| F-001 | Palette Sentiero completa light/dark (≈25 token, §1.1) | sì (B0, `ui/theme/Theme.kt`) |
| F-002 | Tinte categoria (4 tinte, FNV-1a, mappa fissa) | sì (B0/B1, `CategoryTint` + test FNV) |
| F-003 | Font Space Grotesk (M/SB/B) + Inter (R/M/SB), tabular, tracking | sì (B0, 6 font + Inter variabile) |
| F-004 | Scala tipografica DS.Typo + stili form (SF→Inter) | sì (B0, `Typo`; form in Inter) |
| F-005 | Tema segue sistema (mai scelta tema) | sì |
| F-006 | Spaziature/raggi/misure componenti (§1.3) | sì (B0, `Dim`) |
| F-007 | FloatingTabBar (capsula 66, pill attiva) a 5 tab | sì (B0, `FloatingTabBar` 5 tab) |
| F-008 | FAB squircle 58/r20 contestuale per tab | sì (B0; azioni Pianifica vuote fino a B6) |
| F-009 | FAB menu «Spesa/Entrata» + «Trasferimento» | sì (B3, trasferimento apre `AddTransferForm`) |
| F-010 | Componenti: Card, HeroCard, HomeHeroCard, ProgressBar, BudgetStatus, SegmentedPill, FilterChip, EmptyState, MonthBar, SectionLabel, ThinDivider, UnderlineSegment, PrimaryButton/Ghost | parziale (B0: Card, HeroCard, ProgressBar, BudgetStatus, SegmentedPill, FilterChip, EmptyState, MonthBar, SectionLabel, ThinDivider, UnderlineSegment, Primary/Ghost; mancano FixedTotalTile extra e banner) |
| F-011 | MovementRow Sentiero (icona 38 tinta, varianti pianificato/transfer/entrata, `repeat`) | sì (B0, `MovementRow`) |
| F-012 | Ombre (tab bar, FAB, banner) | sì (tab bar, FAB) |
| F-013 | Haptic (soft/medium) | parziale (B2/B3: swipe, FAB) |
| F-014 | Icone: mappa SF → vettori Android (§1.5) | sì (B0, `SfIcons`, 100+ nomi) |
| F-015 | Layout accessibile (font grandi), contenuti oltre tab bar (94 + 100) | parziale (B7: padding 94+100 su tutte le schermate a scorrimento, font 1,6× verificato su Statistiche/Impostazioni; resto da ricontrollare) |
| F-016 | Splash + stato iniziale | no |

### Dati e dominio
| ID | Funzione | Android |
|---|---|---|
| F-020 | Entità Account completa (tipo, esclusione, archivio, colorHex) | sì (B1, Room v3) |
| F-021 | Entità Transaction completa (categoria, fissa, trasferimento, template…) | sì (B1) |
| F-022 | Budget, Goal, Category, RecurringRule su Room | sì (B1 entità+DAO; UI nei blocchi successivi) |
| F-023 | Migrazione Room 2→3 preservando i dati | sì (B1, `Migration2To3` + test JDBC + prova su emulatore) |
| F-024 | Importi BigDecimal/centesimi + `parseAmount` identico | sì (B1, `Amounts`) |
| F-025 | Formattazione valuta per locale+valuta scelta | no (Locale.ITALY, EUR) |
| F-026 | Saldo attuale/futuro per conto (§3.2) | sì (B1, `Balance`) |
| F-027 | Saldo atteso fine mese con competenza S-41 (§3.3) | sì (B1/Home, competenza S-41) |
| F-028 | BalanceTrail (serie actual/projected/marks) | sì (B1, `BalanceTrail` + test) |
| F-029 | Categorie predefinite + seed + migrazione icone | sì (B1, seed categorie) |
| F-030 | Classificatore keyword (T1–T5, soglia 6, JSON 65 KB) | parziale (B1 algoritmo + test; JSON in assets, non ancora collegato a tutte le schermate) |
| F-031 | LastUsedCategory (cronologia nome→categoria) | sì (B1 dominio + test) |
| F-032 | RecurrenceCalculator (settimanale/mensile/annuale, eccezioni, UUIDv5) | sì (B1, UUIDv5 + codec + test) |
| F-033 | RecurringMaterializer (watermark, 36 mesi, rollback) | sì (B5, `RecurringOps.materialize` su Room in transazione; avvio, cambio giorno, nuove regole; test) |
| F-034 | RecurringSeriesEditor (solo questa/seguenti/tutte, salta, termina) | sì (B5, `RecurringOps.apply`: solo questa/seguenti/tutte, salta mese, termina, elimina, rollback; 17 test portati da iOS) |
| F-035 | RecurringSeriesDetector (serie rilevate) | sì (B1 dominio) |
| F-036 | Trasferimenti a due gambe con `transferGroupId` | no |
| F-037 | Budget: spesa per categoria/conto/mese, soglie 80/100 | sì (B6, spesa per mese/categoria/conto, soglie 80/100) |
| F-038 | Obiettivi: progresso, aggiunta risparmio, completamento | sì (B6, progresso, aggiungi risparmio, completamento) |
| F-039 | Rettifica saldo alla modifica conto | no |
| F-040 | Cronologia modifiche (audit log) | sì (B8, `AuditTracker` confronta le istantanee dei dati reali → `audit-log.jsonl` append-only; foglio «Cronologia modifiche»; test `AuditLogTest`; `clearAll()` pronto per B9) |
| F-041 | Preferenze locali (DataStore) per tutte le chiavi di §2 | parziale (B1 `AppPrefs` DataStore) |
| F-042 | Orologio/ricalcolo al cambio giorno/fuso | parziale (tick 30 s) |

### Schermate
| ID | Funzione | Android |
|---|---|---|
| F-050 | Home: header data + wordmark + pulsanti occhio/impostazioni | sì (B4, data+wordmark, occhio persistito, ingranaggio) |
| F-051 | Home: HomeHeroCard con saldo attuale | sì (B4) |
| F-052 | Home: TrailView (curva mese reale/proiettata) | sì (B4, TrailView Canvas) |
| F-053 | Home: Saldo atteso + riepilogo pianificati | sì (B4, competenza S-41) |
| F-054 | Home: carosello conti (card 148, saldo futuro) | sì (B4, carosello card 148) |
| F-055 | Home: ordine/visibilità conti (`HomeAccountOrderSheet`) | sì (B2, `HomeAccountOrderSheet`: check, trascina, salva) |
| F-056 | Home: «Fissi del mese» (2 tile, toggle Impostazioni) | sì (B4, Fissi del mese) |
| F-057 | Home: Ultimi movimenti (4, collassabile, vuoto, swipe/menu) | sì (B4, 4 voci, collasso, swipe/menu) |
| F-058 | Oscura importi (persistito, `•••• €`/`• • •`) | sì (B4, persistito) |
| F-059 | Movimenti: titolo, ricerca per nome | sì (B3) |
| F-060 | Movimenti: chip tipo (Tutti/Fisse/Trasf./Uscite/Entrate) | sì (B5, chip Ricorrenti → pagina) |
| F-061 | Movimenti: menu Mese e Categoria | sì (B3) |
| F-062 | Movimenti: filtri avanzati (importo, periodo) + badge + persistenza | sì (B3, sheet Filtri + badge + chip riepilogo + persistenza min/max/periodo) |
| F-063 | Movimenti: sezione «In arrivo · pianificati» | sì (B3) |
| F-064 | Movimenti: gruppi per giorno con totale | sì (B3, per data; totale giorno senza trasferimenti) |
| F-065 | Movimenti: swipe Conferma/Pianificato ed Elimina | sì (B3, swipe elimina/conferma/pianificato + menu) |
| F-066 | Movimenti: menu contestuale (Ricorrenza/Elimina) | sì (B5, menu Ricorrenza; elimina copia di serie apre l'editor) |
| F-067 | Movimenti: eliminazione trasferimento con conferma | sì (B3, dialog elimina entrambe le gambe) |
| F-068 | Movimenti: pagina Ricorrenti (regole + serie rilevate) | sì (B5, pagina Ricorrenti: ricerca, categorie, serie programmate + rilevate) |
| F-069 | Movimenti: occorrenze virtuali mesi futuri | sì (B5, occorrenze virtuali nei mesi futuri) |
| F-070 | Movimenti: stati vuoti (nessun movimento / nessun risultato) | sì (B3) |
| F-071 | Dettaglio serie rilevata (Storico) | sì (B5, dettaglio serie rilevata + Storico) |
| F-072 | Editor ricorrenza (ambiti, salta mese, termina, elimina) | sì (B5, editor ricorrenza con annulla dopo elimina) |
| F-073 | Aggiungi movimento: importo/descrizione/categoria/conto/data/note | sì (B3) |
| F-074 | Aggiungi movimento: tipo Uscita/Entrata (UnderlineSegment) | sì (B3) |
| F-075 | Aggiungi movimento: categoria auto (storico + classificatore, debounce 280) | sì (B3, storico «Ultima usata» + classificatore, debounce 280) |
| F-076 | Aggiungi movimento: picker categoria + gestione categorie | sì (B3, `CategoryPickerSheet` + Gestisci) |
| F-077 | Aggiungi movimento: spesa/entrata fissa + «Già effettuato» | sì (B3, fissa + «Già effettuato») |
| F-078 | Aggiungi movimento: ricorrenza (nessuna/sett./mens./ann.) | sì (B5, picker Nessuna/Settimanale/Mensile/Annuale) |
| F-079 | Modifica movimento (anche copia di serie → serie intera) | sì (B5, modifica copia = edit(all), «fatto» locale) |
| F-080 | Elimina movimento | sì (B3, con «Annulla») |
| F-081 | Notifiche post-salvataggio (budget, soglia saldo) | sì (B8, dopo Uscita fatta: avvisi budget del mese ≥80%; dopo movimento fatto con conto: soglia saldo; ritardi 2 s / 1 s) |
| F-082 | Aggiungi/modifica trasferimento | sì (B3, `AddTransferForm`) |
| F-083 | Statistiche: header, PDF, MonthBar | sì (B7, titolo, pulsante PDF con spinner, MonthBar indipendente, ingranaggio) |
| F-084 | Statistiche: 3 tile Uscite/Entrate/Netto | sì (B7, tile Uscite/Entrate/Netto hero, `FitText` .65) |
| F-085 | Statistiche: Andamento barre 6M/12M + medie | sì (B7, barre affiancate in Canvas 6M/12M, legenda, etichette mese/iniziale, «Uscite medie», riepilogo a11y) |
| F-086 | Statistiche: Per categoria + confronto mese scorso | sì (B7, Per categoria con %, importo, barra in tinta; variazione vs mese scorso) |
| F-087 | Statistiche: media 12 mesi + anno vs anno | sì (B7, media su soli mesi >0 + Anno vs Anno con ↑/↓ e %) |
| F-088 | Pianifica: segmented Budget/Obiettivi, header | sì (B6) |
| F-089 | Budget: hero «Budget usato» + tacca 80% + giorni (plurale) | sì (B6) |
| F-090 | Budget: card per budget + stato (NN%/Soglia 80%/Sforato) | sì (B6) |
| F-091 | Aggiungi budget (multi-categoria, icona, conto, limite) | sì (B6, multi-categoria, icona, conto, limite) |
| F-092 | Storico budget (6 mesi) | sì (B6, ultimi 6 mesi) |
| F-093 | Elimina budget (menu) | sì (B6, long-press) |
| F-094 | Obiettivi: hero con anello, card, scadenza, `+` | sì (B6, anello hero) |
| F-095 | Aggiungi/modifica obiettivo (36 icone, scadenza, aggiungi risparmio) | sì (B6, 36 icone, scadenza, aggiungi risparmio) |
| F-096 | Elimina obiettivo | sì (B6, long-press) |
| F-097 | Conti: hero patrimonio + «A conti fatti» | sì (B2) |
| F-098 | Conti: gruppi Liquidità / Risparmio e investimenti con totali | sì (B2) |
| F-099 | Conti: AccountRow (tinta tipo, soglia, escluso, → futuro) | sì (B2, soglia, escluso, → futuro) |
| F-100 | Conti: aggiungi conto semplice (nome+saldo) | sì (B2) |
| F-101 | Conti: tipo, escludi dal totale, soglia saldo basso | sì (B2) |
| F-102 | Conti: modifica (con rettifica saldo) | sì (B2, rettifica saldo) |
| F-103 | Conti: archivia/ripristina, sezione Archiviati | sì (B2) |
| F-104 | Conti: elimina con conferma (cascade) | sì (B2, alert con N movimenti) |
| F-105 | Conti: escludi/includi (menu) | sì (B2) |
| F-106 | Gestione categorie (aggiungi/rinomina/elimina, 48 icone) | sì (B2, 48 icone, rinomina riscrive transazioni e budget) |
| F-107 | Impostazioni: lingua, valuta (con conferma), notifiche, report mensile | sì (B2 lingua e valuta con conferma; B8 «Avvisi automatici» + «Report mensile PDF» con permesso Android 13+; revert del toggle se il permesso è negato) |
| F-108 | Impostazioni: blocco app biometrico + disattivazione protetta | sì (B8, `BiometricPrompt` biometria + PIN; spegnere richiede autenticazione; disabilitato senza sblocco configurato) |
| F-109 | Impostazioni: toggle Home (fissi) | sì (B2) |
| F-110 | Impostazioni: export CSV / JSON | sì (B7, «Genera CSV» → «Condividi CSV», JSON completo; formati §5.6, test `ExportsTest`) |
| F-111 | Impostazioni: modalità demo + banner | sì (B8, DB Room separato `bucktrail-demo.db`, toggle senza riavvio, pillola «MODALITÀ DEMO»; nessun avviso né audit in demo) |
| F-112 | Impostazioni: sezione Siri/Scorciatoie, Info (versione, n. transazioni) | parziale (B2: Info; scorciatoie in B10) |
| F-113 | Impostazioni: Account (email, esci, elimina account con ELIMINA) | no |
| F-114 | Pull-to-refresh con sync manuale | no |
| F-115 | Dati demo (seeder v6) | sì (B8, `DemoData` = `DemoDataSeeder` v6: 4 conti, 9 serie, 201 movimenti, 40 budget, 4 obiettivi; test `DemoDataTest`) |

### Auth, sync, piattaforma
| ID | Funzione | Android |
|---|---|---|
| F-120 | Login email/password | no |
| F-121 | Registrazione (conferma password, mail di conferma) | no |
| F-122 | Reset password | no |
| F-123 | Sessione persistita + schermata splash | no |
| F-124 | Blocco app (overlay, background/foreground) | sì (B8, velo a tutto schermo anche come finestra sopra i fogli; blocca in background, chiede PIN/biometria all'avvio e al ritorno; fade .2 s) |
| F-125 | Push Supabase (upsert + orfani, dirty tx) | no |
| F-126 | Pull Supabase (merge campo per campo, guardie) | no |
| F-127 | syncOnLogin / foreground / background / debounce 1,5 s | no |
| F-128 | Resilienza: backoff, stato rete, retry | no |
| F-129 | Banner stato sync | no |
| F-130 | Isolamento multi-utente + clearLocalData | no |
| F-131 | Elimina account (RPC) | no |
| F-132 | Compatibilità dati cross-platform (UUID maiuscoli, UUIDv5, exceptions) | no |
| F-133 | Notifiche locali (budget, fisse, obiettivi, soglia, report) | sì (B8, budget/soglia immediati; fisse 1° 09:00, report 1° 10:00, obiettivo −7 giorni con `AlarmManager.setAndAllowWhileIdle`; ripianificate all'avvio e dopo il riavvio; test `NotificationRulesTest`) |
| F-134 | Permesso notifiche (Android 13+) + canale | sì (B8, `POST_NOTIFICATIONS` runtime, richiesto al primo avvio e attivando il toggle; canale «Avvisi Bucktrail») |
| F-135 | Export PDF mensile | sì (B7, `PdfDocument` A4 con le misure iOS, valuta scelta; impaginazione pura testata in `PdfReportTest`) |
| F-136 | Share sheet / FileProvider | sì (B7, `FileProvider` + `ACTION_SEND` da cache privata, svuotata alla chiusura delle Impostazioni) |
| F-137 | Scorciatoie app (Aggiungi spesa/entrata/Saldo) ↔ App Intents | no |
| F-138 | Widget Glance (saldo, aggiungi spesa) — *extra Android* | no |
| F-139 | Quick Settings Tile — *extra Android* | no |
| F-140 | Assistant App Actions — *extra Android* | no |
| F-141 | Localizzazione 7 lingue + pipeline + locales_config | parziale (B0: script + 7 lingue + locales_config; stringhe extra Android da completare in B11) |
| F-142 | Accessibilità (TalkBack, label, identificatori test) | parziale (1 contentDescription) |
| F-143 | Test: porting test dominio iOS + UI test principali | parziale (2 file test) |
| F-144 | Icona app Bucktrail | sì |
| F-145 | Persistenza locale offline | sì |

---

## 8. Ordine di costruzione consigliato (blocchi eseguibili uno alla volta)

Regola per ogni blocco: l'agente legge **solo** questo file (§ indicate) + i file iOS citati; chiude con `./gradlew assembleDebug lintDebug testDebugUnitTest` verdi, confronto visivo col simulatore/mockup (skill: verifica col mockup, bordi/badge), aggiornamento di §7 (colonna Android) e DIARIO/CONSEGNA. Niente Supabase reale prima di B9.

| # | Blocco | Perimetro (§) | Dipende da | Collaudo |
|---|---|---|---|---|
| **B0** | **Fondamenta design e shell** | §1 intero, F-001…F-016, F-141 (solo pipeline stringhe + 7 lingue base), navigazione a 5 tab con FloatingTabBar, FAB contestuale (azioni vuote), componenti base con preview, mappa icone, font mancanti, `locales_config`. Nessuna logica dati. | — | screenshot light/dark/font grande confrontati con mockup; test colori/tinte FNV |
| **B1** | **Modello dati e dominio puro** | §2, §3 (3.1 formati, 3.2 saldo, 3.3 BalanceTrail, 3.4 ricorrenze calcolo+materializzazione+editor+detector, 3.8 classificatore, 3.5/3.6 budget e obiettivi), migrazione Room 2→3, repository, DataStore prefs. Modulo `domain/` senza Android + test JUnit portati da `MoneyTrackerTests` (vettori UUIDv5/exceptions generati su iOS). | B0 | test unitari; migrazione testata su `schemas/1.json,2.json` |
| **B2** | **Conti e Impostazioni base** | §4.7, §4.9 (valuta+conferma, Home toggle, Info, lingua), `AddAccountView` completa (tipo, esclusione, soglia, rettifica), archivio, elimina, Gestione categorie §4.8, oscura importi persistito | B1 | flussi UI Conti/Categorie |
| **B3** | **Movimenti e inserimento** | §4.2 (senza Ricorrenti/virtuali), §4.3 senza ricorrenza, §4.4 trasferimenti, categoria automatica, fisse/già effettuato, swipe Conferma/Elimina, menu, filtri avanzati, ricerca, gruppi per giorno, vuoti | B1, B2 | UI test aggiunta/modifica/elimina/trasferimento; confronto con mockup `Movimenti` |
| **B4** | **Home** | §4.1 completa (hero+TrailView Canvas, carosello conti, order sheet, Fissi, Ultimi movimenti, saldo atteso competenza S-41) | B1–B3 | confronto `Main.dc.html`; test BalanceTrail |
| **B5** | **Ricorrenze (UI)** | §4.2 pagina Ricorrenti, virtuali, `RecurrenceEditorView`, `ProgrammedRuleCard`, `RecurringSeriesDetailView`, ricorrenza in `AddTransaction`, modifica copia di serie, materializzazione agli avvii (foreground/cambio giorno) | B1, B3 | test iOS RecurringSeriesEditor/Materializer portati; UI test |
| **B6** | **Pianifica: Budget e Obiettivi** | §4.6 completa, notifica budget/soglia post-salvataggio (stub se B8 non fatto), storico budget | B1–B3 | mockup `Pianifica` |
| **B7** | **Statistiche ed Export** | §4.5 (grafici Compose Canvas, no librerie pesanti), PDF (PdfDocument), CSV, JSON, share | B1–B3 | mockup `Statistiche`; confronto PDF con iOS |
| **B8** | **Notifiche, blocco app, audit, demo** | §5.5 notifiche (permesso, alarm, boot), §4.10 AppLock (BiometricPrompt), §4.11 audit log, §4.12 modalità demo (DB separato + seeder v6 + banner), Impostazioni complete §4.9 (sicurezza, demo, esportazioni già B7) | B1–B7 | test seeder = numeri iOS; test notifiche programmate |
| **B9** | **Auth e Sync Supabase** | §4.10 Login/SignUp/Reset, §5.1–5.3, banner sync, clearLocalData, elimina account, regole di compatibilità §5.2, pull-to-refresh. **Prima** su progetto Supabase di test; prova a due dispositivi (iOS+Android) con dati sintetici: duplicati, ricorrenze, trasferimenti, cancellazioni | B1, B5, B8 | test con `MockEngine`; scenario cross-platform documentato |
| **B10** | **Scorciatoie, widget e Assistant** | §5.4 QuickAddActivity, shortcuts, Glance widget, Quick Tile, App Actions, stesso repository + dirty tracking | B3, B9 | prove su emulatore + dispositivo |
| **B11** | **Localizzazione completa, accessibilità e collaudo di parità** | §6 (censire stringhe hardcoded, completare 7 lingue, verifica tedesco), TalkBack/test tag (id di §4), font scale, stress test (`stress-test`), riesame di §7 e di §4.99, pagella | tutti | pagella + collaudatore |

Note di pianificazione: (1) B0 deve già imporre `stringResource` (niente rilavorazione in B11); (2) B1 deve già salvare i campi necessari al sync (UUID maiuscoli per `templateId`/`transferGroupId`, `isDone`, `createdAt`) anche se il sync arriva in B9; (3) B3 e B5 condividono `AddTransaction`: la ricorrenza si aggiunge in B5 senza cambiare lo schema; (4) un agente per blocco; ogni blocco = un commit e una voce in `.cantiere/PIANO.md`.
