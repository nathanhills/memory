import Foundation
import SwiftData
import SwiftUI

enum PreviewSupport {
    @MainActor
    static func container(onboarded: Bool = true) -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: ContactNote.self, ReminderRecord.self, AppSettings.self,
            configurations: configuration
        )
        let context = container.mainContext
        context.insert(AppSettings(notificationsEnabled: true, hasCompletedOnboarding: onboarded))

        let calendar = Calendar.current
        let today = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now
        let inThree = calendar.date(byAdding: .day, value: 3, to: today) ?? today
        let inFive = calendar.date(byAdding: .day, value: 5, to: today) ?? today

        context.insert(
            ReminderRecord(
                kind: .birthday,
                dueAt: today,
                title: "Jordan Lee's birthday",
                body: "Wish Jordan a happy birthday.",
                contactIdentifier: Person.previewJordan.id,
                dedupeKey: "preview-birthday"
            )
        )
        context.insert(
            ReminderRecord(
                kind: .preEvent,
                dueAt: inThree,
                title: "Before lunch with Sam Rivera",
                body: "• Catch up on the house search.\n• Ask about the new job.",
                contactIdentifier: Person.previewSam.id,
                dedupeKey: "preview-event"
            )
        )
        context.insert(
            ReminderRecord(
                kind: .noteDue,
                dueAt: inFive,
                title: "Remember for Alex Chen",
                body: "Send the photos from last weekend.",
                contactIdentifier: Person.previewAlex.id,
                dedupeKey: "preview-note"
            )
        )
        context.insert(
            ContactNote(
                contactIdentifier: Person.previewAlex.id,
                body: "Send the photos from last weekend.",
                remindAt: inFive
            )
        )
        context.insert(
            ContactNote(
                contactIdentifier: Person.previewSam.id,
                body: "Catch up on the house search."
            )
        )
        return container
    }

    @MainActor
    static func store() -> MemoryStore {
        let store = MemoryStore()
        store.people = Person.previews
        store.events = [
            CalendarOccurrence(
                id: "preview-lunch",
                title: "Lunch",
                start: Calendar.current.date(byAdding: .day, value: 3, to: .now) ?? .now,
                end: nil,
                allDay: false,
                attendeeEmails: ["sam@example.com"],
                attendeeNames: ["Sam Rivera"],
                location: "Town"
            )
        ]
        return store
    }
}
