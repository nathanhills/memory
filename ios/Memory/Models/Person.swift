import Contacts
import Foundation
import SwiftUI

struct Person: Identifiable, Hashable {
    let id: String
    var givenName: String
    var familyName: String
    var displayName: String
    var emails: [String]
    var phones: [String]
    var thumbnail: Data?
    var birthdayMonth: Int?
    var birthdayDay: Int?
    var birthdayYear: Int?
    var anniversaryMonth: Int?
    var anniversaryDay: Int?
    var anniversaryYear: Int?

    static func == (lhs: Person, rhs: Person) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var initials: String {
        let parts = displayName.split(separator: " ").prefix(2)
        let letters = parts.compactMap { $0.first }.map(String.init)
        return letters.joined().uppercased()
    }

    var birthdayLabel: String? {
        guard let month = birthdayMonth, let day = birthdayDay else { return nil }
        if let year = birthdayYear {
            return "Birthday \(month)/\(day)/\(year)"
        }
        return "Birthday \(month)/\(day)"
    }

    var primaryLetter: String {
        String(displayName.prefix(1)).uppercased()
    }

    var badgeColor: Color {
        MemoryTheme.badgeColor(for: id.isEmpty ? displayName : id)
    }

    var sectionLetter: String {
        let scalar = displayName.unicodeScalars.first
        if let scalar, CharacterSet.letters.contains(scalar) {
            return String(scalar).uppercased()
        }
        return "#"
    }
}

extension Person {
    init(contact: CNContact) {
        let given = contact.givenName
        let family = contact.familyName
        let composed = [given, family].filter { !$0.isEmpty }.joined(separator: " ")
        let fallback = contact.nickname.isEmpty ? contact.organizationName : contact.nickname
        displayName = composed.isEmpty ? (fallback.isEmpty ? "Unnamed" : fallback) : composed
        id = contact.identifier
        givenName = given
        familyName = family
        emails = contact.emailAddresses.map { $0.value as String }
        phones = contact.phoneNumbers.map { $0.value.stringValue }
        thumbnail = contact.thumbnailImageData
        birthdayMonth = nil
        birthdayDay = nil
        birthdayYear = nil
        anniversaryMonth = nil
        anniversaryDay = nil
        anniversaryYear = nil
        if let birthday = contact.birthday {
            birthdayMonth = birthday.month
            birthdayDay = birthday.day
            birthdayYear = birthday.year
        }
        let anniversary = contact.dates.first {
            let label = CNLabeledValue<NSDateComponents>.localizedString(forLabel: $0.label ?? "")
            return ($0.label == CNLabelDateAnniversary) || label.lowercased().contains("anniversary")
        }
        if let components = anniversary?.value {
            let month = Int(components.month)
            let day = Int(components.day)
            let year = Int(components.year)
            anniversaryMonth = (1...12).contains(month) ? month : nil
            anniversaryDay = (1...31).contains(day) ? day : nil
            anniversaryYear = year > 1900 && year < 3000 ? year : nil
        }
    }

    static let previewJordan = Person(
        id: "preview-jordan",
        givenName: "Jordan",
        familyName: "Lee",
        displayName: "Jordan Lee",
        emails: ["jordan@example.com"],
        phones: [],
        thumbnail: nil,
        birthdayMonth: 9,
        birthdayDay: 24,
        birthdayYear: nil,
        anniversaryMonth: nil,
        anniversaryDay: nil,
        anniversaryYear: nil
    )

    static let previewSam = Person(
        id: "preview-sam",
        givenName: "Sam",
        familyName: "Rivera",
        displayName: "Sam Rivera",
        emails: ["sam@example.com"],
        phones: [],
        thumbnail: nil,
        birthdayMonth: 3,
        birthdayDay: 8,
        birthdayYear: nil,
        anniversaryMonth: nil,
        anniversaryDay: nil,
        anniversaryYear: nil
    )

    static let previewAlex = Person(
        id: "preview-alex",
        givenName: "Alex",
        familyName: "Chen",
        displayName: "Alex Chen",
        emails: ["alex@example.com"],
        phones: [],
        thumbnail: nil,
        birthdayMonth: nil,
        birthdayDay: nil,
        birthdayYear: nil,
        anniversaryMonth: 11,
        anniversaryDay: 2,
        anniversaryYear: nil
    )

    static let previews: [Person] = [previewAlex, previewJordan, previewSam]
}

struct CalendarOccurrence: Identifiable, Hashable {
    let id: String
    var title: String
    var start: Date
    var end: Date?
    var allDay: Bool
    var attendeeEmails: [String]
    var attendeeNames: [String]
    var location: String?
}
