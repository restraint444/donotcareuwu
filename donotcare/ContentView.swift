import SwiftUI
import UserNotifications

struct ContentView: View {
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var timeTracker = TimeTracker()
    @State private var doNotCareMode = false
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
                
                // Time elapsed display - Shows ACTUAL elapsed time since mode was set
                VStack(spacing: 8) {
                    Text(formatElapsedTime(doNotCareMode ? timeTracker.notCaringTime : timeTracker.caringTime))
                        .font(.system(size: 48, weight: .ultraLight, design: .rounded))
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                    
                    Text(doNotCareMode ? "time not caring" : "time caring")
                        .font(.system(size: 16, weight: .light, design: .rounded))
                        .foregroundColor(Color(.tertiaryLabel))
                }
                .padding(.bottom, 20)
                
                // Main control
                HStack(spacing: 16) {
                    Text("do not care")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Toggle("", isOn: $doNotCareMode)
                        .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                        .scaleEffect(1.2)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                
                Spacer()
                
                // Enhanced status with notification info
                VStack(spacing: 8) {
                    Text(doNotCareMode ? "notifications every 60 seconds" : "notifications paused")
                        .font(.system(size: 14, weight: .light, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    if doNotCareMode {
                        VStack(spacing: 4) {
                            Text("pre-scheduled notification system active")
                                .font(.system(size: 12, weight: .light, design: .rounded))
                                .foregroundColor(Color(.tertiaryLabel))
                            
                            Text("works even when app is completely closed")
                                .font(.system(size: 12, weight: .light, design: .rounded))
                                .foregroundColor(Color(.tertiaryLabel))
                                .fontWeight(.medium)
                            
                            // Show session start time for debugging
                            if let startTime = timeTracker.getSessionStartTime() {
                                Text("Started: \(DateFormatter.debugFormatter.string(from: startTime))")
                                    .font(.system(size: 10, weight: .light, design: .monospaced))
                                    .foregroundColor(Color(.quaternaryLabel))
                                    .padding(.top, 4)
                            }
                        }
                        
                        // Debug button (remove in production)
                        Button("Check Notification Status") {
                            notificationManager.checkStatus()
                        }
                        .font(.system(size: 10))
                        .padding(.top, 8)
                    } else {
                        // Show option to clear any lingering notifications
                        Button("Clear All Notifications") {
                            notificationManager.stopNotifications()
                        }
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    }
                }
                .padding(.bottom, 40)
            }
            .padding()
        }
        .onAppear {
            setupNotifications()
            
            // CRITICAL: Restore the actual app state from persistence
            restoreAppState()
            
            timeTracker.startTracking()
        }
        .onChange(of: doNotCareMode) { _, newValue in
            handleDoNotCareModeChange(newValue)
            timeTracker.setCareMode(newValue)
        }
        .onReceive(NotificationCenter.default.publisher(for: .userChoseToCare)) { _ in
            // Handle when user taps "I Care Now" in notification
            doNotCareMode = false
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            print("📱 App going to background - saving state")
            timeTracker.handleAppWillResignActive()
            saveAppState()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            print("📱 App became active - restoring state")
            timeTracker.handleAppDidBecomeActive()
            
            // Verify our state matches reality
            verifyNotificationState()
        }
        .alert("Notification Permission Required", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable notifications in Settings to receive continuous reminders when you don't care.")
        }
    }
    
    // CRITICAL: Restore the actual app state when app launches
    private func restoreAppState() {
        let savedMode = UserDefaults.standard.bool(forKey: "doNotCareMode")
        let hasSavedState = UserDefaults.standard.object(forKey: "doNotCareMode") != nil
        
        if hasSavedState {
            print("📱 Restoring saved state - doNotCareMode: \(savedMode)")
            doNotCareMode = savedMode
            
            // Let TimeTracker restore its state first
            timeTracker.restoreState()
            
            // Verify notifications match our restored state
            verifyNotificationState()
        } else {
            print("📱 No saved state found - starting fresh")
            doNotCareMode = false
        }
    }
    
    // Save app state when backgrounding
    private func saveAppState() {
        UserDefaults.standard.set(doNotCareMode, forKey: "doNotCareMode")
        print("📱 Saved app state - doNotCareMode: \(doNotCareMode)")
    }
    
    // Verify that our UI state matches the actual notification state
    private func verifyNotificationState() {
        notificationManager.checkPendingNotifications { hasNotifications in
            DispatchQueue.main.async {
                if hasNotifications && !self.doNotCareMode {
                    print("⚠️ STATE MISMATCH: Notifications are scheduled but UI shows OFF")
                    print("🔧 Correcting: Setting UI to match notification state")
                    self.doNotCareMode = true
                } else if !hasNotifications && self.doNotCareMode {
                    print("⚠️ STATE MISMATCH: No notifications but UI shows ON")
                    print("🔧 Correcting: Setting UI to match notification state")
                    self.doNotCareMode = false
                }
            }
        }
    }
    
    private func setupNotifications() {
        // Check current authorization status
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
    
    private func handleDoNotCareModeChange(_ newValue: Bool) {
        if newValue {
            // Do not care mode ON - start pre-scheduled notification system
            print("🔴 Do not care mode ON - Starting pre-scheduled notification system (every 60s)")
            notificationManager.startNotifications()
        } else {
            // Do not care mode OFF - stop all notifications immediately
            print("🟢 Do not care mode OFF - Stopping all pre-scheduled notifications")
            notificationManager.stopNotifications()
        }
        
        // Save the new state immediately
        saveAppState()
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
}

// Extension for debug formatting
extension DateFormatter {
    static let debugFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }()
}

#Preview {
    ContentView()
}
