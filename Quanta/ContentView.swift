import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var sidebarSelection: SidebarItem? = .allNotes
    @State private var selectedNote: Note?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    private var selectedSubject: Subject? {
        guard case .subject(let objectID) = sidebarSelection else { return nil }
        return try? viewContext.existingObject(with: objectID) as? Subject
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SubjectListView(selection: $sidebarSelection)
        } content: {
            NoteListView(
                subject: selectedSubject,
                showAll: sidebarSelection == .allNotes,
                selectedNote: $selectedNote
            )
        } detail: {
            if let note = selectedNote {
                NoteEditorView(note: note)
            } else {
                emptyDetail
            }
        }
        .navigationSplitViewStyle(.balanced)
        .tint(.accentColor)
    }

    private var emptyDetail: some View {
        VStack(spacing: 16) {
            Image(systemName: "pencil.tip.crop.circle")
                .font(.system(size: 56))
                .foregroundStyle(.quaternary)
                .symbolRenderingMode(.hierarchical)
            Text("Select a Note")
                .font(QuantaTheme.title)
                .foregroundStyle(.secondary)
            Text("Choose a note from the list or create a new one")
                .font(QuantaTheme.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}
