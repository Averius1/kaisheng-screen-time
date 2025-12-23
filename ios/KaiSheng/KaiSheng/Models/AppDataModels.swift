//
//  AppDataModels.swift
//  KaiSheng
//
//  Data models for app limits and usage tracking
//

import Foundation

struct AppLimit: Codable, Identifiable, Equatable {
    let id: String
    let appName: String
    var dailyLimit: TimeInterval
    let category: AppCategory
    
    enum AppCategory: String, Codable, CaseIterable {
        case social = "Social Media"
        case entertainment = "Entertainment"
        case productivity = "Productivity"
        case games = "Games"
        case utilities = "Utilities"
        case other = "Other"
    }
}

struct AppUsage: Codable, Identifiable {
    let id: String
    let appName: String
    let date: Date
    var usageTime: TimeInterval
    let category: AppLimit.AppCategory
    
    var isLimitExceeded: Bool {
        // This will be set by checking against current limits
        return false
    }
}

struct DowntimeSchedule: Codable, Identifiable {
    let id: UUID
    var name: String
    var startTime: Date
    var endTime: Date
    var isRecurring: Bool
    var recurringDays: Set<String> // e.g., ["Mon", "Tue", "Wed"]
    var blockedApps: [String]
    var blockEntireDevice: Bool
    
    init(id: UUID = UUID(), name: String, startTime: Date, endTime: Date, 
         isRecurring: Bool = false, recurringDays: Set<String> = [], 
         blockedApps: [String] = [], blockEntireDevice: Bool = false) {
        self.id = id
        self.name = name
        self.startTime = startTime
        self.endTime = endTime
        self.isRecurring = isRecurring
        self.recurringDays = recurringDays
        self.blockedApps = blockedApps
        self.blockEntireDevice = blockEntireDevice
    }
}

// Local storage protocol
protocol AppDataStorage {
    func saveAppLimits(_ limits: [AppLimit])
    func loadAppLimits() -> [AppLimit]
    func saveDailyUsage(_ usage: [AppUsage], for date: Date)
    func loadDailyUsage(for date: Date) -> [AppUsage]
    func saveDowntimeSchedules(_ schedules: [DowntimeSchedule])
    func loadDowntimeSchedules() -> [DowntimeSchedule]
    func saveAppUsageHistory(_ usage: AppUsage)
    func loadAppUsageHistory(for appName: String) -> [AppUsage]
}

// Implementation using local file storage
class LocalAppDataStorage: AppDataStorage {
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    
    init() {
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    private func appLimitsURL() -> URL {
        return documentsDirectory.appendingPathComponent("app_limits.json")
    }
    
    private func dailyUsageURL(for date: Date) -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        return documentsDirectory.appendingPathComponent("usage_\(dateString).json")
    }
    
    private func downtimeSchedulesURL() -> URL {
        return documentsDirectory.appendingPathComponent("downtime_schedules.json")
    }
    
    private func usageHistoryURL(for appName: String) -> URL {
        let safeName = appName.replacingOccurrences(of: "/", with: "_")
        return documentsDirectory.appendingPathComponent("history_\(safeName).json")
    }
    
    func saveAppLimits(_ limits: [AppLimit]) {
        saveJSON(limits, to: appLimitsURL())
    }
    
    func loadAppLimits() -> [AppLimit] {
        return loadJSON(from: appLimitsURL()) ?? []
    }
    
    func saveDailyUsage(_ usage: [AppUsage], for date: Date) {
        saveJSON(usage, to: dailyUsageURL(for: date))
    }
    
    func loadDailyUsage(for date: Date) -> [AppUsage] {
        return loadJSON(from: dailyUsageURL(for: date)) ?? []
    }
    
    func saveDowntimeSchedules(_ schedules: [DowntimeSchedule]) {
        saveJSON(schedules, to: downtimeSchedulesURL())
    }
    
    func loadDowntimeSchedules() -> [DowntimeSchedule] {
        return loadJSON(from: downtimeSchedulesURL()) ?? []
    }
    
    func saveAppUsageHistory(_ usage: AppUsage) {
        var history = loadAppUsageHistory(for: usage.appName)
        history.append(usage)
        saveJSON(history, to: usageHistoryURL(for: usage.appName))
    }
    
    func loadAppUsageHistory(for appName: String) -> [AppUsage] {
        return loadJSON(from: usageHistoryURL(for: appName)) ?? []
    }
    
    private func saveJSON<T: Codable>(_ data: T, to url: URL) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(data)
            try jsonData.write(to: url)
        } catch {
            print("Error saving data: \(error)")
        }
    }
    
    private func loadJSON<T: Codable>(from url: URL) -> T? {
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Error loading data: \(error)")
            return nil
        }
    }
}