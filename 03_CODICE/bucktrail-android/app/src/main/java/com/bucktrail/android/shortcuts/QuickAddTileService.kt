package com.bucktrail.android.shortcuts

import android.app.PendingIntent
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import com.bucktrail.android.R

/** Riquadro «Aggiungi spesa» nelle Impostazioni rapide (extra Android: iOS usa il Tocco sul retro, che qui non esiste). */
class QuickAddTileService : TileService() {
    override fun onStartListening() {
        qsTile?.apply { state = Tile.STATE_INACTIVE; label = getString(R.string.aggiungi_spesa); updateTile() }
    }

    @android.annotation.SuppressLint("StartActivityAndCollapseDeprecated") // solo sotto API 34, dove il PendingIntent non esiste
    override fun onClick() {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("bucktrail://add?kind=expense"), this, QuickAddActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        if (Build.VERSION.SDK_INT >= 34) {
            startActivityAndCollapse(PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT))
        } else {
            @Suppress("DEPRECATION") startActivityAndCollapse(intent)
        }
    }
}
