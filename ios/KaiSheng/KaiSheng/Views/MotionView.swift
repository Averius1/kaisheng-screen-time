//
//  MotionView.swift
//  KaiSheng
//
//  Motion tracking detection and settings view
//

import SwiftUI

struct MotionView: View {
    @EnvironmentObject var motionManager: MotionManager
    @State private var showingSettings = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Motion Detection Status
                MotionDetectionCard()
                    .environmentObject(motionManager)
                
                // Walking Statistics
                WalkingStatsCard()
                    .environmentObject(motionManager)
                
                // Motion Settings
                MotionSettingsCard()
                    .environmentObject(motionManager)
                
                // Social Media Apps List (to restrict while walking)
                WalkingRestrictionsCard()
                    .environmentObject(motionManager)
            }
            .padding()
        }
        .navigationTitle("Motion Tracking")
        .navigationBarItems(trailing: settingsButton)
        .sheet(isPresented: $showingSettings) {
            MotionSettingsView()
                .environmentObject(motionManager)
        }
    }
    
    private var settingsButton: some View {
        Button(action: { showingSettings = true }) {
            Image(systemName: "gear")
        }
    }
}

struct MotionDetectionCard: View {
    @EnvironmentObject var motionManager: MotionManager
    
    private var motionStatusColor: Color {
        if motionManager.isWalking {
            return .green
        } else if motionManager.motionManager.isAccelerometerAvailable {
            return .secondary
        } else {
            return .red
        }
    }
    
    private var motionStatusText: String {
        if motionManager.isWalking {
            return "Walking Detected"
        } else if motionManager.motionManager.isAccelerometerAvailable {
            return "No Motion"
        } else {
            return "Motion Unavailable"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Motion Detection")
                        .font(.headline)
                    
                    Text(motionStatusText)
                        .font(.subheadline)
                        .foregroundColor(motionStatusColor)
                }
                
                Spacer()
                
                // Motion indicator with animation
                AnimatedMotionIndicator(isWalking: motionManager.isWalking)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                // Motion details
                if motionManager.isWalking {
                    HStack {
                        VStack(alignment: .leading) {
                            Label("Steps: \(motionManager.stepCount)", systemImage: "figure.walk")
                                .font(.subheadline)
                            
                            if let pace = motionManager.currentPace {
                                Label("Pace: \(String(format: "%.1f", pace)) m/min", systemImage: "speedometer")
                                    .font(.subheadline)
                            }
                            
                            if let walkStartTime = motionManager.walkStartTime {
                                let duration = Date().timeIntervalSince(walkStartTime)
                                let minutes = Int(duration) / 60
                                let seconds = Int(duration) % 60
                                Label("Duration: \(minutes)m \(seconds)s", systemImage: "timer")
                                    .font(.subheadline)
                            }
                        }
                        
                        Spacer()
                    }
                }
                
                // Sensor availability
                HStack {
                    if motionManager.motionManager.isAccelerometerAvailable {
                        SensorStatusIndicator(name: "Accelerometer", available: true)
                    }
                    
                    if CMMotionActivityManager.isActivityAvailable() {
                        SensorStatusIndicator(name: "Activity", available: true)
                    }
                    
                    if CMPedometer.isStepCountingAvailable() {
                        SensorStatusIndicator(name: "Pedometer", available: true)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct AnimatedMotionIndicator: View {
    let isWalking: Bool
    
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(isWalking ? Color.green : Color.secondary)
            .frame(width: 40, height: 40)
            .overlay(
                Circle()
                    .stroke(isWalking ? Color.green : Color.clear, lineWidth: 2)
                    .scaleEffect(isAnimating ? 1.5 : 1)
                    .opacity(isAnimating ? 0 : 1)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: false)
                    )
            )
            .onAppear {
                if isWalking {
                    isAnimating = true
                }
            }
            .onDisappear {
                isAnimating = false
            }
            .animation(.easeInOut, value: isWalking)
    }
}

struct SensorStatusIndicator: View {
    let name: String
    let available: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(available ? .green : .red)
                .frame(width: 8, height: 8)
            
            Text(name)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct WalkingStatsCard: View {
    @EnvironmentObject var motionManager: MotionManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Walking Statistics")
                .font(.headline)
            
            if !motionManager.isWalking {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No active walking session")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Show last walking session if available
                    Text("Start walking to view stats and enable app restrictions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    StatTile(
                        title: "Steps",
                        value: "\(motionManager.stepCount)",
                        icon: "figure.walk",
                        color: .blue
                    )
                    
                    StatTile(
                        title: "Pace",
                        value: motionManager.currentPace.map { String(format: "%.1f", $0) } ?? "--",
                        unit: "m/min",
                        icon: "speedometer",
                        color: .green
                    )
                    
                    if let walkStartTime = motionManager.walkStartTime {
                        let duration = Date().timeIntervalSince(walkStartTime)
                        let minutes = Int(duration) / 60
                        let seconds = Int(duration) % 60
                        
                        StatTile(
                            title: "Duration",
                            value: "\(minutes)m",
                            unit: "\(seconds)s",
                            icon: "timer",
                            color: .orange
                        )
                        
                        let estimatedDistance = Double(motionManager.stepCount) * 0.762 // Average step length in meters
                        StatTile(
                            title: "Distance",
                            value: String(format: "%.1f", estimatedDistance / 1000),
                            unit: "km",
                            icon: "arrow.triangle.turn.up.right.diamond.fill",
                            color: .purple
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct StatTile: View {
    let title: String
    let value: String
    var unit: String? = nil
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if let unit = unit {
                        Text(unit)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct MotionSettingsCard: View {
    @EnvironmentObject var motionManager: MotionManager
    
    @State private var motionSensitivity = 1.1
    @State private var stepThreshold = 5
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Motion Settings")
                    .font(.headline)
                
                Spacer()
                
                Toggle("Enable Motion Detection", isOn: .constant(true))
                    .toggleStyle(SwitchToggleStyle())
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Sensitivity")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(String(format: "%.1f", motionSensitivity))x")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $motionSensitivity, in: 0.8...1.5, step: 0.1)
                
                HStack {
                    Text("Step Threshold")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(stepThreshold) steps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Picker("", selection: $stepThreshold) {
                    ForEach(1...20, id: \.self) { steps in
                        Text("\(steps) steps")
                            .tag(steps)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .labelsHidden()
            }
            
            Text("Higher sensitivity detects walking more easily. Step threshold prevents false positives.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct WalkingRestrictionsCard: View {
    @EnvironmentObject var motionManager: MotionManager
    
    let socialApps = ["Instagram", "TikTok", "Facebook", "Twitter", "Snapchat", "Reddit"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Apps Restricted While Walking")
                    .font(.headline)
                
                Spacer()
                
                if motionManager.isWalking {
                    Label("Active", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            // Status message
            if motionManager.shouldRestrictScrolling() {
                VStack {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        
                        Text("Social media scrolling is restricted due to walking")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            } else if motionManager.isWalking {
                VStack {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        
                        Text("Walking detected - will restrict scrolling after \(10 - motionManager.stepCount) more steps")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            // Apps list
            VStack(alignment: .leading, spacing: 8) {
                Text("Restricted Apps")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ForEach(socialApps, id: \.self) { appName in
                    HStack {
                        Image(systemName: "app.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                        
                        Text(appName)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        if motionManager.isWalking && motionManager.shouldRestrictScrolling() {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct MotionSettingsView: View {
    @EnvironmentObject var motionManager: MotionManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Motion Detection")) {
                    Toggle("Enable Walking Detection", isOn: .constant(true))
                    
                    Toggle("Restrict Social Media While Walking", isOn: .constant(true))
                    
                    Toggle("Reduce Screen Time While Walking", isOn: .constant(true))
                }
                
                Section(header: Text("Sensitivity")) {
                    VStack(alignment: .leading) {
                        Text("Detection Sensitivity: Medium")
                        Picker("Sensitivity", selection: .constant(1)) {
                            Text("Low").tag(0)
                            Text("Medium").tag(1)
                            Text("High").tag(2)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                
                Section(header: Text("Step Threshold")) {
                    Stepper(value: .constant(5), in: 1...20) {
                        Text("\(5) steps before restrictions")
                    }
                }
                
                Section(header: Text("Notifications")) {
                    Toggle("Notify When Walking Detected", isOn: .constant(true))
                    
                    Toggle("Notify When Apps Restricted", isOn: .constant(true))
                }
            }
            .navigationTitle("Motion Settings")
            .navigationBarItems(trailing: doneButton)
        }
    }
    
    private var doneButton: some View {
        Button("Done") {
            presentationMode.wrappedValue.dismiss()
        }
    }
}