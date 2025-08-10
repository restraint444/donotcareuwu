import Foundation
import UserNotifications
import UIKit

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
        print("🔔 Starting background notifications...")
        stopNotifications() // Clear any existing notifications first
        
        // Schedule 64 notifications (iOS limit)
        let maxNotifications = 64
        let intervalSeconds: TimeInterval = 60.0 // 1 minute
        let baseDelay: TimeInterval = 5.0 // Start first notification after 5 seconds
        
        for i in 0..<maxNotifications {
            let identifier = "\(notificationIdentifierPrefix)\(i)"
            
            let content = UNMutableNotificationContent()
            content.title = "Do Not Care"
            content.body = "Remember: you don't care right now"
            content.sound = .default
            content.badge = NSNumber(value: 1)
            content.categoryIdentifier = "CARE_REMINDER"
            
            // Calculate fire time with proper minimum delay
            let timeInterval = baseDelay + (intervalSeconds * Double(i))
            let fireDate = Date().addingTimeInterval(timeInterval)
            
            // Ensure we're scheduling for the future
            guard fireDate > Date() else {
                print("⚠️ Skipping notification \(i) - fire date is in the past")
                continue
            }
            
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
                    print("✅ Successfully scheduled \(maxNotifications) notifications starting in \(baseDelay) seconds")
                }
            }
        }
        
        // Send immediate notification
        sendImmediateNotification()
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
        resetBadgeCount()
    }
    
    private func resetBadgeCount() {
        if #available(iOS 17.0, *) {
            notificationCenter.setBadgeCount(0) { error in
                if let error = error {
                    print("❌ Failed to reset badge count: \(error.localizedDescription)")
                } else {
                    print("✅ Badge count reset to 0")
                }
            }
        } else {
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = 0
                print("✅ Badge count reset to 0 (legacy)")
            }
        }
    }
    
    private func setBadgeCount(_ count: Int) {
        if #available(iOS 17.0, *) {
            notificationCenter.setBadgeCount(count) { error in
                if let error = error {
                    print("❌ Failed to set badge count to \(count): \(error.localizedDescription)")
                } else {
                    print("✅ Badge count set to \(count)")
                }
            }
        } else {
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = count
                print("✅ Badge count set to \(count) (legacy)")
            }
        }
    }
    
    private func sendImmediateNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Do Not Care - Started"
        content.body = "Notifications are now active"
        content.sound = .default
        content.badge = NSNumber(value: 1)
        content.categoryIdentifier = "CARE_REMINDER"
        
        // Use a small delay trigger instead of nil to avoid timing issues
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "immediate_notification",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to send immediate notification: \(error.localizedDescription)")
            } else {
                print("✅ Immediate notification scheduled for 1 second")
                self.setBadgeCount(1)
            }
        }
    }
}
