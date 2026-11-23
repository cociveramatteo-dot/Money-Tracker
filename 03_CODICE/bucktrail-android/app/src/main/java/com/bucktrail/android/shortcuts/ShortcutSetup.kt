package com.bucktrail.android.shortcuts

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.os.Build
import android.app.StatusBarManager
import android.graphics.drawable.Icon
import com.bucktrail.android.R

/** Richieste di sistema per aggiungere il widget e il riquadro (l'utente conferma nel pannello del sistema). */
object ShortcutSetup {
    fun canPinWidget(context: Context): Boolean = AppWidgetManager.getInstance(context).isRequestPinAppWidgetSupported

    fun pinWidget(context: Context) {
        runCatching { AppWidgetManager.getInstance(context).requestPinAppWidget(ComponentName(context, BalanceWidgetReceiver::class.java), null, null) }
    }

    fun requestTile(context: Context) {
        if (Build.VERSION.SDK_INT < 33) return
        runCatching {
            context.getSystemService(StatusBarManager::class.java).requestAddTileService(
                ComponentName(context, QuickAddTileService::class.java), context.getString(R.string.aggiungi_spesa),
                Icon.createWithResource(context, R.drawable.ic_tile_add), context.mainExecutor,
            ) { }
        }
    }
}
