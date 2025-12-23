package com.kaisheng.service

import android.app.ActivityManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.provider.Settings
import androidx.compose.runtime.State
import androidx.compose.runtime.mutableStateOf
import androidx.lifecycle.ViewModel
import com.kaisheng.data.AppDataStorage
import com.kaisheng.data.AppLimit
import com.kaisheng.data.AppUsage
import com.kaisheng.data.LocalAppDataStorage
import java.util.Date
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit

class AppUsageTracker(
    private val context: Context,
    private val storage: AppDataStorage = LocalAppDataStorage(context)
) : ViewModel() {
    
    companion object {
        private const val MAX_APP_LIMIT_HOURS = 24 * 60 * 60L // 24 hours in seconds
        private const val USAGE_CHECK_INTERVAL = 60L // Check every 60 seconds
        private const val BACKGROUND_USAGE_CHECK_INTERVAL = 300L // 5 minutes in background
    }
    
    // State management
    private val _appLimits = mutableStateOf(listOf<AppLimit>())
    val appLimits: State<List<AppLimit>> = _appLimits
    
    private val _currentUsage = mutableStateOf(listOf<AppUsage>())
    val currentUsage: State<List<AppUsage>> = _currentUsage
    
    private val _isBlockingApps = mutableStateOf(false)
    val isBlockingApps: State<Boolean> = _isBlockingApps
    
    // App tracking state
    private val appUsageStartTime = mutableMapOf<String, Long>()
    private var currentApp: String? = null
    private var backgroundTimestamp: Long? = null
    
    // Scheduling
    private val scheduler: ScheduledExecutorService = Executors.newSingleThreadScheduledExecutor()
    private val mainHandler = android.os.Handler(android.os.Looper.getMainLooper())
    
    init {
        loadData()
        setupNotifications()
        startUsageMonitoring()
    }
    
    // Public API
    
    fun addAppLimit(appName: String, category: AppLimit.AppCategory, dailyLimit: Long) {
        if (dailyLimit > MAX_APP_LIMIT_HOURS) return
        
        val newLimit = AppLimit(
            id = UUID.randomUUID().toString(),
            appName = appName,
            dailyLimit = dailyLimit,
            category = category
        )
        
        _appLimits.value += newLimit
        storage.saveAppLimits(_appLimits.value)
    }
    
    fun updateAppLimit(limit: AppLimit) {
        val index = _appLimits.value.indexOfFirst { it.id == limit.id }
        if (index != -1) {
            val updatedLimits = _appLimits.value.toMutableList()
            updatedLimits[index] = limit
            _appLimits.value = updatedLimits
            storage.saveAppLimits(_appLimits.value)
        }
    }
    
    fun removeAppLimit(limitId: String) {
        _appLimits.value = _appLimits.value.filter { it.id != limitId }
        storage.saveAppLimits(_appLimits.value)
    }
    
    fun getAppUsage(appName: String): Long {
        return _currentUsage.value.find { it.appName == appName }?.usageTime ?: 0
    }
    
    fun checkAppLimit(appName: String): Boolean {
        val appLimit = _appLimits.value.find { it.appName == appName } ?: return true
        val currentUsageTime = getAppUsage(appName)
        return currentUsageTime < appLimit.dailyLimit
    }
    
    fun shouldBlockApp(appName: String): Boolean {
        return !checkAppLimit(appName) || _isBlockingApps.value
    }
    
    fun getRemainingTime(appName: String): Long {
        val appLimit = _appLimits.value.find { it.appName == appName } ?: return MAX_APP_LIMIT_HOURS
        val currentUsageTime = getAppUsage(appName)
        return maxOf(0, appLimit.dailyLimit - currentUsageTime)
    }
    
    fun resetDailyUsage() {
        val today = Date()
        val calendar = java.util.Calendar.getInstance()
        calendar.time = today
        calendar.add(java.util.Calendar.DAY_OF_YEAR, -1)
        val yesterday = calendar.time
        
        // Save yesterday's usage to history
        _currentUsage.value.forEach { usage ->
            val archivedUsage = AppUsage(
                id = UUID.randomUUID().toString(),
                appName = usage.appName,
                date = yesterday,
                usageTime = usage.usageTime,
                category = usage.category
            )
            storage.saveAppUsageHistory(archivedUsage)
        }
        
        // Reset current usage
        _currentUsage.value = emptyList()
        storage.saveDailyUsage(_currentUsage.value, today)
        
        // Reset timers
        appUsageStartTime.clear()
        _isBlockingApps.value = false
    }
    
    // Private methods
    
    private fun loadData() {
        // Load app limits
        _appLimits.value = storage.loadAppLimits()
        
        // Load today's usage
        val today = Date()
        _currentUsage.value = storage.loadDailyUsage(today)
        
        // Check if we need to reset for new day
        if (_currentUsage.value.isNotEmpty() && !isDateInToday(_currentUsage.value[0].date)) {
            resetDailyUsage()
        }
    }
    
    private fun isDateInToday(date: Date): Boolean {
        val today = java.util.Calendar.getInstance()
        val dateToCheck = java.util.Calendar.getInstance()
        dateToCheck.time = date
        
        return today.get(java.util.Calendar.YEAR) == dateToCheck.get(java.util.Calendar.YEAR) &&
               today.get(java.util.Calendar.DAY_OF_YEAR) == dateToCheck.get(java.util.Calendar.DAY_OF_YEAR)
    }
    
    private fun setupNotifications() {
        // Request notification permissions for app limit warnings
        // In Android 13+, need to request POST_NOTIFICATIONS permission
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
            val hasPermission = context.checkSelfPermission(
                android.Manifest.permission.POST_NOTIFICATIONS
            ) == android.content.pm.PackageManager.PERMISSION_GRANTED
            
            if (!hasPermission) {
                // Would request permission here in a real app
            }
        }
    }
    
    private fun startUsageMonitoring() {
        // Schedule periodic usage checks
        scheduler.scheduleAtFixedRate(
            {
                updateUsage()
                checkLimitsAndBlockApps()
            },
            0,
            USAGE_CHECK_INTERVAL,
            TimeUnit.SECONDS
        )
        
        // Monitor app state changes
        setupAppStateMonitoring()
        
        // Listen to motion detection via broadcast or shared state
        setupMotionDetectionListener()
    }
    
    private fun setupAppStateMonitoring() {
        // In a real implementation, would use ActivityLifecycleCallbacks
        // or UsageStatsManager to monitor app usage
    }
    
    private fun setupMotionDetectionListener() {
        // Would listen to MotionManager state changes
    }
    
    private fun updateUsage() {
        val today = Date()
        
        // In a real implementation, this would use Android UsageStatsManager
        // to get actual app usage data
        // For MVP, we'll maintain the current usage state
        
        storage.saveDailyUsage(_currentUsage.value, today)
    }
    
    private fun checkLimitsAndBlockApps() {
        _appLimits.value.forEach { limit ->
            val usage = getAppUsage(limit.appName)
            val usagePercentage = (usage.toDouble() / limit.dailyLimit) * 100
            
            // Send warning notifications at 80% and 95% of limit
            if (usagePercentage >= 80 && usagePercentage < 82) {
                sendWarningNotification(limit.appName, usagePercentage)
            } else if (usagePercentage >= 95 && usagePercentage < 97) {
                sendWarningNotification(limit.appName, usagePercentage)
            }
            
            // Block app when limit exceeded
            if (usage >= limit.dailyLimit && !_isBlockingApps.value) {
                blockApp(limit.appName)
            }
        }
    }
    
    private fun blockApp(appName: String) {
        mainHandler.post {
            _isBlockingApps.value = true
        }
        sendBlockNotification(appName)
        
        // In a real implementation, this would use Android's App Usage API
        // to actually block the app or show overlay warnings
        android.util.Log.d("AppUsageTracker", "Blocking app: $appName")
    }
    
    private fun sendWarningNotification(appName: String, usagePercentage: Double) {
        // Create notification for app limit warning
        val notificationId = "limit-warning-${UUID.randomUUID()}"
        val message = "$appName has reached ${usagePercentage.toInt()}% of your daily limit"
        
        createNotification("App Time Limit Warning", message, notificationId)
    }
    
    private fun sendBlockNotification(appName: String) {
        val notificationId = "app-blocked-${UUID.randomUUID()}"
        val message = "$appName has reached its daily time limit and is now blocked"
        
        createNotification("App Time Limit Reached", message, notificationId)
    }
    
    private fun createNotification(title: String, message: String, notificationId: String) {
        // Implementation would create Android notification
        // For MVP, just log the notification
        android.util.Log.d("AppUsageTracker", "Notification: $title - $message")
    }
    
    // Simulate app usage (for testing - would use real Android APIs in production)
    fun simulateAppUsage(appName: String, category: AppLimit.AppCategory, duration: Long) {
        val today = Date()
        
        // Add or update app's daily usage
        val existingIndex = _currentUsage.value.indexOfFirst { it.appName == appName }
        if (existingIndex != -1) {
            val updatedUsage = _currentUsage.value.toMutableList()
            updatedUsage[existingIndex] = updatedUsage[existingIndex].copy(
                usageTime = updatedUsage[existingIndex].usageTime + duration
            )
            _currentUsage.value = updatedUsage
        } else {
            val usage = AppUsage(
                id = UUID.randomUUID().toString(),
                appName = appName,
                date = today,
                usageTime = duration,
                category = category
            )
            _currentUsage.value += usage
        }
        
        storage.saveDailyUsage(_currentUsage.value, today)
    }
    
    override fun onCleared() {
        super.onCleared()
        scheduler.shutdown()
    }
}

// Extension functions to make AppUsageTracker observable in Compose
fun AppUsageTracker.appLimitsState(): State<List<AppLimit>> = _appLimits
fun AppUsageTracker.currentUsageState(): State<List<AppUsage>> = _currentUsage
fun AppUsageTracker.isBlockingAppsState(): State<Boolean> = _isBlockingApps