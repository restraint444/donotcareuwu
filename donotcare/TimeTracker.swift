import Foundation
import SwiftUI

class TimeTracker: ObservableObject {
    @Published var caringTime: TimeInterval = 0
    @Published var notCaringTime: TimeInterval = 0
    
    private var timer: Timer?
    private var currentMode: Bool = false // false = caring, true = not caring
    private var sessionStartTime: Date = Date()
    
    // UserDefaults keys for persistence
    private let caringStartTimeKey = "caringStartTime"
    private let notCaringStartTimeKey = "notCaringStartTimeKey"
    private let lastModeKey = "lastCareMode"
    private let hasActiveSessionKey = "hasActiveSession"
    
    init() {
        sessionStartTime = Date()
        print("📊 TimeTracker initialized")
    }
    
    func startTracking() {
        // Start the timer to update UI every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateCurrentTime()
        }
        print("📊 Time tracking started")
    }
    
    // CRITICAL: Restore state from UserDefaults when app reopens
    func restoreState() {
        let hasActiveSession = UserDefaults.standard.bool(forKey: hasActiveSessionKey)
        
        if hasActiveSession {
            let savedMode = UserDefaults.standard.bool(forKey: lastModeKey)
            currentMode = savedMode
            
            if savedMode {
                // Restore "not caring" session
                let startTime = UserDefaults.standard.double(forKey: notCaringStartTimeKey)
                if startTime > 0 {
                    sessionStartTime = Date(timeIntervalSince1970: startTime)
                    let elapsed = Date().timeIntervalSince(sessionStartTime)
                    notCaringTime = elapsed
                    print("📊 Restored NOT CARING session - elapsed: \(Int(elapsed)) seconds")
                }
            } else {
                // Restore "caring" session
                let startTime = UserDefaults.standard.double(forKey: caringStartTimeKey)
                if startTime > 0 {
                    sessionStartTime = Date(timeIntervalSince1970: startTime)
                    let elapsed = Date().timeIntervalSince(sessionStartTime)
                    caringTime = elapsed
                    print("📊 Restored CARING session - elapsed: \(Int(elapsed)) seconds")
                }
            }
        } else {
            print("📊 No active session to restore - starting fresh")
            // Start fresh caring session
            let now = Date()
            sessionStartTime = now
            currentMode = false
            caringTime = 0
            notCaringTime = 0
            
            // Save initial state
            UserDefaults.standard.set(now.timeIntervalSince1970, forKey: caringStartTimeKey)
            UserDefaults.standard.set(false, forKey: lastModeKey)
            UserDefaults.standard.set(true, forKey: hasActiveSessionKey)
            print("📊 Started fresh CARING session")
        }
    }
    
    func setCareMode(_ careMode: Bool) {
        let now = Date()
        
        // Only reset timer when actually switching modes
        if currentMode != careMode {
            print("📊 Mode switch detected: \(currentMode ? "NOT CARING" : "CARING") → \(careMode ? "NOT CARING" : "CARING")")
            
            currentMode = careMode
            sessionStartTime = now
            
            if careMode {
                // Switching to "not caring" mode - reset both timers
                notCaringTime = 0
                caringTime = 0
                UserDefaults.standard.set(now.timeIntervalSince1970, forKey: notCaringStartTimeKey)
                UserDefaults.standard.removeObject(forKey: caringStartTimeKey)
                print("📊 Started NOT CARING session at \(now)")
            } else {
                // Switching to "caring" mode - reset both timers
                caringTime = 0
                notCaringTime = 0
                UserDefaults.standard.set(now.timeIntervalSince1970, forKey: caringStartTimeKey)
                UserDefaults.standard.removeObject(forKey: notCaringStartTimeKey)
                print("📊 Started CARING session at \(now)")
            }
            
            // Save the new state
            UserDefaults.standard.set(true, forKey: hasActiveSessionKey)
            UserDefaults.standard.set(careMode, forKey: lastModeKey)
        }
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
    
    // Handle app going to background - DON'T reset timer, just save current state
    func handleAppWillResignActive() {
        // Just save current state, don't reset anything
        UserDefaults.standard.set(currentMode, forKey: lastModeKey)
        UserDefaults.standard.set(true, forKey: hasActiveSessionKey)
        
        // Update the start time in UserDefaults to current session start
        if currentMode {
            UserDefaults.standard.set(sessionStartTime.timeIntervalSince1970, forKey: notCaringStartTimeKey)
        } else {
            UserDefaults.standard.set(sessionStartTime.timeIntervalSince1970, forKey: caringStartTimeKey)
        }
        
        print("📊 App going to background - state saved (timer continues)")
        print("📊 Current session: \(currentMode ? "NOT CARING" : "CARING") for \(Int(currentMode ? notCaringTime : caringTime)) seconds")
    }
    
    // Handle app coming back from background - restore and continue timing
    func handleAppDidBecomeActive() {
        let savedMode = UserDefaults.standard.bool(forKey: lastModeKey)
        
        if savedMode == currentMode {
            // We're in the same mode - just update the elapsed time based on saved start time
            if currentMode {
                let startTime = UserDefaults.standard.double(forKey: notCaringStartTimeKey)
                if startTime > 0 {
                    sessionStartTime = Date(timeIntervalSince1970: startTime)
                    let elapsed = Date().timeIntervalSince(sessionStartTime)
                    notCaringTime = elapsed
                    print("📊 App returned - continuing NOT CARING session, elapsed: \(Int(elapsed)) seconds")
                }
            } else {
                let startTime = UserDefaults.standard.double(forKey: caringStartTimeKey)
                if startTime > 0 {
                    sessionStartTime = Date(timeIntervalSince1970: startTime)
                    let elapsed = Date().timeIntervalSince(sessionStartTime)
                    caringTime = elapsed
                    print("📊 App returned - continuing CARING session, elapsed: \(Int(elapsed)) seconds")
                }
            }
        }
    }
    
    // Public method to get session start time for debugging
    func getSessionStartTime() -> Date? {
        return sessionStartTime
    }
    
    // Clear all session data
    func clearSession() {
        UserDefaults.standard.removeObject(forKey: caringStartTimeKey)
        UserDefaults.standard.removeObject(forKey: notCaringStartTimeKey)
        UserDefaults.standard.removeObject(forKey: lastModeKey)
        UserDefaults.standard.removeObject(forKey: hasActiveSessionKey)
        
        caringTime = 0
        notCaringTime = 0
        sessionStartTime = Date()
        print("📊 Session data cleared")
    }
    
    deinit {
        timer?.invalidate()
        print("📊 TimeTracker deinitialized")
    }
}
