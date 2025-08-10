import SwiftUI
import UserNotifications

@main
struct DoNotCareApp: App {
    
    init() {
        // Configure notification delegate on app launch
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        
        // Request critical alert permission (optional - requires special entitlement)
        // This would make notifications more likely to wake the screen
        setupNotificationCategories()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    print("📱 App going to background - saving time state")
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    print("📱 App became active - calculating background time")
                }
        }
    }
    
    private func setupNotificationCategories() {
        // Create a more prominent notification category
        let careAction = UNNotificationAction(
            identifier: "CARE_ACTION",
            title: "I Care Now",
            options: [.foreground]
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "Keep Not Caring",
            options: []
        )
        
        let careCategory = UNNotificationCategory(
            identifier: "DO_NOT_CARE_REMINDER",
            actions: [careAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction, .allowInCarPlay]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([careCategory])
        print("✅ Enhanced notification categories set up")
    }
}

// Enhanced notification delegate for better screen wake behavior
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    // This makes notifications appear as banners even when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("📱 Notification will present: \(notification.request.identifier)")
        
        // Show banner, play sound, and update badge even in foreground
        // This combination should wake the screen
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification taps and actions
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("📱 User interacted with notification: \(response.notification.request.identifier)")
        print("📱 Action identifier: \(response.actionIdentifier)")
        
        // Handle different actions
        switch response.actionIdentifier {
        case "CARE_ACTION":
            print("💚 User chose to care - could toggle app state here")
            // You could send a notification to ContentView to turn off "do not care" mode
            NotificationCenter.default.post(name: .userChoseToCare, object: nil)
            
        case "DISMISS_ACTION":
            print("💭 User chose to keep not caring")
            
        case UNNotificationDefaultActionIdentifier:
            print("📱 User tapped notification (default action)")
            
        default:
            print("📱 Unknown action: \(response.actionIdentifier)")
        }
        
        // Reset badge count when user interacts
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
