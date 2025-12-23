package com.kaisheng

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import com.kaisheng.service.AppUsageTracker
import com.kaisheng.service.DowntimeScheduler
import com.kaisheng.service.MotionManager
import com.kaisheng.ui.theme.KaiShengTheme
import com.kaisheng.ui.views.MainScreen

class MainActivity : ComponentActivity() {
    
    // View models for the services
    private val motionManager: MotionManager by viewModels()
    private val appTracker: AppUsageTracker by viewModels()
    private val downtimeScheduler: DowntimeScheduler by viewModels()
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Request any required permissions
        checkAndRequestPermissions()
        
        setContent {
            KaiShengTheme {
                // A surface container using the 'background' color from the theme
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    MainScreen(
                        motionManager = motionManager,
                        appTracker = appTracker,
                        downtimeScheduler = downtimeScheduler
                    )
                }
            }
        }
    }
    
    private fun checkAndRequestPermissions() {
        // Check for usage stats permission (required for app tracking)
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as android.app.usage.UsageStatsManager
        val hasPermission = try {
            val endTime = System.currentTimeMillis()
            val startTime = endTime - 1000
            usageStatsManager.queryUsageStats(
                android.app.usage.UsageStatsManager.INTERVAL_DAILY,
                startTime,
                endTime
            )
            true
        } catch (e: Exception) {
            false
        }
        
        if (!hasPermission) {
            // Redirect to settings to enable usage access
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            startActivity(intent)
        }
    }
    
    override fun onStart() {
        super.onStart()
        // Start motion detection when activity becomes visible
        motionManager.startMotionUpdates()
    }
    
    override fun onStop() {
        super.onStop()
        // Stop motion detection when activity goes to background
        motionManager.stopMotionUpdates()
    }
}