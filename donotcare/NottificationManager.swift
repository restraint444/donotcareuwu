import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    private let notificationCenter = UNUserNotificationCenter.current()
    private let notificationIdentifierPrefix = "care_notification_"
    
    func requestPermission() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("✅ Notification permission granted")
                } else {
                    print("❌ Notification permission denied")
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func startNotifications() {
        print("🔔 Starting background notifications (every 60 seconds)...")
        stopNotifications() // Clear any existing notifications first
        
        // Schedule 64 notifications (iOS limit) starting from now
        // This gives us ~1 hour of notifications every minute
        let maxNotifications = 64
        let intervalSeconds = 60.0 // 1 minute
        
        for i in 0..<maxNotifications {
            let identifier = "\(notificationIdentifierPrefix)\(i)"
            
            let content = UNMutableNotificationContent()
            content.title = "Do Not Care"
            content.body = "Remember: you don't care right now"
            content.sound = .default
            content.badge = NSNumber(value: 1)
            content.categoryIdentifier = "CARE_REMINDER"
            
            // CRITICAL: Use absolute date trigger, not time interval
            let fireDate = Date().addingTimeInterval(intervalSeconds * Double(i + 1))
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fireDate),
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            
            notificationCenter.add(request) { error in
                if let error = error {
                    print("❌ Failed to schedule notification \(i): \(error.localizedDescription)")
                } else if i == 0 {
                    print("✅ Successfully scheduled \(maxNotifications) notifications starting at \(fireDate)")
                    print("🕐 First notification will fire in 60 seconds")
                }
            }
        }
        
        // Send immediate test notification
        sendImmediateTestNotification()
    }
    
    func stopNotifications() {
        print("🛑 Stopping all notifications...")
        
        // Remove all pending notifications with our identifier prefix
        notificationCenter.getPendingNotificationRequests { requests in
            let identifiersToRemove = requests
                .filter { $0.identifier.hasPrefix(self.notificationIdentifierPrefix) }
                .map { $0.identifier }
            
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
            print("🗑️ Removed \(identifiersToRemove.count) pending notifications")
        }
        
        // Remove delivered notifications from notification center
        notificationCenter.removeAllDeliveredNotifications()
        
        // Reset badge count
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
    
    private func sendImmediateTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Do Not Care - Started"
        content.body = "Notifications are now active. First reminder in 60 seconds."
        content.sound = .default
        content.badge = NSNumber(value: 1)
        content.categoryIdentifier = "CARE_REMINDER"
        
        let request = UNNotificationRequest(
            identifier: "immediate_test_notification",
            content: content,
            trigger: nil // Send immediately
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to send immediate notification: \(error.localizedDescription)")
            } else {
                print("✅ Immediate test notification sent")
            }
        }
    }
    
    // Debug function to check pending notifications
    func checkPendingNotifications() {
        notificationCenter.getPendingNotificationRequests { requests in
            let careNotifications = requests.filter { $0.identifier.hasPrefix(self.notificationIdentifierPrefix) }
            print("📋 Pending care notifications: \(careNotifications.count)")
            
            for request in careNotifications.prefix(10) { // Show first 10
                if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                    let components = trigger.dateComponents
                    if let hour = components.hour, let minute = components.minute, let second = components.second {
                        print("  - \(request.identifier): \(hour):\(String(format: "%02d", minute)):\(String(format: "%02d", second))")
                    }
                }
            }
            
            if careNotifications.isEmpty {
                print("⚠️ NO NOTIFICATIONS SCHEDULED!")
            } else {
                print("✅ Notifications properly scheduled for background delivery")
            }
        }
    }
    
    // Check notification authorization status
    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                print("🔐 Notification Authorization Status:")
                print("  - Status: \(settings.authorizationStatus.rawValue)")
                print("  - Alert Setting: \(settings.alertSetting.rawValue)")
                print("  - Badge Setting: \(settings.badgeSetting.rawValue)")
                print("  - Sound Setting: \(settings.soundSetting.rawValue)")
                
                if settings.authorizationStatus != .authorized {
                    print("⚠️ Notifications not fully authorized!")
                }
            }
        }
    }
}
