package com.bucktrail.android.domain

import java.time.ZoneId
import java.time.format.DateTimeFormatter

/** Export CSV (§5.6): intestazione localizzata, tutti i campi tra virgolette, difesa dalle formule dei fogli di calcolo. */
object CsvExport {
    class Labels(
        val headers: List<String>, val expense: String, val income: String, val yes: String, val no: String,
        val category: (String) -> String,
    )

    const val FILE_NAME = "transazioni.csv"
    private val dateFormat = DateTimeFormatter.ofPattern("dd/MM/yyyy")

    /** Racchiude tra `"` (raddoppiati all'interno); prefissa con `'` se inizia con `= + - @ TAB CR LF`. */
    fun escape(field: String): String {
        val s = if (field.isNotEmpty() && field[0] in "=+-@\t\r\n") "'$field" else field
        return "\"" + s.replace("\"", "\"\"") + "\""
    }

    /** Tutte le transazioni (anche pianificate e trasferimenti), dalla più recente; importo positivo con punto e 2 decimali. */
    fun build(transactions: List<TransactionData>, accountNames: Map<String, String>, zone: ZoneId, labels: Labels): String {
        val sb = StringBuilder(labels.headers.joinToString(",") { escape(it) }).append('\n')
        for (t in transactions.sortedWith(compareByDescending<TransactionData> { it.date }.thenByDescending { it.createdAt })) {
            sb.append(
                listOf(
                    dateFormat.format(t.date.atZone(zone)), t.name, Amounts.fixedFractionString(t.amount),
                    if (t.type == Amounts.TYPE_EXPENSE) labels.expense else labels.income, labels.category(t.category),
                    t.accountId?.let { accountNames[it] }.orEmpty(), if (t.isDone) labels.yes else labels.no, t.recurringFrequency,
                ).joinToString(",") { escape(it) },
            ).append('\n')
        }
        return sb.toString()
    }
}

/** Scrittore JSON con la stessa forma di `JSONEncoder([.prettyPrinted, .sortedKeys])`: indentazione 2, `"chiave" : valore`, chiavi ordinate. */
object PrettyJson {
    /** Numero già formattato (nessuna virgolette). */
    class Num(val text: String)

    fun write(value: Any?, indent: Int = 0): String = when (value) {
        null -> "null"
        is Boolean -> value.toString()
        is Num -> value.text
        is String -> quote(value)
        is Map<*, *> -> if (value.isEmpty()) "{\n${"  ".repeat(indent)}}" else {
            val pad = "  ".repeat(indent + 1)
            value.entries.sortedBy { it.key as String }.joinToString(",\n", "{\n", "\n${"  ".repeat(indent)}}") { "$pad${quote(it.key as String)} : ${write(it.value, indent + 1)}" }
        }
        is List<*> -> if (value.isEmpty()) "[\n${"  ".repeat(indent)}]" else {
            val pad = "  ".repeat(indent + 1)
            value.joinToString(",\n", "[\n", "\n${"  ".repeat(indent)}]") { "$pad${write(it, indent + 1)}" }
        }
        else -> quote(value.toString())
    }

    private fun quote(s: String): String {
        val sb = StringBuilder("\"")
        for (ch in s) when (ch) {
            '"' -> sb.append("\\\"")
            '\\' -> sb.append("\\\\")
            '/' -> sb.append("\\/")
            '\n' -> sb.append("\\n")
            '\r' -> sb.append("\\r")
            '\t' -> sb.append("\\t")
            '\b' -> sb.append("\\b")
            '\u000C' -> sb.append("\\f")
            else -> if (ch < ' ') sb.append(String.format("\\u%04x", ch.code)) else sb.append(ch)
        }
        return sb.append('"').toString()
    }
}
