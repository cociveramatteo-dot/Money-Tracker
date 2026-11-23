# Regole R8 di Bucktrail (release).
# Room, Compose, Glance, DataStore, kotlinx.serialization (solo JsonElement, nessuna classe @Serializable), Biometric e Fragment
# portano le proprie regole consumer: qui solo quanto serve a ciò che l'app carica per nome.

# Receiver, servizi e attività dichiarati nel manifest sono già mantenuti da AAPT; i widget Glance si istanziano per riflessione
-keep class com.bucktrail.android.shortcuts.** { *; }
-keep class com.bucktrail.android.notifications.ReminderReceiver { *; }
-keep class com.bucktrail.android.notifications.BootReceiver { *; }

# Nomi risorsa composti a runtime (`demo_tx_*`, ecc.) con Resources.getIdentifier: non togliere le stringhe demo
-keepclassmembers class **.R$string { public static final int demo_*; }

# Stack trace leggibili nei report
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
