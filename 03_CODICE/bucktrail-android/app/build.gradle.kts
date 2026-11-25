plugins {
    id("com.android.application") version "8.13.2"
    id("org.jetbrains.kotlin.android") version "2.2.21"
    id("org.jetbrains.kotlin.plugin.compose") version "2.2.21"
    id("org.jetbrains.kotlin.kapt") version "2.2.21"
    id("androidx.room") version "2.7.2"
}

/** URL e chiave anon (pubblica per design) si leggono dal codice iOS come configurazione: mai copiate nel repository Android né nei documenti. */
fun iosSupabase(name: String): String {
    val file = rootProject.file("../../MoneyTracker/Auth/SupabaseConfig.swift")
    if (!file.exists()) return ""
    return Regex("static let $name\\s*=\\s*(?:URL\\(string:\\s*)?\"([^\"]+)\"").find(file.readText())?.groupValues?.get(1) ?: ""
}
fun supabaseValue(property: String, iosName: String): String = (findProperty(property) as String?)?.takeIf { it.isNotBlank() } ?: iosSupabase(iosName)

android {
    namespace = "com.bucktrail.android"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.bucktrail.android"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "0.1.0"
        // `-PsupabaseUrl=http://10.0.2.2:PORT -PsupabaseKey=...` (debug) punta a un server finto locale (prove sull'emulatore, mai il cloud reale)
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        // Il debug NON punta mai al cloud reale: URL finto (non risolvibile) salvo -PsupabaseUrl/-PsupabaseKey espliciti.
        // Solo la release legge URL e chiave da SupabaseConfig.swift.
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    buildTypes {
        debug {
            buildConfigField("boolean", "E2E_ENABLED", (findProperty("e2e") == "true").toString())
            val url = (findProperty("supabaseUrl") as String?)?.takeIf { it.isNotBlank() } ?: "https://supabase-finto.invalid"
            val key = (findProperty("supabaseKey") as String?)?.takeIf { it.isNotBlank() } ?: "chiave-finta-debug"
            buildConfigField("String", "SUPABASE_URL", "\"$url\"")
            buildConfigField("String", "SUPABASE_ANON_KEY", "\"$key\"")
        }
        release {
            buildConfigField("boolean", "E2E_ENABLED", "false")
            buildConfigField("String", "SUPABASE_URL", "\"${supabaseValue("supabaseUrl", "url")}\"")
            buildConfigField("String", "SUPABASE_ANON_KEY", "\"${supabaseValue("supabaseKey", "anonKey")}\"")
            // R8: codice e risorse inutilizzati tolti (le regole sono in proguard-rules.pro)
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
    buildFeatures { compose = true; buildConfig = true }
    testOptions {
        unitTests.isReturnDefaultValues = true
        unitTests.all { test ->
            val vectors = rootProject.file("../../MoneyTrackerTests/Fixtures/e2e-vectors-v1.json")
            test.inputs.file(vectors)
            test.systemProperty("e2eVectors", vectors.absolutePath)
        }
    }
    lint { warningsAsErrors = false; abortOnError = true }
}

kotlin { jvmToolchain(17) }
room { schemaDirectory("$projectDir/schemas") }

dependencies {
    implementation(platform("androidx.compose:compose-bom:2025.10.01"))
    implementation("androidx.activity:activity-compose:1.11.0")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.datastore:datastore-preferences:1.1.7")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.9.0")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.9.4")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.9.4")
    implementation("androidx.biometric:biometric:1.1.0")
    implementation("androidx.glance:glance-appwidget:1.1.1")
    implementation("androidx.fragment:fragment:1.8.9")
    implementation("androidx.room:room-runtime:2.7.2")
    implementation("androidx.room:room-ktx:2.7.2")
    kapt("androidx.room:room-compiler:2.7.2")
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.xerial:sqlite-jdbc:3.50.3.0")
    androidTestImplementation(platform("androidx.compose:compose-bom:2025.10.01"))
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
    androidTestImplementation("androidx.test.ext:junit:1.3.0")
    androidTestImplementation("androidx.test:runner:1.7.0")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
}
