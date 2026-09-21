import EventKit
import Foundation

enum CalendarServiceError: LocalizedError {
    case denied

    var errorDescription: String? {
        switch self {
        case .denied:
            "Calendar access is off. Enable it in Settings to get pre-event reminders."
        }
    }
}

struct CalendarService {
    private let store = EKEventStore()

    var authorizationStatus: EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }

    var isReadable: Bool {
        switch authorizationStatus {
        case .fullAccess, .authorized:
            true
        case .denied, .restricted, .notDetermined, .writeOnly:
            false
        @unknown default:
            false
        }
    }

    func requestAccess() async -> Bool {
        if isReadable { return true }
        switch authorizationStatus {
        case .denied, .restricted, .writeOnly:
            return false
        default:
            break
        }
        do {
            return try await store.requestFullAccessToEvents()
        } catch {
            return false
        }
    }

    func fetchUpcomingEvents(days: Int = 90) throws -> [CalendarOccurrence] {
        guard isReadable else { throw CalendarServiceError.denied }

        let start = Date()
        let end = Calendar.current.date(byAdding: .day, value: days, to: start) ?? start
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let events = store.events(matching: predicate)

        return events.map { event in
            let attendees = event.attendees ?? []
            return CalendarOccurrence(
                id: event.eventIdentifier ?? UUID().uuidString,
                title: event.title ?? "Untitled event",
                start: event.startDate,
                end: event.endDate,
                allDay: event.isAllDay,
                attendeeEmails: attendees.compactMap(\.memoryEmail),
                attendeeNames: attendees.compactMap(\.name),
                location: event.location
            )
        }
        .sorted { $0.start < $1.start }
    }
}

private extension EKParticipant {
    var memoryEmail: String? {
        let url = url
        if url.scheme?.lowercased() == "mailto" {
            let candidate = url.path.isEmpty ? (url.resourceSpecifier ?? "") : url.path
            let trimmed = candidate.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return trimmed.isEmpty ? nil : trimmed.lowercased()
        }
        let absolute = url.absoluteString
        if absolute.lowercased().hasPrefix("mailto:") {
            return String(absolute.dropFirst(7)).lowercased()
        }
        return nil
    }
}
