import SwiftData
import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(MemoryStore.self) private var store
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Query private var settingsRows: [AppSettings]

    private var settings: AppSettings {
        store.settings(in: modelContext)
    }

    var body: some View {
        Form {
            Section {
                Button {
                    Task { await store.sync(context: modelContext) }
                } label: {
                    if store.isSyncing {
                        Label("Syncing…", systemImage: "arrow.clockwise")
                    } else {
                        Label("Sync Now", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(store.isSyncing)

                if let contacts = settingsRows.first?.lastContactsSync {
                    LabeledContent("Contacts") {
                        Text(contacts, format: .dateTime.month().day().hour().minute())
                            .foregroundStyle(.secondary)
                    }
                }
                if let calendar = settingsRows.first?.lastCalendarSync {
                    LabeledContent("Calendar") {
                        Text(calendar, format: .dateTime.month().day().hour().minute())
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Sync")
            } footer: {
                Text("Memory reads Contacts and Calendar on this iPhone. Notes stay on-device.")
            }

            if let error = store.lastError ?? settingsRows.first?.lastError {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    }
                }
            }

            Section("Reminders") {
                Stepper(value: hoursBinding, in: 1...168) {
                    LabeledContent("Before Events") {
                        Text("\(settings.eventReminderHours) hr")
                            .foregroundStyle(.secondary)
                    }
                }
                Toggle("Notifications", isOn: notificationsBinding)
            }
        }
        .navigationTitle("Settings")
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
            }
        )
    }
}
