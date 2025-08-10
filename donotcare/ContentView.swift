import SwiftUI
import UserNotifications

struct ContentView: View {
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var timeTracker = TimeTracker()
    @State private var doNotCareMode = false
    @State private var focusMode = false
    @State private var showingPermissionAlert = false
    
    var body: some View {
        ZStack {
            // Soft, calming background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color(.systemGray6).opacity(0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Time display
                VStack(spacing: 8) {
                    Text(getDisplayTime())
                        .font(.system(size: 48, weight: .ultraLight, design: .rounded))
                        .foregroundColor(getDisplayColor())
                        .monospacedDigit()
                    
                    Text(getDisplayLabel())
                        .font(.system(size: 16, weight: .light, design: .rounded))
                        .foregroundColor(Color(.tertiaryLabel))
                }
                .padding(.bottom, 20)
                
                // Main controls - Two mutually exclusive modes
                VStack(spacing: 16) {
                    // Do Not Care Mode
                    HStack(spacing: 16) {
                        Text("do not care")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        
                        Toggle("", isOn: Binding(
                            get: { doNotCareMode },
                            set: { newValue in
                                handleToggleChange(doNotCare: newValue, focus: focusMode, toggleChanged: .doNotCare)
                            }
                        ))
                        .toggleStyle(SwitchToggleStyle(tint: .orange))
                        .scaleEffect(1.2)
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                    .opacity(focusMode ? 0.7 : 1.0)
                    
                    // Focus Mode
                    HStack(spacing: 16) {
                        Text("focus mode")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        
                        Toggle("", isOn: Binding(
                            get: { focusMode },
                            set: { newValue in
                                handleToggleChange(doNotCare: doNotCareMode, focus: newValue, toggleChanged: .focus)
                            }
                        ))
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                        .scaleEffect(1.2)
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                    .opacity(doNotCareMode ? 0.7 : 1.0)
                }
                
                Spacer()
                
                // Status display
                VStack(spacing: 8) {
                    Text(getStatusText())
                        .font(.system(size: 14, weight: .light, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 40)
            }
            .padding()
        }
        .onAppear {
            setupNotifications()
            restoreAppState()
            timeTracker.startTracking()
        }
        .onReceive(NotificationCenter.default.publisher(for: .userChoseToCare)) { _ in
            // Handle when user taps "I Care Now" in notification
            handleToggleChange(doNotCare: false, focus: false, toggleChanged: .notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            timeTracker.handleAppWillResignActive()
            saveAppState()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            timeTracker.handleAppDidBecomeActive()
        }
        .alert("Notification Permission Required", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable notifications in Settings to receive focus reminders.")
        }
    }
    
    // Enum to track which toggle was changed
    private enum ToggleType {
        case doNotCare
        case focus
        case notification
    }
    
    // FIXED: Unified toggle handler with strict mutual exclusivity
    private func handleToggleChange(doNotCare: Bool, focus: Bool, toggleChanged: ToggleType) {
        print("🎛️ Toggle change - doNotCare: \(doNotCare), focus: \(focus), changed: \(toggleChanged)")
        
        // STEP 1: ABORT any previous process immediately
        print("🛑 ABORTING previous process before state change")
        notificationManager.stopAllNotifications()
        
        // STEP 2: Determine new state with mutual exclusivity enforcement
        let newState = determineNewState(doNotCare: doNotCare, focus: focus, toggleChanged: toggleChanged)
        
        // STEP 3: Update UI state variables
        doNotCareMode = newState.doNotCare
        focusMode = newState.focus
        
        // STEP 4: Activate the appropriate mode
        activateMode(doNotCare: newState.doNotCare, focus: newState.focus)
        
        // STEP 5: Save state
        saveAppState()
        
        print("✅ Toggle change complete - Final state: doNotCare: \(doNotCareMode), focus: \(focusMode)")
    }
    
    private func determineNewState(doNotCare: Bool, focus: Bool, toggleChanged: ToggleType) -> (doNotCare: Bool, focus: Bool) {
        switch toggleChanged {
        case .doNotCare:
            if doNotCare {
                // Do Not Care was turned ON - turn off Focus
                print("🔴 Do Not Care ON - forcing Focus OFF")
                return (doNotCare: true, focus: false)
            } else {
                // Do Not Care was turned OFF - keep Focus as is
                print("⚪ Do Not Care OFF - Focus remains \(focus ? "ON" : "OFF")")
                return (doNotCare: false, focus: focus)
            }
            
        case .focus:
            if focus {
                // Focus was turned ON - turn off Do Not Care
                print("🔵 Focus ON - forcing Do Not Care OFF")
                return (doNotCare: false, focus: true)
            } else {
                // Focus was turned OFF - keep Do Not Care as is
                print("⚪ Focus OFF - Do Not Care remains \(doNotCare ? "ON" : "OFF")")
                return (doNotCare: doNotCare, focus: false)
            }
            
        case .notification:
            // Notification action - turn both OFF
            print("📱 Notification action - turning both OFF")
            return (doNotCare: false, focus: false)
        }
    }
    
    private func activateMode(doNotCare: Bool, focus: Bool) {
        if doNotCare && !focus {
            // Only do not care mode active
            print("🔴 ACTIVATING Do Not Care Mode")
            timeTracker.setMode(.doNotCare)
            notificationManager.startDoNotCareNotifications()
        } else if !doNotCare && focus {
            // Only focus mode active
            print("🔵 ACTIVATING Focus Mode")
            timeTracker.setMode(.focus)
            notificationManager.startFocusNotifications()
        } else {
            // Both off or invalid state - caring mode
            print("🟢 ACTIVATING Caring Mode")
            timeTracker.setMode(.caring)
            // Notifications already stopped in STEP 1
        }
    }
    
    // Get the time to display
    private func getDisplayTime() -> String {
        let displayTime = timeTracker.getDisplayTime()
        
        if doNotCareMode {
            // Show countdown time
            return formatCountdownTime(displayTime)
        } else {
            // Show elapsed time (caring or focus)
            return formatElapsedTime(displayTime)
        }
    }
    
    // Get the display color based on current mode
    private func getDisplayColor() -> Color {
        if doNotCareMode {
            return .orange
        } else if focusMode {
            return .blue
        } else {
            return .secondary
        }
    }
    
    // Get the label to display based on current mode
    private func getDisplayLabel() -> String {
        if doNotCareMode {
            let remainingTime = timeTracker.getRemainingCountdownTime()
            if remainingTime <= 0 {
                return "session complete"
            } else {
                return "time remaining"
            }
        } else if focusMode {
            return "time spent focusing"
        } else {
            return "time spent caring"
        }
    }
    
    // Get status text based on current mode
    private func getStatusText() -> String {
        if doNotCareMode {
            let remainingTime = timeTracker.getRemainingCountdownTime()
            if remainingTime <= 0 {
                return "40-minute session complete - toggle to restart"
            } else {
                return "focus reminders active (40s intervals for 40 min)"
            }
        } else if focusMode {
            return "focus reminders active (every 60s until stopped)"
        } else {
            return "both reminder modes off - caring mode active"
        }
    }
    
    private func restoreAppState() {
        let savedDoNotCareMode = UserDefaults.standard.bool(forKey: "doNotCareMode")
        let savedFocusMode = UserDefaults.standard.bool(forKey: "focusMode")
        let hasDoNotCareSavedState = UserDefaults.standard.object(forKey: "doNotCareMode") != nil
        let hasFocusSavedState = UserDefaults.standard.object(forKey: "focusMode") != nil
        
        if hasDoNotCareSavedState || hasFocusSavedState {
            print("📱 Restoring saved state - doNotCareMode: \(savedDoNotCareMode), focusMode: \(savedFocusMode)")
            
            // Ensure mutual exclusivity during restoration
            if savedDoNotCareMode && savedFocusMode {
                print("⚠️ Both modes were saved as true - defaulting to caring mode")
                doNotCareMode = false
                focusMode = false
                timeTracker.setMode(.caring)
            } else if savedDoNotCareMode {
                doNotCareMode = true
                focusMode = false
                timeTracker.setMode(.doNotCare)
                notificationManager.startDoNotCareNotifications()
            } else if savedFocusMode {
                doNotCareMode = false
                focusMode = true
                timeTracker.setMode(.focus)
                notificationManager.startFocusNotifications()
            } else {
                doNotCareMode = false
                focusMode = false
                timeTracker.setMode(.caring)
            }
            
            timeTracker.restoreState()
        } else {
            print("📱 No saved state found - starting fresh in caring mode")
            doNotCareMode = false
            focusMode = false
            timeTracker.setMode(.caring)
        }
    }
    
    private func saveAppState() {
        UserDefaults.standard.set(doNotCareMode, forKey: "doNotCareMode")
        UserDefaults.standard.set(focusMode, forKey: "focusMode")
    }
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .notDetermined:
                    self.notificationManager.requestPermission()
                case .denied:
                    self.showingPermissionAlert = true
                case .authorized, .provisional, .ephemeral:
                    print("✅ Notifications already authorized")
                @unknown default:
                    self.notificationManager.requestPermission()
                }
            }
        }
    }
    
    private func formatElapsedTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    private func formatCountdownTime(_ time: TimeInterval) -> String {
        let totalSeconds = max(0, Int(time))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    ContentView()
}
