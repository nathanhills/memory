import Foundation

struct ReminderDraft: Hashable {
    var kind: ReminderKind
    var dueAt: Date
    var title: String
    var body: String?
    var contactIdentifier: String?
    var noteID: UUID?
    var eventIdentifier: String?
    var dedupeKey: String
}

enum ReminderEngine {
    static func materialize(
        people: [Person],
        notes: [ContactNote],
        events: [CalendarOccurrence],
        eventReminderHours: Int,
        now: Date = .now
    ) -> [ReminderDraft] {
        var drafts: [ReminderDraft] = []
        let calendar = Calendar.current
        let horizon = calendar.date(byAdding: .day, value: 30, to: now) ?? now

        var emailToPerson: [String: Person] = [:]
        var nameToPerson: [String: Person] = [:]
        for person in people {
            for email in person.emails {
                emailToPerson[email.lowercased()] = person
            }
            nameToPerson[person.displayName.lowercased()] = person
        }

        for note in notes {
            guard let remindAt = note.remindAt else { continue }
            let person = people.first { $0.id == note.contactIdentifier }
            drafts.append(
                ReminderDraft(
                    kind: .noteDue,
                    dueAt: remindAt,
                    title: "Remember for \(person?.displayName ?? "a friend")",
                    body: note.body,
                    contactIdentifier: note.contactIdentifier,
                    noteID: note.id,
                    eventIdentifier: nil,
                    dedupeKey: "note_due:\(note.id.uuidString):\(remindAt.timeIntervalSince1970)"
                )
            )
        }

        for person in people {
            if let month = person.birthdayMonth, let day = person.birthdayDay,
               let due = nextOccurrence(month: month, day: day, from: now, calendar: calendar),
               due <= horizon
            {
                drafts.append(
                    ReminderDraft(
                        kind: .birthday,
                        dueAt: morningOf(due, calendar: calendar),
                        title: "\(person.displayName)'s birthday",
                        body: "Wish \(person.displayName) a happy birthday.",
                        contactIdentifier: person.id,
                        noteID: nil,
                        eventIdentifier: nil,
                        dedupeKey: "birthday:\(person.id):\(dayKey(due, calendar: calendar))"
                    )
                )
            }

            if let month = person.anniversaryMonth, let day = person.anniversaryDay,
               let due = nextOccurrence(month: month, day: day, from: now, calendar: calendar),
               due <= horizon
            {
                drafts.append(
                    ReminderDraft(
                        kind: .anniversary,
                        dueAt: morningOf(due, calendar: calendar),
                        title: "\(person.displayName)'s anniversary",
                        body: "Remember \(person.displayName) today.",
                        contactIdentifier: person.id,
                        noteID: nil,
                        eventIdentifier: nil,
                        dedupeKey: "anniversary:\(person.id):\(dayKey(due, calendar: calendar))"
                    )
                )
            }
        }

        let lead = TimeInterval(eventReminderHours * 60 * 60)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now

        for event in events {
            let dueAt = event.start.addingTimeInterval(-lead)
            if dueAt < yesterday { continue }

            var matched: [String: Person] = [:]
            for email in event.attendeeEmails {
                if let person = emailToPerson[email.lowercased()] {
                    matched[person.id] = person
                }
            }
            for name in event.attendeeNames {
                if let person = nameToPerson[name.lowercased()] {
                    matched[person.id] = person
                }
            }

            for person in matched.values {
                let recent = notes
                    .filter { $0.contactIdentifier == person.id }
                    .sorted { $0.updatedAt > $1.updatedAt }
                    .prefix(3)
                let summary = recent.isEmpty
                    ? "No notes yet — add something to remember before you meet."
                    : recent.map { "• \($0.body)" }.joined(separator: "\n")

                drafts.append(
                    ReminderDraft(
                        kind: .preEvent,
                        dueAt: dueAt,
                        title: "Before \(event.title) with \(person.displayName)",
                        body: summary,
                        contactIdentifier: person.id,
                        noteID: recent.first?.id,
                        eventIdentifier: event.id,
                        dedupeKey: "pre_event:\(event.id):\(person.id)"
                    )
                )
            }
        }

        return drafts
    }

    private static func nextOccurrence(month: Int, day: Int, from: Date, calendar: Calendar) -> Date? {
        guard (1...12).contains(month), (1...31).contains(day) else { return nil }
        var components = calendar.dateComponents([.year], from: from)
        components.month = month
        components.day = day
        components.hour = 9
        components.minute = 0
        guard var candidate = calendar.date(from: components) else { return nil }
        if calendar.startOfDay(for: candidate) < calendar.startOfDay(for: from) {
            components.year = (components.year ?? 0) + 1
            candidate = calendar.date(from: components) ?? candidate
        }
        return candidate
    }

    private static func morningOf(_ date: Date, calendar: Calendar) -> Date {
        calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
    }

    private static func dayKey(_ date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}
