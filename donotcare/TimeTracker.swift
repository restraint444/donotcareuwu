import Foundation
import SwiftUI

class TimeTracker: ObservableObject {
    @Published var caringTime: TimeInterval = 0
    @Published var notCaringTime: TimeInterval = 0
    
    private var timer: Timer?
    private var currentMode: Bool = false // false = caring, true = not caring
    
    // UserDefaults keys for persistence
    private let caringTimeKey = "caringTimeTotal"
    private let notCaringTimeKey = "notCaringTimeTotal"
    private let lastUpdateKey = "lastUpdateTime"
    private let lastModeKey = "lastCareMode"
    
    init() {
        loadPersistedTimes()
        calculateTimeFromBackground()
    }
    
    func startTracking() {
        // Start the timer to update UI every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateCurrentTime()
        }
    }
    
    func setCareMode(_ careMode: Bool) {
        // Save current accumulated time before switching modes
        saveCurrentState()
        
        currentMode = careMode
        
        // Save the new mode
        UserDefaults.standard.set(careMode, forKey: lastModeKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastUpdateKey)
        
        print("📊 Mode switched to: \(careMode ? "not caring" : "caring")")
        print("📊 Current caring time: \(formatTime(caringTime))")
        print("📊 Current not caring time: \(formatTime(notCaringTime))")
    }
    
    private func updateCurrentTime() {
        let now = Date().timeIntervalSince1970
        let lastUpdate = UserDefaults.standard.double(forKey: lastUpdateKey)
        
        if lastUpdate > 0 {
            let timeDiff = now - lastUpdate
            
            if currentMode {
                // Not caring mode - increment not caring time
                notCaringTime += timeDiff
                UserDefaults.standard.set(notCaringTime, forKey: notCaringTimeKey)
            } else {
                // Caring mode - increment caring time
                caringTime += timeDiff
                UserDefaults.standard.set(caringTime, forKey: caringTimeKey) // Fixed: was using wrong parameters
            }
        }
        
        // Update last update time
        UserDefaults.standard.set(now, forKey: lastUpdateKey)
    }
    
    private func saveCurrentState() {
        updateCurrentTime() // Make sure we're up to date
        UserDefaults.standard.set(caringTime, forKey: caringTimeKey)
        UserDefaults.standard.set(notCaringTime, forKey: notCaringTimeKey)
    }
    
    private func loadPersistedTimes() {
        caringTime = UserDefaults.standard.double(forKey: caringTimeKey)
        notCaringTime = UserDefaults.standard.double(forKey: notCaringTimeKey)
        currentMode = UserDefaults.standard.bool(forKey: lastModeKey)
        
        print("📊 Loaded persisted times:")
        print("📊 Caring time: \(formatTime(caringTime))")
        print("📊 Not caring time: \(formatTime(notCaringTime))")
        print("📊 Last mode: \(currentMode ? "not caring" : "caring")")
    }
    
    private func calculateTimeFromBackground() {
        let lastUpdate = UserDefaults.standard.double(forKey: lastUpdateKey)
        
        if lastUpdate > 0 {
            let now = Date().timeIntervalSince1970
            let timeDiff = now - lastUpdate
            
            // Only add time if the app was backgrounded for more than 10 seconds
            // (to avoid small timing issues when quickly switching between apps)
            if timeDiff > 10 {
                let lastMode = UserDefaults.standard.bool(forKey: lastModeKey)
                
                if lastMode {
                    // Was in not caring mode
                    notCaringTime += timeDiff
                    print("📊 Added \(formatTime(timeDiff)) to not caring time from background")
                } else {
                    // Was in caring mode
                    caringTime += timeDiff
                    print("📊 Added \(formatTime(timeDiff)) to caring time from background")
                }
                
                // Save updated times
                UserDefaults.standard.set(caringTime, forKey: caringTimeKey)
                UserDefaults.standard.set(notCaringTime, forKey: notCaringTimeKey)
            }
        }
        
        // Update the last update time to now
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
        saveCurrentState()
    }
}
