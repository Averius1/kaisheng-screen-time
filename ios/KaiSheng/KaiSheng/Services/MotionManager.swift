//
//  MotionManager.swift
//  KaiSheng
//
//  Motion detection service using CoreMotion
//  Detects walking and triggers app restrictions
//

import Foundation
import CoreMotion
import Combine

class MotionManager: ObservableObject {
    // Shared instance for singleton pattern
    static let shared = MotionManager()
    
    private let motionManager = CMMotionManager()
    private let activityManager = CMMotionActivityManager()
    private let pedometer = CMPedometer()
    
    @Published var isWalking = false
    @Published var walkStartTime: Date?
    @Published var currentPace: Double?
    @Published var stepCount: Int = 0
    
    // Thresholds for motion detection
    private let walkingAccelerationThreshold = 1.1
    private let walkingStepThreshold = 5
    
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupMotionDetection()
    }
    
    func startMotionUpdates() {
        guard motionManager.isAccelerometerAvailable else {
            print("Accelerometer not available on this device")
            return
        }
        
        motionManager.accelerometerUpdateInterval = 0.5 // Update every half second
        
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let self = self, let accelerometerData = data else { return }
            
            let acceleration = self.calculateTotalAcceleration(accelerometerData)
            self.processAcceleration(acceleration)
        }
        
        // Start activity detection for more accurate walking detection
        if CMMotionActivityManager.isActivityAvailable() {
            activityManager.startActivityUpdates(to: .main) { [weak self] activity in
                guard let self = self, let activityData = activity else { return }
                self.processActivity(activityData)
            }
        }
        
        // Start pedometer for step counting
        if CMPedometer.isStepCountingAvailable() {
            pedometer.startUpdates(from: Date()) { [weak self] pedometerData, error in
                guard let self = self, let data = pedometerData else { return }
                
                DispatchQueue.main.async {
                    self.stepCount = data.numberOfSteps.intValue
                    if let pace = data.currentPace {
                        self.currentPace = pace.doubleValue
                    }
                }
            }
        }
    }
    
    func stopMotionUpdates() {
        motionManager.stopAccelerometerUpdates()
        if CMMotionActivityManager.isActivityAvailable() {
            activityManager.stopActivityUpdates()
        }
        if CMPedometer.isStepCountingAvailable() {
            pedometer.stopUpdates()
        }
        stopWalkDetectionTimer()
    }
    
    private func setupMotionDetection() {
        startMotionUpdates()
    }
    
    private func calculateTotalAcceleration(_ data: CMAccelerometerData) -> Double {
        let x = data.acceleration.x
        let y = data.acceleration.y
        let z = data.acceleration.z
        
        return sqrt(x * x + y * y + z * z)
    }
    
    private func processAcceleration(_ acceleration: Double) {
        // Acceleration due to walking typically shows periodic variations above 1g
        if acceleration > walkingAccelerationThreshold {
            if !isWalking {
                startWalkingDetection()
            }
        } else {
            // If acceleration drops below threshold, stop walking after a delay
            if isWalking {
                stopWalkingDetection()
            }
        }
    }
    
    private func processActivity(_ activity: CMMotionActivity) {
        DispatchQueue.main.async {
            if activity.automotive {
                self.stopWalkingDetection()
            } else if activity.walking && !self.isWalking {
                self.setWalkingStatus(true)
            } else if !activity.walking && self.isWalking {
                self.stopWalkingDetection()
            }
        }
    }
    
    private func startWalkingDetection() {
        if isWalking { return }
        
        // Debounce - require consistent walking motion
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.setWalkingStatus(true)
        }
    }
    
    private func stopWalkingDetection() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.setWalkingStatus(false)
        }
    }
    
    private func setWalkingStatus(_ walking: Bool) {
        DispatchQueue.main.async {
            if walking && !self.isWalking {
                self.isWalking = true
                self.walkStartTime = Date()
                NotificationCenter.default.post(name: .walkingStarted, object: nil)
            } else if !walking && self.isWalking {
                self.isWalking = false
                NotificationCenter.default.post(name: .walkingEnded, object: nil)
                self.walkStartTime = nil
            }
        }
    }
    
    private func stopWalkDetectionTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // Get formatted walking duration
    func getWalkingDuration() -> TimeInterval {
        guard let startTime = walkStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    // Check if walking and should restrict apps
    func shouldRestrictScrolling() -> Bool {
        return isWalking && stepCount >= walkingStepThreshold
    }
}

// Notification extensions
extension Notification.Name {
    static let walkingStarted = Notification.Name("walkingStarted")
    static let walkingEnded = Notification.Name("walkingEnded")
}