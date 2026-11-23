package com.bucktrail.android

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.bucktrail.android.ui.BucktrailApp
import com.bucktrail.android.ui.theme.BucktrailTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent { BucktrailTheme { BucktrailApp() } }
    }
}
