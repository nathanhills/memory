import SwiftData
import SwiftUI

struct RemindersView: View {
    @Environment(MemoryStore.self) private var store
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ReminderRecord.dueAt) private var reminders: [ReminderRecord]

    private var visible: [ReminderRecord] {
        let horizon = Calendar.current.date(byAdding: .day, value: 60, to: .now) ?? .now
        return reminders
            .filter { $0.status != .dismissed && $0.dueAt <= horizon }
            .sorted { $0.dueAt < $1.dueAt }
    }

    var body: some View {
        Group {
            if visible.isEmpty {
                ContentUnavailableView(
                    "No Reminders",
                    systemImage: "bell",
                    description: Text("Sync contacts and add notes to grow this list.")
                )
            } else {
                List {
                    ForEach(visible, id: \.id) { reminder in
                        Group {
                            if let person = store.person(for: reminder.contactIdentifier) {
                                NavigationLink(value: person) {
                                    ReminderRow(reminder: reminder)
                                }
                            } else {
                                ReminderRow(reminder: reminder)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            if reminder.status == .pending {
                                Button("Dismiss") {
                                    store.dismiss(reminder, context: modelContext)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Reminders")
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
    }
}
