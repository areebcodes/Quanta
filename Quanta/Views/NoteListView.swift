import SwiftUI
import CoreData

struct NoteListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Note.updatedAt, ascending: false)],
        animation: .spring(response: 0.3)
    )
    private var notes: FetchedResults<Note>

    @State private var searchText = ""
    @State private var navigateToNote: Note?

    private let columns = [
        GridItem(.adaptive(minimum: 220, maximum: 300), spacing: 24)
    ]

    var filteredNotes: [Note] {
        if searchText.isEmpty { return Array(notes) }
        return notes.filter { ($0.title ?? "").localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if notes.isEmpty {
                    emptyState
                } else {
                    gridContent
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Quanta")
            .searchable(text: $searchText, prompt: "Search notes")
            .navigationDestination(for: Note.self) { note in
                NoteEditorView(note: note)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: createNote) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
        }
    }

    private var gridContent: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(filteredNotes, id: \.objectID) { note in
                    NavigationLink(value: note) {
                        NoteCardView(note: note)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            renameNote(note)
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }
                        Divider()
                        Button(role: .destructive) {
                            deleteNote(note)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(24)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Notes Yet", systemImage: "pencil.tip.crop.circle")
                .font(.title2)
        } description: {
            Text("Tap + to create your first note")
        } actions: {
            Button("Create Note", action: createNote)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
    }

    private func createNote() {
        withAnimation(.spring(response: 0.3)) {
            let note = Note(context: viewContext)
            note.id = UUID()
            note.title = "Untitled"
            note.createdAt = Date()
            note.updatedAt = Date()
            try? viewContext.save()
        }
    }

    private func deleteNote(_ note: Note) {
        withAnimation(.spring(response: 0.3)) {
            viewContext.delete(note)
            try? viewContext.save()
        }
    }

    private func renameNote(_ note: Note) {
        // Rename is handled inline via NoteEditorView title field
    }
}
