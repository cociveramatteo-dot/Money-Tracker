package com.bucktrail.android.sync.e2e

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File
import javax.xml.parsers.DocumentBuilderFactory

class E2EStringsTest {
    @Test
    fun everyAndroidCatalogMatchesTheSame55IOSStrings() {
        val fixture = File(checkNotNull(System.getProperty("e2eVectors")))
        val ios = checkNotNull(fixture.parentFile?.parentFile?.parentFile).resolve("MoneyTracker")
        val resources = File("src/main/res")
        val languages = mapOf(
            "it" to "values", "en" to "values-en", "de" to "values-de", "es" to "values-es",
            "fr" to "values-fr", "ja" to "values-ja", "zh-Hans" to "values-b+zh+Hans",
        )
        val iosPair = Regex("""^"(e2e_\w+)"\s*=\s*"(.*)";$""")
        languages.forEach { (language, folder) ->
            val pairs = ios.resolve("$language.lproj/Localizable.strings").readLines().mapNotNull {
                iosPair.matchEntire(it)?.destructured?.let { (key, value) -> key to value }
            }
            assertEquals(language, 55, pairs.size)
            val nodes = DocumentBuilderFactory.newInstance().newDocumentBuilder()
                .parse(resources.resolve("$folder/strings.xml")).getElementsByTagName("string")
            val android = (0 until nodes.length).mapNotNull { index ->
                val node = nodes.item(index)
                val key = node.attributes.getNamedItem("name").nodeValue
                if (!key.startsWith("e2e_")) null else {
                    assertEquals(key, "false", node.attributes.getNamedItem("formatted").nodeValue)
                    val value = node.textContent.replace("\\'", "'").replace("\\\"", "\"")
                    assertTrue("$language/$key", value.isNotBlank() && '%' !in value)
                    key to value
                }
            }
            assertEquals(language, 55, android.size)
            assertEquals(language, pairs.toMap(), android.toMap())
        }
    }
}
