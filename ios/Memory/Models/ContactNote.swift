import Foundation
import SwiftData

@Model
final class ContactNote {
    var id: UUID
    var contactIdentifier: String
    var body: String
    var remindAt: Date?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        contactIdentifier: String,
        body: String,
        remindAt: Date? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.contactIdentifier = contactIdentifier
        self.body = body
        self.remindAt = remindAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
