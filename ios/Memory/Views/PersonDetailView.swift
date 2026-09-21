import SwiftData
import SwiftUI

struct PersonDetailView: View {
    @Environment(MemoryStore.self) private var store
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ContactNote.createdAt, order: .reverse) private var allNotes: [ContactNote]

    let person: Person
    @State private var showingComposer = false

    private var notes: [ContactNote] {
        allNotes.filter { $0.contactIdentifier == person.id }
    }

    private var sharedEvents: [CalendarOccurrence] {
        store.upcomingEvents(matching: person)
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    PersonAvatar(person: person, size: 56)
                    VStack(alignment: .leading, spacing: 4) {
                        if let email = person.emails.first {
                            Text(email)
                                .foregroundStyle(.secondary)
                        }
                        if let birthday = person.birthdayLabel {
                            Text(birthday)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Notes") {
                Button {
                    showingComposer = true
                } label: {
                    Label("Add Note", systemImage: "plus")
                }

                if notes.isEmpty {
                    Text("No notes yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(notes, id: \.id) { note in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(note.body)
                            HStack {
                                Text(note.createdAt, format: .dateTime.month().day().year())
                                if let remindAt = note.remindAt {
                                    Text(remindAt, format: .dateTime.month().day().hour().minute())
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button("Delete", role: .destructive) {
                                store.deleteNote(note, context: modelContext)
                            }
                        }
                    }
                }
            }

            Section("Upcoming Together") {
                if sharedEvents.isEmpty {
                    Text("No matching calendar events.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sharedEvents) { event in
                        LabeledContent(event.title) {
                            Text(event.start, format: .dateTime.month().day().hour().minute())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(person.displayName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingComposer = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .accessibilityLabel("Add Note")
            }
        }
        .sheet(isPresented: $showingComposer) {
            NoteComposerView(person: person)
        }
    }
}

struct NoteComposerView: View {
    @Environment(MemoryStore.self) private var store
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let person: Person
    @State private var draft = ""
    @State private var includeReminder = false
    @State private var remindAt = Date()

    private var canSave: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Note") {
                    TextField("Something you want to remember", text: $draft, axis: .vertical)
                        .lineLimit(3...8)
                }
                Section {
                    Toggle("Remind Me", isOn: $includeReminder)
                    if includeReminder {
                        DatePicker("Date", selection: $remindAt)
                    }
                }
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        save()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSave)
                    .accessibilityLabel("Save")
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func save() {
        let body = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }
        store.addNote(
            contactIdentifier: person.id,
            body: body,
            remindAt: includeReminder ? remindAt : nil,
            context: modelContext
        )
        dismiss()
    }
}
