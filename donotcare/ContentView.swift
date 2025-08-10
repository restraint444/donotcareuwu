import SwiftUI
import UserNotifications

struct ContentView: View {
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var timeTracker = TimeTracker()
    @State private var doNotCareMode = false // false = caring mode (OFF), true = do not care mode (ON)
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
                
                // Time elapsed display - RESETS TO 0 on mode change
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
                
                // Main control - Reduced font size for single line
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
                        }
                        
                        // Debug button (remove in production)
                        Button("Check Notification Status") {
                            notificationManager.checkStatus()
                        }
                        .font(.system(size: 10))
                        .padding(.top, 8)
                    }
                }
                .padding(.bottom, 40)
            }
            .padding()
        }
        .onAppear {
            setupNotifications()
            timeTracker.startTracking()
        }
        .onChange(of: doNotCareMode) { _, newValue in
            handleDoNotCareModeChange(newValue)
            timeTracker.setCareMode(newValue) // This now resets the timer to 0
        }
        .onReceive(NotificationCenter.default.publisher(for: .userChoseToCare)) { _ in
            // Handle when user taps "I Care Now" in notification
            doNotCareMode = false
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            print("📱 App going to background - notification system will continue independently")
            timeTracker.handleAppWillResignActive()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            print("📱 App became active - checking notification system status")
            timeTracker.handleAppDidBecomeActive()
            
            // Check notification status when app becomes active
            if doNotCareMode {
                notificationManager.checkStatus()
            }
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

#Preview {
    ContentView()
}
