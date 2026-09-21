import Foundation
import UserNotifications

enum NotificationService {
    static func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    static func reschedule(reminders: [ReminderRecord], enabled: Bool) async {
        let center = UNUserNotificationCenter.current()
        await center.removeAllPendingNotificationRequests()
        guard enabled else { return }

        let upcoming = reminders.filter { $0.status == .pending && $0.dueAt > .now }.prefix(64)
        for reminder in upcoming {
            let content = UNMutableNotificationContent()
            content.title = reminder.kind.label
            content.body = reminder.title
            content.sound = .default

            let interval = reminder.dueAt.timeIntervalSinceNow
            guard interval > 1 else { continue }
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            let request = UNNotificationRequest(
                identifier: reminder.dedupeKey,
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }
}
