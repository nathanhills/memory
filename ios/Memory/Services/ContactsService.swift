import Contacts
import Foundation

enum ContactsServiceError: LocalizedError {
    case denied

    var errorDescription: String? {
        switch self {
        case .denied:
            "Contacts access is off. Enable it in Settings to see your people."
        }
    }
}

struct ContactsService {
    private let store = CNContactStore()

    var authorizationStatus: CNAuthorizationStatus {
        CNContactStore.authorizationStatus(for: .contacts)
    }

    var isReadable: Bool {
        switch authorizationStatus {
        case .authorized:
            true
        case .denied, .restricted, .notDetermined:
            false
        @unknown default:
            true
        }
    }

    func requestAccess() async -> Bool {
        if isReadable { return true }
        if authorizationStatus == .denied || authorizationStatus == .restricted {
            return false
        }
        return await withCheckedContinuation { continuation in
            store.requestAccess(for: .contacts) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    func fetchPeople() throws -> [Person] {
        guard isReadable else { throw ContactsServiceError.denied }

        let keys: [CNKeyDescriptor] = [
            CNContactIdentifierKey as CNKeyDescriptor,
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactNicknameKey as CNKeyDescriptor,
            CNContactOrganizationNameKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactThumbnailImageDataKey as CNKeyDescriptor,
            CNContactBirthdayKey as CNKeyDescriptor,
            CNContactDatesKey as CNKeyDescriptor,
        ]

        let request = CNContactFetchRequest(keysToFetch: keys)
        request.sortOrder = .givenName

        var people: [Person] = []
        try store.enumerateContacts(with: request) { contact, _ in
            let person = Person(contact: contact)
            let hasIdentity = !person.displayName.isEmpty && person.displayName != "Unnamed"
            let hasReachable = !person.emails.isEmpty || !person.phones.isEmpty
            if hasIdentity || hasReachable {
                people.append(person)
            }
        }
        return people.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }
}
