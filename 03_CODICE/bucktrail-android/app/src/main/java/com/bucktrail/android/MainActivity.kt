package com.bucktrail.android

import android.os.Bundle
import androidx.fragment.app.FragmentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.bucktrail.android.security.AppLockGate
import com.bucktrail.android.ui.BucktrailApp
import com.bucktrail.android.ui.theme.BucktrailTheme

class MainActivity : FragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent { BucktrailTheme { AppLockGate { BucktrailApp() } } }
    }
}
