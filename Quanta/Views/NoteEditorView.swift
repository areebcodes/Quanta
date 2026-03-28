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
    @State private var selectedSize: ToolSize = .medium
    @State private var canvasUndoManager: UndoManager?
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var currentPage = 1
    @State private var totalPages = 3

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Subject.sortOrder, ascending: true)]
    )
    private var subjects: FetchedResults<Subject>

    var body: some View {
        VStack(spacing: 0) {
            // Canvas area with page indicator
            ZStack(alignment: .bottom) {
                canvas

                // Page indicator
                if note.pdfData == nil {
                    pageIndicator
                        .padding(.bottom, 8)
                }
            }

            // Toolbar
            CanvasToolbar(
                selectedTool: $selectedTool,
                selectedColor: $selectedColor,
                selectedSize: $selectedSize,
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
            generateThumbnail()
            save()
        }
        .onChange(of: annotationsData) { _, _ in
            note.annotationsData = annotationsData
            note.updatedAt = Date()
            save()
        }
    }

    // MARK: - Page Indicator

    private var pageIndicator: some View {
        Text("Page \(currentPage) of \(totalPages)")
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.6))
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(.black.opacity(0.5), in: Capsule())
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
                selectedSize: selectedSize,
                onUndoManagerReady: { canvasUndoManager = $0 }
            )
        } else {
            DrawingCanvasView(
                drawingData: $drawingData,
                selectedTool: selectedTool,
                selectedColor: selectedColor,
                selectedSize: selectedSize,
                onUndoManagerReady: { canvasUndoManager = $0 },
                onPageChange: { page, total in
                    currentPage = page + 1
                    totalPages = total
                }
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
        } else if !drawingData.isEmpty {
            if let exported = exportPaginatedDrawing() {
                items.append(exported)
            }
        }

        if !items.isEmpty {
            shareItems = items
            showingShareSheet = true
        }
    }

    private func exportPaginatedDrawing() -> Data? {
        guard let drawing = try? PKDrawing(data: drawingData) else { return nil }

        let screenWidth = UIScreen.main.bounds.width
        let margin: CGFloat = 40
        let canvasPageWidth = screenWidth - margin * 2
        let canvasPageHeight = canvasPageWidth * QuantaTheme.pageRatio
        let gap = QuantaTheme.pageGap
        let xOffset = (screenWidth - canvasPageWidth) / 2

        // Letter size in points
        let letterWidth: CGFloat = 612
        let letterHeight: CGFloat = 792
        let pageBounds = CGRect(x: 0, y: 0, width: letterWidth, height: letterHeight)

        let maxY = drawing.bounds.maxY
        let exportPageCount = max(1, Int(ceil((maxY - gap) / (canvasPageHeight + gap))) + 1)

        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds)
        return renderer.pdfData { context in
            for i in 0..<exportPageCount {
                context.beginPage()
                let pageTop = gap + CGFloat(i) * (canvasPageHeight + gap)
                let clipRect = CGRect(x: xOffset, y: pageTop, width: canvasPageWidth, height: canvasPageHeight)
                let image = drawing.image(from: clipRect, scale: 2.0)
                image.draw(in: pageBounds)
            }
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
                   let pageDrawing = try? PKDrawing(data: drawingDataForPage) {
                    pageDrawing.image(from: bounds, scale: 2.0).draw(in: bounds)
                }
            }
        }
    }

    // MARK: - Thumbnails

    private func generateThumbnail() {
        guard !drawingData.isEmpty, let drawing = try? PKDrawing(data: drawingData) else {
            note.thumbnailData = nil
            return
        }

        // Capture first page area
        let screenWidth = UIScreen.main.bounds.width
        let margin: CGFloat = 40
        let canvasPageWidth = screenWidth - margin * 2
        let canvasPageHeight = canvasPageWidth * QuantaTheme.pageRatio
        let gap = QuantaTheme.pageGap
        let xOffset = (screenWidth - canvasPageWidth) / 2
        let firstPageRect = CGRect(x: xOffset, y: gap, width: canvasPageWidth, height: canvasPageHeight)

        let image = drawing.image(from: firstPageRect, scale: 1.0)
        let targetSize = CGSize(width: 400, height: 300)
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
