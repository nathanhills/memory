import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(MemoryStore.self) private var store
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsRows: [AppSettings]
    @State private var isRequesting = false

    private var settings: AppSettings {
        store.settings(in: modelContext)
    }

    var body: some View {
        Group {
            if settings.hasCompletedOnboarding {
                MainTabView()
            } else {
                WelcomeView(isRequesting: isRequesting) {
                    Task { await continueOnboarding() }
                }
            }
        }
        .onAppear {
            _ = settings
            if settings.hasCompletedOnboarding {
                Task { await store.sync(context: modelContext) }
            }
        }
    }

    private func continueOnboarding() async {
        isRequesting = true
        defer { isRequesting = false }
        _ = await store.contactsService.requestAccess()
        _ = await store.calendarService.requestAccess()
        await NotificationService.requestAuthorizationIfNeeded()
        settings.hasCompletedOnboarding = true
        settings.notificationsEnabled = true
        try? modelContext.save()
        await store.sync(context: modelContext)
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                TodayView()
            }
            .tabItem { Label("Today", systemImage: "sun.max") }

            NavigationStack {
                PeopleView()
            }
            .tabItem { Label("People", systemImage: "person.2") }

            NavigationStack {
                RemindersView()
            }
            .tabItem { Label("Reminders", systemImage: "bell") }

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
