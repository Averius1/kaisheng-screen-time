package com.kaisheng.data

import java.util.Date
import java.util.UUID

// Data models for app limits and usage tracking
// These mirror the iOS implementation for cross-platform consistency

data class AppLimit(
    val id: String,
    val appName: String,
    var dailyLimit: Long, // Time in seconds
    val category: AppCategory
) {
    enum class AppCategory {
        SOCIAL,
        ENTERTAINMENT,
        PRODUCTIVITY,
        GAMES,
        UTILITIES,
        OTHER
        
        override fun toString(): String {
            return when (this) {
                SOCIAL -> "Social Media"
                ENTERTAINMENT -> "Entertainment"
                PRODUCTIVITY -> "Productivity"
                GAMES -> "Games"
                UTILITIES -> "Utilities"
                OTHER -> "Other"
            }
        }
        
        companion object {
            fun fromString(value: String): AppCategory {
                return when (value.lowercase()) {
                    "social" -> SOCIAL
                    "entertainment" -> ENTERTAINMENT
                    "productivity" -> PRODUCTIVITY
                    "games" -> GAMES
                    "utilities" -> UTILITIES
                    else -> OTHER
                }
            }
        }
    }
}

data class AppUsage(
    val id: String,
    val appName: String,
    val date: Date,
    var usageTime: Long, // Time in seconds
    val category: AppLimit.AppCategory,
    val isLimitExceeded: Boolean = false
)

data class DowntimeSchedule(
    val id: UUID,
    var name: String,
    var startTime: Date,
    var endTime: Date,
    var isRecurring: Boolean,
    var recurringDays: Set<String>, // e.g., ["Mon", "Tue", "Wed"]
    var blockedApps: List<String>,
    var blockEntireDevice: Boolean
)

interface AppDataStorage {
    fun saveAppLimits(limits: List<AppLimit>)
    fun loadAppLimits(): List<AppLimit>
    fun saveDailyUsage(usage: List<AppUsage>, date: Date)
    fun loadDailyUsage(date: Date): List<AppUsage>
    fun saveDowntimeSchedules(schedules: List<DowntimeSchedule>)
    fun loadDowntimeSchedules(): List<DowntimeSchedule>
    fun saveAppUsageHistory(usage: AppUsage)
    fun loadAppUsageHistory(appName: String): List<AppUsage>
}

// Implementation using local file storage
class LocalAppDataStorage(
    private val context: android.content.Context
) : AppDataStorage {
    
    companion object {
        private const val PREFS_NAME = "KaiShengPrefs"
        private const val KEY_APP_LIMITS = "app_limits"
        private const val KEY_DOWNTIME_SCHEDULES = "downtime_schedules"
    }
    
    private val sharedPreferences = context.getSharedPreferences(PREFS_NAME, android.content.Context.MODE_PRIVATE)
    private val gson = com.google.gson.Gson()
    
    override fun saveAppLimits(limits: List<AppLimit>) {
        val json = gson.toJson(limits)
        sharedPreferences.edit().putString(KEY_APP_LIMITS, json).apply()
    }
    
    override fun loadAppLimits(): List<AppLimit> {
        val json = sharedPreferences.getString(KEY_APP_LIMITS, "[]")
        return try {
            val type = com.google.gson.reflect.TypeToken.getParameterized(
                List::class.java, 
                AppLimit::class.java
            ).type
            gson.fromJson(json, type) ?: emptyList()
        } catch (e: Exception) {
            emptyList()
        }
    }
    
    override fun saveDailyUsage(usage: List<AppUsage>, date: Date) {
        val dateFormat = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.getDefault())
        val dateString = dateFormat.format(date)
        val key = "usage_$dateString"
        
        val json = gson.toJson(usage)
        sharedPreferences.edit().putString(key, json).apply()
    }
    
    override fun loadDailyUsage(date: Date): List<AppUsage> {
        val dateFormat = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.getDefault())
        val dateString = dateFormat.format(date)
        val key = "usage_$dateString"
        
        val json = sharedPreferences.getString(key, "[]")
        return try {
            val type = com.google.gson.reflect.TypeToken.getParameterized(
                List::class.java, 
                AppUsage::class.java
            ).type
            gson.fromJson(json, type) ?: emptyList()
        } catch (e: Exception) {
            emptyList()
        }
    }
    
    override fun saveDowntimeSchedules(schedules: List<DowntimeSchedule>) {
        val json = gson.toJson(schedules)
        sharedPreferences.edit().putString(KEY_DOWNTIME_SCHEDULES, json).apply()
    }
    
    override fun loadDowntimeSchedules(): List<DowntimeSchedule> {
        val json = sharedPreferences.getString(KEY_DOWNTIME_SCHEDULES, "[]")
        return try {
            val type = com.google.gson.reflect.TypeToken.getParameterized(
                List::class.java, 
                DowntimeSchedule::class.java
            ).type
            gson.fromJson(json, type) ?: emptyList()
        } catch (e: Exception) {
            emptyList()
        }
    }
    
    override fun saveAppUsageHistory(usage: AppUsage) {
        val safeName = usage.appName.replace("/", "_")
        val key = "history_$safeName"
        
        val existingHistory = loadAppUsageHistory(usage.appName).toMutableList()
        existingHistory.add(usage)
        
        val json = gson.toJson(existingHistory)
        sharedPreferences.edit().putString(key, json).apply()
    }
    
    override fun loadAppUsageHistory(appName: String): List<AppUsage> {
        val safeName = appName.replace("/", "_")
        val key = "history_$safeName"
        
        val json = sharedPreferences.getString(key, "[]")
        return try {
            val type = com.google.gson.reflect.TypeToken.getParameterized(
                List::class.java, 
                AppUsage::class.java
            ).type
            gson.fromJson(json, type) ?: emptyList()
        } catch (e: Exception) {
            emptyList()
        }
    }
}

// Extension function for String replacement
private fun String.replace(oldChar: String, newChar: String): String {
    return this.replace(oldChar, newChar)
}