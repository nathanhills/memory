import SwiftData
import SwiftUI

@main
struct MemoryApp: App {
    @State private var store = MemoryStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .preferredColorScheme(.light)
        }
        .modelContainer(for: [ContactNote.self, ReminderRecord.self, AppSettings.self])
    }
}

#Preview("Welcome") {
    WelcomeView(isRequesting: false, onContinue: {})
}

#Preview("Updates") {
    NavigationStack {
        UpdatesView()
    }
    .environment(PreviewSupport.store())
    .modelContainer(PreviewSupport.container())
}

#Preview("Contacts") {
    NavigationStack {
        ContactsView()
    }
    .environment(PreviewSupport.store())
    .modelContainer(PreviewSupport.container())
}

#Preview("Person") {
    NavigationStack {
        PersonDetailView(person: .previewJordan)
    }
    .environment(PreviewSupport.store())
    .modelContainer(PreviewSupport.container())
}
