import SwiftUI
import UIKit

struct PersonAvatar: View {
    let person: Person
    var size: CGFloat = 40

    var body: some View {
        Group {
            if let data = person.thumbnail, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Text(person.initials)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.secondarySystemFill))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }
}

struct SyncToolbarButton: View {
    @Environment(MemoryStore.self) private var store
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Button {
            Task { await store.sync(context: modelContext) }
        } label: {
            if store.isSyncing {
                ProgressView()
            } else {
                Label("Sync", systemImage: "arrow.clockwise")
            }
        }
        .disabled(store.isSyncing)
        .accessibilityLabel("Sync contacts and calendar")
    }
}

struct ReminderRow: View {
    let reminder: ReminderRecord

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                HStack(spacing: 8) {
                    Text(reminder.kind.label)
                    Text(reminder.dueAt, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute())
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                if let body = reminder.body, !body.isEmpty {
                    Text(body)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }
        } icon: {
            Image(systemName: reminder.kind.systemImage)
                .foregroundStyle(.tint)
        }
    }
}
