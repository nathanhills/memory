import SwiftUI

struct WelcomeView: View {
    var isRequesting: Bool
    var onContinue: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            MemoryTheme.cream.ignoresSafeArea()

            Text("MEMORY")
                .font(.memory(120))
                .fontWidth(.condensed)
                .foregroundStyle(MemoryTheme.ink.opacity(0.06))
                .rotationEffect(.degrees(-8))
                .offset(x: 24, y: 80)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: -8) {
                        Text("Mem")
                        Text("ory")
                            .foregroundStyle(MemoryTheme.ink.opacity(0.28))
                    }
                    .memoryDisplay(64)
                    Spacer()
                    VStack(spacing: -6) {
                        LetterBadge(letter: "M", color: MemoryTheme.orange, size: 38)
                        LetterBadge(letter: "N", color: MemoryTheme.gold, size: 38)
                        LetterBadge(letter: "Y", color: MemoryTheme.sage, size: 38)
                    }
                }
                .padding(.top, 12)

                Text("Keep the people in your life close — notes, birthdays, and what to remember before you meet.")
                    .font(.memory(16, weight: .medium))
                    .foregroundStyle(MemoryTheme.ink.opacity(0.72))
                    .padding(.bottom, 8)

                MemoryCard(fill: MemoryTheme.orange, minHeight: 88) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes")
                                .memoryDisplay(24)
                            Text("What you want to remember")
                                .font(.memory(13, weight: .medium))
                                .foregroundStyle(MemoryTheme.ink.opacity(0.7))
                        }
                        Spacer()
                        Text("01")
                            .memoryDisplay(40)
                    }
                }

                MemoryCard(fill: MemoryTheme.sage, minHeight: 88) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Birthdays")
                                .memoryDisplay(24)
                            Text("And anniversaries, on this phone")
                                .font(.memory(13, weight: .medium))
                                .foregroundStyle(MemoryTheme.ink.opacity(0.7))
                        }
                        Spacer()
                        Text("02")
                            .memoryDisplay(40)
                    }
                }

                MemoryCard(fill: MemoryTheme.gray, minHeight: 88) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Before you meet")
                                .memoryDisplay(22)
                            Text("Calendar context, read-only")
                                .font(.memory(13, weight: .medium))
                                .foregroundStyle(MemoryTheme.ink.opacity(0.7))
                        }
                        Spacer()
                        Text("03")
                            .memoryDisplay(40)
                    }
                }

                Spacer(minLength: 8)

                Button(action: onContinue) {
                    MemoryCard(fill: MemoryTheme.paper, minHeight: 72) {
                        HStack {
                            Text(isRequesting ? "Connecting" : "Continue")
                                .memoryDisplay(28)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(MemoryTheme.ink)
                                .frame(width: 40, height: 40)
                                .background(MemoryTheme.coral, in: Circle())
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(isRequesting)
                .opacity(isRequesting ? 0.6 : 1)
                .accessibilityLabel(isRequesting ? "Connecting" : "Continue")

                Text("Notes stay on this iPhone. Contacts and Calendar are read-only.")
                    .font(.memory(12, weight: .medium))
                    .foregroundStyle(MemoryTheme.muted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 20)
        }
    }
}
