# MoneyTracker — Audit Report
Data: 2026-06-23  
Scope: 17 file Swift (SwiftUI + SwiftData, iOS)

---

## Tabella problemi

| File | Riga | Categoria | Descrizione | Stato |
|------|------|-----------|-------------|-------|
| `Models.swift` | 269–280 | **Performance** | `Double.currencyFormatted`, `currencySymbol` allocavano un nuovo `NumberFormatter` ad ogni chiamata — path caldissimo (usato in ogni row di ogni lista) | ✅ Fixato |
| `Models.swift` | 285–296 | **Performance** | `Date.monthYearFormatted` e `Date.dayMonthFormatted` allocavano un nuovo `DateFormatter` ad ogni chiamata — usate dentro `body` in moltissime view | ✅ Fixato |
| `Theme.swift` | 466 | **Performance** | `MonthBar.label` allocava un `DateFormatter` ad ogni render della view | ✅ Fixato |
| `StatisticsView.swift` | 522–529 | **Performance** | `Date.shortMonthFormatted` allocava un `DateFormatter` ad ogni chiamata — usata nel loop dei trend | ✅ Fixato |
| `AccountsView.swift` | 265 | **Correttezza** | Simbolo valuta `"€"` hardcoded invece di `Double.currencySymbol` — non si aggiornava al cambio valuta in Settings | ✅ Fixato |
| `AddTransferView.swift` | 36 | **Correttezza** | Simbolo valuta `"€"` hardcoded invece di `Double.currencySymbol` | ✅ Fixato |
| `DashboardView.swift` | 155–167 | **Performance** | `monthTotal` e `topCats` iteravano `monthExpenses` separatamente (due passate sull'array). Ora calcolano total + top-cats in un unico passaggio con `monthStatsCache` | ✅ Fixato |
| `TransactionsView.swift` | 96–97 | **Performance** | `monthIncome` e `monthExpenses` accedevano direttamente a `filtered` — aggiunto `filteredSnapshot` per centralizzare l'accesso e rendere esplicita la dipendenza dalla stessa computed property | ✅ Fixato |
| `CategoryClassifier.swift` | 1736–1749 | **Dead code** | `suggestions(for:max:)` mai chiamata nel codebase — duplicava esattamente il body di `classify(_:)` | ✅ Rimossa |
| `NotificationManager.swift` | 53 | **Performance** | `checkBudgets` carica tutte le transazioni `isDone == true` senza filtro mese al livello del DB; poi filtra in memoria. Per DB grandi questo può essere costoso. | ⚠️ Suggerimento |
| `BudgetView.swift` | 443 | **Performance** | `BudgetHistorySheet.spent(in:for:)` filtra l'intero array `transactions` per ogni budget × mese nel loop. Con molti budget/transazioni può essere lento. | ⚠️ Suggerimento |
| `StatisticsView.swift` | 63–84 | **Performance** | `last12Stats` e `monthlyTrend` iterano l'intero array `transactions` N volte (12 e 6 iterazioni), chiamate in `body`. Accettabile per dataset normali ma potrebbe degradare con migliaia di transazioni. | ⚠️ Suggerimento |
| `Models.swift` | 322–411 | **Correttezza** | `Transaction.processRecurring` usa `try?` silenziosamente; in caso di errore il salvataggio fallisce senza log. Conservativo: non critico all'avvio, ma difficile da diagnosticare. | ⚠️ Suggerimento |

---

## Fix applicati

### 1. `FormatterCache` — cache centralizzata per formatter costosi (`Models.swift`)
Introdotto `enum FormatterCache` con:
- `currencyFormatter()` — `NumberFormatter` con currency riutilizzato, ricreato solo al cambio del codice valuta
- `monthYear` — `DateFormatter("MMMM yyyy")` singleton
- `dayMonth` — `DateFormatter("d MMM")` singleton
- `shortMonth` — `DateFormatter("MMM")` singleton per i grafici

`Double.currencyFormatted`, `Double.currencySymbol`, `Date.monthYearFormatted`, `Date.dayMonthFormatted` ora usano tutti questi singleton.

**Impatto**: eliminata la creazione di N oggetti `NumberFormatter`/`DateFormatter` per ogni render di ogni row — riduzione allocazioni heap in path caldi.

---

### 2. `MonthBar.label` usa `monthYearFormatted` (`Theme.swift`)
Rimosso `DateFormatter` locale all'interno di `label`. Ora delega a `Date.monthYearFormatted` che usa `FormatterCache.monthYear`.

---

### 3. `Date.shortMonthFormatted` usa `FormatterCache` (`StatisticsView.swift`)
Rimosso il `DateFormatter` allocato inline nel computed property. Ora usa `FormatterCache.shortMonth`.

---

### 4. Simbolo valuta dinamico in `AddAccountView` e `AddTransferView`
`Text("€")` sostituito con `Text(Double.currencySymbol)` nei due form. Prima, cambiare valuta in Settings (es. USD) lasciava "$" nel campo importo ma mostrava "€" nel form di aggiunta conto/trasferimento.

---

### 5. `monthStatsCache` — passata unica su `monthExpenses` (`DashboardView.swift`)
`monthTotal` e `topCats` leggevano `monthExpenses` separatamente (due `filter` + due `reduce`/loop sull'array). Ora `monthStatsCache` compila totale e dizionario categorie in una sola iterazione.

---

### 6. `filteredSnapshot` — accesso centralizzato ai dati filtrati (`TransactionsView.swift`)
`monthIncome`, `monthExpenses`, e i controlli di visibilità nella lista leggevano `filtered` indipendentemente. Ora tutti passano per `filteredSnapshot` (alias di `filtered`) che rende esplicito il fatto che sono derivati dallo stesso filtro applicato.

---

### 7. Rimossa funzione dead `CategoryClassifier.suggestions(for:max:)` (`CategoryClassifier.swift`)
La funzione duplicava completamente il body di `classify(_:)` e non veniva chiamata in nessun file del progetto.

---

## Suggerimenti non implementati

### A. `NotificationManager.checkBudgets` — fetch troppo ampio
Il fetch `#Predicate { $0.isDone }` carica tutte le transazioni completate, poi filtra il mese in memoria. Con un DB grande (migliaia di transazioni) questo è O(N) a ogni salvataggio di una transazione.
**Suggerimento**: aggiungere un filtro mese/anno al predicate (richiederebbe di passare i componenti come valori scalari, dato che SwiftData non supporta predicati su computed properties).

### B. `BudgetHistorySheet.spent(in:for:)` — O(N × budget × mesi)
Per ogni mese (6) × ogni budget del mese la funzione scansiona `transactions` completo. Andrebbero pre-raggruppate le uscite per mese una volta sola, poi usate nel loop.

### C. `StatisticsView` — `last12Stats` e `monthlyTrend` sono O(N × 12) / O(N × 6)
Per ogni mese si fa `.filter { isSameMonth }` sull'intero array transactions. Con migliaia di transazioni e frequenti cambi di `selectedMonth` può essere percettibile. Soluzione: usare un `Dictionary<Date, [Transaction]>` raggruppato per mese.

### D. `Transaction.processRecurring` — errori silenziosi
`try? context.save()` al termine del processo ricorrente non logga l'errore. Non critico (il processo tenterà di nuovo al prossimo lancio), ma conviene almeno un `print` in DEBUG per diagnosi.
