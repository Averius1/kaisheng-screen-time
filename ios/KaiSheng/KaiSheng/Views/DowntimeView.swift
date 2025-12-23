//
//  DowntimeView.swift
//  KaiSheng
//
//  Downtime scheduling and management view
//

import SwiftUI

struct DowntimeView: View {
    @EnvironmentObject var downtimeScheduler: DowntimeScheduler
    @State private var showingAddSchedule = false
    
    var body: some View {
        ZStack {
            if downtimeScheduler.schedules.isEmpty {
                EmptyStateView(
                    title: "No Downtime Schedules",
                    message: "Create schedules to block apps during specific times to reduce distractions",
                    icon: "moon"
                )
            } else {
                List {
                    ForEach(downtimeScheduler.schedules) { schedule in
                        DowntimeScheduleRowView(schedule: schedule)
                            .environmentObject(downtimeScheduler)
                    }
                    .onDelete(perform: deleteSchedule)
                }
            }
        }
        .navigationBarItems(trailing: addButton)
        .sheet(isPresented: $showingAddSchedule) {
            AddDowntimeScheduleView(isPresented: $showingAddSchedule)
                .environmentObject(downtimeScheduler)
        }
    }
    
    private var addButton: some View {
        Button(action: { showingAddSchedule = true }) {
            Image(systemName: "plus")
        }
    }
    
    private func deleteSchedule(at offsets: IndexSet) {
        offsets.forEach { index in
            if index < downtimeScheduler.schedules.count {
                let schedule = downtimeScheduler.schedules[index]
                downtimeScheduler.removeSchedule(schedule.id)
            }
        }
    }
}

struct DowntimeScheduleRowView: View {
    @EnvironmentObject var downtimeScheduler: DowntimeScheduler
    let schedule: DowntimeSchedule
    
    @State private var showingEditSchedule = false
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    private var timeRange: String {
        let startString = timeFormatter.string(from: schedule.startTime)
        let endString = timeFormatter.string(from: schedule.endTime)
        return "\(startString) - \(endString)"
    }
    
    private var recurrenceInfo: String {
        if !schedule.isRecurring {
            return "One-time schedule"
        } else if schedule.recurringDays.count == 7 {
            return "Every day"
        } else {
            let dayNames = schedule.recurringDays.sorted().joined(separator: ", ")
            return "On: \(dayNames)"
        }
    }
    
    private var isCurrentlyActive: Bool {
        downtimeScheduler.isInDowntime && downtimeScheduler.activeDowntime?.id == schedule.id
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(schedule.name)
                        .font(.headline)
                    
                    Text(timeRange)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isCurrentlyActive {
                    Text("ACTIVE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .cornerRadius(12)
                }
            }
            
            Text(recurrenceInfo)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Apps affected
            VStack(alignment: .leading, spacing: 4) {
                if schedule.blockEntireDevice {
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.orange)
                        
                        Text("Entire Device (except calls/emergency)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                } else if schedule.blockedApps.count == 1 {
                    HStack {
                        Image(systemName: "app.fill")
                        Text("1 app blocked")
                            .font(.caption)
                    }
                } else {
                    HStack {
                        Image(systemName: "app.fill")
                        Text("\(schedule.blockedApps.count) apps blocked")
                            .font(.caption)
                    }
                }
                
                if !schedule.blockedApps.isEmpty && !schedule.blockEntireDevice {
                    Text(schedule.blockedApps.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Button("Edit Schedule") {
                showingEditSchedule = true
            }
            .font(.caption)
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showingEditSchedule) {
            EditDowntimeScheduleView(schedule: schedule, isPresented: $showingEditSchedule)
                .environmentObject(downtimeScheduler)
        }
    }
}

struct AddDowntimeScheduleView: View {
    @EnvironmentObject var downtimeScheduler: DowntimeScheduler
    @Binding var isPresented: Bool
    
    @State private var name = ""
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(3600)
    @State private var isRecurring = false
    @State private var selectedDays = Set<String>()
    @State private var blockEntireDevice = false
    @State private var selectedApps = Set<String>()
    
    let dayOptions = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    static let appOptions = [
        "Instagram", "TikTok", "Facebook", "Twitter", "YouTube", 
        "Netflix", "Spotify", "Games", "Snapchat", "WhatsApp", 
        "Reddit", "Pinterest"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Schedule Details")) {
                    TextField("Schedule Name", text: $name)
                    
                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    
                    DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                }
                
                Section(header: Text("Recurrence")) {
                    Toggle("Recurring Schedule", isOn: $isRecurring)
                    
                    if isRecurring {
                        Text("Select Days")
                            .font(.headline)
                        
                        ForEach(dayOptions, id: \.self) { day in
                            MultipleSelectionRow(
                                title: day,
                                isSelected: selectedDays.contains(day)
                            ) {
                                if selectedDays.contains(day) {
                                    selectedDays.remove(day)
                                } else {
                                    selectedDays.insert(day)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Restrictions")) {
                    Toggle("Block Entire Device", isOn: $blockEntireDevice)
                    
                    if !blockEntireDevice {
                        Text("Block Access To:")
                            .font(.headline)
                        
                        ForEach(AddDowntimeScheduleView.appOptions, id: \.self) { app in
                            MultipleSelectionRow(
                                title: app,
                                isSelected: selectedApps.contains(app)
                            ) {
                                if selectedApps.contains(app) {
                                    selectedApps.remove(app)
                                } else {
                                    selectedApps.insert(app)
                                }
                            }
                        }
                    } else {
                        Text("All non-essential apps will be blocked (calls, emergency, and health apps will remain available)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button("Add Schedule") {
                        addSchedule()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .disabled(name.isEmpty || (!blockEntireDevice && selectedApps.isEmpty))
                }
            }
            .navigationTitle("Add Downtime Schedule")
            .navigationBarItems(
                leading: Button("Cancel") { isPresented = false }
            )
        }
    }
    
    private func addSchedule() {
        let schedule = DowntimeSchedule(
            name: name,
            startTime: startTime,
            endTime: endTime,
            isRecurring: isRecurring,
            recurringDays: selectedDays,
            blockedApps: Array(selectedApps),
            blockEntireDevice: blockEntireDevice
        )
        
        downtimeScheduler.addSchedule(schedule)
        isPresented = false
    }
}

struct EditDowntimeScheduleView: View {
    @EnvironmentObject var downtimeScheduler: DowntimeScheduler
    @Binding var isPresented: Bool
    let schedule: DowntimeSchedule
    
    @State private var name: String
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var isRecurring: Bool
    @State private var selectedDays: Set<String>
    @State private var blockEntireDevice: Bool
    @State private var selectedApps: Set<String>
    
    let dayOptions = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    init(schedule: DowntimeSchedule, isPresented: Binding<Bool>) {
        self.schedule = schedule
        _isPresented = isPresented
        
        _name = State(initialValue: schedule.name)
        _startTime = State(initialValue: schedule.startTime)
        _endTime = State(initialValue: schedule.endTime)
        _isRecurring = State(initialValue: schedule.isRecurring)
        _selectedDays = State(initialValue: schedule.recurringDays)
        _blockEntireDevice = State(initialValue: schedule.blockEntireDevice)
        _selectedApps = State(initialValue: Set(schedule.blockedApps))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Schedule Details")) {
                    TextField("Schedule Name", text: $name)
                    
                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    
                    DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                }
                
                Section(header: Text("Recurrence")) {
                    Toggle("Recurring Schedule", isOn: $isRecurring)
                    
                    if isRecurring {
                        Text("Select Days")
                            .font(.headline)
                        
                        ForEach(dayOptions, id: \.self) { day in
                            MultipleSelectionRow(
                                title: day,
                                isSelected: selectedDays.contains(day)
                            ) {
                                if selectedDays.contains(day) {
                                    selectedDays.remove(day)
                                } else {
                                    selectedDays.insert(day)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Restrictions")) {
                    Toggle("Block Entire Device", isOn: $blockEntireDevice)
                    
                    if !blockEntireDevice {
                        Text("Block Access To:")
                            .font(.headline)
                        
                        ForEach(AddDowntimeScheduleView.appOptions, id: \.self) { app in
                            MultipleSelectionRow(
                                title: app,
                                isSelected: selectedApps.contains(app)
                            ) {
                                if selectedApps.contains(app) {
                                    selectedApps.remove(app)
                                } else {
                                    selectedApps.insert(app)
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Button("Update Schedule") {
                        updateSchedule()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .disabled(name.isEmpty || (!blockEntireDevice && selectedApps.isEmpty))
                }
            }
            .navigationTitle("Edit Schedule")
            .navigationBarItems(
                leading: Button("Cancel") { isPresented = false }
            )
        }
    }
    
    private func updateSchedule() {
        let updatedSchedule = DowntimeSchedule(
            id: schedule.id,
            name: name,
            startTime: startTime,
            endTime: endTime,
            isRecurring: isRecurring,
            recurringDays: selectedDays,
            blockedApps: Array(selectedApps),
            blockEntireDevice: blockEntireDevice
        )
        
        downtimeScheduler.updateSchedule(updatedSchedule)
        isPresented = false
    }
}

struct MultipleSelectionRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
        }
    }
}