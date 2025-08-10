import Foundation
import UserNotifications
import UIKit

class NotificationManager: ObservableObject {
    private let notificationCenter = UNUserNotificationCenter.current()
    private var currentNotificationMode: String = "none"
    
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
    
    // MARK: - Do Not Care Mode Notifications
    func startDoNotCareNotifications() {
        print("🔴 STARTING Do Not Care notifications - aborting any previous process")
        
        // STEP 1: Abort any previous notification process
        abortCurrentNotificationProcess()
        
        // STEP 2: Set new mode
        currentNotificationMode = "doNotCare"
        
        // STEP 3: Clear everything
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
        
        // STEP 4: Schedule new notification system
        scheduleDoNotCareSystem()
        
        print("✅ Do Not Care notification system activated")
    }
    
    private func scheduleDoNotCareSystem() {
        // Schedule immediate notification (1 second)
        scheduleImmediateNotification(
            identifier: "do_not_care_immediate",
            title: "💭 Do Not Care",
            body: getRandomDoNotCareMessage(),
            delay: 1.0,
            mode: "do_not_care"
        )
        
        // Schedule 60 notifications at 40-second intervals
        let cadence: TimeInterval = 40.0
        for i in 1...60 {
            let delay = cadence * Double(i) // 40s, 80s, 120s, ..., 2400s
            
            scheduleDelayedNotification(
                identifier: "do_not_care_\(i)",
                title: "💭 Do Not Care",
                body: getRandomDoNotCareMessage(),
                delay: delay,
                mode: "do_not_care",
                sequence: i
            )
        }
        
        print("✅ Do Not Care: Scheduled 61 notifications (1 immediate + 60 at 40s intervals)")
    }
    
    // MARK: - Focus Mode Notifications
    func startFocusNotifications() {
        print("🔵 STARTING Focus Mode notifications - aborting any previous process")
        
        // STEP 1: Abort any previous notification process
        abortCurrentNotificationProcess()
        
        // STEP 2: Set new mode
        currentNotificationMode = "focus"
        
        // STEP 3: Clear everything
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
        
        // STEP 4: Schedule new notification system
        scheduleFocusSystem()
        
        print("✅ Focus notification system activated")
    }
    
    private func scheduleFocusSystem() {
        // Schedule immediate notification (1 second)
        scheduleImmediateNotification(
            identifier: "focus_immediate",
            title: "🎯 Focus Mode",
            body: getRandomFocusMessage(),
            delay: 1.0,
            mode: "focus"
        )
        
        // Schedule repeating notification every 60 seconds
        scheduleRepeatingNotification(
            identifier: "focus_repeating",
            title: "🎯 Focus Mode",
            body: "Stay focused - you're in the zone! 🎯",
            interval: 60.0,
            mode: "focus"
        )
        
        print("✅ Focus: Scheduled 2 notifications (1 immediate + 1 repeating every 60s)")
    }
    
    // MARK: - Notification Scheduling Helpers
    private func scheduleImmediateNotification(identifier: String, title: String, body: String, delay: TimeInterval, mode: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        content.badge = NSNumber(value: 1)
        content.categoryIdentifier = mode == "focus" ? "FOCUS_REMINDER" : "DO_NOT_CARE_REMINDER"
        content.userInfo = [
            "wake_screen": true,
            "priority": "high",
            "type": "\(mode)_immediate",
            "mode": mode
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule immediate \(mode) notification: \(error)")
            } else {
                print("✅ \(mode.capitalized): Immediate notification scheduled for \(delay)s")
            }
        }
    }
    
    private func scheduleDelayedNotification(identifier: String, title: String, body: String, delay: TimeInterval, mode: String, sequence: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        content.badge = NSNumber(value: 1)
        content.categoryIdentifier = "DO_NOT_CARE_REMINDER"
        content.userInfo = [
            "wake_screen": true,
            "priority": "high",
            "type": "do_not_care_scheduled",
            "sequence": sequence,
            "mode": mode
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule \(mode) notification \(sequence): \(error)")
            }
        }
    }
    
    private func scheduleRepeatingNotification(identifier: String, title: String, body: String, interval: TimeInterval, mode: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        content.badge = NSNumber(value: 1)
        content.categoryIdentifier = "FOCUS_REMINDER"
        content.userInfo = [
            "wake_screen": true,
            "priority": "high",
            "type": "focus_repeating",
            "mode": mode
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule repeating \(mode) notification: \(error)")
            } else {
                print("✅ \(mode.capitalized): Repeating notification scheduled every \(interval)s")
            }
        }
    }
    
    // MARK: - Process Control
    private func abortCurrentNotificationProcess() {
        if currentNotificationMode != "none" {
            print("🛑 ABORTING previous notification process: \(currentNotificationMode)")
            
            // Cancel all pending notifications
            notificationCenter.removeAllPendingNotificationRequests()
            notificationCenter.removeAllDeliveredNotifications()
            
            // Reset state
            currentNotificationMode = "none"
            
            print("✅ Previous notification process aborted")
        }
    }
    
    // MARK: - Stop All Notifications
    func stopAllNotifications() {
        print("🛑 STOPPING all notifications")
        
        abortCurrentNotificationProcess()
        resetBadgeCount()
        
        print("✅ All notifications stopped")
    }
    
    func checkPendingNotifications(completion: @escaping (Bool) -> Void) {
        notificationCenter.getPendingNotificationRequests { requests in
            let hasNotifications = requests.count > 0
            print("📊 Pending notifications: \(requests.count) (Mode: \(self.currentNotificationMode))")
            
            if requests.count > 0 {
                let doNotCareCount = requests.filter { $0.identifier.contains("do_not_care") }.count
                let focusCount = requests.filter { $0.identifier.contains("focus") }.count
                print("📊 - Do Not Care: \(doNotCareCount)")
                print("📊 - Focus: \(focusCount)")
            }
            
            completion(hasNotifications)
        }
    }
    
    private func getRandomDoNotCareMessage() -> String {
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
    
    private func getRandomFocusMessage() -> String {
        let messages = [
            "Stay focused - you're in the zone! 🎯",
            "Deep focus mode activated 🧠",
            "You're doing amazing work 💪",
            "Keep that concentration flowing ⚡",
            "Focus is your superpower 🌟",
            "In the zone and crushing it 🔥",
            "Laser focus engaged 🎯",
            "Your attention is powerful 💎",
            "Flow state: activated ✨",
            "Focused mind, powerful results 🚀",
            "You're in your element 🌊",
            "Concentration level: expert 🎖️",
            "Focus mode: maximum efficiency 📈",
            "Your mind is sharp today 🗡️",
            "Deep work in progress 📚"
        ]
        return messages.randomElement() ?? "Stay focused - you're in the zone! 🎯"
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
