import Foundation
import OSLog

/// On-device auto-categorization via keyword/stem matching.
/// Returns a category NAME string — must match an existing Category.name in the DB.
/// Falls back to "Altro" if nothing matches.
///
/// HOW STEMS WORK
/// The algorithm uses String.contains(), so a stem like "pizz" matches:
///   "pizza", "pizzeria", "pizzata", "la pizzata di sabato" — all → Cibo
/// Use stems for word families; use full strings for brands/proper nouns.
///
/// SCORING
/// Each match adds word.count points, so longer (more specific) matches win.
/// E.g. "esselunga" (9 pts) beats "bar" (3 pts) on the same input.
///
/// LANGUAGES COVERED
/// 🇮🇹 Italiano · 🇬🇧 English · 🇩🇪 Deutsch · 🇫🇷 Français · 🇪🇸 Español
/// 🇵🇹 Português · 🇷🇴 Română · 🇵🇱 Polski · 🇳🇱 Nederlands · 🇭🇷 Hrvatski · 🇦🇱 Shqip
///
/// NEW CATEGORIES (work when user creates a matching Category in the app)
/// "Stipendio", "Bollette", "Animali", "Bambini"
///
/// DATI
/// Il dizionario keyword→categoria vive in Resources/CategoryKeywords.json (~3600 voci),
/// non più hardcoded in questo file: era un "God File" da quasi 2000 righe che mischiava
/// dati statici e algoritmo. Caricato una sola volta all'init, non ad ogni classify().
// nonisolated: è un motore di classificazione puro (NSCache è thread-safe), senza stato
// legato alla UI — non deve ereditare il default @MainActor del progetto. Questo lo rende
// anche chiamabile da contesti non isolati (es. i test) senza `await`.
nonisolated final class KeywordCategoryClassifier: CategoryClassifying, @unchecked Sendable {

    /// Istanza di produzione: carica Resources/CategoryKeywords.json dal bundle dell'app.
    static let shared = KeywordCategoryClassifier()

    /// Lista piatta pre-normalizzata (lowercase + diacritici rimossi), ordinata per lunghezza desc.
    /// Costruita una sola volta all'init, non al primo accesso.
    private let flatKeywords: [(word: String, cat: String)]

    // MARK: - Result cache (avoids re-classifying identical inputs during typing debounce)
    // countLimit + totalCostLimit prevengono crescita illimitata dell'heap.
    // Con stringhe medie di ~20 char (40 byte UTF-16) il limite di 512 KB copre
    // ~6.400 entry come coppie chiave+valore, molto più del caso d'uso reale.
    private let resultCache: NSCache<NSString, NSString> = {
        let c = NSCache<NSString, NSString>()
        c.countLimit      = 2_000    // max 2 k entry uniche
        c.totalCostLimit  = 512_000  // max 512 KB totali
        return c
    }()

    /// - Parameter keywords: dizionario categoria→keyword da usare. `nil` (produzione)
    ///   carica `Resources/CategoryKeywords.json` dal bundle indicato. Nei test si passa
    ///   un dizionario minimo esplicito: nessuna dipendenza dal bundle o dal file reale.
    nonisolated init(keywords: [String: [String]]? = nil, bundle: Bundle = .main) {
        let source = keywords ?? Self.loadKeywords(from: bundle)
        var pairs: [(word: String, cat: String)] = []
        pairs.reserveCapacity(source.values.reduce(0) { $0 + $1.count })
        for (cat, words) in source {
            for word in words {
                let norm = word.lowercased()
                    .folding(options: .diacriticInsensitive, locale: .current)
                pairs.append((norm, cat))
            }
        }
        self.flatKeywords = pairs.sorted { $0.word.count > $1.word.count }
    }

    private static func loadKeywords(from bundle: Bundle) -> [String: [String]] {
        guard let url = bundle.url(forResource: "CategoryKeywords", withExtension: "json") else {
            Logger.classifier.error("CategoryKeywords.json non trovato nel bundle — il classifier ritornerà sempre \"Altro\"")
            return [:]
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([String: [String]].self, from: data)
        } catch {
            Logger.classifier.error("CategoryKeywords.json illeggibile: \(error.localizedDescription, privacy: .public)")
            return [:]
        }
    }

    // MARK: - Public API

    /// Classifica il testo dell'utente e ritorna la categoria migliore, o "Altro".
    ///
    /// Algoritmo a 5 livelli (peso decrescente):
    ///   T1 – Match esatto parola         ×4.0
    ///   T2 – Prefisso input→keyword      ×2.5  (utente sta ancora scrivendo)
    ///   T3 – Prefisso keyword→input      ×3.0  (keyword è radice della parola scritta)
    ///   T4 – Stem italiano               ×2.0  (plurali, coniugazioni, desinenze)
    ///   T5 – Fuzzy edit-distance 1       ×1.5  (typo recovery, solo per ≥5 char)
    ///
    /// Keyword multi-parola ("penny market") vengono cercate come frase nel testo intero ×3.0.
    /// Confidence threshold: punteggio totale ≥ 6 per evitare match su parole irrilevanti.
    nonisolated func classify(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return "Altro" }

        // Return cached result if available
        let cacheKey = trimmed as NSString
        if let cached = resultCache.object(forKey: cacheKey) { return cached as String }

        // Normalizza: lowercase + rimuovi diacritici
        let norm = trimmed.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)

        // Token dell'input: solo lettere, min 2 char (ignora articoli/preposizioni brevi)
        let inputWords = norm
            .components(separatedBy: CharacterSet.letters.inverted)
            .filter { $0.count >= 2 }

        guard !inputWords.isEmpty else { return "Altro" }

        var scores: [String: Double] = [:]

        for pair in flatKeywords {
            let kw = pair.word
            let kwParts = kw.components(separatedBy: " ").filter { !$0.isEmpty }

            let matchScore: Double
            if kwParts.count > 1 {
                // ── Keyword multi-parola: cerca la frase intera nel testo ─────────
                matchScore = norm.contains(kw) ? Double(kw.count) * 3.0 : 0
            } else {
                // ── Keyword singola: confronta con ogni token dell'input ──────────
                let best = inputWords.reduce(0.0) { best, word in
                    max(best, singleWordScore(input: word, keyword: kw))
                }
                matchScore = best * Double(kw.count)
            }

            if matchScore > 0 {
                scores[pair.cat, default: 0.0] += matchScore
            }
        }

        // Soglia minima di confidenza
        guard let best = scores.max(by: { $0.value < $1.value }),
              best.value >= 6.0 else {
            resultCache.setObject("Altro" as NSString, forKey: cacheKey)
            return "Altro"
        }

        let result = best.key
        resultCache.setObject(result as NSString, forKey: cacheKey)
        return result
    }

    // MARK: - Matching tiers

    /// Ritorna un moltiplicatore [0, 4] per quanto bene `input` matcha `keyword`.
    private nonisolated func singleWordScore(input: String, keyword: String) -> Double {

        // T1 – Match esatto ──────────────────────────────────────── ×4.0
        if input == keyword { return 4.0 }

        // T2 – Input è prefisso di keyword (utente sta scrivendo)
        //      "pizz" → "pizza" (4/5=80% ≥60%) → match
        //      "sup"  → "supermercato" (3/13=23% <60%, ma ≥5 char → parziale)
        if keyword.hasPrefix(input) && input.count >= 3 {
            let ratio = Double(input.count) / Double(keyword.count)
            if ratio >= 0.60 { return 2.5 }
            if input.count >= 5 { return 1.5 }  // abbastanza specifico anche con ratio bassa
            return 0
        }

        // T3 – Keyword è prefisso dell'input (forma estesa della keyword)
        //      "pizzer"  → input "pizzeria"   (6/8=75% ≥60%) → match
        //      "pizz"    → input "pizzicotto"  (4/10=40% <60%) → no match ✓
        if input.hasPrefix(keyword) {
            let ratio = Double(keyword.count) / Double(input.count)
            if ratio >= 0.60 { return 3.0 }
            return 0
        }

        // T4 – Stem italiano (plurali, coniugazioni, desinenze)
        //      "panetterie" → stem "panetter" == stem di "panetteria" → Cibo
        let iStem = Self.italianStem(input)
        let kStem = Self.italianStem(keyword)
        if iStem.count >= 3 && iStem == kStem { return 2.0 }
        // Prova anche il confronto input→stem(keyword) e stem(input)→keyword
        if iStem.count >= 3 && (input == kStem || iStem == keyword) { return 2.0 }

        // T5 – Fuzzy: edit distance 1 (typo recovery)
        //      Solo per parole ≥5 char per evitare falsi positivi su parole brevi
        if input.count >= 5 && keyword.count >= 5 &&
           abs(input.count - keyword.count) <= 2 &&
           Self.levenshtein(input, keyword) == 1 { return 1.5 }

        return 0
    }

    // MARK: - Italian stemmer (suffix stripping)

    private static let italianSuffixes: [String] = [
        // ordinati dal più lungo al più corto per applicare sempre il suffisso più specifico
        "abilita", "abilità", "issimo", "issima", "issimi", "issime",
        "azione", "azioni", "amento", "amenti", "imento", "imenti",
        "mente", "arsi", "ersi", "irsi",
        "ando", "endo",
        "are", "ere", "ire",
        "ato", "ata", "ati", "ate",
        "uto", "uta", "uti", "ute",
        "ito", "ita", "iti", "ite",
        "eria", "erie", "ario", "aria",
        "ino", "ina", "ini", "ine",
        "one", "oni", "gli", "he", "hi",
        "le", "li", "i", "e", "a", "o",
    ]

    private static func italianStem(_ word: String) -> String {
        for suffix in italianSuffixes {
            if word.hasSuffix(suffix) && word.count - suffix.count >= 3 {
                return String(word.dropLast(suffix.count))
            }
        }
        return word
    }

    // MARK: - Levenshtein distance (O(n) space)

    private static func levenshtein(_ a: String, _ b: String) -> Int {
        let a = Array(a), b = Array(b)
        guard !a.isEmpty else { return b.count }
        guard !b.isEmpty else { return a.count }
        var prev = Array(0...b.count)
        for i in 1...a.count {
            var curr = [i] + Array(repeating: 0, count: b.count)
            for j in 1...b.count {
                curr[j] = a[i-1] == b[j-1]
                    ? prev[j-1]
                    : 1 + min(prev[j-1], prev[j], curr[j-1])
            }
            prev = curr
        }
        return prev[b.count]
    }
}
