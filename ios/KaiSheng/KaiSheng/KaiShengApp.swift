//
//  KaiShengApp.swift
//  KaiSheng
//
//  Main entry point for the KaiSheng screen time management app
//

import SwiftUI

@main
struct KaiShengApp: App {
    @StateObject private var motionManager = MotionManager()
    @StateObject private var appTracker = AppUsageTracker()
    @StateObject private var downtimeScheduler = DowntimeScheduler()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(motionManager)
                .environmentObject(appTracker)
                .environmentObject(downtimeScheduler)
        }
    }
}