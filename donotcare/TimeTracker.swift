import Foundation
import SwiftUI

class TimeTracker: ObservableObject {
    @Published var caringTime: TimeInterval = 0
    @Published var notCaringTime: TimeInterval = 0
    
    private var timer: Timer?
    private var currentMode: Bool = false // false = caring, true = not caring
    private var sessionStartTime: Date = Date()
    
    // UserDefaults keys for persistence (keeping for historical data if needed)
    private let caringTimeKey = "caringTimeTotal"
    private let notCaringTimeKey = "notCaringTimeTotal"
    private let lastUpdateKey = "lastUpdateTime"
    private let lastModeKey = "lastCareMode"
    
    init() {
        // Always start fresh - don't load persisted times
        caringTime = 0
        notCaringTime = 0
        sessionStartTime = Date()
        print("📊 TimeTracker initialized - starting fresh")
    }
    
    func startTracking() {
        // Start the timer to update UI every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateCurrentTime()
        }
        print("📊 Time tracking started")
    }
    
    func setCareMode(_ careMode: Bool) {
        currentMode = careMode
        
        // RESET: Always start the timer at 0 when switching modes
        if careMode {
            // Switching to "not caring" mode - reset not caring time to 0
            notCaringTime = 0
            print("📊 Switched to NOT CARING mode - timer reset to 0")
        } else {
            // Switching to "caring" mode - reset caring time to 0
            caringTime = 0
            print("📊 Switched to CARING mode - timer reset to 0")
        }
        
        // Reset session start time for the new mode
        sessionStartTime = Date()
        
        // Save the new mode for background calculations
        UserDefaults.standard.set(careMode, forKey: lastModeKey)
        UserDefaults.standard.set(sessionStartTime.timeIntervalSince1970, forKey: lastUpdateKey)
    }
    
    private func updateCurrentTime() {
        let now = Date()
        let timeElapsed = now.timeIntervalSince(sessionStartTime)
        
        if currentMode {
            // Not caring mode - update not caring time
            notCaringTime = timeElapsed
        } else {
            // Caring mode - update caring time
            caringTime = timeElapsed
        }
    }
    
    // Handle app going to background
    func handleAppWillResignActive() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastUpdateKey)
        UserDefaults.standard.set(currentMode, forKey: lastModeKey)
        print("📊 App going to background - saved state")
    }
    
    // Handle app coming back from background
    func handleAppDidBecomeActive() {
        let lastUpdate = UserDefaults.standard.double(forKey: lastUpdateKey)
        let lastMode = UserDefaults.standard.bool(forKey: lastModeKey)
        
        if lastUpdate > 0 && lastMode == currentMode {
            let now = Date().timeIntervalSince1970
            let backgroundTime = now - lastUpdate
            
            // Only adjust if we were backgrounded for more than 5 seconds
            if backgroundTime > 5 {
                // Adjust session start time to account for background time
                sessionStartTime = sessionStartTime.addingTimeInterval(-backgroundTime)
                print("📊 App returned from background - adjusted timer by \(Int(backgroundTime)) seconds")
            }
        }
        
        // Update last update time
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastUpdateKey)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    deinit {
        timer?.invalidate()
        print("📊 TimeTracker deinitialized")
    }
}
