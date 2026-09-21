import SwiftUI

struct PeopleView: View {
    @Environment(MemoryStore.self) private var store
    @Environment(\.modelContext) private var modelContext
    @State private var query = ""

    private var filtered: [Person] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return store.people }
        return store.people.filter { person in
            let hay = ([person.displayName, person.givenName, person.familyName] + person.emails)
                .joined(separator: " ")
                .lowercased()
            return hay.contains(q)
        }
    }

    var body: some View {
        Group {
            if store.people.isEmpty {
                ContentUnavailableView {
                    Label("No People", systemImage: "person.2")
                } description: {
                    Text("Allow Contacts access, then pull to refresh.")
                } actions: {
                    Button("Sync") {
                        Task { await store.sync(context: modelContext) }
                    }
                }
            } else if filtered.isEmpty {
                ContentUnavailableView.search(text: query)
            } else {
                List(filtered) { person in
                    NavigationLink(value: person) {
                        HStack(spacing: 12) {
                            PersonAvatar(person: person)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(person.displayName)
                                if let email = person.emails.first {
                                    Text(email)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("People")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $query, prompt: "Name or email")
        .navigationDestination(for: Person.self) { person in
            PersonDetailView(person: person)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SyncToolbarButton()
            }
        }
        .refreshable {
            await store.sync(context: modelContext)
        }
    }
}
