import SwiftData
import SwiftUI

@main
struct MemoryApp: App {
    @State private var store = MemoryStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
        }
        .modelContainer(for: [ContactNote.self, ReminderRecord.self, AppSettings.self])
    }
}

#Preview("Welcome") {
    WelcomeView(isRequesting: false, onContinue: {})
}

#Preview("Today empty") {
    NavigationStack {
        TodayView()
    }
    .environment(MemoryStore())
    .modelContainer(for: [ContactNote.self, ReminderRecord.self, AppSettings.self], inMemory: true)
}
