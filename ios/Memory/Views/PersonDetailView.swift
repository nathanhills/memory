import SwiftData
import SwiftUI

struct PersonDetailView: View {
    @Environment(MemoryStore.self) private var store
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ContactNote.createdAt, order: .reverse) private var allNotes: [ContactNote]

    let person: Person

    @State private var draft = ""
    @State private var remindAt = Date()
    @State private var includeReminder = false

    private var notes: [ContactNote] {
        allNotes.filter { $0.contactIdentifier == person.id }
    }

    private var sharedEvents: [CalendarOccurrence] {
        store.upcomingEvents(matching: person)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                header
                notesSection
                eventsSection
            }
            .padding(24)
        }
        .background { AtmosphereBackground() }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            PersonAvatar(person: person, size: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text(person.displayName)
                    .font(.system(.largeTitle, design: .serif))
                    .foregroundStyle(MemoryTheme.ink)
                if let email = person.emails.first {
                    Text(email)
                        .foregroundStyle(MemoryTheme.inkSoft)
                }
                if let birthday = person.birthdayLabel {
                    Text(birthday)
                        .font(.subheadline)
                        .foregroundStyle(MemoryTheme.sea)
                }
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notes")
                .font(.system(.title2, design: .serif))

            VStack(alignment: .leading, spacing: 10) {
                Text("New note")
                    .font(.subheadline)
                    .foregroundStyle(MemoryTheme.inkSoft)
                TextField("Something you want to remember…", text: $draft, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(.white.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(MemoryTheme.ink.opacity(0.12), lineWidth: 1)
                    )

                Toggle("Remind me on a date", isOn: $includeReminder)
                    .foregroundStyle(MemoryTheme.inkSoft)
                if includeReminder {
                    DatePicker("Remind me on", selection: $remindAt)
                        .labelsHidden()
                }

                Button {
                    let body = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !body.isEmpty else { return }
                    store.addNote(
                        contactIdentifier: person.id,
                        body: body,
                        remindAt: includeReminder ? remindAt : nil,
                        context: modelContext
                    )
                    draft = ""
                    includeReminder = false
                } label: {
                    Text("Save note")
                }
                .buttonStyle(SeaButtonStyle(disabled: draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if notes.isEmpty {
                Text("No notes yet. Capture something worth remembering.")
                    .font(.subheadline)
                    .foregroundStyle(MemoryTheme.inkSoft)
            } else {
                ForEach(notes, id: \.id) { note in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(note.body)
                            .foregroundStyle(MemoryTheme.ink)
                        HStack(spacing: 12) {
                            Text(note.createdAt.formatted(.dateTime.month().day().year()))
                            if let remindAt = note.remindAt {
                                Text("Remind \(remindAt.formatted(.dateTime.month().day().year().hour().minute()))")
                                    .foregroundStyle(MemoryTheme.coral)
                            }
                            Button("Delete", role: .destructive) {
                                store.deleteNote(note, context: modelContext)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(MemoryTheme.inkSoft)
                    }
                    .padding(.bottom, 12)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(MemoryTheme.ink.opacity(0.1))
                            .frame(height: 1)
                    }
                }
            }
        }
    }

    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming together")
                .font(.system(.title2, design: .serif))
            if sharedEvents.isEmpty {
                Text("No upcoming calendar events with matching attendees.")
                    .font(.subheadline)
                    .foregroundStyle(MemoryTheme.inkSoft)
            } else {
                ForEach(sharedEvents) { event in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(.headline)
                        Text(event.start.formatted(.dateTime.month().day().hour().minute()))
                            .font(.subheadline)
                            .foregroundStyle(MemoryTheme.inkSoft)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
    }
}
