import SwiftUI
import UIKit

extension ReminderKind {
    var cardFill: Color {
        switch self {
        case .noteDue: MemoryTheme.orange
        case .birthday: MemoryTheme.sage
        case .anniversary: MemoryTheme.lavender
        case .preEvent: MemoryTheme.gray
        }
    }
}

struct PersonAvatar: View {
    let person: Person
    var size: CGFloat = 40

    var body: some View {
        Group {
            if let data = person.thumbnail, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay {
                        Circle().stroke(MemoryTheme.paper, lineWidth: 3)
                    }
            } else {
                LetterBadge(letter: person.primaryLetter, color: person.badgeColor, size: size)
            }
        }
        .accessibilityHidden(true)
    }
}

struct SyncToolbarButton: View {
    @Environment(MemoryStore.self) private var store
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        CircleIconButton(
            systemName: store.isSyncing ? "arrow.triangle.2.circlepath" : "arrow.up.right",
            fill: MemoryTheme.coral
        ) {
            Task { await store.sync(context: modelContext) }
        }
        .disabled(store.isSyncing)
        .accessibilityLabel("Sync contacts and calendar")
        .opacity(store.isSyncing ? 0.55 : 1)
    }
}

struct ReminderCard: View {
    let reminder: ReminderRecord
    var person: Person?

    var body: some View {
        MemoryCard(fill: reminder.kind.cardFill, minHeight: 132) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        LetterBadge(
                            letter: person?.primaryLetter ?? String(reminder.kind.editorialLabel.prefix(1)),
                            color: person?.badgeColor ?? MemoryTheme.gold,
                            size: 28
                        )
                        Text(reminder.kind.editorialLabel)
                            .font(.memory(13, weight: .heavy))
                            .fontWidth(.condensed)
                            .tracking(0.8)
                            .foregroundStyle(MemoryTheme.ink)
                    }

                    Text(person?.displayName ?? reminder.title)
                        .memoryDisplay(26)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)

                    if let body = reminder.body, !body.isEmpty {
                        Text(body)
                            .font(.memory(14, weight: .medium))
                            .foregroundStyle(MemoryTheme.ink.opacity(0.72))
                            .lineLimit(2)
                    }

                    Text(reminder.dueAt, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute())
                        .font(.memory(12, weight: .bold))
                        .fontWidth(.condensed)
                        .foregroundStyle(MemoryTheme.ink.opacity(0.55))
                }
                Spacer(minLength: 8)
                Text(reminder.dueDayNumber)
                    .memoryDisplay(64)
                    .padding(.top, 8)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        let who = person?.displayName ?? reminder.title
        return "\(reminder.kind.label), \(who), \(reminder.title)"
    }
}

struct ContactCard: View {
    let person: Person
    var noteCount: Int
    var fill: Color

    var body: some View {
        MemoryCard(fill: fill, minHeight: 96) {
            HStack(alignment: .center, spacing: 12) {
                PersonAvatar(person: person, size: 44)
                VStack(alignment: .leading, spacing: 4) {
                    Text(person.displayName)
                        .memoryDisplay(24)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(subtitle)
                        .font(.memory(13, weight: .medium))
                        .foregroundStyle(MemoryTheme.ink.opacity(0.58))
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                Text(person.primaryLetter)
                    .memoryDisplay(52)
                    .opacity(0.92)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(person.displayName)
        .accessibilityHint(subtitle)
    }

    private var subtitle: String {
        var parts: [String] = []
        if noteCount > 0 {
            parts.append(noteCount == 1 ? "1 note" : "\(noteCount) notes")
        }
        if let birthday = person.birthdayLabel {
            parts.append(birthday)
        } else if let email = person.emails.first {
            parts.append(email)
        }
        return parts.isEmpty ? "No notes yet" : parts.joined(separator: " · ")
    }
}

struct EmptyEditorialCard: View {
    var title: String
    var subtitle: String
    var count: String = "0"
    var fill: Color = MemoryTheme.gray
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        MemoryCard(fill: fill, minHeight: 160) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    Text(title)
                        .memoryDisplay(32)
                        .lineLimit(2)
                    Spacer()
                    Text(count)
                        .memoryDisplay(64)
                }
                Text(subtitle)
                    .font(.memory(15, weight: .medium))
                    .foregroundStyle(MemoryTheme.ink.opacity(0.65))
                if let actionTitle, let action {
                    Button(action: action) {
                        HStack {
                            Text(actionTitle)
                                .font(.memory(16, weight: .heavy))
                                .fontWidth(.condensed)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 13, weight: .bold))
                                .frame(width: 28, height: 28)
                                .background(MemoryTheme.ink.opacity(0.12), in: Circle())
                        }
                        .foregroundStyle(MemoryTheme.ink)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
            }
        }
    }
}

struct MemoryTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 10) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    selection = tab
                } label: {
                    HStack(spacing: 10) {
                        Text(tab.badge)
                            .font(.memory(16))
                            .fontWidth(.condensed)
                            .foregroundStyle(MemoryTheme.ink)
                            .frame(width: 34, height: 34)
                            .background(tab.color, in: Circle())
                        Text(tab.title)
                            .font(.memory(16, weight: .heavy))
                            .fontWidth(.condensed)
                            .foregroundStyle(selection == tab ? MemoryTheme.ink : MemoryTheme.muted)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        selection == tab ? MemoryTheme.paper : Color.clear,
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selection == tab ? .isSelected : AccessibilityTraits())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(MemoryTheme.cream)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(MemoryTheme.ink.opacity(0.08))
                .frame(height: 1)
        }
    }
}

struct HeaderActionCluster: View {
    var onSettings: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            SyncToolbarButton()
            if let onSettings {
                CircleIconButton(systemName: "slider.horizontal.3", fill: MemoryTheme.gold, action: onSettings)
                    .accessibilityLabel("Settings")
            }
        }
    }
}
