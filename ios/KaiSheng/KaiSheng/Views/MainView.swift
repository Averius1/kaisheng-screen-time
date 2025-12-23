//
//  MainView.swift
//  KaiSheng
//
//  Main dashboard view showing overview of all features
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var motionManager: MotionManager
    @EnvironmentObject var appTracker: AppUsageTracker
    @EnvironmentObject var downtimeScheduler: DowntimeScheduler
    
    @State private var showingSettings = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "house")
                    }
                    .tag(0)
                    .environmentObject(motionManager)
                    .environmentObject(appTracker)
                    .environmentObject(downtimeScheduler)
                
                AppLimitsView()
                    .tabItem {
                        Label("App Limits", systemImage: "app.badge")
                    }
                    .tag(1)
                    .environmentObject(appTracker)
                
                DowntimeView()
                    .tabItem {
                        Label("Downtime", systemImage: "moon")
                    }
                    .tag(2)
                    .environmentObject(downtimeScheduler)
                
                MotionView()
                    .tabItem {
                        Label("Motion", systemImage: "figure.walk")
                    }
                    .tag(3)
                    .environmentObject(motionManager)
            }
            .navigationTitle(getNavigationTitle())
            .navigationBarItems(trailing: settingsButton)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    private var settingsButton: some View {
        Button(action: { showingSettings = true }) {
            Image(systemName: "gear")
                .font(.title2)
        }
    }
    
    private func getNavigationTitle() -> String {
        switch selectedTab {
        case 0: return "KaiSheng Dashboard"
        case 1: return "App Time Limits"
        case 2: return "Scheduled Downtime"
        case 3: return "Motion Tracking"
        default: return "KaiSheng"
        }
    }
}

struct DashboardView: View {
    @EnvironmentObject var motionManager: MotionManager
    @EnvironmentObject var appTracker: AppUsageTracker
    @EnvironmentObject var downtimeScheduler: DowntimeScheduler
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Motion Status Card
                MotionStatusCard()
                    .environmentObject(motionManager)
                
                // App Usage Summary Card
                AppUsageSummaryCard()
                    .environmentObject(appTracker)
                
                // Downtime Status Card
                DowntimeStatusCard()
                    .environmentObject(downtimeScheduler)
                
                // Quick Actions
                QuickActionsGrid()
                    .environmentObject(appTracker)
                    .environmentObject(downtimeScheduler)
            }
            .padding()
        }
    }
}

struct MotionStatusCard: View {
    @EnvironmentObject var motionManager: MotionManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Motion Tracking")
                        .font(.headline)
                    
                    if motionManager.isWalking {
                        Text("Walking Detected")
                            .font(.subheadline)
                            .foregroundColor(.green)
                        
                        if let walkStartTime = motionManager.walkStartTime {
                            Text("Started: \(walkStartTime, formatter: timeFormatter)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("No Motion Detected")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Motion indicator
                VStack {
                    Circle()
                        .fill(motionManager.isWalking ? Color.green : Color.gray)
                        .frame(width: 20, height: 20)
                        .animation(.easeInOut, value: motionManager.isWalking)
                    
                    if motionManager.isWalking {
                        Text("\(motionManager.stepCount)")
                            .font(.caption)
                    }
                }
            }
            
            if motionManager.isWalking {
                ProgressView(value: Double(motionManager.stepCount), total: 10)
                    .accentColor(.green)
                
                Text("Steps: \(motionManager.stepCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

struct AppUsageSummaryCard: View {
    @EnvironmentObject var appTracker: AppUsageTracker
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("App Usage Today")
                    .font(.headline)
                
                Spacer()
                
                Button("Reset All") {
                    appTracker.resetDailyUsage()
                }
                .font(.caption)
                .disabled(appTracker.currentUsage.isEmpty)
            }
            
            if appTracker.currentUsage.isEmpty {
                Text("No usage tracked yet today")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(appTracker.currentUsage.prefix(3), id: \.id) { usage in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(usage.appName)
                                .font(.subheadline)
                            
                            if let limit = appTracker.appLimits.first(where: { $0.appName == usage.appName }) {
                                let percentage = min(100, (usage.usageTime / limit.dailyLimit) * 100)
                                
                                ProgressView(value: percentage, total: 100)
                                    .accentColor(percentage > 90 ? .red : percentage > 75 ? .orange : .blue)
                                
                                HStack {
                                    Text(formatTime(usage.usageTime))
                                        .font(.caption)
                                    
                                    Spacer()
                                    
                                    Text("/ \(formatTime(limit.dailyLimit))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text(formatTime(usage.usageTime))
                                    .font(.caption)
                            }
                        }
                        
                        if appTracker.shouldBlockApp(usage.appName) {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                if appTracker.currentUsage.count > 3 {
                    Text("+ \(appTracker.currentUsage.count - 3) more apps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct DowntimeStatusCard: View {
    @EnvironmentObject var downtimeScheduler: DowntimeScheduler
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Downtime Status")
                        .font(.headline)
                    
                    if downtimeScheduler.isInDowntime {
                        Text("Active")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                        
                        if let schedule = downtimeScheduler.activeDowntime {
                            Text(schedule.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("No Active Downtime")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Status indicator
                Circle()
                    .fill(downtimeScheduler.isInDowntime ? Color.orange : Color.gray)
                    .frame(width: 20, height: 20)
                    .animation(.easeInOut, value: downtimeScheduler.isInDowntime)
            }
            
            // Show next scheduled downtime
            if let nextSchedule = downtimeScheduler.getNextSchedule() {
                HStack {
                    Text("Next: \(nextSchedule.name)")
                        .font(.caption)
                    
                    Spacer()
                    
                    if let startTime = getNextOccurrence(for: nextSchedule) {
                        Text("at \(startTime, formatter: timeFormatter)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    private func getNextOccurrence(for schedule: DowntimeSchedule) -> Date? {
        let now = Date()
        var nextDate = downtimeScheduler.getScheduleStartTime(for: schedule, on: now)
        
        if nextDate <= now {
            // If schedule time has passed today, get tomorrow's occurrence
            nextDate = downtimeScheduler.getScheduleStartTime(for: schedule, on: now.addingTimeInterval(24 * 60 * 60))
        }
        
        return nextDate
    }
}

struct QuickActionsGrid: View {
    @EnvironmentObject var appTracker: AppUsageTracker
    @EnvironmentObject var downtimeScheduler: DowntimeScheduler
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Actions")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                QuickActionButton(
                    title: "Add App Limit",
                    icon: "plus",
                    action: { /* Navigate to App Limits tab */ },
                    color: .blue
                )
                
                QuickActionButton(
                    title: "Start Downtime",
                    icon: "moon.fill",
                    action: startImmediateDowntime,
                    color: downtimeScheduler.isInDowntime ? .gray : .orange
                )
                
                QuickActionButton(
                    title: "Pause Tracking",
                    icon: "pause.fill",
                    action: pauseTracking,
                    color: .yellow
                )
                
                QuickActionButton(
                    title: "View History",
                    icon: "chart.bar",
                    action: { /* Show usage history */ },
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private func startImmediateDowntime() {
        guard !downtimeScheduler.isInDowntime else { return }
        
        let schedule = DowntimeSchedule(
            name: "Quick Downtime",
            startTime: Date(),
            endTime: Date().addingTimeInterval(60 * 60), // 1 hour from now
            blockEntireDevice: false
        )
        
        downtimeScheduler.addSchedule(schedule)
    }
    
    private func pauseTracking() {
        // This would pause/resume tracking
        // Implementation would toggle tracking state
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    let color: Color
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(color.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}