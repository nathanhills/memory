import SwiftData
import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(MemoryStore.self) private var store
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    @Query private var settingsRows: [AppSettings]

    private var settings: AppSettings {
        store.settings(in: modelContext)
    }

    var body: some View {
        List {
            Section {
                EditorialHeader(
                    title: "Settings",
                    subtitle: "Sync",
                    count: nil,
                    trailing: AnyView(
                        CircleIconButton(systemName: "xmark", fill: MemoryTheme.gray) {
                            dismiss()
                        }
                        .accessibilityLabel("Close")
                    )
                )
                .memoryListRow()
            }

            Section {
                Button {
                    Task { await store.sync(context: modelContext) }
                } label: {
                    MemoryCard(fill: MemoryTheme.orange, minHeight: 88) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(store.isSyncing ? "Syncing" : "Sync now")
                                    .memoryDisplay(26)
                                Text("Contacts and the next 90 days of Calendar")
                                    .font(.memory(13, weight: .medium))
                                    .foregroundStyle(MemoryTheme.ink.opacity(0.7))
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 16, weight: .bold))
                                .frame(width: 40, height: 40)
                                .background(MemoryTheme.paper.opacity(0.55), in: Circle())
                                .foregroundStyle(MemoryTheme.ink)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(store.isSyncing)
                .memoryListRow()

                if let contacts = settingsRows.first?.lastContactsSync {
                    MemoryCard(fill: MemoryTheme.paper, minHeight: 72) {
                        HStack {
                            Text("Contacts")
                                .font(.memory(16, weight: .heavy))
                                .fontWidth(.condensed)
                            Spacer()
                            Text(contacts, format: .dateTime.month().day().hour().minute())
                                .font(.memory(15, weight: .bold))
                                .fontWidth(.condensed)
                                .foregroundStyle(MemoryTheme.muted)
                        }
                        .foregroundStyle(MemoryTheme.ink)
                    }
                    .memoryListRow()
                }
                if let calendar = settingsRows.first?.lastCalendarSync {
                    MemoryCard(fill: MemoryTheme.gray, minHeight: 72) {
                        HStack {
                            Text("Calendar")
                                .font(.memory(16, weight: .heavy))
                                .fontWidth(.condensed)
                            Spacer()
                            Text(calendar, format: .dateTime.month().day().hour().minute())
                                .font(.memory(15, weight: .bold))
                                .fontWidth(.condensed)
                                .foregroundStyle(MemoryTheme.muted)
                        }
                        .foregroundStyle(MemoryTheme.ink)
                    }
                    .memoryListRow()
                }
            }

            if let error = store.lastError ?? settingsRows.first?.lastError {
                Section {
                    MemoryCard(fill: MemoryTheme.coral, minHeight: 100) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(error)
                                .font(.memory(15, weight: .semibold))
                                .foregroundStyle(MemoryTheme.ink)
                            Button("Open Settings") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    openURL(url)
                                }
                            }
                            .font(.memory(15, weight: .heavy))
                            .fontWidth(.condensed)
                            .foregroundStyle(MemoryTheme.ink)
                        }
                    }
                    .memoryListRow()
                }
            }

            Section {
                SectionWord(text: "Reminders")
                    .memoryListRow()

                MemoryCard(fill: MemoryTheme.sage, minHeight: 96) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Before events")
                                .memoryDisplay(22)
                            Spacer()
                            Text("\(settings.eventReminderHours)h")
                                .memoryDisplay(36)
                        }
                        Stepper(
                            "Hours before a meeting to surface notes",
                            value: hoursBinding,
                            in: 1...168
                        )
                        .labelsHidden()
                        .tint(MemoryTheme.ink)
                    }
                }
                .memoryListRow()

                MemoryCard(fill: MemoryTheme.gold, minHeight: 88) {
                    Toggle(isOn: notificationsBinding) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Lock screen")
                                .memoryDisplay(22)
                            Text("Local notifications for pending reminders")
                                .font(.memory(13, weight: .medium))
                                .foregroundStyle(MemoryTheme.ink.opacity(0.7))
                        }
                    }
                    .tint(MemoryTheme.ink)
                }
                .memoryListRow()
            }

            Section {
                Text("Memory reads Contacts and Calendar on this iPhone. Notes stay on-device.")
                    .font(.memory(13, weight: .medium))
                    .foregroundStyle(MemoryTheme.muted)
                    .memoryListRow()
            }
        }
        .listStyle(.plain)
        .listSectionSeparator(.hidden)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .memoryBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
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

private extension View {
    func memoryListRow() -> some View {
        listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}
