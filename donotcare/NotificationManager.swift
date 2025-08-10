import Foundation
import UserNotifications
import UIKit

class NotificationManager: ObservableObject {
    private let notificationCenter = UNUserNotificationCenter.current()
    private var notificationTimer: Timer?
    private var isActive = false
    
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
        print("🔔 Starting notification loop - IMMEDIATE notification + timer every 60s")
        
        // Clear any existing notifications
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
        
        isActive = true
        
        // Send notification RIGHT NOW
        sendImmediateNotification()
        
        // Start timer that fires every 60 seconds
        notificationTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            self.sendNotification()
        }
        
        print("✅ Immediate notification sent + 60s timer started")
    }
    
    private func sendImmediateNotification() {
        let content = UNMutableNotificationContent()
        content.title = "💭 Do Not Care"
        content.body = "Focus reminders activated - you don't care now"
        content.sound = UNNotificationSound.default
        content.badge = NSNumber(value: 1)
        content.categoryIdentifier = "WAKE_REMINDER"
        
        content.userInfo = [
            "wake_screen": true,
            "priority": "high"
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "immediate_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to send immediate notification: \(error)")
            } else {
                print("✅ IMMEDIATE notification sent")
            }
        }
    }
    
    private func sendNotification() {
        guard isActive else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "💭 Do Not Care"
        content.body = getRandomWakeMessage()
        content.sound = UNNotificationSound.default
        content.badge = NSNumber(value: 1)
        content.categoryIdentifier = "WAKE_REMINDER"
        
        content.userInfo = [
            "wake_screen": true,
            "priority": "high"
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "timer_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to send timer notification: \(error)")
            } else {
                print("✅ Timer notification sent")
            }
        }
    }
    
    func stopNotifications() {
        print("🛑 Stopping notification loop")
        isActive = false
        
        // Stop the timer
        notificationTimer?.invalidate()
        notificationTimer = nil
        
        // Clear all notifications
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
        resetBadgeCount()
        
        print("✅ Notification loop stopped")
    }
    
    func checkPendingNotifications(completion: @escaping (Bool) -> Void) {
        notificationCenter.getPendingNotificationRequests { requests in
            let hasNotifications = requests.count > 0
            print("📊 Pending notifications: \(requests.count)")
            completion(hasNotifications)
        }
    }
    
    private func getRandomWakeMessage() -> String {
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
            "Your peace matters more 🕊️",
            "Choose your battles - this isn't one ⚔️",
            "Save your energy for what matters 💫"
        ]
        return messages.randomElement() ?? "Remember: you don't care right now 💭"
    }
    
    private func resetBadgeCount() {
        if #available(iOS 17.0, *) {
            notificationCenter.setBadgeCount(0) { error in
                if let error = error {
                    print("❌ Failed to reset badge: \(error)")
                }
            }
        } else {
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
        }
    }
}
