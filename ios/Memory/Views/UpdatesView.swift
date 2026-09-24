import SwiftData
import SwiftUI

struct UpdatesView: View {
    @Environment(MemoryStore.self) private var store
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ReminderRecord.dueAt) private var reminders: [ReminderRecord]
    @Query private var settingsRows: [AppSettings]
    @State private var showingSettings = false
    @State private var selectedPerson: Person?

    private var pending: [ReminderRecord] {
        let horizon = Calendar.current.date(byAdding: .day, value: 60, to: .now) ?? .now
        return reminders
            .filter { $0.status == .pending && $0.dueAt <= horizon }
            .sorted { $0.dueAt < $1.dueAt }
    }

    private var dueToday: [ReminderRecord] {
        pending.filter { Calendar.current.isDateInToday($0.dueAt) || $0.dueAt < .now }
    }

    private var upcoming: [ReminderRecord] {
        pending.filter { reminder in
            !dueToday.contains(where: { $0.id == reminder.id })
        }
    }

    var body: some View {
        List {
            Section {
                header
                    .memoryListRow()
            }

            if let error = store.lastError {
                Section {
                    EmptyEditorialCard(
                        title: "Sync\nneeds a look",
                        subtitle: error,
                        count: "!",
                        fill: MemoryTheme.coral
                    )
                    .memoryListRow()
                }
            }

            if store.people.isEmpty {
                Section {
                    EmptyEditorialCard(
                        title: "Connect\npeople",
                        subtitle: "Sync Contacts and the next 90 days of Calendar to see who to remember.",
                        count: "—",
                        fill: MemoryTheme.gray,
                        actionTitle: store.isSyncing ? "Syncing" : "Sync now",
                        action: {
                            Task { await store.sync(context: modelContext) }
                        }
                    )
                    .memoryListRow()
                }
            } else if pending.isEmpty {
                Section {
                    EmptyEditorialCard(
                        title: "Nothing\ndue",
                        subtitle: "Add a note with a remind date, or wait for birthdays and meetings.",
                        count: "0",
                        fill: MemoryTheme.gray
                    )
                    .memoryListRow()
                }
            } else {
                if !dueToday.isEmpty {
                    Section {
                        SectionWord(text: "Today")
                            .memoryListRow()
                        ForEach(dueToday, id: \.id) { reminder in
                            reminderLink(reminder)
                        }
                    }
                }
                if !upcoming.isEmpty {
                    Section {
                        SectionWord(text: "Coming up")
                            .memoryListRow()
                        ForEach(upcoming, id: \.id) { reminder in
                            reminderLink(reminder)
                        }
                    }
                }
            }

            if let synced = settingsRows.first?.lastContactsSync {
                Section {
                    MemoryCard(fill: MemoryTheme.paper, minHeight: 72) {
                        HStack {
                            Text("Last synced")
                                .font(.memory(15, weight: .heavy))
                                .fontWidth(.condensed)
                            Spacer()
                            Text(synced, format: .dateTime.month().day().hour().minute())
                                .font(.memory(15, weight: .bold))
                                .fontWidth(.condensed)
                                .foregroundStyle(MemoryTheme.muted)
                        }
                        .foregroundStyle(MemoryTheme.ink)
                    }
                    .memoryListRow()
                }
            }
        }
        .listStyle(.plain)
        .listSectionSeparator(.hidden)
        .listSectionSpacing(8)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .memoryBackground()
        .navigationTitle("Updates")
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $selectedPerson) { person in
            PersonDetailView(person: person)
        }
        .refreshable {
            await store.sync(context: modelContext)
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView()
            }
            .presentationDetents([.medium, .large])
            .presentationBackground(MemoryTheme.cream)
        }
    }

    private var header: some View {
        EditorialHeader(
            title: "Updates",
            subtitle: "Reminders",
            count: pending.count,
            countColor: MemoryTheme.orange,
            trailing: AnyView(
                VStack(alignment: .trailing, spacing: 10) {
                    CountBadge(count: pending.count, color: MemoryTheme.orange)
                    HeaderActionCluster(onSettings: { showingSettings = true })
                }
            )
        )
    }

    @ViewBuilder
    private func reminderLink(_ reminder: ReminderRecord) -> some View {
        let person = store.person(for: reminder.contactIdentifier)
        Group {
            if let person {
                Button {
                    selectedPerson = person
                } label: {
                    ReminderCard(reminder: reminder, person: person)
                }
                .buttonStyle(.plain)
            } else {
                ReminderCard(reminder: reminder, person: nil)
            }
        }
        .memoryListRow()
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if reminder.status == .pending {
                Button("Dismiss") {
                    store.dismiss(reminder, context: modelContext)
                }
                .tint(MemoryTheme.ink)
            }
        }
        .accessibilityHint(person == nil ? "" : "Opens \(person?.displayName ?? "contact")")
    }
}

private extension View {
    func memoryListRow() -> some View {
        listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}
