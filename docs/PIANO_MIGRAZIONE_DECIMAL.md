# Piano di migrazione: Double → Decimal (rilascio dedicato)

**Stato:** pianificato, non iniziato
**Tipo di rilascio:** dedicato — nessuna altra feature nello stesso ciclo
**Rischio:** alto (schema del database locale + contratto di sync). Mitigato da backup pre-migrazione, migrazione custom testata e rollout graduale.
**Prerequisito già in produzione:** `Double.parseAmount` quantizza ogni importo al centesimo in ingresso, quindi i dati esistenti sono già "puliti" — la migrazione parte da una base sana.

---

## 1. Perché

`Double` rappresenta il denaro in base 2: 0.10 non esiste esattamente, e ogni somma accumula un errore infinitesimale. Oggi l'errore è innocuo (quantizzazione in ingresso + arrotondamento del formatter in uscita), ma `Decimal` elimina la classe di problemi alla radice: l'aritmetica avviene in base 10, come i soldi. È lo standard per il software finanziario serio ed è il prerequisito per funzioni future che moltiplicano/dividono denaro (quote, interessi, split di spese, multi-valuta).

## 2. Perimetro esatto (inventario)

### Modelli SwiftData (5 proprietà, 4 modelli)
| Modello | Proprietà | Note |
|---|---|---|
| `Transaction` | `amount` | + computed `signedAmount` |
| `Account` | `initialBalance` | + computed `currentBalance`, `futureBalance`, `plannedDelta` |
| `Budget` | `monthlyLimit` | |
| `Goal` | `targetAmount`, `currentAmount` | + computed `progress`, `remaining` |

### Contratto Supabase (SyncService.swift)
DTO da aggiornare: `SBTransaction.amount`, `SBAccount.initialBalance`, `SBBudget.monthlyLimit`, `SBGoal.targetAmount/currentAmount`.
Tabelle: `mt_transactions`, `mt_accounts`, `mt_budgets`, `mt_goals`.

### Confini dove Double resta legittimo (conversione al bordo)
- **Swift Charts** (StatisticsView): plottare richiede `Double` → convertire al momento del plot.
- **String(format:)** in PDF e CSV → passare da `NSDecimalNumber` o formatter.
- **AppIntents** (`amount: Double` da Siri): il tipo del parametro resta Double, conversione+quantizzazione immediata a `Decimal` in `perform()`.
- **UI %/progress** (barre, GeometryReader): i rapporti adimensionali possono restare Double.

### Utility da migrare
- `Double.parseAmount` → `Decimal.parseAmount` (la logica interna è GIÀ in Decimal: basta non convertire più a Double in uscita).
- `currencyFormatted` / `currencyCompact` → extension su `Decimal` (NumberFormatter accetta `NSDecimalNumber` nativamente).
- Tutti i `reduce(0.0)` sui flussi di denaro → `reduce(Decimal.zero)`.

## 3. Strategia tecnica: VersionedSchema + migrazione custom

Il cambio di tipo di un attributo NON è una migrazione lightweight. Serve il meccanismo formale di SwiftData:

```
enum SchemaV1: VersionedSchema { … modelli attuali con Double … }
enum SchemaV2: VersionedSchema { … modelli con Decimal … }

enum MoneyTrackerMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self, SchemaV2.self] }
    static var stages: [MigrationStage] { [migrateV1toV2] }

    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion:   SchemaV2.self,
        willMigrate: nil,
        didMigrate:  { context in
            // Pass di riparazione: ogni valore convertito viene ANCHE
            // quantizzato al centesimo — sistema eventuali dati legacy sporchi.
        }
    )
}
```

Punti d'attenzione:
1. **Entrambi i container** (reale e demo) usano lo stesso schema: la migrazione va applicata a tutti e due in `MoneyTrackerApp.init()`.
2. **Backup pre-migrazione:** prima di aprire il container V2, copiare il file `.store` (+ `-wal`, `-shm`) in `Application Support/backup-v1/`. Se la migrazione fallisce → si può ripristinare e tornare all'ultima build V1.
3. **Conversione con quantizzazione:** ogni Double → `Decimal(string: String(format: "%.2f", d))` (mai `Decimal(d)`, che erediterebbe il rumore binario).
4. Il fallback in-memory esistente resta come ultima rete di sicurezza.

## 4. Migrazione Supabase (da eseguire PRIMA del rilascio app)

Postgres: le colonne diventano `numeric(12,2)`. La conversione da `double precision` è lossless per valori già a 2 decimali:

```sql
ALTER TABLE mt_transactions ALTER COLUMN amount          TYPE numeric(12,2) USING round(amount::numeric, 2);
ALTER TABLE mt_accounts     ALTER COLUMN initial_balance TYPE numeric(12,2) USING round(initial_balance::numeric, 2);
ALTER TABLE mt_budgets      ALTER COLUMN monthly_limit   TYPE numeric(12,2) USING round(monthly_limit::numeric, 2);
ALTER TABLE mt_goals        ALTER COLUMN target_amount   TYPE numeric(12,2) USING round(target_amount::numeric, 2),
                            ALTER COLUMN current_amount  TYPE numeric(12,2) USING round(current_amount::numeric, 2);
```

Compatibilità: `numeric` in JSON viaggia come number → i client V1 (Double) continuano a funzionare durante la transizione. I DTO V2 usano `Decimal`, che `JSONDecoder`/`JSONEncoder` gestiscono nativamente. **Verificare col PostgREST di Supabase il round-trip di un valore sentinella (es. 0.10) in entrambe le direzioni prima del rollout.**

Ordine obbligato: prima il DB (retro-compatibile), poi l'app.

## 5. Piano di test (gate di rilascio — tutti verdi o non si pubblica)

1. **Unit — parser:** i 19 edge case già validati per `parseAmount`, su `Decimal`.
2. **Unit — aritmetica:** `0.1 + 0.2 == 0.3` esatto; somma di 10.000 transazioni da 0,10 € == 1.000,00 € esatto (con Double fallirebbe al confronto bit a bit).
3. **Migrazione:** fixture di store V1 popolato (transazioni, trasferimenti, ricorrenti, budget, obiettivi, valori sporchi tipo 33.333333) → migrare → verificare conteggi identici, totali identici al centesimo, relazioni intatte.
4. **Sync round-trip:** push V2 → Supabase → pull su installazione pulita → byte-identico al centesimo. Test incrociato V1 client ↔ DB migrato.
5. **Demo container:** seed + tour completi post-migrazione.
6. **UI end-to-end:** grafici (conversione al bordo), PDF, CSV, Siri intents, filtri min/max.
7. **Regressione performance:** Decimal è più lento di Double (~10x su operazioni singole, irrilevante a questa scala) — confermare che Statistiche con 10k transazioni resti fluida; la cache `byMonth` esistente assorbe il costo.

## 6. Rollout

1. Migrazione SQL su Supabase (retro-compatibile con l'app in produzione).
2. Build V2 in **TestFlight** ≥ 1 settimana, con dati reali dei beta tester (la migrazione locale gira al primo avvio: è il punto di rischio massimo).
3. Rilascio App Store **graduale (phased release)**, monitorando i crash del primo avvio.
4. Rollback: l'app non può tornare a V1 dopo la migrazione locale (schema one-way) → in emergenza si ripristina dal backup pre-migrazione fatto al punto 3.2. Tenere pronta una build V1.1 "hotfix" solo come paracadute.

## 7. Ordine dei lavori e stima

| # | Attività | Stima |
|---|---|---|
| 1 | SchemaV1/V2 + MigrationPlan + backup pre-migrazione | 1 giorno |
| 2 | Modelli, computed properties, parser, formatter su Decimal | 0,5 giorni |
| 3 | Call site (viste, reduce, grafici, PDF, CSV, intents) | 1 giorno |
| 4 | DTO sync + SQL Supabase + test round-trip | 0,5 giorni |
| 5 | Suite di test (§5) | 1 giorno |
| 6 | TestFlight + phased release | 1–2 settimane calendario |

Totale sviluppo: **~4 giorni** + finestra di beta.

## 8. Cosa NON fare

- Non mischiare questa migrazione con altre feature o altri cambi di schema.
- Non usare `Decimal(double:)` per convertire — porta con sé il rumore binario.
- Non rilasciare senza il test di migrazione su fixture reale (punto 5.3): è il test che protegge i dati degli utenti.
