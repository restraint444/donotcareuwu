import Foundation
import SwiftUI

enum TrackingMode {
    case caring
    case doNotCare
    case focus
}

class TimeTracker: ObservableObject {
    // Three independent timers for three different purposes
    @Published var caringTime: TimeInterval = 0      // Timer 1: Always resets to 0 on any toggle change
    @Published var countdownTime: TimeInterval = 0   // Timer 2: 40-minute countdown
    @Published var focusTime: TimeInterval = 0       // Timer 3: Focus session time
    
    // UI timer for display updates
    private var displayTimer: Timer?
    
    // Current active mode
    private var currentMode: TrackingMode = .caring
    
    // Timer 1: Caring time tracking (ALWAYS RESETS on any toggle change)
    private var caringStartTime: Date?
    // NOTE: No totalCaringTime persistence - always starts fresh
    
    // Timer 2: Countdown tracking (40-minute sessions)
    private var countdownStartTime: Date?
    private let countdownDuration: TimeInterval = 40 * 60 // 40 minutes
    
    // Timer 3: Focus session tracking
    private var focusStartTime: Date?
    
    // UserDefaults keys for persistence (removed caring time persistence)
    private let caringStartTimeKey = "caringStartTime"
    private let countdownStartTimeKey = "countdownStartTime"
    private let focusStartTimeKey = "focusStartTime"
    private let lastModeKey = "lastTrackingMode"
    
    init() {
        loadSavedState()
        print("📊 TimeTracker initialized - caring time ALWAYS starts at 0")
        print("📊 - Caring time: \(formatTime(caringTime)) (fresh start)")
        print("📊 - Countdown time: \(formatTime(countdownTime))")
        print("📊 - Focus time: \(formatTime(focusTime))")
    }
    
    func startTracking() {
        // Start the display timer to update UI every second
        displayTimer?.invalidate()
        displayTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateAllTimers()
        }
        print("📊 Display timer started - updating all timers every second")
    }
    
    func setMode(_ mode: TrackingMode) {
        guard mode != currentMode else {
            print("📊 Mode unchanged: \(mode.toString())")
            return
        }
        
        let previousMode = currentMode
        print("📊 MODE SWITCH: \(previousMode.toString().uppercased()) → \(mode.toString().uppercased())")
        
        // STEP 1: Stop previous mode's timer
        stopPreviousModeTimer(previousMode)
        
        // STEP 2: ALWAYS reset caring time on any mode change
        resetCaringTime()
        
        // STEP 3: Start new mode's timer
        startNewModeTimer(mode)
        
        // STEP 4: Update current mode
        currentMode = mode
        
        // STEP 5: Update display immediately
        updateAllTimers()
        
        // STEP 6: Save state
        saveState()
        
        print("📊 Mode switch complete: \(mode.toString().uppercased()) active")
    }
    
    private func resetCaringTime() {
        // ALWAYS reset caring time to 0 on any toggle change
        caringTime = 0
        caringStartTime = nil
        print("📊 🔄 CARING TIME RESET TO 0 (any toggle change)")
    }
    
    private func stopPreviousModeTimer(_ mode: TrackingMode) {
        switch mode {
        case .caring:
            // Don't save caring time - it will be reset anyway
            caringStartTime = nil
            print("📊 STOPPED caring timer - will reset to 0")
            
        case .doNotCare:
            if countdownStartTime != nil {
                countdownStartTime = nil
                print("📊 STOPPED countdown timer")
            }
            
        case .focus:
            if focusStartTime != nil {
                focusStartTime = nil
                print("📊 STOPPED focus timer")
            }
        }
    }
    
    private func startNewModeTimer(_ mode: TrackingMode) {
        let now = Date()
        
        switch mode {
        case .caring:
            caringStartTime = now
            caringTime = 0 // Always start from 0
            print("📊 STARTED caring timer from 00:00 (fresh start)")
            
        case .doNotCare:
            countdownStartTime = now
            countdownTime = countdownDuration // Start at 40:00
            print("📊 STARTED countdown timer at 40:00")
            
        case .focus:
            focusStartTime = now
            focusTime = 0 // Start at 00:00
            print("📊 STARTED focus timer at 00:00")
        }
    }
    
    private func updateAllTimers() {
        let now = Date()
        
        // Update Timer 1: Caring time (only when caring mode is active, always from 0)
        if currentMode == .caring, let startTime = caringStartTime {
            let currentSession = now.timeIntervalSince(startTime)
            caringTime = currentSession // No accumulated total - always fresh
        }
        
        // Update Timer 2: Countdown time (only when do not care mode is active)
        if currentMode == .doNotCare, let startTime = countdownStartTime {
            let elapsed = now.timeIntervalSince(startTime)
            let remaining = countdownDuration - elapsed
            countdownTime = max(0, remaining)
        }
        
        // Update Timer 3: Focus time (only when focus mode is active)
        if currentMode == .focus, let startTime = focusStartTime {
            let elapsed = now.timeIntervalSince(startTime)
            focusTime = elapsed
        }
    }
    
    // Get the appropriate time for UI display
    func getDisplayTime() -> TimeInterval {
        switch currentMode {
        case .caring:
            return caringTime
        case .doNotCare:
            return countdownTime
        case .focus:
            return focusTime
        }
    }
    
    // Get remaining countdown time (for do not care mode status)
    func getRemainingCountdownTime() -> TimeInterval {
        return countdownTime
    }
    
    // Check if countdown has completed
    func isCountdownComplete() -> Bool {
        return currentMode == .doNotCare && countdownTime <= 0
    }
    
    private func loadSavedState() {
        // NOTE: No longer loading totalCaringTime - always starts fresh
        
        let savedCaringStartTime = UserDefaults.standard.double(forKey: caringStartTimeKey)
        if savedCaringStartTime > 0 {
            caringStartTime = Date(timeIntervalSince1970: savedCaringStartTime)
        }
        
        let savedCountdownStartTime = UserDefaults.standard.double(forKey: countdownStartTimeKey)
        if savedCountdownStartTime > 0 {
            countdownStartTime = Date(timeIntervalSince1970: savedCountdownStartTime)
        }
        
        let savedFocusStartTime = UserDefaults.standard.double(forKey: focusStartTimeKey)
        if savedFocusStartTime > 0 {
            focusStartTime = Date(timeIntervalSince1970: savedFocusStartTime)
        }
        
        let savedModeString = UserDefaults.standard.string(forKey: lastModeKey) ?? "caring"
        currentMode = TrackingMode.fromString(savedModeString)
        
        // Initialize display times - caring always starts at 0
        caringTime = 0 // Always fresh start
        countdownTime = countdownDuration
        focusTime = 0
        
        print("📊 Loaded saved state - Mode: \(currentMode.toString().uppercased())")
        print("📊 Caring time ALWAYS starts fresh at 0")
    }
    
    func restoreState() {
        // Calculate current times based on saved start times
        updateAllTimers()
        print("📊 State restored - Current display: \(formatTime(getDisplayTime()))")
    }
    
    func saveState() {
        UserDefaults.standard.set(currentMode.toString(), forKey: lastModeKey)
        // NOTE: No longer saving totalCaringTime - always starts fresh
        
        // Save active timer start times
        if let startTime = caringStartTime {
            UserDefaults.standard.set(startTime.timeIntervalSince1970, forKey: caringStartTimeKey)
        } else {
            UserDefaults.standard.removeObject(forKey: caringStartTimeKey)
        }
        
        if let startTime = countdownStartTime {
            UserDefaults.standard.set(startTime.timeIntervalSince1970, forKey: countdownStartTimeKey)
        } else {
            UserDefaults.standard.removeObject(forKey: countdownStartTimeKey)
        }
        
        if let startTime = focusStartTime {
            UserDefaults.standard.set(startTime.timeIntervalSince1970, forKey: focusStartTimeKey)
        } else {
            UserDefaults.standard.removeObject(forKey: focusStartTimeKey)
        }
    }
    
    func handleAppWillResignActive() {
        // No need to accumulate caring progress - it resets on next toggle anyway
        saveState()
        print("📊 App backgrounding - \(currentMode.toString().uppercased()): \(formatTime(getDisplayTime()))")
    }
    
    func handleAppDidBecomeActive() {
        updateAllTimers()
        print("📊 App foregrounding - \(currentMode.toString().uppercased()): \(formatTime(getDisplayTime()))")
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = Int(time)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    deinit {
        // No need to save caring progress - it resets on next toggle anyway
        displayTimer?.invalidate()
        print("📊 TimeTracker deinitialized - all timers stopped")
    }
}

// Extension to convert between TrackingMode and String for UserDefaults
extension TrackingMode {
    func toString() -> String {
        switch self {
        case .caring:
            return "caring"
        case .doNotCare:
            return "doNotCare"
        case .focus:
            return "focus"
        }
    }
    
    static func fromString(_ string: String) -> TrackingMode {
        switch string {
        case "caring":
            return .caring
        case "doNotCare":
            return .doNotCare
        case "focus":
            return .focus
        default:
            return .caring
        }
    }
}
