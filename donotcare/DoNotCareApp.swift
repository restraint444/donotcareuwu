import SwiftUI
import UserNotifications

@main
struct DoNotCareApp: App {
    
    init() {
        // Configure notification delegate on app launch
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        
        // Setup enhanced notification categories for better wake behavior
        setupNotificationCategories()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
    }
    
    private func setupNotificationCategories() {
        // Create actions that encourage user interaction
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
        
        // Create category with available options for maximum wake behavior
        let wakeCategory = UNNotificationCategory(
            identifier: "WAKE_REMINDER",
            actions: [careAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction, .allowInCarPlay]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([wakeCategory])
        print("✅ Enhanced wake notification categories configured")
    }
}

// Enhanced notification delegate optimized for screen wake behavior
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    // Critical: This makes notifications appear even when app is in foreground
    // AND ensures maximum wake behavior when app is backgrounded
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("📱 Notification will present: \(notification.request.identifier)")
        
        // Check if this is a maintenance notification
        if let maintenance = notification.request.content.userInfo["maintenance"] as? Bool, maintenance {
            print("🔧 Maintenance notification received - rescheduling more notifications")
            // Get the notification manager and reschedule
            DispatchQueue.main.async {
                // You'll need to access your notification manager instance here
                // For now, we'll handle this in the ContentView
                NotificationCenter.default.post(name: .maintenanceNotificationReceived, object: nil)
            }
        }
        
        // Use all available presentation options for maximum wake effect
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge, .list])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    // Handle notification taps and actions
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("📱 User interacted with notification: \(response.notification.request.identifier)")
        print("📱 Action identifier: \(response.actionIdentifier)")
        
        // Check if this is a maintenance notification
        if let maintenance = response.notification.request.content.userInfo["maintenance"] as? Bool, maintenance {
            print("🔧 Maintenance notification tapped - rescheduling more notifications")
            NotificationCenter.default.post(name: .maintenanceNotificationReceived, object: nil)
        }
        
        // Handle different actions
        switch response.actionIdentifier {
        case "CARE_ACTION":
            print("💚 User chose to care - toggling app state")
            NotificationCenter.default.post(name: .userChoseToCare, object: nil)
            
        case "DISMISS_ACTION":
            print("💭 User chose to keep not caring")
            
        case UNNotificationDefaultActionIdentifier:
            print("📱 User tapped notification (default action)")
            
        default:
            print("📱 Unknown action: \(response.actionIdentifier)")
        }
        
        completionHandler()
    }
}

// Extension for notification names
extension Notification.Name {
    static let userChoseToCare = Notification.Name("userChoseToCare")
    static let maintenanceNotificationReceived = Notification.Name("maintenanceNotificationReceived")
}
