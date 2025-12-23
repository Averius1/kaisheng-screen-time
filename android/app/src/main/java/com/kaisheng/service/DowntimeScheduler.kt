package com.kaisheng.service

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import androidx.compose.runtime.State
import androidx.compose.runtime.mutableStateOf
import androidx.lifecycle.ViewModel
import com.kaisheng.data.AppDataStorage
import com.kaisheng.data.DowntimeSchedule
import com.kaisheng.data.LocalAppDataStorage
import java.util.Calendar
import java.util.Date
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit

class DowntimeScheduler(
    private val context: Context,
    private val storage: AppDataStorage = LocalAppDataStorage(context)
) : ViewModel() {
    
    companion object {
        private const val DOWNTIME_CHECK_INTERVAL = 60L // Check every 60 seconds
        private const val NOTIFICATION_CHANNEL_ID = "downtime_notifications"
    }
    
    // State management
    private val _schedules = mutableStateOf(listOf<DowntimeSchedule>())
    val schedules: State<List<DowntimeSchedule>> = _schedules
    
    private val _isInDowntime = mutableStateOf(false)
    val isInDowntime: State<Boolean> = _isInDowntime
    
    private val _activeDowntime = mutableStateOf<DowntimeSchedule?>(null)
    val activeDowntime: State<DowntimeSchedule?> = _activeDowntime
    
    // Scheduling
    private val scheduler: ScheduledExecutorService = Executors.newSingleThreadScheduledExecutor()
    private val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    private val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    
    // Broadcast receiver for handling alarms
    private val downtimeReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                "com.kaisheng.DOWNTIME_START" -> {
                    val scheduleId = intent.getStringExtra("scheduleId")
                    scheduleId?.let { handleDowntimeStart(it) }
                }
                "com.kaisheng.DOWNTIME_END" -> {
                    val scheduleId = intent.getStringExtra("scheduleId")
                    scheduleId?.let { handleDowntimeEnd(it) }
                }
            }
        }
    }
    
    init {
        loadSchedules()
        setupScheduling()
        setupNotifications()
        registerBroadcastReceiver()
    }
    
    // Public API
    
    fun addSchedule(schedule: DowntimeSchedule) {
        _schedules.value += schedule
        saveSchedules()
        scheduleNotification(schedule)
    }
    
    fun updateSchedule(schedule: DowntimeSchedule) {
        val index = _schedules.value.indexOfFirst { it.id == schedule.id }
        if (index != -1) {
            val updatedSchedules = _schedules.value.toMutableList()
            updatedSchedules[index] = schedule
            _schedules.value = updatedSchedules
            saveSchedules()
            updateScheduleNotification(schedule)
        }
    }
    
    fun removeSchedule(scheduleId: String) {
        _schedules.value = _schedules.value.filter { it.id.toString() != scheduleId }
        saveSchedules()
        removeScheduleNotification(scheduleId)
    }
    
    fun isAppBlocked(appName: String): Boolean {
        if (!_isInDowntime.value) return false
        val activeSchedule = _activeDowntime.value ?: return false
        
        return if (activeSchedule.blockEntireDevice) {
            !isCriticalApp(appName)
        } else {
            activeSchedule.blockedApps.contains(appName)
        }
    }
    
    fun shouldBlockDevice(): Boolean {
        return _isInDowntime.value && (_activeDowntime.value?.blockEntireDevice ?: false)
    }
    
    fun getActiveSchedule(): DowntimeSchedule? {
        return _activeDowntime.value
    }
    
    fun getNextSchedule(): DowntimeSchedule? {
        val now = Date()
        
        return _schedules.value
            .filter { schedule ->
                shouldScheduleBeActiveToday(schedule) &&
                getScheduleStartTime(schedule, now) > now
            }
            .minByOrNull { schedule ->
                getScheduleStartTime(schedule, now)
            }
    }
    
    // Private methods
    
    private fun loadSchedules() {
        _schedules.value = storage.loadDowntimeSchedules()
        
        // Reschedule all notifications
        _schedules.value.forEach { schedule ->
            scheduleNotification(schedule)
        }
    }
    
    private fun saveSchedules() {
        storage.saveDowntimeSchedules(_schedules.value)
    }
    
    private fun setupScheduling() {
        // Check downtime status every minute
        scheduler.scheduleAtFixedRate(
            {
                checkDowntimeStatus()
            },
            0,
            DOWNTIME_CHECK_INTERVAL,
            TimeUnit.SECONDS
        )
        
        // Check immediately on startup
        checkDowntimeStatus()
    }
    
    private fun checkDowntimeStatus() {
        val now = Date()
        val activeSchedules = mutableListOf<DowntimeSchedule>()
        
        _schedules.value.forEach { schedule ->
            if (shouldScheduleBeActiveToday(schedule)) {
                val scheduleStart = getScheduleStartTime(schedule, now)
                val scheduleEnd = getScheduleEndTime(schedule, now)
                
                if (now >= scheduleStart && now < scheduleEnd) {
                    activeSchedules.add(schedule)
                }
            }
        }
        
        // Determine downtime status (take the most restrictive schedule)
        val mostRestrictive = activeSchedules.maxByOrNull { schedule ->
            // Prefer schedules that block the entire device, then those with more blocked apps
            when {
                schedule.blockEntireDevice -> 1000 // High priority
                else -> schedule.blockedApps.size // Priority based on number of blocked apps
            }
        }
        
        if (mostRestrictive != null) {
            _isInDowntime.value = true
            _activeDowntime.value = mostRestrictive
            
            if (!_isInDowntime.value) {
                sendDowntimeStartedNotification(mostRestrictive)
            }
        } else {
            if (_isInDowntime.value) {
                sendDowntimeEndedNotification()
            }
            
            _isInDowntime.value = false
            _activeDowntime.value = null
        }
    }
    
    private fun shouldScheduleBeActiveToday(schedule: DowntimeSchedule): Boolean {
        if (!schedule.isRecurring) {
            return true // Non-recurring schedules are always considered for today
        }
        
        val calendar = Calendar.getInstance()
        val today = calendar.get(Calendar.DAY_OF_WEEK)
        val dayNames = arrayOf("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday")
        val todayName = dayNames[today - 1]
        
        return schedule.recurringDays.contains(todayName)
    }
    
    private fun getScheduleStartTime(schedule: DowntimeSchedule, date: Date): Date {
        val calendar = Calendar.getInstance()
        calendar.time = date
        
        val startCalendar = Calendar.getInstance()
        startCalendar.time = schedule.startTime
        
        calendar.set(Calendar.HOUR_OF_DAY, startCalendar.get(Calendar.HOUR_OF_DAY))
        calendar.set(Calendar.MINUTE, startCalendar.get(Calendar.MINUTE))
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        
        return calendar.time
    }
    
    private fun getScheduleEndTime(schedule: DowntimeSchedule, date: Date): Date {
        val startTime = getScheduleStartTime(schedule, date)
        val duration = schedule.endTime.time - schedule.startTime.time
        
        // Handle schedules that cross midnight
        return if (duration < 0) {
            // Schedule ends next day
            Date(startTime.time + 24 * 60 * 60 * 1000 + duration)
        } else {
            Date(startTime.time + duration)
        }
    }
    
    private fun isCriticalApp(appName: String): Boolean {
        // Define apps that should never be blocked
        val criticalApps = listOf(
            "Phone", "Messages", "Emergency", "Health", "SOS",
            "Emergency Call", "Medical ID", "Settings"
        )
        return criticalApps.contains(appName)
    }
    
    private fun scheduleNotification(schedule: DowntimeSchedule) {
        val now = Date()
        val startTime = getScheduleStartTime(schedule, now)
        
        if (startTime > now) {
            // Schedule start notification (5 minutes before)
            val notificationTime = Date(startTime.time - 5 * 60 * 1000)
            scheduleAlarm(schedule, notificationTime, "DOWNTIME_START")
        }
    }
    
    private fun updateScheduleNotification(schedule: DowntimeSchedule) {
        removeScheduleNotification(schedule.id.toString())
        scheduleNotification(schedule)
    }
    
    private fun removeScheduleNotification(scheduleId: String) {
        val intent = Intent("com.kaisheng.DOWNTIME_START")
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            scheduleId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)
    }
    
    private fun scheduleAlarm(schedule: DowntimeSchedule, time: Date, action: String) {
        val intent = Intent(action).apply {
            putExtra("scheduleId", schedule.id.toString())
        }
        
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            schedule.id.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, time.time, pendingIntent)
    }
    
    private fun handleDowntimeStart(scheduleId: String) {
        val schedule = _schedules.value.find { it.id.toString() == scheduleId }
        schedule?.let {
            sendDowntimeStartedNotification(it)
        }
    }
    
    private fun handleDowntimeEnd(scheduleId: String) {
        sendDowntimeEndedNotification()
    }
    
    private fun setupNotifications() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Downtime Notifications",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Notifications for downtime schedules"
            }
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun sendDowntimeStartedNotification(schedule: DowntimeSchedule) {
        val title = if (schedule.blockEntireDevice) {
            "Device Downtime Started"
        } else {
            "App Downtime Started"
        }
        
        val appList = if (schedule.blockEntireDevice) {
            "All non-essential apps"
        } else {
            schedule.blockedApps.joinToString(", ")
        }
        
        val message = "Downtime '${schedule.name}' has begun. Blocked: $appList"
        
        createNotification(title, message)
    }
    
    private fun sendDowntimeEndedNotification() {
        val title = "Downtime Ended"
        val message = "Downtime period has ended. Apps are now available."
        
        createNotification(title, message)
    }
    
    private fun createNotification(title: String, message: String) {
        val notificationId = System.currentTimeMillis().toInt()
        
        val notification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, NOTIFICATION_CHANNEL_ID)
        } else {
            Notification.Builder(context)
        }.apply {
            setContentTitle(title)
            setContentText(message)
            setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            setAutoCancel(true)
        }.build()
        
        notificationManager.notify(notificationId, notification)
    }
    
    private fun registerBroadcastReceiver() {
        val filter = IntentFilter().apply {
            addAction("com.kaisheng.DOWNTIME_START")
            addAction("com.kaisheng.DOWNTIME_END")
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(downtimeReceiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            context.registerReceiver(downtimeReceiver, filter)
        }
    }
    
    private fun handleTimezoneChange() {
        // Reload schedules and re-evaluate downtime status
        loadSchedules()
        checkDowntimeStatus()
    }
    
    override fun onCleared() {
        super.onCleared()
        scheduler.shutdown()
        try {
            context.unregisterReceiver(downtimeReceiver)
        } catch (e: Exception) {
            // Receiver might not be registered
        }
    }
}

// Extension functions to make DowntimeScheduler observable in Compose
fun DowntimeScheduler.schedulesState(): State<List<DowntimeSchedule>> = _schedules
fun DowntimeScheduler.isInDowntimeState(): State<Boolean> = _isInDowntime
fun DowntimeScheduler.activeDowntimeState(): State<DowntimeSchedule?> = _activeDowntime