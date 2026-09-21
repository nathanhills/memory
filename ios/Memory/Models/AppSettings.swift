import Foundation
import SwiftData

@Model
final class AppSettings {
    var eventReminderHours: Int
    var notificationsEnabled: Bool
    var lastContactsSync: Date?
    var lastCalendarSync: Date?
    var lastError: String?
    var hasCompletedOnboarding: Bool

    init(
        eventReminderHours: Int = 24,
        notificationsEnabled: Bool = true,
        lastContactsSync: Date? = nil,
        lastCalendarSync: Date? = nil,
        lastError: String? = nil,
        hasCompletedOnboarding: Bool = false
    ) {
        self.eventReminderHours = eventReminderHours
        self.notificationsEnabled = notificationsEnabled
        self.lastContactsSync = lastContactsSync
        self.lastCalendarSync = lastCalendarSync
        self.lastError = lastError
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}
