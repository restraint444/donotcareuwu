import SwiftUI
import UserNotifications

@main
struct DoNotCareApp: App {
    
    init() {
        // Configure notification delegate on app launch
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        
        // Setup enhanced notification categories for both modes
        setupNotificationCategories()
        
        print("🚀 Do Not Care app launched - dual notification system ready")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
    }
    
    private func setupNotificationCategories() {
        // Create actions for Do Not Care mode
        let careAction = UNNotificationAction(
            identifier: "CARE_ACTION",
            title: "I Care Now",
            options: [.foreground]
        )
        
        let dismissDoNotCareAction = UNNotificationAction(
            identifier: "DISMISS_DO_NOT_CARE",
            title: "Keep Not Caring",
            options: []
        )
        
        // Create actions for Focus mode
        let stopFocusAction = UNNotificationAction(
            identifier: "STOP_FOCUS_ACTION",
            title: "Stop Focusing",
            options: [.foreground]
        )
        
        let continueFocusAction = UNNotificationAction(
            identifier: "CONTINUE_FOCUS",
            title: "Stay Focused",
            options: []
        )
        
        // Create categories
        let doNotCareCategory = UNNotificationCategory(
            identifier: "DO_NOT_CARE_REMINDER",
            actions: [careAction, dismissDoNotCareAction],
            intentIdentifiers: [],
            options: [.customDismissAction, .allowInCarPlay]
        )
        
        let focusCategory = UNNotificationCategory(
            identifier: "FOCUS_REMINDER",
            actions: [stopFocusAction, continueFocusAction],
            intentIdentifiers: [],
            options: [.customDismissAction, .allowInCarPlay]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([doNotCareCategory, focusCategory])
        print("✅ Enhanced notification categories configured for both modes")
    }
}

// Enhanced notification delegate optimized for dual-mode behavior
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    // Critical: This makes notifications appear even when app is in foreground
    // AND ensures maximum wake behavior when app is backgrounded
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let mode = notification.request.content.userInfo["mode"] as? String ?? "unknown"
        let type = notification.request.content.userInfo["type"] as? String ?? "unknown"
        print("📱 Notification will present - Mode: \(mode), Type: \(type)")
        
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
        let mode = response.notification.request.content.userInfo["mode"] as? String ?? "unknown"
        print("📱 User interacted with \(mode) notification: \(response.notification.request.identifier)")
        print("📱 Action identifier: \(response.actionIdentifier)")
        
        // Handle different actions
        switch response.actionIdentifier {
        case "CARE_ACTION":
            print("💚 User chose to care - toggling app state")
            NotificationCenter.default.post(name: .userChoseToCare, object: nil)
            
        case "DISMISS_DO_NOT_CARE":
            print("💭 User chose to keep not caring")
            
        case "STOP_FOCUS_ACTION":
            print("🛑 User chose to stop focusing - toggling app state")
            NotificationCenter.default.post(name: .userChoseToCare, object: nil)
            
        case "CONTINUE_FOCUS":
            print("🎯 User chose to continue focusing")
            
        case UNNotificationDefaultActionIdentifier:
            print("📱 User tapped notification body - opening app")
            // Default tap behavior - app opens normally
            
        default:
            print("📱 Unknown action: \(response.actionIdentifier)")
        }
        
        completionHandler()
    }
}

// Extension for custom notification names
extension Notification.Name {
    static let userChoseToCare = Notification.Name("userChoseToCare")
}
