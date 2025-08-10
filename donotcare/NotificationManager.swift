import Foundation
import UserNotifications
import UIKit

class NotificationManager: ObservableObject {
    private let notificationCenter = UNUserNotificationCenter.current()
    private var isActive = false
    private let maxNotifications = 64 // iOS limit for pending notifications
    private let notificationInterval: TimeInterval = 60.0 // 60 seconds
    
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
        print("🔔 Starting continuous notification system - scheduling \(maxNotifications) notifications")
        stopNotifications() // Clear any existing notifications
        isActive = true
        
        // Pre-schedule all notifications at once (this works even when app is backgrounded)
        scheduleAllNotifications()
        
        print("✅ Pre-scheduled \(maxNotifications) notifications - system will work when app is closed")
    }
    
    private func scheduleAllNotifications() {
        guard isActive else { return }
        
        // Schedule notifications starting from 1 second, then every 60 seconds
        for i in 0..<maxNotifications {
            let delay = (i == 0) ? 1.0 : Double(i) * notificationInterval + 1.0
            let identifier = "wake_notification_\(i)"
            
            scheduleNotification(delay: delay, identifier: identifier, sequence: i + 1)
        }
        
        print("✅ Scheduled \(maxNotifications) notifications:")
        print("   - First notification: 1 second from now")
        print("   - Subsequent notifications: every \(Int(notificationInterval)) seconds")
        print("   - Last notification: \(Int(Double(maxNotifications) * notificationInterval / 60)) minutes from now")
    }
    
    private func scheduleNotification(delay: TimeInterval, identifier: String, sequence: Int) {
        let content = UNMutableNotificationContent()
        content.title = "💭 Do Not Care"
        content.body = getRandomWakeMessage()
        content.sound = UNNotificationSound.default
        content.badge = NSNumber(value: 1)
        content.categoryIdentifier = "WAKE_REMINDER"
        
        // Add userInfo for wake behavior and sequence tracking
        content.userInfo = [
            "wake_screen": true,
            "priority": "high",
            "sequence": sequence,
            "scheduled_time": Date().timeIntervalSince1970 + delay,
            "notification_type": "continuous_reminder"
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification \(sequence): \(error.localizedDescription)")
            } else {
                let fireTime = Date().addingTimeInterval(delay)
                print("✅ Scheduled notification \(sequence) for \(DateFormatter.timeFormatter.string(from: fireTime))")
            }
        }
    }
    
    func stopNotifications() {
        print("🛑 Stopping notification system")
        isActive = false
        
        // Remove all pending notifications
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
        
        // Reset badge count
        resetBadgeCount()
        
        // Check how many were actually removed
        notificationCenter.getPendingNotificationRequests { requests in
            print("✅ Removed all notifications - \(requests.count) notifications cleared")
        }
    }
    
    private func getRandomWakeMessage() -> String {
        let wakeMessages = [
            "Remember: you don't care right now 💭",
            "Keep not caring - you're doing great 🌟",
            "Stay in your don't care zone 🧘‍♂️",
            "Don't care mode: fully active ✨",
            "You're mastering the art of not caring 🎯",
            "Caring is optional today 🦋",
            "Not caring is your superpower 💪",
            "Embrace the freedom of not caring 🕊️",
            "Your energy is precious - save it 💎",
            "Not your problem, not your concern 🚫",
            "Let it go, you don't care 🍃",
            "Not your circus, not your monkeys 🎪",
            "Your peace matters more 🕊️",
            "Choose your battles - this isn't one ⚔️",
            "Save your energy for what matters 💫"
        ]
        return wakeMessages.randomElement() ?? "Remember: you don't care right now 💭"
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
    
    // Enhanced debug function
    func checkStatus() {
        print("📊 Notification Manager Status:")
        print("   Active: \(isActive)")
        print("   System: Pre-scheduled notification system (works when app is closed)")
        
        notificationCenter.getPendingNotificationRequests { requests in
            print("   📅 Pending notifications: \(requests.count)")
            
            // Show next 5 notifications
            let sortedRequests = requests.sorted { req1, req2 in
                guard let trigger1 = req1.trigger as? UNTimeIntervalNotificationTrigger,
                      let trigger2 = req2.trigger as? UNTimeIntervalNotificationTrigger else {
                    return false
                }
                return trigger1.timeInterval < trigger2.timeInterval
            }
            
            print("   📋 Next notifications:")
            for (index, request) in sortedRequests.prefix(5).enumerated() {
                if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger {
                    let fireDate = Date().addingTimeInterval(trigger.timeInterval)
                    let sequence = request.content.userInfo["sequence"] as? Int ?? 0
                    print("     \(index + 1). Sequence #\(sequence): \(DateFormatter.timeFormatter.string(from: fireDate))")
                }
            }
            
            if requests.count > 5 {
                print("     ... and \(requests.count - 5) more notifications")
            }
        }
        
        // Check delivered notifications
        notificationCenter.getDeliveredNotifications { delivered in
            print("   📬 Delivered notifications: \(delivered.count)")
        }
    }
    
    // This method is no longer needed since we pre-schedule everything
    func handleMaintenanceNotification() {
        guard isActive else { return }
        print("🔧 Maintenance notification received - system is pre-scheduled, no action needed")
        
        // Check if we're running low on notifications and warn user
        notificationCenter.getPendingNotificationRequests { requests in
            if requests.count < 5 {
                print("⚠️ Warning: Only \(requests.count) notifications remaining!")
                print("💡 User should toggle OFF and ON again to reschedule more notifications")
            }
        }
    }
}

// Extension for time formatting
extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }()
}
