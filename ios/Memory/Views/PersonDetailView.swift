import SwiftData
import SwiftUI

struct PersonDetailView: View {
    @Environment(MemoryStore.self) private var store
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
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
                HStack(alignment: .top, spacing: 12) {
                    CircleIconButton(systemName: "arrow.left", fill: MemoryTheme.gray) {
                        dismiss()
                    }
                    .accessibilityLabel("Back")
                    Spacer()
                    CircleIconButton(systemName: "square.and.pencil", fill: MemoryTheme.orange) {
                        showingComposer = true
                    }
                    .accessibilityLabel("Add Note")
                }
                .memoryListRow()

                MemoryCard(fill: person.badgeColor, minHeight: 168) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: -4) {
                                Text(person.givenName.isEmpty ? person.displayName : person.givenName)
                                    .memoryDisplay(40)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                                if !person.familyName.isEmpty {
                                    Text(person.familyName)
                                        .memoryDisplay(40)
                                        .foregroundStyle(MemoryTheme.ink.opacity(0.28))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.6)
                                }
                            }
                            Spacer()
                            Text(person.primaryLetter)
                                .memoryDisplay(72)
                        }

                        if let email = person.emails.first {
                            Text(email)
                                .font(.memory(14, weight: .semibold))
                                .foregroundStyle(MemoryTheme.ink.opacity(0.7))
                        }
                        if let birthday = person.birthdayLabel {
                            Text(birthday.uppercased())
                                .font(.memory(12, weight: .heavy))
                                .fontWidth(.condensed)
                                .tracking(0.8)
                                .foregroundStyle(MemoryTheme.ink)
                        }
                    }
                }
                .memoryListRow()
            }

            Section {
                SectionWord(text: "Notes")
                    .memoryListRow()

                Button {
                    showingComposer = true
                } label: {
                    MemoryCard(fill: MemoryTheme.orange, minHeight: 72) {
                        HStack {
                            Text("Add note")
                                .memoryDisplay(24)
                            Spacer()
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .frame(width: 36, height: 36)
                                .background(MemoryTheme.paper.opacity(0.55), in: Circle())
                                .foregroundStyle(MemoryTheme.ink)
                        }
                    }
                }
                .buttonStyle(.plain)
                .memoryListRow()

                if notes.isEmpty {
                    EmptyEditorialCard(
                        title: "No notes\nyet",
                        subtitle: "Write something you want to remember the next time you see them.",
                        count: "0",
                        fill: MemoryTheme.gray
                    )
                    .memoryListRow()
                } else {
                    ForEach(notes, id: \.id) { note in
                        MemoryCard(fill: MemoryTheme.paper, minHeight: 96) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(note.body)
                                    .font(.memory(16, weight: .semibold))
                                    .foregroundStyle(MemoryTheme.ink)
                                HStack {
                                    Text(note.createdAt, format: .dateTime.month().day().year())
                                    if let remindAt = note.remindAt {
                                        Text("Remind \(remindAt.formatted(.dateTime.month().day().hour().minute()))")
                                    }
                                }
                                .font(.memory(12, weight: .bold))
                                .fontWidth(.condensed)
                                .foregroundStyle(MemoryTheme.muted)
                            }
                        }
                        .memoryListRow()
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button("Delete", role: .destructive) {
                                store.deleteNote(note, context: modelContext)
                            }
                        }
                    }
                }
            }

            Section {
                SectionWord(text: "Together")
                    .memoryListRow()

                if sharedEvents.isEmpty {
                    EmptyEditorialCard(
                        title: "No shared\nevents",
                        subtitle: "Upcoming calendar events that match this person will land here.",
                        count: "0",
                        fill: MemoryTheme.gray
                    )
                    .memoryListRow()
                } else {
                    ForEach(Array(sharedEvents.enumerated()), id: \.element.id) { index, event in
                        MemoryCard(fill: index.isMultiple(of: 2) ? MemoryTheme.sage : MemoryTheme.stone, minHeight: 100) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("EVENT")
                                        .font(.memory(12, weight: .heavy))
                                        .fontWidth(.condensed)
                                        .tracking(0.8)
                                    Text(event.title)
                                        .memoryDisplay(24)
                                        .lineLimit(2)
                                    Text(event.start, format: .dateTime.month().day().hour().minute())
                                        .font(.memory(13, weight: .bold))
                                        .fontWidth(.condensed)
                                        .foregroundStyle(MemoryTheme.ink.opacity(0.65))
                                }
                                Spacer()
                                Text(String(Calendar.current.component(.day, from: event.start)))
                                    .memoryDisplay(52)
                            }
                        }
                        .memoryListRow()
                    }
                }
            }
        }
        .listStyle(.plain)
        .listSectionSeparator(.hidden)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .memoryBackground()
        .navigationTitle(person.displayName)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
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
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: -4) {
                            Text("New")
                            Text("Note")
                                .foregroundStyle(MemoryTheme.ink.opacity(0.28))
                        }
                        .memoryDisplay(40)
                        Spacer()
                        CircleIconButton(systemName: "xmark", fill: MemoryTheme.gray) {
                            dismiss()
                        }
                        .accessibilityLabel("Cancel")
                    }
                    .memoryListRow()
                }

                Section {
                    MemoryCard(fill: person.badgeColor, minHeight: 160) {
                        TextField("Something you want to remember", text: $draft, axis: .vertical)
                            .font(.memory(22, weight: .semibold))
                            .fontWidth(.condensed)
                            .foregroundStyle(MemoryTheme.ink)
                            .lineLimit(4...10)
                    }
                    .memoryListRow()

                    MemoryCard(fill: MemoryTheme.gold, minHeight: 88) {
                        Toggle(isOn: $includeReminder) {
                            Text("Remind me")
                                .memoryDisplay(22)
                        }
                        .tint(MemoryTheme.ink)
                    }
                    .memoryListRow()

                    if includeReminder {
                        MemoryCard(fill: MemoryTheme.paper, minHeight: 72) {
                            DatePicker("Date", selection: $remindAt)
                                .font(.memory(16, weight: .heavy))
                                .fontWidth(.condensed)
                                .foregroundStyle(MemoryTheme.ink)
                                .tint(MemoryTheme.orange)
                        }
                        .memoryListRow()
                    }

                    Button {
                        save()
                    } label: {
                        MemoryCard(fill: canSave ? MemoryTheme.orange : MemoryTheme.gray, minHeight: 72) {
                            HStack {
                                Text("Save")
                                    .memoryDisplay(26)
                                Spacer()
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .frame(width: 36, height: 36)
                                    .background(MemoryTheme.paper.opacity(0.55), in: Circle())
                                    .foregroundStyle(MemoryTheme.ink)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.55)
                    .accessibilityLabel("Save")
                    .memoryListRow()
                }
            }
            .listStyle(.plain)
            .listSectionSeparator(.hidden)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .memoryBackground()
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(MemoryTheme.cream)
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

private extension View {
    func memoryListRow() -> some View {
        listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}
