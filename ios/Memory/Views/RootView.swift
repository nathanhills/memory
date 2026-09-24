import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(MemoryStore.self) private var store
    @Environment(\.modelContext) private var modelContext
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
        .preferredColorScheme(.light)
        .tint(MemoryTheme.orange)
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
    @State private var selection: AppTab = .updates

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                NavigationStack {
                    UpdatesView()
                }
                .opacity(selection == .updates ? 1 : 0)
                .offset(x: selection == .updates ? 0 : -12)
                .allowsHitTesting(selection == .updates)
                .accessibilityHidden(selection != .updates)

                NavigationStack {
                    ContactsView()
                }
                .opacity(selection == .contacts ? 1 : 0)
                .offset(x: selection == .contacts ? 0 : 12)
                .allowsHitTesting(selection == .contacts)
                .accessibilityHidden(selection != .contacts)
            }
            .animation(.easeInOut(duration: 0.18), value: selection)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            MemoryTabBar(selection: $selection)
        }
        .background(MemoryTheme.cream.ignoresSafeArea())
    }
}
