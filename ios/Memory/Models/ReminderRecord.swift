import Foundation
import SwiftData

enum ReminderKind: String, Codable, CaseIterable {
    case noteDue = "note_due"
    case birthday
    case anniversary
    case preEvent = "pre_event"

    var label: String {
        switch self {
        case .noteDue: "Note"
        case .birthday: "Birthday"
        case .anniversary: "Anniversary"
        case .preEvent: "Before event"
        }
    }

    var systemImage: String {
        switch self {
        case .noteDue: "note.text"
        case .birthday: "gift"
        case .anniversary: "heart"
        case .preEvent: "calendar"
        }
    }

    var editorialLabel: String {
        switch self {
        case .noteDue: "NOTE"
        case .birthday: "BIRTHDAY"
        case .anniversary: "ANNIVERSARY"
        case .preEvent: "BEFORE"
        }
    }
}

enum ReminderStatus: String, Codable {
    case pending
    case dismissed
}

@Model
final class ReminderRecord {
    var id: UUID
    var typeRaw: String
    var statusRaw: String
    var dueAt: Date
    var title: String
    var body: String?
    var contactIdentifier: String?
    var noteID: UUID?
    var eventIdentifier: String?
    var dedupeKey: String
    var createdAt: Date

    var kind: ReminderKind {
        get { ReminderKind(rawValue: typeRaw) ?? .noteDue }
        set { typeRaw = newValue.rawValue }
    }

    var status: ReminderStatus {
        get { ReminderStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        kind: ReminderKind,
        status: ReminderStatus = .pending,
        dueAt: Date,
        title: String,
        body: String? = nil,
        contactIdentifier: String? = nil,
        noteID: UUID? = nil,
        eventIdentifier: String? = nil,
        dedupeKey: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.typeRaw = kind.rawValue
        self.statusRaw = status.rawValue
        self.dueAt = dueAt
        self.title = title
        self.body = body
        self.contactIdentifier = contactIdentifier
        self.noteID = noteID
        self.eventIdentifier = eventIdentifier
        self.dedupeKey = dedupeKey
        self.createdAt = createdAt
    }

    var dueDayNumber: String {
        String(Calendar.current.component(.day, from: dueAt))
    }
}
