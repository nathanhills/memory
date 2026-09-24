import SwiftData
import SwiftUI

struct ContactsView: View {
    @Environment(MemoryStore.self) private var store
    @Environment(\.modelContext) private var modelContext
    @Query private var notes: [ContactNote]
    @State private var query = ""
    @State private var selectedPerson: Person?

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

    private var grouped: [(letter: String, people: [Person])] {
        let dict = Dictionary(grouping: filtered) { $0.sectionLetter }
        return dict.keys.sorted().map { letter in
            (letter, dict[letter] ?? [])
        }
    }

    var body: some View {
        List {
            Section {
                header
                    .memoryListRow()
                MemorySearchField(text: $query, prompt: "Name or email")
                    .memoryListRow()
            }

            if store.people.isEmpty {
                Section {
                    EmptyEditorialCard(
                        title: "No\npeople",
                        subtitle: "Allow Contacts access, then pull to refresh.",
                        count: "—",
                        fill: MemoryTheme.gray,
                        actionTitle: store.isSyncing ? "Syncing" : "Sync now",
                        action: {
                            Task { await store.sync(context: modelContext) }
                        }
                    )
                    .memoryListRow()
                }
            } else if filtered.isEmpty {
                Section {
                    EmptyEditorialCard(
                        title: "No\nmatches",
                        subtitle: "Nothing in Contacts matches “\(query)”.",
                        count: "0",
                        fill: MemoryTheme.stone
                    )
                    .memoryListRow()
                }
            } else {
                ForEach(grouped, id: \.letter) { group in
                    Section {
                        Text(group.letter)
                            .memoryDisplay(40)
                            .padding(.top, 4)
                            .memoryListRow()
                            .accessibilityAddTraits(.isHeader)

                        ForEach(Array(group.people.enumerated()), id: \.element.id) { index, person in
                            Button {
                                selectedPerson = person
                            } label: {
                                ContactCard(
                                    person: person,
                                    noteCount: noteCount(for: person),
                                    fill: MemoryTheme.contactCardFill(at: index)
                                )
                            }
                            .buttonStyle(.plain)
                            .memoryListRow()
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .listSectionSeparator(.hidden)
        .listSectionSpacing(4)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .scrollIndicators(.hidden)
        .memoryBackground()
        .navigationTitle("Contacts")
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $selectedPerson) { person in
            PersonDetailView(person: person)
        }
        .refreshable {
            await store.sync(context: modelContext)
        }
    }

    private var header: some View {
        EditorialHeader(
            title: "Contacts",
            subtitle: "People",
            count: filtered.count,
            countColor: MemoryTheme.sage,
            trailing: AnyView(
                VStack(alignment: .trailing, spacing: 10) {
                    CountBadge(count: filtered.count, color: MemoryTheme.sage)
                    HeaderActionCluster()
                }
            )
        )
    }

    private func noteCount(for person: Person) -> Int {
        notes.filter { $0.contactIdentifier == person.id }.count
    }
}

private extension View {
    func memoryListRow() -> some View {
        listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}
