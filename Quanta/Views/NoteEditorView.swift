import SwiftUI
import PencilKit
import PDFKit
import UniformTypeIdentifiers

struct NoteEditorView: View {
    @ObservedObject var note: Note
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.undoManager) private var undoManager

    @State private var title: String = ""
    @State private var drawingData: Data = Data()
    @State private var annotationsData: Data = Data()
    @State private var canvasStyle: CanvasStyle = .blank
    @State private var showingPDFImporter = false
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var showingDeletePDFAlert = false

    var body: some View {
        ZStack {
            // Full-bleed canvas
            VStack(spacing: 0) {
                editorHeader
                Divider()
                canvasArea
            }

            // Floating toolbar overlay
            if note.pdfData == nil {
                GeometryReader { geo in
                    FloatingToolbar(
                        canvasStyle: $canvasStyle,
                        onUndo: { undoManager?.undo() },
                        onRedo: { undoManager?.redo() },
                        onImportPDF: { showingPDFImporter = true },
                        onExport: { exportNote() }
                    )
                    .onAppear {
                        // Position at top-center initially handled by FloatingToolbar default
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if note.pdfData != nil {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button { showingPDFImporter = true } label: {
                        Image(systemName: "doc.badge.plus")
                            .symbolRenderingMode(.hierarchical)
                    }
                    Button { exportNote() } label: {
                        Image(systemName: "square.and.arrow.up")
                            .symbolRenderingMode(.hierarchical)
                    }
                    Button { showingDeletePDFAlert = true } label: {
                        Image(systemName: "doc.badge.minus")
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
        }
        .fileImporter(isPresented: $showingPDFImporter, allowedContentTypes: [.pdf]) { result in
            if case .success(let url) = result { importPDF(from: url) }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: shareItems)
        }
        .alert("Remove PDF?", isPresented: $showingDeletePDFAlert) {
            Button("Remove", role: .destructive) { removePDF() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The PDF and its annotations will be removed.")
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
        .onChange(of: canvasStyle) { _, newValue in
            note.canvasStyle = newValue.rawValue
            save()
        }
    }

    // MARK: - Header

    private var editorHeader: some View {
        HStack(spacing: 12) {
            // Subject color indicator
            if let subject = note.subject {
                Circle()
                    .fill(QuantaTheme.color(for: subject.colorName ?? "blue").gradient)
                    .frame(width: 10, height: 10)
            }

            TextField("Note Title", text: $title)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .onChange(of: title) { _, newValue in
                    note.title = newValue
                    note.updatedAt = Date()
                    save()
                }

            if note.pdfData != nil {
                Label("PDF", systemImage: "doc.richtext.fill")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue.gradient, in: Capsule())
            }
        }
        .padding(.horizontal, QuantaTheme.padding)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    // MARK: - Canvas

    @ViewBuilder
    private var canvasArea: some View {
        if let pdfData = note.pdfData {
            PDFAnnotationView(
                pdfData: pdfData,
                annotationsData: $annotationsData
            )
        } else {
            ZStack {
                CanvasBackgroundView(style: canvasStyle)
                DrawingCanvasView(drawingData: $drawingData, isOverlay: canvasStyle != .blank)
            }
        }
    }

    // MARK: - Actions

    private func loadNoteData() {
        title = note.title ?? "Untitled"
        drawingData = note.drawingData ?? Data()
        annotationsData = note.annotationsData ?? Data()
        canvasStyle = CanvasStyle(rawValue: note.canvasStyle) ?? .blank
    }

    private func importPDF(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        guard let data = try? Data(contentsOf: url) else { return }
        note.pdfData = data
        note.updatedAt = Date()
        annotationsData = Data()
        note.annotationsData = Data()
        generatePDFThumbnail(from: data)
        save()
    }

    private func removePDF() {
        note.pdfData = nil
        note.annotationsData = nil
        annotationsData = Data()
        note.updatedAt = Date()
        generateDrawingThumbnail()
        save()
    }

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
            let fitRect = aspectFitRect(for: image.size, in: targetSize)
            image.draw(in: fitRect)
        }
        note.thumbnailData = thumbnail.jpegData(compressionQuality: 0.7)
    }

    private func generatePDFThumbnail(from data: Data) {
        guard let document = PDFDocument(data: data),
              let page = document.page(at: 0) else { return }
        let thumbnail = page.thumbnail(of: CGSize(width: 400, height: 300), for: .mediaBox)
        note.thumbnailData = thumbnail.jpegData(compressionQuality: 0.7)
    }

    private func save() { try? viewContext.save() }

    private func saveAll() {
        note.title = title
        note.drawingData = drawingData
        note.annotationsData = annotationsData
        note.canvasStyle = canvasStyle.rawValue
        note.updatedAt = Date()
        save()
    }

    private func aspectFitRect(for imageSize: CGSize, in containerSize: CGSize) -> CGRect {
        let scale = min(containerSize.width / imageSize.width, containerSize.height / imageSize.height)
        let w = imageSize.width * scale
        let h = imageSize.height * scale
        return CGRect(x: (containerSize.width - w) / 2, y: (containerSize.height - h) / 2, width: w, height: h)
    }
}
