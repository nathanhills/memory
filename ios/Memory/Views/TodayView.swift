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

    private var todayItems: [ReminderRecord] {
        pending.filter { Calendar.current.isDateInToday($0.dueAt) || $0.dueAt < .now }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Memory")
                        .font(.system(size: 44, weight: .regular, design: .serif))
                        .foregroundStyle(MemoryTheme.seaDeep)
                    Text("Who to remember today")
                        .font(.system(.title2, design: .serif))
                        .foregroundStyle(MemoryTheme.ink)
                    Text("Birthdays, notes coming due, and friends you’ll see soon.")
                        .foregroundStyle(MemoryTheme.inkSoft)
                }

                if store.people.isEmpty {
                    EmptyCard {
                        Text("Connect your people")
                            .font(.system(.title3, design: .serif))
                        Text("Sync iPhone Contacts and the next 90 days of Calendar to get started.")
                            .font(.subheadline)
                            .foregroundStyle(MemoryTheme.inkSoft)
                        Button {
                            Task { await store.sync(context: modelContext) }
                        } label: {
                            Text(store.isSyncing ? "Syncing…" : "Sync contacts & calendar")
                        }
                        .buttonStyle(SeaButtonStyle(disabled: store.isSyncing))
                        .disabled(store.isSyncing)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Coming up")
                                .font(.system(.title3, design: .serif))
                            Spacer()
                        }
                        if pending.isEmpty {
                            Text("No reminders in the next week. Add a note with a remind date, or wait for birthdays and meetings.")
                                .foregroundStyle(MemoryTheme.inkSoft)
                        } else {
                            ForEach(pending.prefix(8), id: \.id) { reminder in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(todayItems.contains(where: { $0.id == reminder.id })
                                         ? "\(reminder.kind.label.uppercased()) · today"
                                         : reminder.kind.label.uppercased())
                                        .font(.caption.weight(.medium))
                                        .tracking(0.6)
                                        .foregroundStyle(MemoryTheme.sea)
                                    Text(reminder.title)
                                        .font(.headline)
                                        .foregroundStyle(MemoryTheme.ink)
                                    Text(reminder.dueAt.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute()))
                                        .font(.subheadline)
                                        .foregroundStyle(MemoryTheme.inkSoft)
                                }
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .overlay(alignment: .bottom) {
                                    Rectangle()
                                        .fill(MemoryTheme.ink.opacity(0.08))
                                        .frame(height: 1)
                                }
                            }
                        }
                    }

                    Button {
                        Task { await store.sync(context: modelContext) }
                    } label: {
                        Text(store.isSyncing ? "Syncing…" : "Re-sync")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(MemoryTheme.sea)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .disabled(store.isSyncing)

                    if let synced = settingsRows.first?.lastContactsSync {
                        Text("Last synced \(synced.formatted(.dateTime.month().day().hour().minute()))")
                            .font(.caption)
                            .foregroundStyle(MemoryTheme.inkSoft)
                    }
                }

                if let error = store.lastError {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(MemoryTheme.coral)
                }
            }
            .padding(24)
        }
        .background { AtmosphereBackground() }
        .navigationBarTitleDisplayMode(.inline)
    }
}
