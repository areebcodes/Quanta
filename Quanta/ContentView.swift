import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var path = NavigationPath()
    @State private var selectedSubject: Subject?

    var body: some View {
        NavigationStack(path: $path) {
            NavigationSplitView {
                SidebarView(selectedSubject: $selectedSubject)
            } detail: {
                NoteGridView(selectedSubject: selectedSubject, path: $path)
            }
            .navigationSplitViewStyle(.balanced)
            .navigationDestination(for: NSManagedObjectID.self) { objectID in
                if let note = try? viewContext.existingObject(with: objectID) as? Note {
                    NoteEditorView(note: note)
                }
            }
        }
        .tint(QuantaTheme.gold)
        .preferredColorScheme(.dark)
    }
}
