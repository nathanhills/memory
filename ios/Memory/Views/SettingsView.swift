import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(MemoryStore.self) private var store
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsRows: [AppSettings]
    @State private var savedMessage: String?

    private var settings: AppSettings {
        store.settings(in: modelContext)
    }

    var body: some View {
        Form {
            Section("iPhone sync") {
                Button {
                    Task { await store.sync(context: modelContext) }
                } label: {
                    Text(store.isSyncing ? "Syncing…" : "Sync contacts & calendar now")
                }
                .disabled(store.isSyncing)

                if let contacts = settingsRows.first?.lastContactsSync {
                    Text("Contacts: \(contacts.formatted(.dateTime.month().day().hour().minute()))")
                        .foregroundStyle(MemoryTheme.inkSoft)
                }
                if let calendar = settingsRows.first?.lastCalendarSync {
                    Text("Calendar: \(calendar.formatted(.dateTime.month().day().hour().minute()))")
                        .foregroundStyle(MemoryTheme.inkSoft)
                }
                if let error = store.lastError ?? settingsRows.first?.lastError {
                    Text(error)
                        .foregroundStyle(MemoryTheme.coral)
                }
            }

            Section("Reminders") {
                Stepper(value: hoursBinding, in: 1...168) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hours before calendar events to surface notes")
                        Text("\(settings.eventReminderHours) hours")
                            .font(.subheadline)
                            .foregroundStyle(MemoryTheme.inkSoft)
                    }
                }
                Toggle("Lock screen notifications for upcoming reminders", isOn: notificationsBinding)
            }
        }
        .scrollContentBackground(.hidden)
        .background { AtmosphereBackground() }
        .navigationTitle("Settings")
        .safeAreaInset(edge: .bottom) {
            if let savedMessage {
                Text(savedMessage)
                    .font(.subheadline)
                    .foregroundStyle(MemoryTheme.seaDeep)
                    .padding(.bottom, 12)
            }
        }
        .onAppear {
            _ = settings
        }
    }

    private var hoursBinding: Binding<Int> {
        Binding(
            get: { settings.eventReminderHours },
            set: { newValue in
                settings.eventReminderHours = newValue
                store.refreshReminders(context: modelContext, settings: settings)
                savedMessage = "Saved"
            }
        )
    }

    private var notificationsBinding: Binding<Bool> {
        Binding(
            get: { settings.notificationsEnabled },
            set: { newValue in
                settings.notificationsEnabled = newValue
                if newValue {
                    Task { await NotificationService.requestAuthorizationIfNeeded() }
                }
                store.refreshReminders(context: modelContext, settings: settings)
                savedMessage = "Saved"
            }
        )
    }
}
