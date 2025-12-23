//
//  AppLimitsView.swift
//  KaiSheng
//
//  App time limits management view
//

import SwiftUI

struct AppLimitsView: View {
    @EnvironmentObject var appTracker: AppUsageTracker
    @State private var showingAddLimit = false
    @State private var selectedAppCategory = AppLimit.AppCategory.social
    @State private var appLimitHours = 1
    @State private var customAppName = ""
    
    let availableApps = [
        "Instagram": AppLimit.AppCategory.social,
        "TikTok": AppLimit.AppCategory.social,
        "Facebook": AppLimit.AppCategory.social,
        "Twitter": AppLimit.AppCategory.social,
        "YouTube": AppLimit.AppCategory.entertainment,
        "Netflix": AppLimit.AppCategory.entertainment,
        "Spotify": AppLimit.AppCategory.entertainment,
        "Games": AppLimit.AppCategory.games,
        "Snapchat": AppLimit.AppCategory.social,
        "WhatsApp": AppLimit.AppCategory.social,
        "Reddit": AppLimit.AppCategory.social,
        "Pinterest": AppLimit.AppCategory.social
    ]
    
    var body: some View {
        ZStack {
            if appTracker.appLimits.isEmpty {
                EmptyStateView(
                    title: "No App Limits Set",
                    message: "Add time limits for apps to start managing your screen time",
                    icon: "app.badge"
                )
            } else {
                List {
                    ForEach(appTracker.appLimits) { limit in
                        AppLimitRowView(limit: limit)
                            .environmentObject(appTracker)
                    }
                    .onDelete(perform: deleteAppLimit)
                }
            }
        }
        .navigationBarItems(trailing: addButton)
        .sheet(isPresented: $showingAddLimit) {
            AddAppLimitView(
                isPresented: $showingAddLimit,
                appTracker: appTracker
            )
        }
    }
    
    private var addButton: some View {
        Button(action: { showingAddLimit = true }) {
            Image(systemName: "plus")
        }
    }
    
    private func deleteAppLimit(at offsets: IndexSet) {
        offsets.forEach { index in
            if index < appTracker.appLimits.count {
                let limit = appTracker.appLimits[index]
                appTracker.removeAppLimit(limitId: limit.id)
            }
        }
    }
}

struct AppLimitRowView: View {
    @EnvironmentObject var appTracker: AppUsageTracker
    let limit: AppLimit
    
    @State private var editingLimit = false
    @State private var newLimit: TimeInterval
    
    private var currentUsage: TimeInterval {
        appTracker.getAppUsage(for: limit.appName)
    }
    
    private var usagePercentage: Double {
        let percentage = (currentUsage / limit.dailyLimit) * 100
        return min(100, percentage)
    }
    
    private var remainingTime: TimeInterval {
        appTracker.getRemainingTime(for: limit.appName)
    }
    
    init(limit: AppLimit) {
        self.limit = limit
        _newLimit = State(initialValue: limit.dailyLimit / 3600) // Store in hours
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(limit.appName)
                        .font(.headline)
                    
                    Text(limit.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if appTracker.shouldBlockApp(limit.appName) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                ProgressView(value: usagePercentage, total: 100)
                    .accentColor(progressColor)
                
                HStack {
                    Text("\(formatTime(currentUsage)) used")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if remainingTime <= 0 {
                        Text("Limit Reached")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else {
                        Text("\(formatTime(remainingTime)) left")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if editingLimit {
                    HStack {
                        Text("New limit:")
                            .font(.caption)
                        
                        Picker("Hours", selection: $newLimit) {
                            ForEach(0..<25) { hour in
                                Text("\(hour)h")
                                    .tag(TimeInterval(hour))
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        Button("Save") {
                            updateLimit()
                            editingLimit = false
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        
                        Button("Cancel") {
                            editingLimit = false
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                } else {
                    Button("Edit Limit") {
                        newLimit = limit.dailyLimit / 3600
                        editingLimit = true
                    }
                    .font(.caption)
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private var progressColor: Color {
        if usagePercentage > 90 {
            return .red
        } else if usagePercentage > 75 {
            return .orange
        } else {
            return .blue
        }
    }
    
    private func updateLimit() {
        var updatedLimit = limit
        updatedLimit.dailyLimit = newLimit * 3600 // Convert back to seconds
        appTracker.updateAppLimit(limit: updatedLimit)
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

struct AddAppLimitView: View {
    @Binding var isPresented: Bool
    @ObservedObject var appTracker: AppUsageTracker
    
    @State private var selectedApp = "Instagram"
    @State private var selectedCategory = AppLimit.AppCategory.social
    @State private var limitHours = 2
    
    static let availableApps = [
        "Instagram": AppLimit.AppCategory.social,
        "TikTok": AppLimit.AppCategory.social,
        "Facebook": AppLimit.AppCategory.social,
        "Twitter": AppLimit.AppCategory.social,
        "YouTube": AppLimit.AppCategory.entertainment,
        "Netflix": AppLimit.AppCategory.entertainment,
        "Spotify": AppLimit.AppCategory.entertainment,
        "Games": AppLimit.AppCategory.games,
        "Snapchat": AppLimit.AppCategory.social,
        "WhatsApp": AppLimit.AppCategory.social,
        "Reddit": AppLimit.AppCategory.social,
        "Pinterest": AppLimit.AppCategory.social
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Select App")) {
                    Picker("App", selection: $selectedApp) {
                        ForEach(Array(AddAppLimitView.availableApps.keys).sorted(), id: \.self) { appName in
                            Text(appName)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                }
                
                Section(header: Text("Daily Time Limit")) {
                    Picker("Hours", selection: $limitHours) {
                        ForEach(0..<25) { hour in
                            Text("\(hour) hours")
                                .tag(hour)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                }
                
                Section {
                    Button("Add Limit") {
                        addAppLimit()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .disabled(limitHours == 0)
                }
            }
            .navigationTitle("Add App Limit")
            .navigationBarItems(
                leading: Button("Cancel") { isPresented = false }
            )
        }
    }
    
    private func addAppLimit() {
        guard let category = AddAppLimitView.availableApps[selectedApp] else { return }
        
        let limitDuration = TimeInterval(limitHours * 3600)
        appTracker.addAppLimit(
            appName: selectedApp,
            category: category,
            dailyLimit: limitDuration
        )
        
        isPresented = false
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 60)
    }
}