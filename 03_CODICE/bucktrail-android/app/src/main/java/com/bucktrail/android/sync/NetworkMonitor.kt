package com.bucktrail.android.sync

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities

/** `NWPathMonitor` iOS: avvisa quando la rete va e viene. */
object NetworkMonitor {
    fun start(context: Context, onChange: (available: Boolean) -> Unit) {
        val cm = context.getSystemService(ConnectivityManager::class.java) ?: return
        runCatching {
            cm.registerDefaultNetworkCallback(object : ConnectivityManager.NetworkCallback() {
                override fun onAvailable(network: Network) = onChange(true)
                override fun onLost(network: Network) = onChange(false)
                override fun onCapabilitiesChanged(network: Network, caps: NetworkCapabilities) =
                    onChange(caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET))
            })
        }
    }
}
