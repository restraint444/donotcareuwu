import SwiftUI
import UserNotifications

struct ContentView: View {
    @StateObject private var notificationManager = NotificationManager()
    @State private var careMode = true // true = caring (ON), false = not caring (OFF)
    @State private var startTime = Date()
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
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
                
                // Time elapsed display
                VStack(spacing: 8) {
                    Text(formatElapsedTime(elapsedTime))
                        .font(.system(size: 48, weight: .ultraLight, design: .rounded))
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                    
                    Text(careMode ? "time caring" : "time not caring")
                        .font(.system(size: 16, weight: .light, design: .rounded))
                        .foregroundColor(Color(.tertiaryLabel))
                }
                .padding(.bottom, 20)
                
                // Main control
                HStack(spacing: 16) {
                    Text("care")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Toggle("", isOn: $careMode)
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
                
                // Simple status
                Text(careMode ? "notifications paused" : "notifications active")
                    .font(.system(size: 14, weight: .light, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 40)
            }
            .padding()
        }
        .onAppear {
            setupNotifications()
            startTimer()
        }
        .onChange(of: careMode) { _, newValue in
            handleCareModeChange(newValue)
            resetTimer()
        }
        .alert("Notification Permission Required", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable notifications in Settings to receive reminders when you don't care.")
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
        
        // Set up notification categories
        setupNotificationCategories()
    }
    
    private func setupNotificationCategories() {
        let careCategory = UNNotificationCategory(
            identifier: "CARE_REMINDER",
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([careCategory])
    }
    
    private func handleCareModeChange(_ newValue: Bool) {
        if newValue {
            // Caring mode ON - stop notifications
            print("🟢 Care mode ON - Stopping all background notifications")
            notificationManager.stopNotifications()
        } else {
            // Caring mode OFF - start notifications
            print("🔴 Care mode OFF - Starting background notifications")
            notificationManager.startNotifications()
        }
    }
    
    private func startTimer() {
        startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            elapsedTime = Date().timeIntervalSince(startTime)
        }
    }
    
    private func resetTimer() {
        startTime = Date()
        elapsedTime = 0
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
