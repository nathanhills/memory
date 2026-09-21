import SwiftUI

struct PeopleView: View {
    @Environment(MemoryStore.self) private var store
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
                ScrollView {
                    EmptyCard {
                        Text("No contacts yet. Sync from iPhone Contacts to populate this list.")
                            .foregroundStyle(MemoryTheme.inkSoft)
                    }
                    .padding(24)
                }
                .background { AtmosphereBackground() }
            } else {
                List {
                    ForEach(filtered) { person in
                        NavigationLink(value: person) {
                            HStack(spacing: 12) {
                                PersonAvatar(person: person)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(person.displayName)
                                        .foregroundStyle(MemoryTheme.ink)
                                    if let email = person.emails.first {
                                        Text(email)
                                            .font(.subheadline)
                                            .foregroundStyle(MemoryTheme.inkSoft)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.white.opacity(0.35))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background { AtmosphereBackground() }
                .searchable(text: $query, prompt: "Search by name or email")
            }
        }
        .navigationTitle("People")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: Person.self) { person in
            PersonDetailView(person: person)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SyncToolbarButton()
            }
        }
    }
}

struct SyncToolbarButton: View {
    @Environment(MemoryStore.self) private var store
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Button {
            Task { await store.sync(context: modelContext) }
        } label: {
            if store.isSyncing {
                ProgressView()
            } else {
                Text("Sync")
            }
        }
        .disabled(store.isSyncing)
    }
}
