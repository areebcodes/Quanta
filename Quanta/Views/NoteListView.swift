import SwiftUI
import CoreData

struct NoteListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest private var notes: FetchedResults<Note>

    @Binding var selectedNote: Note?
    @State private var searchText = ""
    @State private var sortNewestFirst = true

    let subject: Subject?
    let showAll: Bool
    let title: String
    let subjectColor: Color?

    init(subject: Subject?, showAll: Bool, selectedNote: Binding<Note?>) {
        self.subject = subject
        self.showAll = showAll
        self._selectedNote = selectedNote

        let request = Note.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Note.updatedAt, ascending: false)]
        if !showAll, let subject {
            request.predicate = NSPredicate(format: "subject == %@", subject)
            self.title = subject.name ?? "Notes"
            self.subjectColor = QuantaTheme.color(for: subject.colorName ?? "blue")
        } else {
            self.title = "All Notes"
            self.subjectColor = nil
        }
        _notes = FetchRequest(fetchRequest: request)
    }

    private var filteredNotes: [Note] {
        let base = searchText.isEmpty
            ? Array(notes)
            : notes.filter { ($0.title ?? "").localizedCaseInsensitiveContains(searchText) }
        return sortNewestFirst ? base : base.reversed()
    }

    var body: some View {
        Group {
            if notes.isEmpty {
                emptyState
            } else {
                noteList
            }
        }
        .navigationTitle(title)
        .searchable(text: $searchText, prompt: "Search notes")
        .toolbar { listToolbar }
    }

    // MARK: - Note List

    private var noteList: some View {
        List(selection: $selectedNote) {
            ForEach(filteredNotes, id: \.objectID) { note in
                NoteCardView(note: note, accentColor: subjectColor)
                    .tag(note)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
                    .contextMenu {
                        Button {
                            duplicateNote(note)
                        } label: {
                            Label("Duplicate", systemImage: "doc.on.doc")
                        }

                        if !showAll {
                            Button {
                                note.subject = nil
                                try? viewContext.save()
                            } label: {
                                Label("Remove from Subject", systemImage: "folder.badge.minus")
                            }
                        }

                        Divider()

                        Button(role: .destructive) {
                            deleteNote(note)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Notes Yet", systemImage: "pencil.tip.crop.circle")
                .font(QuantaTheme.title)
        } description: {
            Text("Tap + to create your first note")
                .font(QuantaTheme.subheadline)
        } actions: {
            Button(action: createNote) {
                Label("Create Note", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .buttonBorderShape(.capsule)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var listToolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(action: createNote) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
            }
        }
        ToolbarItem(placement: .secondaryAction) {
            Menu {
                Button {
                    withAnimation { sortNewestFirst = true }
                } label: {
                    Label("Newest First", systemImage: sortNewestFirst ? "checkmark" : "")
                }
                Button {
                    withAnimation { sortNewestFirst = false }
                } label: {
                    Label("Oldest First", systemImage: !sortNewestFirst ? "checkmark" : "")
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down.circle")
                    .symbolRenderingMode(.hierarchical)
            }
        }
    }

    // MARK: - Actions

    private func createNote() {
        withAnimation(.spring(response: 0.35)) {
            let note = Note(context: viewContext)
            note.id = UUID()
            note.title = "Untitled"
            note.createdAt = Date()
            note.updatedAt = Date()
            if !showAll {
                note.subject = subject
            }
            try? viewContext.save()
            selectedNote = note
        }
    }

    private func duplicateNote(_ note: Note) {
        withAnimation {
            let copy = Note(context: viewContext)
            copy.id = UUID()
            copy.title = "\(note.title ?? "Untitled") Copy"
            copy.createdAt = Date()
            copy.updatedAt = Date()
            copy.drawingData = note.drawingData
            copy.pdfData = note.pdfData
            copy.annotationsData = note.annotationsData
            copy.thumbnailData = note.thumbnailData
            copy.canvasStyle = note.canvasStyle
            copy.subject = note.subject
            try? viewContext.save()
        }
    }

    private func deleteNote(_ note: Note) {
        withAnimation(.spring(response: 0.3)) {
            if selectedNote == note {
                selectedNote = nil
            }
            viewContext.delete(note)
            try? viewContext.save()
        }
    }
}
