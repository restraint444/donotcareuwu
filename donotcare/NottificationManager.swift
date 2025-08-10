import Foundation
import UserNotifications
import UIKit

class NotificationManager: ObservableObject {
    private let notificationCenter = UNUserNotificationCenter.current()
    private let notificationIdentifierPrefix = "do_not_care_notification_"
    
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
        print("🔔 Starting 'do not care' notifications - 1 hour schedule...")
        stopNotifications() // Clear any existing notifications first
        
        let totalNotifications = 180 // 3 hours worth
        let intervalSeconds: TimeInterval = 20.0 // Every 20 seconds
        let baseDelay: TimeInterval = 5.0 // Start after 5 seconds
        
        for i in 0..<totalNotifications {
            let identifier = "\(notificationIdentifierPrefix)\(i)"
            
            let content = UNMutableNotificationContent()
            content.title = "Do Not Care"
            content.body = getRandomNotificationMessage()
            content.sound = .default
            content.badge = NSNumber(value: 1)
            content.categoryIdentifier = "DO_NOT_CARE_REMINDER"
            
            let timeInterval = baseDelay + (intervalSeconds * Double(i))
            let safeTimeInterval = max(timeInterval, 1.0)
            
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: safeTimeInterval,
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
                } else {
                    if i < 3 {
                        let minutes = Int(safeTimeInterval / 60)
                        let seconds = Int(safeTimeInterval.truncatingRemainder(dividingBy: 60))
                        print("✅ Scheduled 'do not care' notification \(i) for \(minutes)m \(seconds)s from now")
                    }
                    if i == totalNotifications - 1 {
                        let totalDurationMinutes = Double(totalNotifications) * intervalSeconds / 60.0
                        print("✅ All \(totalNotifications) 'do not care' notifications scheduled successfully")
                        print("📊 Total duration: \(String(format: "%.0f", totalDurationMinutes)) minutes (1 hour)")
                        print("📊 Interval: Every \(Int(intervalSeconds)) seconds")
                        print("📊 Last notification will fire in: \(String(format: "%.1f", totalDurationMinutes)) minutes")
                    }
                }
            }
        }
        
        // Send immediate notification
        sendImmediateNotification()
        
        // Debug function to check scheduled notifications
        debugScheduledNotifications()
    }
    
    func stopNotifications() {
        print("🛑 Stopping all 'do not care' notifications...")
        
        // Remove all pending notifications with our identifier prefix
        notificationCenter.getPendingNotificationRequests { requests in
            let identifiersToRemove = requests
                .filter { $0.identifier.hasPrefix(self.notificationIdentifierPrefix) }
                .map { $0.identifier }
            
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
            print("🗑️ Removed \(identifiersToRemove.count) pending 'do not care' notifications")
        }
        
        // Remove delivered notifications from notification center
        notificationCenter.removeAllDeliveredNotifications()
        
        // Reset badge count
        resetBadgeCount()
    }
    
    private func debugScheduledNotifications() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.notificationCenter.getPendingNotificationRequests { requests in
                let careNotifications = requests.filter { $0.identifier.hasPrefix(self.notificationIdentifierPrefix) }
                print("🔍 DEBUG: \(careNotifications.count) 'do not care' notifications currently scheduled")
                
                // Print first few and last few scheduled times for verification
                let sortedNotifications = careNotifications.sorted { req1, req2 in
                    guard let trigger1 = req1.trigger as? UNTimeIntervalNotificationTrigger,
                          let trigger2 = req2.trigger as? UNTimeIntervalNotificationTrigger else {
                        return false
                    }
                    return trigger1.timeInterval < trigger2.timeInterval
                }
                
                print("📅 First 3 notifications:")
                for (index, request) in sortedNotifications.prefix(3).enumerated() {
                    if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger {
                        let fireDate = Date().addingTimeInterval(trigger.timeInterval)
                        let formatter = DateFormatter()
                        formatter.timeStyle = .medium
                        print("   \(index + 1): \(formatter.string(from: fireDate))")
                    }
                }
                
                if sortedNotifications.count > 3 {
                    print("📅 Last 3 notifications:")
                    for (index, request) in sortedNotifications.suffix(3).enumerated() {
                        if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger {
                            let fireDate = Date().addingTimeInterval(trigger.timeInterval)
                            let formatter = DateFormatter()
                            formatter.timeStyle = .medium
                            let notificationNumber = sortedNotifications.count - 2 + index
                            print("   \(notificationNumber): \(formatter.string(from: fireDate))")
                        }
                    }
                }
            }
        }
    }
    
    private func getRandomNotificationMessage() -> String {
        let messages = [
            "Remember: you don't care right now",
            "Keep not caring",
            "Stay in your don't care zone",
            "Don't care mode: active",
            "You're doing great at not caring",
            "Caring is optional",
            "Not caring is your superpower",
            "Embrace the art of not caring",
            "Your energy is precious - don't waste it",
            "Not your problem, not your concern",
            "Let it go, you don't care",
            "Not your circus, not your monkeys",
            "Your peace matters more",
            "Choose your battles - this isn't one",
            "Save your energy for what matters"
        ]
        return messages.randomElement() ?? "Remember: you don't care right now"
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
        content.body = "'Do not care' notifications every 20 seconds for 1 hour are now active"
        content.sound = .default
        content.badge = NSNumber(value: 1)
        content.categoryIdentifier = "DO_NOT_CARE_REMINDER"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2.0, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "immediate_do_not_care_notification",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to send immediate 'do not care' notification: \(error.localizedDescription)")
            } else {
                print("✅ Immediate 'do not care' notification scheduled for 2 seconds")
                print("🎯 Next 180 notifications will fire every 20 seconds for 1 hour")
                self.setBadgeCount(1)
            }
        }
    }
}
