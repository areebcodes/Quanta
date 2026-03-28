import SwiftUI
import PencilKit
import PDFKit
import UniformTypeIdentifiers

struct NoteEditorView: View {
    @ObservedObject var note: Note
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var drawingData: Data = Data()
    @State private var annotationsData: Data = Data()
    @State private var selectedTool: CanvasTool = .pen
    @State private var selectedColor: Color = .black
    @State private var canvasUndoManager: UndoManager?
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var showingSubjectPicker = false

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Subject.sortOrder, ascending: true)]
    )
    private var subjects: FetchedResults<Subject>

    var body: some View {
        VStack(spacing: 0) {
            canvas
            CanvasToolbar(
                selectedTool: $selectedTool,
                selectedColor: $selectedColor,
                onUndo: { canvasUndoManager?.undo() },
                onRedo: { canvasUndoManager?.redo() }
            )
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(QuantaTheme.topBarBg, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar { editorToolbar }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: shareItems)
        }
        .onAppear(perform: loadNoteData)
        .onDisappear(perform: saveAll)
        .onChange(of: drawingData) { _, _ in
            note.drawingData = drawingData
            note.updatedAt = Date()
            generateDrawingThumbnail()
            save()
        }
        .onChange(of: annotationsData) { _, _ in
            note.annotationsData = annotationsData
            note.updatedAt = Date()
            save()
        }
    }

    // MARK: - Canvas

    @ViewBuilder
    private var canvas: some View {
        if let pdfData = note.pdfData {
            PDFAnnotationView(
                pdfData: pdfData,
                annotationsData: $annotationsData,
                selectedTool: selectedTool,
                selectedColor: selectedColor,
                onUndoManagerReady: { canvasUndoManager = $0 }
            )
        } else {
            DrawingCanvasView(
                drawingData: $drawingData,
                selectedTool: selectedTool,
                selectedColor: selectedColor,
                onUndoManagerReady: { canvasUndoManager = $0 }
            )
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var editorToolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            TextField("Note Title", text: $title)
                .font(QuantaTheme.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .onChange(of: title) { _, newValue in
                    note.title = newValue
                    note.updatedAt = Date()
                    save()
                }
        }

        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: 12) {
                // Subject picker
                Menu {
                    Button {
                        note.subject = nil
                        save()
                    } label: {
                        Label("None", systemImage: note.subject == nil ? "checkmark" : "")
                    }
                    Divider()
                    ForEach(subjects, id: \.objectID) { subject in
                        Button {
                            note.subject = subject
                            save()
                        } label: {
                            Label(
                                "\(subject.emoji ?? "") \(subject.name ?? "")",
                                systemImage: note.subject?.objectID == subject.objectID ? "checkmark" : ""
                            )
                        }
                    }
                } label: {
                    if let subject = note.subject {
                        SubjectPill(subject: subject)
                    } else {
                        Image(systemName: "tag")
                            .font(.system(size: 15, weight: .medium))
                    }
                }

                // Export
                Button { exportNote() } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .medium))
                }
            }
        }
    }

    // MARK: - Data

    private func loadNoteData() {
        title = note.title ?? "Untitled"
        drawingData = note.drawingData ?? Data()
        annotationsData = note.annotationsData ?? Data()
    }

    private func save() { try? viewContext.save() }

    private func saveAll() {
        note.title = title
        note.drawingData = drawingData
        note.annotationsData = annotationsData
        note.updatedAt = Date()
        save()
    }

    // MARK: - Export

    private func exportNote() {
        var items: [Any] = []

        if let pdfData = note.pdfData {
            if let exported = exportAnnotatedPDF(pdfData: pdfData) {
                items.append(exported)
            }
        } else if !drawingData.isEmpty, let drawing = try? PKDrawing(data: drawingData) {
            let bounds = drawing.bounds
            if !bounds.isEmpty {
                items.append(drawing.image(from: bounds.insetBy(dx: -20, dy: -20), scale: 2.0))
            }
        }

        if !items.isEmpty {
            shareItems = items
            showingShareSheet = true
        }
    }

    private func exportAnnotatedPDF(pdfData: Data) -> Data? {
        guard let document = PDFDocument(data: pdfData), document.pageCount > 0 else { return nil }
        let annotations = PageAnnotations.decode(from: annotationsData)
        let defaultBounds = document.page(at: 0)!.bounds(for: .mediaBox)
        let renderer = UIGraphicsPDFRenderer(bounds: defaultBounds)
        return renderer.pdfData { context in
            for i in 0..<document.pageCount {
                guard let page = document.page(at: i) else { continue }
                let bounds = page.bounds(for: .mediaBox)
                context.beginPage(withBounds: bounds, pageInfo: [:])
                let cgContext = context.cgContext
                cgContext.saveGState()
                cgContext.translateBy(x: 0, y: bounds.height)
                cgContext.scaleBy(x: 1, y: -1)
                page.draw(with: .mediaBox, to: cgContext)
                cgContext.restoreGState()
                if let drawingDataForPage = annotations.pages[i],
                   let drawing = try? PKDrawing(data: drawingDataForPage) {
                    drawing.image(from: bounds, scale: 2.0).draw(in: bounds)
                }
            }
        }
    }

    // MARK: - Thumbnails

    private func generateDrawingThumbnail() {
        guard !drawingData.isEmpty, let drawing = try? PKDrawing(data: drawingData) else {
            note.thumbnailData = nil
            return
        }
        let bounds = drawing.bounds
        guard !bounds.isEmpty else { return }
        let targetSize = CGSize(width: 400, height: 300)
        let image = drawing.image(from: bounds, scale: 1.0)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let thumbnail = renderer.image { _ in
            UIColor.white.setFill()
            UIRectFill(CGRect(origin: .zero, size: targetSize))
            let scale = min(targetSize.width / image.size.width, targetSize.height / image.size.height)
            let w = image.size.width * scale
            let h = image.size.height * scale
            image.draw(in: CGRect(x: (targetSize.width - w) / 2, y: (targetSize.height - h) / 2, width: w, height: h))
        }
        note.thumbnailData = thumbnail.jpegData(compressionQuality: 0.7)
    }
}
