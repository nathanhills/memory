import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(MemoryStore.self) private var store
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ReminderRecord.dueAt) private var reminders: [ReminderRecord]
    @Query private var settingsRows: [AppSettings]

    private var pending: [ReminderRecord] {
        let horizon = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now
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
        Group {
            if store.people.isEmpty {
                ContentUnavailableView {
                    Label("Connect Your People", systemImage: "person.2")
                } description: {
                    Text("Sync Contacts and the next 90 days of Calendar to see who to remember.")
                } actions: {
                    Button("Sync") {
                        Task { await store.sync(context: modelContext) }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(store.isSyncing)
                }
            } else if pending.isEmpty {
                ContentUnavailableView(
                    "Nothing This Week",
                    systemImage: "checkmark.circle",
                    description: Text("Add a note with a remind date, or wait for birthdays and meetings.")
                )
            } else {
                List {
                    if !dueToday.isEmpty {
                        Section("Today") {
                            ForEach(dueToday, id: \.id) { reminder in
                                reminderLink(reminder)
                            }
                        }
                    }
                    if !upcoming.isEmpty {
                        Section("Coming Up") {
                            ForEach(upcoming.prefix(8), id: \.id) { reminder in
                                reminderLink(reminder)
                            }
                        }
                    }
                    if let synced = settingsRows.first?.lastContactsSync {
                        Section {
                            LabeledContent("Last Synced") {
                                Text(synced, format: .dateTime.month().day().hour().minute())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.large)
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
        .overlay(alignment: .bottom) {
            if let error = store.lastError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding()
            }
        }
    }

    @ViewBuilder
    private func reminderLink(_ reminder: ReminderRecord) -> some View {
        if let person = store.person(for: reminder.contactIdentifier) {
            NavigationLink(value: person) {
                ReminderRow(reminder: reminder)
            }
        } else {
            ReminderRow(reminder: reminder)
        }
    }
}
