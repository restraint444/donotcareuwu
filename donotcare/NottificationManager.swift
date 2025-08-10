import Foundation
import UserNotifications
import UIKit

class NotificationManager: ObservableObject {
    private let notificationCenter = UNUserNotificationCenter.current()
    private let notificationIdentifier = "do_not_care_notification"
    private var notificationTimer: Timer?
    
    func requestPermission() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert]) { granted, error in
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
        print("🔔 Starting 'do not care' notifications every 20 seconds...")
        stopNotifications() // Clear any existing notifications first
        
        // Send immediate notification to confirm
        sendImmediateNotification()
        
        // Start timer for continuous notifications every 20 seconds
        notificationTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: true) { _ in
            self.sendWakeUpNotification()
        }
        
        print("✅ Notification timer started - will fire every 20 seconds")
    }
    
    func stopNotifications() {
        print("🛑 Stopping all 'do not care' notifications...")
        
        // Stop the timer
        notificationTimer?.invalidate()
        notificationTimer = nil
        
        // Remove all scheduled notifications
        notificationCenter.removeAllPendingNotificationRequests()
        
        // Remove delivered notifications from notification center
        notificationCenter.removeAllDeliveredNotifications()
        
        // Reset badge count
        resetBadgeCount()
        
        print("🗑️ All notifications stopped and cleared")
    }
    
    private func sendImmediateNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🚀 Do Not Care - Started"
        content.body = "Notifications every 20 seconds are now active. Your screen will wake with each reminder."
        
        // Enhanced settings for maximum wake behavior
        content.sound = .default
        content.badge = NSNumber(value: 1)
        content.categoryIdentifier = "DO_NOT_CARE_REMINDER"
        
        // Critical alert settings for better screen wake
        content.interruptionLevel = .critical
        
        // Add userInfo for enhanced wake behavior
        content.userInfo = [
            "importance": "critical",
            "wake_screen": true,
            "immediate": true
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2.0, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "immediate_\(notificationIdentifier)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to send immediate notification: \(error.localizedDescription)")
            } else {
                print("✅ Immediate notification scheduled for 2 seconds")
                self.setBadgeCount(1)
            }
        }
    }
    
    private func sendWakeUpNotification() {
        let content = UNMutableNotificationContent()
        content.title = "💭 Do Not Care"
        content.body = getRandomNotificationMessage()
        
        // Maximum wake settings
        content.sound = .default
        content.badge = NSNumber(value: 1)
        content.categoryIdentifier = "DO_NOT_CARE_REMINDER"
        content.interruptionLevel = .critical
        
        // Add userInfo to make notification more "important"
        content.userInfo = [
            "importance": "critical",
            "wake_screen": true,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // Use immediate trigger since we're using Timer for scheduling
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "\(notificationIdentifier)_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to send wake notification: \(error.localizedDescription)")
            } else {
                print("✅ Wake notification sent at \(Date())")
            }
        }
    }
    
    private func getRandomNotificationMessage() -> String {
        let messages = [
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
            "Your peace matters more than anything 🕊️",
            "Choose your battles - this isn't one ⚔️",
            "Save your energy for what truly matters ⭐"
        ]
        return messages.randomElement() ?? "Remember: you don't care right now 💭"
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
}
