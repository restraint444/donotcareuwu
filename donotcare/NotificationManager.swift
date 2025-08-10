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
        
        // Send immediate notification when turned on
        sendImmediateNotification()
        
        // Pre-schedule all notifications at once (this works even when app is backgrounded)
        scheduleAllNotifications()
        
        print("✅ Sent immediate notification + pre-scheduled \(maxNotifications) notifications")
    }
    
    private func sendImmediateNotification() {
        let content = UNMutableNotificationContent()
        content.title = "💭 Do Not Care"
        content.body = "Do not care mode activated - notifications every 60 seconds"
        content.sound = UNNotificationSound.default
        content.badge = NSNumber(value: 1)
        content.categoryIdentifier = "WAKE_REMINDER"
        
        content.userInfo = [
            "wake_screen": true,
            "priority": "high",
            "sequence": 0,
            "notification_type": "immediate_activation"
        ]
        
        // Send immediately (0.1 second delay to ensure it fires)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "immediate_notification",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule immediate notification: \(error.localizedDescription)")
            } else {
                print("✅ Immediate notification scheduled")
            }
        }
    }
    
    private func scheduleAllNotifications() {
        guard isActive else { return }
        
        // Schedule notifications starting from 60 seconds, then every 60 seconds after that
        for i in 0..<maxNotifications {
            let delay = Double(i + 1) * notificationInterval // Start at 60s, then 120s, 180s, etc.
            let identifier = "wake_notification_\(i)"
            
            scheduleNotification(delay: delay, identifier: identifier, sequence: i + 1)
        }
        
        print("✅ Scheduled \(maxNotifications) notifications:")
        print("   - Immediate notification: now")
        print("   - First scheduled notification: 60 seconds from now")
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
    
    // CRITICAL: New method to check if notifications are actually scheduled
    func checkPendingNotifications(completion: @escaping (Bool) -> Void) {
        notificationCenter.getPendingNotificationRequests { requests in
            let hasNotifications = requests.count > 0
            print("📊 Pending notifications check: \(requests.count) notifications found")
            completion(hasNotifications)
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
}

// Extension for time formatting
extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }()
}
