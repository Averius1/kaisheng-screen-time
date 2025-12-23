//
//  SettingsView.swift
//  KaiSheng
//
//  App settings and configuration view
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appTracker: AppUsageTracker
    @EnvironmentObject var motionManager: MotionManager
    @EnvironmentObject var downtimeScheduler: DowntimeScheduler
    
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                // General Settings
                Section(header: Text("General")) {
                    NavigationLink("Notifications", destination: NotificationSettingsView())
                    
                    NavigationLink("Data & Storage", destination: DataStorageSettingsView())
                    
                    NavigationLink("Appearance", destination: AppearanceSettingsView())
                }
                
                // Feature Settings
                Section(header: Text("Features")) {
                    NavigationLink("Motion Detection", destination: MotionSettingsDetailView())
                        .environmentObject(motionManager)
                    
                    NavigationLink("App Tracking", destination: AppTrackingSettingsView())
                        .environmentObject(appTracker)
                    
                    NavigationLink("Downtime", destination: DowntimeSettingsView())
                        .environmentObject(downtimeScheduler)
                }
                
                // Privacy & Security
                Section(header: Text("Privacy & Security")) {
                    Toggle("Local Data Only", isOn: .constant(true))
                        .disabled(true)
                    
                    NavigationLink("Permissions", destination: PermissionSettingsView())
                    
                    Toggle("Require Face ID/Touch ID", isOn: .constant(false))
                }
                
                // Backup & Reset
                Section(header: Text("Backup & Reset")) {
                    Button("Export Data") {
                        // Implementation for data export
                    }
                    
                    Button("Reset All Settings") {
                        showingResetAlert = true
                    }
                    .foregroundColor(.red)
                    
                    Button("Clear All Data") {
                        showingResetAlert = true
                    }
                    .foregroundColor(.red)
                }
                
                // About
                Section(header: Text("About")) {
                    NavigationLink("Help & FAQ", destination: HelpView())
                    
                    NavigationLink("Contact Support", destination: SupportView())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Version")
                            .font(.headline)
                        
                        Text("1.0.0 (MVP)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: doneButton)
            .alert(isPresented: $showingResetAlert) {
                Alert(
                    title: Text("Reset All Data"),
                    message: Text("This will permanently delete all your app usage data, schedules, and settings. This action cannot be undone."),
                    primaryButton: .destructive(Text("Reset")) {
                        resetAllData()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    private var doneButton: some View {
        Button("Done") {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func resetAllData() {
        // Reset app tracker
        appTracker.resetDailyUsage()
        appTracker.appLimits.removeAll()
        
        // Clear downtime schedules
        downtimeScheduler.schedules.removeAll()
        
        // Persist empty data
        if let storage = appTracker.storage as? LocalAppDataStorage {
            storage.saveAppLimits([])
            storage.saveDowntimeSchedules([])
        }
    }
}

// MARK: - Settings Subviews

struct NotificationSettingsView: View {
    var body: some View {
        Form {
            Section(header: Text("Notifications")) {
                Toggle("App Limit Warnings", isOn: .constant(true))
                
                Toggle("Downtime Notifications", isOn: .constant(true))
                
                Toggle("Walking Detection Alerts", isOn: .constant(true))
                
                Toggle("Daily Usage Summary", isOn: .constant(false))
            }
            
            Section(header: Text("Warning Thresholds")) {
                VStack(alignment: .leading) {
                    Text("App Limit Warning")
                        .font(.headline)
                    
                    Picker("Percentage", selection: .constant(80)) {
                        Text("70%").tag(70)
                        Text("80%").tag(80)
                        Text("90%").tag(90)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Toggle("Final Warning at 95%", isOn: .constant(true))
            }
        }
        .navigationTitle("Notifications")
    }
}

struct DataStorageSettingsView: View {
    var body: some View {
        Form {
            Section(header: Text("Storage")) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Usage History Retention")
                        .font(.headline)
                    
                    Picker("Duration", selection: .constant(30)) {
                        Text("7 days").tag(7)
                        Text("30 days").tag(30)
                        Text("90 days").tag(90)
                        Text("Forever").tag(0)
                    }
                }
            }
            
            Section(header: Text("Export")) {
                NavigationLink("Export Usage Data", destination: EmptyView())
                
                NavigationLink("Export Schedule Data", destination: EmptyView())
            }
            
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Storage Used")
                        .font(.headline)
                    
                    Text("~ 2.3 MB")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Data & Storage")
    }
}

struct AppearanceSettingsView: View {
    var body: some View {
        Form {
            Section(header: Text("Theme")) {
                Picker("Appearance", selection: .constant(0)) {
                    Text("System").tag(0)
                    Text("Light").tag(1)
                    Text("Dark").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            Section {
                Toggle("Use Large Text", isOn: .constant(false))
                
                Toggle("Reduce Animations", isOn: .constant(false))
            }
        }
        .navigationTitle("Appearance")
    }
}

struct MotionSettingsDetailView: View {
    @EnvironmentObject var motionManager: MotionManager
    
    @State private var sensitivity = 1.1
    @State private var stepThreshold = 5
    
    var body: some View {
        Form {
            Section(header: Text("Detection")) {
                Toggle("Enable Walking Detection", isOn: .constant(true))
                
                Toggle("Restrict Social Media While Walking", isOn: .constant(true))
                
                Toggle("Reduce Tracking During Walking", isOn: .constant(true))
            }
            
            Section(header: Text("Sensitivity")) {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Detection Sensitivity")
                        Spacer()
                        Text("\(String(format: "%.1f", sensitivity))x")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $sensitivity, in: 0.8...1.5, step: 0.1)
                }
                
                Stepper("Step Threshold: \(stepThreshold)", value: $stepThreshold, in: 1...20)
                
                Text("Number of steps before restricting apps")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("Notifications")) {
                Toggle("Walking Detection Alerts", isOn: .constant(true))
                
                Toggle("Restriction Warnings", isOn: .constant(true))
            }
            
            Section {
                Button("Calibrate Motion Sensors") {
                    // Implementation for sensor calibration
                }
                
                Button("Test Motion Detection") {
                    // Implementation for testing motion detection
                }
            }
        }
        .navigationTitle("Motion Detection")
    }
}

struct AppTrackingSettingsView: View {
    @EnvironmentObject var appTracker: AppUsageTracker
    
    var body: some View {
        Form {
            Section(header: Text("Tracking")) {
                Toggle("Enable App Tracking", isOn: .constant(true))
                
                Toggle("Track in Background", isOn: .constant(true))
                
                Toggle("Auto-detect New Apps", isOn: .constant(true))
            }
            
            Section {
                Toggle("Show App Icons", isOn: .constant(true))
                
                Toggle("Frequency Alerts", isOn: .constant(false))
                
                Toggle("Most Used Apps Widget", isOn: .constant(true))
            }
        }
        .navigationTitle("App Tracking")
    }
}

struct DowntimeSettingsView: View {
    @EnvironmentObject var downtimeScheduler: DowntimeScheduler
    
    var body: some View {
        Form {
            Section(header: Text("Downtime")) {
                Toggle("Enable Scheduled Downtime", isOn: .constant(true))
                
                Toggle("Show Downtime Status", isOn: .constant(true))
            }
            
            Section(header: Text("Emergency Access")) {
                Toggle("Allow Emergency Calls", isOn: .constant(true))
                
                Toggle("Allow Health Apps", isOn: .constant(true))
            }
            
            Section(header: Text("Notifications")) {
                Toggle("Downtime Reminders", isOn: .constant(true))
                
                Toggle("Missed Downtime Alerts", isOn: .constant(false))
            }
        }
        .navigationTitle("Downtime")
    }
}

struct PermissionSettingsView: View {
    var body: some View {
        Form {
            Section(header: Text("Required Permissions")) {
                PermissionRow(
                    name: "Motion & Fitness",
                    status: "Granted",
                    color: .green
                )
                
                PermissionRow(
                    name: "Notifications",
                    status: "Granted",
                    color: .green
                )
                
                PermissionRow(
                    name: "App Tracking",
                    status: "Granted",
                    color: .green
                )
            }
            
            Section {
                Text("KaiSheng requires these permissions to function properly. All data is stored locally on your device.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Permissions")
    }
}

struct PermissionRow: View {
    let name: String
    let status: String
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(name)
                    .font(.headline)
                
                Text(status)
                    .font(.caption)
                    .foregroundColor(color)
            }
            
            Spacer()
            
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
        }
    }
}

struct HelpView: View {
    var body: some View {
        List {
            Section(header: Text("Getting Started")) {
                NavigationLink("How to Set App Limits", destination: HelpDetailView(title: "App Limits"))
                
                NavigationLink("How to Schedule Downtime", destination: HelpDetailView(title: "Downtime"))
                
                NavigationLink("Motion Detection Guide", destination: HelpDetailView(title: "Motion"))
            }
            
            Section(header: Text("Features")) {
                NavigationLink("Understanding App Limits", destination: HelpDetailView(title: "Understanding Limits"))
                
                NavigationLink("Recurring Schedules", destination: HelpDetailView(title: "Recurring Schedules"))
                
                NavigationLink("Motion-Based Restrictions", destination: HelpDetailView(title: "Motion Restrictions"))
            }
            
            Section(header: Text("Troubleshooting")) {
                NavigationLink("Motion Detection Issues", destination: HelpDetailView(title: "Motion Issues"))
                
                NavigationLink("App Tracking Problems", destination: HelpDetailView(title: "Tracking Issues"))
                
                NavigationLink("Downtime Not Working", destination: HelpDetailView(title: "Downtime Issues"))
            }
        }
        .navigationTitle("Help & FAQ")
    }
}

struct HelpDetailView: View {
    let title: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Help content for \(title)")
                    .font(.headline)
                
                Text("Detailed help information would be shown here for \ \(title). This is a placeholder for the MVP.")
                    .font(.body)
            }
            .padding()
        }
        .navigationTitle(title)
    }
}

struct SupportView: View {
    var body: some View {
        Form {
            Section(header: Text("Contact Support")) {
                Text("For technical support or feature requests:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "envelope")
                        Text("support@kaisheng.app")
                    }
                    
                    HStack {
                        Image(systemName: "globe")
                        Text("https://kaisheng.app")
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section {
                Text("All support requests are handled directly. KaiSheng stores data locally only and does not collect personal information.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Contact Support")
    }
}