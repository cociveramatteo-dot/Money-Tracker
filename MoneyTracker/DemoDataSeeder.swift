import SwiftData
import Foundation

// MARK: - DemoDataSeeder
//
// Popola il container demo con dati realistici su tutte le sezioni dell'app:
// • 4 conti con tipi diversi e saldi credibili
// • ~70 transazioni su 3 mesi (varie categorie, alcune fisse, alcune pianificate)
// • 5 budget mese corrente a diversi livelli di utilizzo
// • 4 obiettivi di risparmio a diversi stadi di avanzamento
//
// Viene eseguito solo se il container demo è vuoto (guard count == 0).
// Non tocca mai il container reale dell'utente.

struct DemoDataSeeder {

    /// Versione del seed — incrementa ogni volta che cambia il contenuto demo.
    /// Se la versione in UserDefaults è diversa, il container viene ripulito e riseminato.
    private static let seedVersion = 5
    private static let seedVersionKey = "demoSeedVersion"

    /// Azzera completamente il container demo e lo risemina con dati freschi.
    /// Chiamato all'avvio del tour per garantire uno stato pulito
    /// indipendentemente da eventuali modifiche fatte in sessioni precedenti.
    @MainActor
    static func forceReset(context: ModelContext) {
        if let accounts     = try? context.fetch(FetchDescriptor<Account>())     { accounts.forEach     { context.delete($0) } }
        if let transactions = try? context.fetch(FetchDescriptor<Transaction>()) { transactions.forEach { context.delete($0) } }
        if let budgets      = try? context.fetch(FetchDescriptor<Budget>())      { budgets.forEach      { context.delete($0) } }
        if let goals        = try? context.fetch(FetchDescriptor<Goal>())        { goals.forEach        { context.delete($0) } }
        context.safeSave()
        Category.seedIfNeeded(context: context)
        seed(context: context)
        UserDefaults.standard.set(seedVersion, forKey: seedVersionKey)
    }

    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let savedVersion = UserDefaults.standard.integer(forKey: seedVersionKey)
        let accountCount = (try? context.fetchCount(FetchDescriptor<Account>())) ?? 0

        if accountCount == 0 || savedVersion < seedVersion {
            // Ripulisci tutto prima di riseminare (evita duplicati su upgrade di versione)
            if accountCount > 0 {
                if let accounts     = try? context.fetch(FetchDescriptor<Account>())     { accounts.forEach     { context.delete($0) } }
                if let transactions = try? context.fetch(FetchDescriptor<Transaction>()) { transactions.forEach { context.delete($0) } }
                if let budgets      = try? context.fetch(FetchDescriptor<Budget>())      { budgets.forEach      { context.delete($0) } }
                if let goals        = try? context.fetch(FetchDescriptor<Goal>())        { goals.forEach        { context.delete($0) } }
                context.safeSave()
            }
            seed(context: context)
            UserDefaults.standard.set(seedVersion, forKey: seedVersionKey)
        }
    }

    @MainActor
    private static func seed(context: ModelContext) {
        let cal = Calendar.current
        let now = Date()

        func date(daysAgo d: Int, hour h: Int = 12) -> Date {
            var c = cal.dateComponents([.year, .month, .day], from: cal.date(byAdding: .day, value: -d, to: now) ?? now)
            c.hour = h; c.minute = 0
            return cal.date(from: c) ?? now
        }

        // MARK: Conti

        let conto    = Account(name: String(localized: "demo.account.conto"),   type: .conto,       initialBalance: 620,   colorHex: "1A1A1A")
        let risparmi = Account(name: String(localized: "demo.account.risparmi"), type: .risparmio,   initialBalance: 3_800, colorHex: "4A4A4A")
        let carta    = Account(name: String(localized: "demo.account.carta"),   type: .carta,       initialBalance: 0,     colorHex: "6A6A6A")
        let contanti = Account(name: String(localized: "demo.account.contanti"), type: .contanti,    initialBalance: 95,    colorHex: "9A9A9A")
        context.insert(conto)
        context.insert(risparmi)
        context.insert(carta)
        context.insert(contanti)

        // MARK: Transazioni — 3 mesi
        // Tupla: (nome, importo, tipo, categoria, icona, giorni fa, conto, isFixed, isDone)

        typealias TxRow = (String, Double, TransactionType, String, String, Int, Account, Bool, Bool)

        // isFixed: true SOLO su Affitto e abbonamenti digitali — gli unici che in una vera app
        // sarebbero segnati come "spesa fissa". Tutto il resto a false per evitare che il
        // swipe sinistro "Fatto/Pianificato" compaia su quasi ogni riga della lista movimenti.
        // Nessuna transazione isDone:false — le pianificate attivano anch'esse il swipe.

        // Localized demo transaction names
        let lStipendio   = String(localized: "demo.tx.stipendio")
        let lAffitto     = String(localized: "demo.tx.affitto")
        let lBolletta    = String(localized: "demo.tx.bolletta")
        let lCarburante  = String(localized: "demo.tx.carburante")
        let lFarmacia    = String(localized: "demo.tx.farmacia")
        let lRegalo      = String(localized: "demo.tx.regalo")
        let lSupermercato = String(localized: "demo.tx.supermercato")
        let lVolo        = String(localized: "demo.tx.volo")
        let lHotel       = String(localized: "demo.tx.hotel")
        let lDentista    = String(localized: "demo.tx.dentista")
        let lCinema      = String(localized: "demo.tx.cinema")
        let lRistorante  = String(localized: "demo.tx.ristorante")
        let lRisparmio   = String(localized: "demo.tx.risparmio")

        let transactions: [TxRow] = [

            (lStipendio,              1_750,  .entrata, "Lavoro",       "briefcase.fill",        27, conto,    false, true),
            (lAffitto,                  650,  .uscita,  "Casa",         "house.fill",            26, conto,    true,  true),
            (lBolletta,                  78,  .uscita,  "Casa",         "house.fill",            25, conto,    false, true),
            ("Esselunga",               87.5, .uscita,  "Cibo",         "fork.knife",            22, conto,    false, true),
            ("Netflix",                 17.99,.uscita,  "Abbonamenti",  "repeat.circle.fill",    21, carta,    true,  true),
            ("Spotify",                  9.99,.uscita,  "Abbonamenti",  "repeat.circle.fill",    21, carta,    true,  true),
            (lCarburante,                58,  .uscita,  "Trasporti",    "car.fill",              18, conto,    false, true),
            ("Trattoria Da Nino",        48,  .uscita,  "Svago",        "gamecontroller.fill",   15, carta,    false, true),
            (lSupermercato,              52.3,.uscita,  "Cibo",         "fork.knife",            10, conto,    false, true),
            (lFarmacia,                  24,  .uscita,  "Salute",       "heart.fill",             7, carta,    false, true),
            (lRegalo,                    45,  .uscita,  "Regali",       "gift.fill",              3, carta,    false, true),

            (lStipendio,              1_750,  .entrata, "Lavoro",       "briefcase.fill",        57, conto,    false, true),
            (lAffitto,                  650,  .uscita,  "Casa",         "house.fill",            56, conto,    true,  true),
            (lBolletta,                  81,  .uscita,  "Casa",         "house.fill",            55, conto,    false, true),
            (lVolo,                     118,  .uscita,  "Viaggi",       "airplane",              52, carta,    false, true),
            (lHotel,                    195,  .uscita,  "Viaggi",       "airplane",              50, carta,    false, true),
            ("Esselunga",               91.2, .uscita,  "Cibo",         "fork.knife",            47, conto,    false, true),
            ("Netflix",                 17.99,.uscita,  "Abbonamenti",  "repeat.circle.fill",    45, carta,    true,  true),
            ("Spotify",                  9.99,.uscita,  "Abbonamenti",  "repeat.circle.fill",    45, carta,    true,  true),
            (lDentista,                 130,  .uscita,  "Salute",       "heart.fill",            42, carta,    false, true),
            (lCinema,                    55,  .uscita,  "Svago",        "gamecontroller.fill",   38, carta,    false, true),

            (lStipendio,              1_750,  .entrata, "Lavoro",       "briefcase.fill",        87, conto,    false, true),
            (lAffitto,                  650,  .uscita,  "Casa",         "house.fill",            86, conto,    true,  true),
            (lBolletta,                  74,  .uscita,  "Casa",         "house.fill",            85, conto,    false, true),
            ("Esselunga",               79.8, .uscita,  "Cibo",         "fork.knife",            82, conto,    false, true),
            ("Netflix",                 17.99,.uscita,  "Abbonamenti",  "repeat.circle.fill",    80, carta,    true,  true),
            ("Spotify",                  9.99,.uscita,  "Abbonamenti",  "repeat.circle.fill",    80, carta,    true,  true),
            (lCarburante,                52,  .uscita,  "Trasporti",    "car.fill",              77, conto,    false, true),
            (lRistorante,                44,  .uscita,  "Svago",        "gamecontroller.fill",   74, carta,    false, true),
            ("Amazon",                   38,  .uscita,  "Shopping",     "bag.fill",              71, carta,    false, true),
        ]

        for tx in transactions {
            let t = Transaction(
                name:         tx.0,
                amount:       tx.1,
                type:         tx.2,
                category:     tx.3,
                categoryIcon: tx.4,
                date:         date(daysAgo: tx.5),
                isDone:       tx.8,
                isFixed:      tx.7,
                account:      tx.6
            )
            context.insert(t)
        }

        // MARK: Spese fisse pianificate (isDone: false)
        // Queste transazioni NON sono ancora confermate → contribuiscono al saldoAtteso
        // ma non al saldoAttuale, rendendo visibile la differenza nella Home e nel tour.
        // date(daysAgo: negativo) = data futura.

        let planned: [(String, Double, String, String, Int, Account)] = [
            (lAffitto,    650,   "Casa",        "house.fill",           -5, conto),
            ("Netflix",    17.99, "Abbonamenti", "repeat.circle.fill",  -8, carta),
            (lBolletta,    78,    "Casa",        "bolt.fill",           -12, conto),
            ("Spotify",     9.99, "Abbonamenti", "repeat.circle.fill",  -15, carta),
        ]
        for p in planned {
            let t = Transaction(
                name:         p.0,
                amount:       p.1,
                type:         .uscita,
                category:     p.2,
                categoryIcon: p.3,
                date:         date(daysAgo: p.4),
                isDone:       false,
                isFixed:      true,
                account:      p.5
            )
            context.insert(t)
        }

        let transferId = UUID().uuidString
        let tOut = Transaction(name: lRisparmio, amount: 300, type: .uscita,
                               category: "Giroconto", categoryIcon: "arrow.left.arrow.right",
                               date: date(daysAgo: 20), isDone: true,
                               isTransfer: true, transferGroupId: transferId, account: conto)
        let tIn  = Transaction(name: lRisparmio, amount: 300, type: .entrata,
                               category: "Giroconto", categoryIcon: "arrow.left.arrow.right",
                               date: date(daysAgo: 20), isDone: true,
                               isTransfer: true, transferGroupId: transferId, account: risparmi)
        context.insert(tOut)
        context.insert(tIn)

        // MARK: Budget mese corrente

        let m = cal.component(.month, from: now)
        let y = cal.component(.year,  from: now)

        let budgets: [(String, String, Double)] = [
            ("Cibo",        "fork.knife",          280),   // ~90% utilizzato
            ("Svago",       "gamecontroller.fill",  150),   // ~70%
            ("Abbonamenti", "repeat.circle.fill",    40),   // ~80%
            ("Trasporti",   "car.fill",             180),   // ~85%
            ("Salute",      "heart.fill",           200),   // ~57%
        ]
        for b in budgets {
            context.insert(Budget(category: b.0, categoryIcon: b.1, monthlyLimit: b.2, month: m, year: y))
        }

        // Budget mese precedente (per lo storico)
        let prevM = m == 1 ? 12 : m - 1
        let prevY = m == 1 ? y - 1 : y
        let prevBudgets: [(String, String, Double)] = [
            ("Cibo",        "fork.knife",          280),
            ("Svago",       "gamecontroller.fill",  150),
            ("Abbonamenti", "repeat.circle.fill",    40),
            ("Trasporti",   "car.fill",             180),
            ("Viaggi",      "airplane",             400),
        ]
        for b in prevBudgets {
            context.insert(Budget(category: b.0, categoryIcon: b.1, monthlyLimit: b.2, month: prevM, year: prevY))
        }

        // MARK: Obiettivi

        context.insert(Goal(
            name:          String(localized: "demo.goal.vacanza"),
            targetAmount:  2_800,
            currentAmount: 1_960,   // 70%
            emoji:         "airplane",
            deadline:      cal.date(byAdding: .month, value: 2, to: now)
        ))
        context.insert(Goal(
            name:          String(localized: "demo.goal.emergenza"),
            targetAmount:  15_000,
            currentAmount: 12_400,  // 83%
            emoji:         "banknote",
            deadline:      nil
        ))
        context.insert(Goal(
            name:          "MacBook Pro M4",
            targetAmount:  2_499,
            currentAmount: 640,     // 26%
            emoji:         "laptopcomputer",
            deadline:      cal.date(byAdding: .month, value: 8, to: now)
        ))
        context.insert(Goal(
            name:          String(localized: "demo.goal.fotografia"),
            targetAmount:  450,
            currentAmount: 450,     // 100% completato
            emoji:         "camera.fill",
            deadline:      nil
        ))

        context.safeSave()
    }
}
