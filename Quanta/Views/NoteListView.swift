import SwiftUI
import CoreData
import PDFKit
import UniformTypeIdentifiers

struct NoteGridView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let selectedSubject: Subject?
    @Binding var path: NavigationPath

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Note.updatedAt, ascending: false)],
        animation: .spring(response: 0.35)
    )
    private var allNotes: FetchedResults<Note>

    @State private var searchText = ""
    @State private var showPDFImporter = false

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    private var filteredNotes: [Note] {
        var notes = Array(allNotes)
        if let subject = selectedSubject {
            notes = notes.filter { $0.subject?.objectID == subject.objectID }
        }
        if !searchText.isEmpty {
            notes = notes.filter { ($0.title ?? "").localizedCaseInsensitiveContains(searchText) }
        }
        return notes
    }

    private var headerTitle: String {
        if let subject = selectedSubject {
            return "\(subject.emoji ?? "") \(subject.name ?? "")"
        }
        return "All Notes"
    }

    var body: some View {
        ZStack {
            QuantaTheme.darkBg.ignoresSafeArea()

            if filteredNotes.isEmpty && searchText.isEmpty {
                emptyState
            } else {
                noteGrid
            }

            // FAB
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    fabButton
                        .padding(.trailing, 28)
                        .padding(.bottom, 28)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .fileImporter(isPresented: $showPDFImporter, allowedContentTypes: [.pdf]) { result in
            importPDF(result: result)
        }
    }

    // MARK: - Grid

    private var noteGrid: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                searchBar

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(filteredNotes, id: \.objectID) { note in
                        Button {
                            path.append(note.objectID)
                        } label: {
                            NoteCardView(note: note)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteNote(note)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "note.text")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.15))

            Text("No notes yet")
                .font(QuantaTheme.headline)
                .foregroundStyle(.white.opacity(0.4))

            Text("Tap + to create one")
                .font(QuantaTheme.subheadline)
                .foregroundStyle(.white.opacity(0.25))
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text(headerTitle)
                .font(QuantaTheme.title)
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.4))
            TextField("Search notes", text: $searchText)
                .foregroundStyle(.white)
                .font(QuantaTheme.body)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(QuantaTheme.searchBg, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    // MARK: - FAB

    private var fabButton: some View {
        Menu {
            Button { createNote() } label: {
                Label("New Note", systemImage: "pencil.tip")
            }
            Button { showPDFImporter = true } label: {
                Label("Import PDF", systemImage: "doc.badge.plus")
            }
        } label: {
            Image(systemName: "plus")
                .font(.title2.bold())
                .foregroundStyle(.black)
                .frame(width: 60, height: 60)
                .background(QuantaTheme.gold, in: Circle())
                .shadow(color: QuantaTheme.gold.opacity(0.4), radius: 16, y: 6)
        }
    }

    // MARK: - Actions

    private func createNote() {
        let note = Note(context: viewContext)
        note.id = UUID()
        note.title = "Untitled"
        note.createdAt = Date()
        note.updatedAt = Date()
        note.subject = selectedSubject
        try? viewContext.save()
        path.append(note.objectID)
    }

    private func importPDF(result: Result<URL, Error>) {
        guard case .success(let url) = result else { return }
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        guard let data = try? Data(contentsOf: url) else { return }

        let note = Note(context: viewContext)
        note.id = UUID()
        note.title = url.deletingPathExtension().lastPathComponent
        note.createdAt = Date()
        note.updatedAt = Date()
        note.pdfData = data
        note.subject = selectedSubject

        if let doc = PDFDocument(data: data), let page = doc.page(at: 0) {
            let thumb = page.thumbnail(of: CGSize(width: 400, height: 300), for: .mediaBox)
            note.thumbnailData = thumb.jpegData(compressionQuality: 0.7)
        }

        try? viewContext.save()
        path.append(note.objectID)
    }

    private func deleteNote(_ note: Note) {
        withAnimation {
            viewContext.delete(note)
            try? viewContext.save()
        }
    }
}
