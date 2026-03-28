import SwiftUI
import CoreData
import PDFKit
import UniformTypeIdentifiers

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var path: NavigationPath

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Note.updatedAt, ascending: false)],
        animation: .spring(response: 0.35)
    )
    private var notes: FetchedResults<Note>

    @State private var searchText = ""
    @State private var showPDFImporter = false

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    private var filteredNotes: [Note] {
        if searchText.isEmpty { return Array(notes) }
        return notes.filter { ($0.title ?? "").localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ZStack {
            // Background
            QuantaTheme.darkBg.ignoresSafeArea()

            if notes.isEmpty {
                emptyState
            } else {
                noteGrid
            }

            // Floating + button
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
        .navigationBarHidden(true)
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
                .padding(.bottom, 100) // space for FAB
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Quanta")
                .font(.system(size: 48, weight: .heavy, design: .rounded))
                .foregroundStyle(QuantaTheme.gold)

            Text("Your notes live here")
                .font(QuantaTheme.subheadline)
                .foregroundStyle(.white.opacity(0.5))

            Menu {
                Button { createNote() } label: {
                    Label("New Note", systemImage: "pencil.tip")
                }
                Button { showPDFImporter = true } label: {
                    Label("Import PDF", systemImage: "doc.badge.plus")
                }
            } label: {
                Text("Create")
                    .font(QuantaTheme.headline)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(QuantaTheme.gold, in: Capsule())
            }
            .padding(.top, 8)

            Spacer()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Quanta")
                .font(QuantaTheme.wordmark)
                .foregroundStyle(QuantaTheme.gold)
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
