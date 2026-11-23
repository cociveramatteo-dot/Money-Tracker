package com.bucktrail.android.data

import android.content.Context
import com.bucktrail.android.domain.KeywordCategoryClassifier
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonPrimitive

/** Classificatore categorie (asset `CategoryKeywords.json`), caricato una volta per processo; condiviso da app e scorciatoie. */
object ClassifierProvider {
    @Volatile private var cached: KeywordCategoryClassifier? = null

    suspend fun get(context: Context): KeywordCategoryClassifier = cached ?: withContext(Dispatchers.IO) {
        val text = context.applicationContext.assets.open("CategoryKeywords.json").bufferedReader().use { it.readText() }
        val map = (Json.parseToJsonElement(text) as JsonObject).mapValues { (_, v) -> (v as JsonArray).map { it.jsonPrimitive.content } }
        KeywordCategoryClassifier(map).also { cached = it }
    }

    suspend fun classify(context: Context, name: String): String {
        val c = get(context)
        return withContext(Dispatchers.Default) { c.classify(name) }
    }
}
