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
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        header
                        Text("Nothing queued right now. Sync contacts and add notes to grow this list.")
                            .foregroundStyle(MemoryTheme.inkSoft)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background { AtmosphereBackground() }
            } else {
                List {
                    ForEach(visible, id: \.id) { reminder in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Text(reminder.kind.label.uppercased())
                                    .font(.caption.weight(.medium))
                                    .tracking(0.6)
                                    .foregroundStyle(MemoryTheme.sea)
                                Text(reminder.dueAt.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute()))
                                    .font(.caption)
                                    .foregroundStyle(MemoryTheme.inkSoft)
                            }
                            Text(reminder.title)
                                .font(.system(.title3, design: .serif))
                                .foregroundStyle(MemoryTheme.ink)
                            if let body = reminder.body, !body.isEmpty {
                                Text(body)
                                    .font(.subheadline)
                                    .foregroundStyle(MemoryTheme.inkSoft)
                            }
                            if reminder.status == .pending {
                                Button("Dismiss") {
                                    store.dismiss(reminder, context: modelContext)
                                }
                                .font(.subheadline)
                                .foregroundStyle(MemoryTheme.inkSoft)
                            }
                        }
                        .padding(.vertical, 8)
                        .listRowBackground(Color.white.opacity(0.35))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background { AtmosphereBackground() }
            }
        }
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.large)
        .safeAreaInset(edge: .top, alignment: .leading, spacing: 0) {
            if !visible.isEmpty {
                Text("Notes due, birthdays, anniversaries, and pre-event context.")
                    .font(.subheadline)
                    .foregroundStyle(MemoryTheme.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                    .background(Color.clear)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reminders")
                .font(.system(.largeTitle, design: .serif))
            Text("Notes due, birthdays, anniversaries, and pre-event context.")
                .foregroundStyle(MemoryTheme.inkSoft)
        }
    }
}
