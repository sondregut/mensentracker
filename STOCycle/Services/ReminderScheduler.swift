import Foundation
import UserNotifications

enum ReminderScheduler {
    private static let identifier = "sto-cycle-daily-check-in"

    static func update(enabled: Bool, time: Date) async -> Bool {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard enabled else { return true }

#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-uiTestDenyReminder") {
            return false
        }
#endif

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else { return false }

            let content = UNMutableNotificationContent()
            content.title = "A gentle check-in"
            content.body = "How are you feeling today? A quick log helps reveal your patterns."
            content.sound = .default

            let components = Calendar.current.dateComponents([.hour, .minute], from: time)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            try await center.add(request)
            return true
        } catch {
            return false
        }
    }
}
