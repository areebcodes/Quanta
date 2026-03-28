import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            DashboardView(path: $path)
                .navigationDestination(for: NSManagedObjectID.self) { objectID in
                    if let note = try? viewContext.existingObject(with: objectID) as? Note {
                        NoteEditorView(note: note)
                    }
                }
        }
        .tint(QuantaTheme.gold)
    }
}
