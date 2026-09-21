import Foundation
import Observation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class MemoryStore {
    var people: [Person] = []
    var events: [CalendarOccurrence] = []
    var isSyncing = false
    var lastError: String?

    let contactsService = ContactsService()
    let calendarService = CalendarService()

    func settings(in context: ModelContext) -> AppSettings {
        var descriptor = FetchDescriptor<AppSettings>()
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let created = AppSettings()
        context.insert(created)
        return created
    }

    func sync(context: ModelContext) async {
        isSyncing = true
        defer { isSyncing = false }
        lastError = nil

        var loadedPeople: [Person] = []
        var loadedEvents: [CalendarOccurrence] = []
        var errors: [String] = []

        do {
            loadedPeople = try contactsService.fetchPeople()
        } catch {
            errors.append(error.localizedDescription)
        }

        do {
            loadedEvents = try calendarService.fetchUpcomingEvents()
        } catch {
            errors.append(error.localizedDescription)
        }

        people = loadedPeople
        events = loadedEvents

        let settings = settings(in: context)
        if contactsService.isReadable { settings.lastContactsSync = .now }
        if calendarService.isReadable { settings.lastCalendarSync = .now }

        let notes = (try? context.fetch(FetchDescriptor<ContactNote>())) ?? []
        refreshReminders(context: context, notes: notes, settings: settings)

        let message = errors.isEmpty ? nil : errors.joined(separator: "\n")
        settings.lastError = message
        lastError = message
        try? context.save()
    }

    func refreshReminders(context: ModelContext, notes: [ContactNote]? = nil, settings: AppSettings? = nil) {
        let settings = settings ?? self.settings(in: context)
        let notes = notes ?? ((try? context.fetch(FetchDescriptor<ContactNote>())) ?? [])
        let drafts = ReminderEngine.materialize(
            people: people,
            notes: notes,
            events: events,
            eventReminderHours: settings.eventReminderHours
        )

        let existing = (try? context.fetch(FetchDescriptor<ReminderRecord>())) ?? []
        let dismissedKeys = Set(existing.filter { $0.status == .dismissed }.map(\.dedupeKey))
        let existingByKey = Dictionary(uniqueKeysWithValues: existing.map { ($0.dedupeKey, $0) })

        for record in existing where record.status == .pending {
            if !drafts.contains(where: { $0.dedupeKey == record.dedupeKey }) {
                context.delete(record)
            }
        }

        for draft in drafts {
            if dismissedKeys.contains(draft.dedupeKey) { continue }
            if let record = existingByKey[draft.dedupeKey] {
                record.title = draft.title
                record.body = draft.body
                record.dueAt = draft.dueAt
                record.contactIdentifier = draft.contactIdentifier
                record.noteID = draft.noteID
                record.eventIdentifier = draft.eventIdentifier
            } else {
                context.insert(
                    ReminderRecord(
                        kind: draft.kind,
                        dueAt: draft.dueAt,
                        title: draft.title,
                        body: draft.body,
                        contactIdentifier: draft.contactIdentifier,
                        noteID: draft.noteID,
                        eventIdentifier: draft.eventIdentifier,
                        dedupeKey: draft.dedupeKey
                    )
                )
            }
        }

        try? context.save()
        let pending = ((try? context.fetch(FetchDescriptor<ReminderRecord>())) ?? [])
            .filter { $0.status == .pending }
        Task {
            await NotificationService.reschedule(
                reminders: pending,
                enabled: settings.notificationsEnabled
            )
        }
    }

    func addNote(
        contactIdentifier: String,
        body: String,
        remindAt: Date?,
        context: ModelContext
    ) {
        let note = ContactNote(
            contactIdentifier: contactIdentifier,
            body: body.trimmingCharacters(in: .whitespacesAndNewlines),
            remindAt: remindAt
        )
        context.insert(note)
        refreshReminders(context: context)
    }

    func deleteNote(_ note: ContactNote, context: ModelContext) {
        context.delete(note)
        refreshReminders(context: context)
    }

    func dismiss(_ reminder: ReminderRecord, context: ModelContext) {
        reminder.status = .dismissed
        try? context.save()
        let pending = ((try? context.fetch(FetchDescriptor<ReminderRecord>())) ?? [])
            .filter { $0.status == .pending }
        let settings = settings(in: context)
        Task {
            await NotificationService.reschedule(
                reminders: pending,
                enabled: settings.notificationsEnabled
            )
        }
    }

    func person(for identifier: String?) -> Person? {
        guard let identifier else { return nil }
        return people.first { $0.id == identifier }
    }

    func upcomingEvents(matching person: Person) -> [CalendarOccurrence] {
        let emails = Set(person.emails.map { $0.lowercased() })
        let name = person.displayName.lowercased()
        return events.filter { event in
            event.attendeeEmails.contains { emails.contains($0) }
                || event.attendeeNames.contains { $0.lowercased() == name }
        }
    }
}
