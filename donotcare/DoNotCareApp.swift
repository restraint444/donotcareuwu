import SwiftUI
import UserNotifications

@main
struct DoNotCareApp: App {
    
    init() {
        // Configure notification delegate on app launch
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    // App is going to background - save current state
                    print("📱 App going to background - saving time state")
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // App became active - this will trigger TimeTracker's calculateTimeFromBackground
                    print("📱 App became active - calculating background time")
                }
        }
    }
}

// Notification delegate to handle foreground notifications
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    // This makes notifications appear as banners even when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner, play sound, and update badge even in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification taps
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("📱 User tapped 'do not care' notification: \(response.notification.request.identifier)")
        
        // Reset badge count when user interacts with notification
        resetBadgeCountOnInteraction()
        
        completionHandler()
    }
    
    private func resetBadgeCountOnInteraction() {
        if #available(iOS 17.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(0) { error in
                if let error = error {
                    print("❌ Failed to reset badge count on interaction: \(error.localizedDescription)")
                } else {
                    print("✅ Badge count reset on user interaction")
                }
            }
        } else {
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = 0
                print("✅ Badge count reset on user interaction (legacy)")
            }
        }
    }
}
