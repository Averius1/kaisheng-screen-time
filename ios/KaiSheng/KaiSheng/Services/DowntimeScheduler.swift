//
//  DowntimeScheduler.swift
//  KaiSheng
//
//  Scheduled downtime management for blocking apps during configured time windows
//

import Foundation
import UserNotifications
import Combine

class DowntimeScheduler: ObservableObject {
    // Shared instance
    static let shared = DowntimeScheduler()
    
    @Published var schedules: [DowntimeSchedule] = []
    @Published var isInDowntime = false
    @Published var activeDowntime: DowntimeSchedule?
    
    private let storage: LocalAppDataStorage
    private let notificationCenter = UNUserNotificationCenter.current()
    private var schedulerTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init(storage: LocalAppDataStorage = LocalAppDataStorage()) {
        self.storage = storage
        loadSchedules()
        setupScheduling()
    }
    
    // MARK: - Public API
    
    func addSchedule(_ schedule: DowntimeSchedule) {
        schedules.append(schedule)
        saveSchedules()
        scheduleNotification(for: schedule)
    }
    
    func updateSchedule(_ schedule: DowntimeSchedule) {
        if let index = schedules.firstIndex(where: { $0.id == schedule.id }) {
            schedules[index] = schedule
            saveSchedules()
            updateScheduleNotification(for: schedule)
        }
    }
    
    func removeSchedule(_ scheduleId: UUID) {
        schedules.removeAll { $0.id == scheduleId }
        saveSchedules()
        removeScheduleNotification(for: scheduleId)
    }
    
    func isAppBlocked(_ appName: String) -> Bool {
        guard isInDowntime, let activeSchedule = activeDowntime else { return false }
        
        if activeSchedule.blockEntireDevice {
            // Allow exceptions for critical apps
            return !isCriticalApp(appName)
        } else {
            return activeSchedule.blockedApps.contains(appName)
        }
    }
    
    func shouldBlockDevice() -> Bool {
        return isInDowntime && (activeDowntime?.blockEntireDevice ?? false)
    }
    
    func getActiveSchedule() -> DowntimeSchedule? {
        return activeDowntime
    }
    
    func getNextSchedule() -> DowntimeSchedule? {
        let now = Date()
        let calendar = Calendar.current
        
        // Find the next schedule from now
        return schedules
            .filter { schedule in
                // Only consider schedules that should be active on this day
                guard shouldScheduleBeActiveToday(schedule) else { return false }
                
                // Check if schedule will be active later today
                let startTime = getScheduleStartTime(for: schedule, on: now)
                return startTime > now
            }
            .sorted { schedule1, schedule2 in
                let time1 = getScheduleStartTime(for: schedule1, on: now)
                let time2 = getScheduleStartTime(for: schedule2, on: now)
                return time1 < time2
            }
            .first
    }
    
    // MARK: - Private Methods
    
    private func setupScheduling() {
        // Check downtime status every minute
        schedulerTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.checkDowntimeStatus()
        }
        
        // Check immediately
        checkDowntimeStatus()
        
        // Setup notification delegates
        setupNotificationHandling()
        
        // Register for timezone change notifications
        NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)
            .sink { [weak self] _ in
                self?.handleTimezoneChange()
            }
            .store(in: &cancellables)
    }
    
    private func loadSchedules() {
        schedules = storage.loadDowntimeSchedules()
        
        // Reschedule all notifications
        for schedule in schedules {
            scheduleNotification(for: schedule)
        }
    }
    
    private func saveSchedules() {
        storage.saveDowntimeSchedules(schedules)
    }
    
    private func checkDowntimeStatus() {
        let now = Date()
        var activeSchedules = [DowntimeSchedule]()
        
        for schedule in schedules {
            if shouldScheduleBeActiveToday(schedule) {
                let scheduleStart = getScheduleStartTime(for: schedule, on: now)
                let scheduleEnd = getScheduleEndTime(for: schedule, on: now)
                
                if now >= scheduleStart && now < scheduleEnd {
                    activeSchedules.append(schedule)
                }
            }
        }
        
        // Determine downtime status (take the most restrictive schedule)
        if let mostRestrictive = activeSchedules.max(by: { schedule1, schedule2 in
            // Prefer schedules that block the entire device
            if schedule1.blockEntireDevice != schedule2.blockEntireDevice {
                return schedule1.blockEntireDevice ? false : true
            }
            // Otherwise prefer schedule with more blocked apps
            return schedule1.blockedApps.count < schedule2.blockedApps.count
        }) {
            DispatchQueue.main.async {
                self.isInDowntime = true
                self.activeDowntime = mostRestrictive
            }
            
            if isInDowntime == false {
                sendDowntimeStartedNotification(schedule: mostRestrictive)
            }
        } else {
            if isInDowntime == true {
                sendDowntimeEndedNotification()
            }
            
            DispatchQueue.main.async {
                self.isInDowntime = false
                self.activeDowntime = nil
            }
        }
    }
    
    private func shouldScheduleBeActiveToday(_ schedule: DowntimeSchedule) -> Bool {
        if !schedule.isRecurring {
            return true // Non-recurring schedules are always considered for today
        }
        
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let weekdaySymbols = calendar.weekdaySymbols
        let todayName = weekdaySymbols[weekday - 1]
        
        return schedule.recurringDays.contains(todayName)
    }
    
    private func getScheduleStartTime(for schedule: DowntimeSchedule, on date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: schedule.startTime)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = components.year
        combinedComponents.month = components.month
        combinedComponents.day = components.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        
        return calendar.date(from: combinedComponents) ?? date
    }
    
    private func getScheduleEndTime(for schedule: DowntimeSchedule, on date: Date) -> Date {
        let startTime = getScheduleStartTime(for: schedule, on: date)
        let duration = schedule.endTime.timeIntervalSince(schedule.startTime)
        
        // Handle schedules that cross midnight
        if duration < 0 {
            // Schedule ends next day
            return startTime.addingTimeInterval(24 * 60 * 60 + duration)
        } else {
            return startTime.addingTimeInterval(duration)
        }
    }
    
    private func isCriticalApp(_ appName: String) -> Bool {
        // Define apps that should never be blocked
        let criticalApps = [
            "Phone", "Messages", "Emergency", "Health", "SOS",
            "Emergency Call", "Medical ID", "Settings"
        ]
        return criticalApps.contains(appName)
    }
    
    private func scheduleNotification(for schedule: DowntimeSchedule) {
        // Remove existing notification
        removeScheduleNotification(for: schedule.id)
        
        let identifier = "downtime-\(schedule.id)"
        
        // Schedule start notification
        let startContent = UNMutableNotificationContent()
        startContent.title = "Downtime Starting Soon"
        startContent.body = "\(schedule.name) will begin in 5 minutes"
        startContent.sound = .default
        
        // Calculate notification time (5 minutes before schedule)
        let now = Date()
        if let scheduleTime = getScheduleStartTime(for: schedule, on: now).addingTimeInterval(-300) as Date?,
           scheduleTime > now {
            let trigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: scheduleTime), repeats: false)
            let request = UNNotificationRequest(identifier: "\(identifier)-start", content: startContent, trigger: trigger)
            notificationCenter.add(request)
        }
    }
    
    private func updateScheduleNotification(for schedule: DowntimeSchedule) {
        removeScheduleNotification(for: schedule.id)
        scheduleNotification(for: schedule)
    }
    
    private func removeScheduleNotification(for scheduleId: UUID) {
        let identifier = "downtime-\(scheduleId)"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["\(identifier)-start"])
    }
    
    private func sendDowntimeStartedNotification(schedule: DowntimeSchedule) {
        let content = UNMutableNotificationContent()
        content.title = if schedule.blockEntireDevice {
            "Device Downtime Started"
        } else {
            "App Downtime Started"
        }
        
        let appList = schedule.blockEntireDevice ? "All non-essential apps" : schedule.blockedApps.joined(separator: ", ")
        content.body = "Downtime '\(schedule.name)' has begun. Blocked: \(appList)"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "downtime-started-\(Date())", content: content, trigger: nil)
        notificationCenter.add(request)
    }
    
    private func sendDowntimeEndedNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Downtime Ended"
        content.body = "Downtime period has ended. Apps are now available."
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "downtime-ended-\(Date())", content: content, trigger: nil)
        notificationCenter.add(request)
    }
    
    private func handleTimezoneChange() {
        // Reload schedules and re-evaluate downtime status
        loadSchedules()
        checkDowntimeStatus()
    }
    
    private func setupNotificationHandling() {
        // Handle background notifications to ensure scheduling continues
        notificationCenter.delegate = self
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension DowntimeScheduler: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification actions if needed
        completionHandler()
    }
}