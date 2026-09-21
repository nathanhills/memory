import SwiftUI

struct WelcomeView: View {
    var isRequesting: Bool
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            AtmosphereBackground()
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                Text("Memory")
                    .font(.system(size: 56, weight: .regular, design: .serif))
                    .foregroundStyle(MemoryTheme.seaDeep)

                Text("Keep the people in your life close — notes, birthdays, and what to remember before you meet.")
                    .font(.system(.title2, design: .serif))
                    .foregroundStyle(MemoryTheme.ink)
                    .padding(.top, 20)

                Text("Connect iPhone Contacts and Calendar, jot notes about friends, and get reminded when it matters.")
                    .font(.title3)
                    .foregroundStyle(MemoryTheme.inkSoft)
                    .padding(.top, 12)

                Button(action: onContinue) {
                    Text(isRequesting ? "Connecting…" : "Continue")
                }
                .buttonStyle(SeaButtonStyle(disabled: isRequesting))
                .disabled(isRequesting)
                .padding(.top, 36)

                Text("We request read-only access to your contacts and calendar. Notes stay on this iPhone.")
                    .font(.footnote)
                    .foregroundStyle(MemoryTheme.inkSoft.opacity(0.85))
                    .padding(.top, 20)

                Spacer()
            }
            .padding(.horizontal, 28)
        }
    }
}
