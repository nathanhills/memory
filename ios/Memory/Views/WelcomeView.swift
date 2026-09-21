import SwiftUI

struct WelcomeView: View {
    var isRequesting: Bool
    var onContinue: () -> Void

    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("Memory", systemImage: "person.crop.circle.badge.clock")
            } description: {
                Text("Keep notes, birthdays, and context for the people in your life. Memory uses Contacts and Calendar on this iPhone.")
            } actions: {
                Button(isRequesting ? "Connecting…" : "Continue") {
                    onContinue()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isRequesting)
            }
            .padding()
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Text("Notes stay on this iPhone. Contacts and Calendar are read-only.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
    }
}
