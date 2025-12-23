//
//  AppUsageTracker.swift
//  KaiSheng
//
//  App usage tracking and limit enforcement
//  Uses native iOS APIs to monitor app usage and enforce time limits
//

import Foundation
import UserNotifications
import Combine

class AppUsageTracker: ObservableObject {
    // Shared instance
    static let shared = AppUsageTracker()
    
    @Published var appLimits: [AppLimit] = []
    @Published var currentUsage: [AppUsage] = []
    @Published var isBlockingApps = false
    
    private let storage: LocalAppDataStorage
    private var usageTimer: Timer?
    private let kMaxAppLimitHours: TimeInterval = 24
    
    // App tracking state
    private var appUsageStartTime: [String: Date] = [:]
    private var currentApp: String?
    private var backgroundDate: Date?
    
    init(storage: LocalAppDataStorage = LocalAppDataStorage()) {
        self.storage = storage
        loadData()
        setupNotifications()
        startUsageMonitoring()
    }
    
    // MARK: - Public API
    
    func addAppLimit(appName: String, category: AppLimit.AppCategory, dailyLimit: TimeInterval) {
        guard dailyLimit <= kMaxAppLimitHours else { return }
        
        let newLimit = AppLimit(
            id: UUID().uuidString,
            appName: appName,
            dailyLimit: dailyLimit,
            category: category
        )
        
        appLimits.append(newLimit)
        storage.saveAppLimits(appLimits)
    }
    
    func updateAppLimit(limit: AppLimit) {
        if let index = appLimits.firstIndex(where: { $0.id == limit.id }) {
            appLimits[index] = limit
            storage.saveAppLimits(appLimits)
        }
    }
    
    func removeAppLimit(limitId: String) {
        appLimits.removeAll { $0.id == limitId }
        storage.saveAppLimits(appLimits)
    }
    
    func getAppUsage(for appName: String) -> TimeInterval {
        return currentUsage.first(where: { $0.appName == appName })?.usageTime ?? 0
    }
    
    func checkAppLimit(for appName: String) -> Bool {
        guard let appLimit = appLimits.first(where: { $0.appName == appName }) else { return true }
        let currentUsageTime = getAppUsage(for: appName)
        return currentUsageTime < appLimit.dailyLimit
    }
    
    func shouldBlockApp(_ appName: String) -> Bool {
        return !checkAppLimit(for: appName) || isBlockingApps
    }
    
    func getRemainingTime(for appName: String) -> TimeInterval {
        guard let appLimit = appLimits.first(where: { $0.appName == appName }) else { return kMaxAppLimitHours }
        let currentUsageTime = getAppUsage(for: appName)
        return max(0, appLimit.dailyLimit - currentUsageTime)
    }
    
    func resetDailyUsage() {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        // Save yesterday's usage to history
        for usage in currentUsage {
            let archivedUsage = AppUsage(
                id: UUID().uuidString,
                appName: usage.appName,
                date: yesterday,
                usageTime: usage.usageTime,
                category: usage.category
            )
            storage.saveAppUsageHistory(archivedUsage)
        }
        
        // Reset current usage
        currentUsage = []
        storage.saveDailyUsage(currentUsage, for: today)
        
        // Reset timers
        appUsageStartTime.removeAll()
        isBlockingApps = false
    }
    
    // MARK: - Private Methods
    
    private func loadData() {
        // Load app limits
        appLimits = storage.loadAppLimits()
        
        // Load today's usage
        let today = Date()
        currentUsage = storage.loadDailyUsage(for: today)
        
        // Check if we need to reset for new day
        if Calendar.current.isDateInToday(currentUsage.first?.date ?? Date()) == false {
            resetDailyUsage()
        }
    }
    
    private func setupNotifications() {
        // Request notification permissions for app limit warnings
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error)")
            }
        }
    }
    
    private func startUsageMonitoring() {
        // Background timer to periodically check app usage and enforce limits
        usageTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.updateUsage()
            self?.checkLimitsAndBlockApps()
        }
        
        // Listen to app state changes
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in self?.appDidBecomeActive() }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in self?.appWillResignActive() }
            .store(in: &cancellables)
        
        // Listen to motion detection
        NotificationCenter.default.publisher(for: .walkingStarted)
            .sink { [weak self] _ in
                print("Walking detected - monitoring social app scrolling")
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .walkingEnded)
            .sink { [weak self] _ in
                print("Walking ended - resuming normal operation")
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func appDidBecomeActive() {
        if let bgDate = backgroundDate {
            let backgroundDuration = Date().timeIntervalSince(bgDate)
            if backgroundDuration > 3600 { // 1 hour
                // Likely new day, check and reset if needed
                checkForNewDay()
            }
            backgroundDate = nil
        }
    }
    
    private func appWillResignActive() {
        backgroundDate = Date()
    }
    
    private func checkForNewDay() {
        let now = Date()
        let storedDate = currentUsage.first?.date ?? now
        
        if !Calendar.current.isDate(storedDate, inSameDayAs: now) {
            resetDailyUsage()
        }
    }
    
    private func updateUsage() {
        // In a real implementation, this would use iOS UsageStats APIs to get actual app usage
        // For MVP, we'll simulate usage updates
        let today = Date()
        
        for var usage in currentUsage {
            // Simulate some usage (in real app, this comes from iOS APIs)
            usage.usageTime += 60 // Add 1 minute
            
            if let index = currentUsage.firstIndex(where: { $0.id == usage.id }) {
                currentUsage[index] = usage
            }
            
            storage.saveAppUsageHistory(usage)
        }
        
        storage.saveDailyUsage(currentUsage, for: today)
    }
    
    private func checkLimitsAndBlockApps() {
        for limit in appLimits {
            let usage = getAppUsage(for: limit.appName)
            let usagePercentage = (usage / limit.dailyLimit) * 100
            
            // Send warning notifications at 80% and 95% of limit
            if usagePercentage >= 80 && usagePercentage < 82 {
                sendWarningNotification(appName: limit.appName, usagePercentage: usagePercentage)
            } else if usagePercentage >= 95 && usagePercentage < 97 {
                sendWarningNotification(appName: limit.appName, usagePercentage: usagePercentage)
            }
            
            // Block app when limit exceeded
            if usage >= limit.dailyLimit && !isBlockingApps {
                blockApp(limit.appName)
            }
        }
    }
    
    private func blockApp(_ appName: String) {
        DispatchQueue.main.async {
            self.isBlockingApps = true
            self.sendBlockNotification(appName: appName)
        }
        
        // In a real implementation, this would use iOS Screen Time APIs or device management
        // For MVP, we'll use a local flag and show overlay warnings
        print("Blocking app: \(appName)")
    }
    
    private func unblockApps() {
        DispatchQueue.main.async {
            self.isBlockingApps = false
        }
        print("Unblocking apps")
    }
    
    private func sendWarningNotification(appName: String, usagePercentage: Double) {
        let content = UNMutableNotificationContent()
        content.title = "App Time Limit Warning"
        content.body = "\(appName) has reached \(Int(usagePercentage))% of your daily limit"
        content.sound = .default
        
        // Use existing notification or create new one
        let identifier = "limit-warning-\(appName)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error)")
            }
        }
    }
    
    private func sendBlockNotification(appName: String) {
        let content = UNMutableNotificationContent()
        content.title = "App Time Limit Reached"
        content.body = "\(appName) has reached its daily time limit and is now blocked"
        content.sound = .defaultCritical
        content.badge = 1
        
        let request = UNNotificationRequest(identifier: "app-blocked-\(appName)\(Date())", content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending block notification: \(error)")
            }
        }
    }
    
    // Simulate app usage (for testing - would use real iOS APIs in production)
    func simulateAppUsage(appName: String, category: AppLimit.AppCategory, duration: TimeInterval) {
        let today = Date()
        
        // Add or update app's daily usage
        if let existingIndex = currentUsage.firstIndex(where: { $0.appName == appName }) {
            currentUsage[existingIndex].usageTime += duration
        } else {
            let usage = AppUsage(
                id: UUID().uuidString,
                appName: appName,
                date: today,
                usageTime: duration,
                category: category
            )
            currentUsage.append(usage)
        }
        
        storage.saveDailyUsage(currentUsage, for: today)
    }
}