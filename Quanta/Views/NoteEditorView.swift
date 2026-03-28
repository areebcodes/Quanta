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
    @State private var showingPDFImporter = false
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var showingDeletePDFAlert = false

    var body: some View {
        VStack(spacing: 0) {
            titleBar
            Divider()
            canvas
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { editorToolbar }
        .fileImporter(
            isPresented: $showingPDFImporter,
            allowedContentTypes: [.pdf]
        ) { result in
            if case .success(let url) = result {
                importPDF(from: url)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: shareItems)
        }
        .alert("Remove PDF?", isPresented: $showingDeletePDFAlert) {
            Button("Remove", role: .destructive) { removePDF() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the PDF and its annotations. Your drawings will be preserved.")
        }
        .onAppear(perform: loadNoteData)
        .onDisappear(perform: saveAll)
        .onChange(of: drawingData) { _, newValue in
            note.drawingData = newValue
            note.updatedAt = Date()
            generateDrawingThumbnail()
            save()
        }
        .onChange(of: annotationsData) { _, newValue in
            note.annotationsData = newValue
            note.updatedAt = Date()
            save()
        }
    }

    // MARK: - Subviews

    private var titleBar: some View {
        HStack(spacing: 12) {
            TextField("Note Title", text: $title)
                .font(.title2.bold())
                .onChange(of: title) { _, newValue in
                    note.title = newValue
                    note.updatedAt = Date()
                    save()
                }

            if note.pdfData != nil {
                Label("PDF", systemImage: "doc.richtext")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue, in: Capsule())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var canvas: some View {
        if let pdfData = note.pdfData {
            PDFAnnotationView(
                pdfData: pdfData,
                annotationsData: $annotationsData
            )
        } else {
            DrawingCanvasView(drawingData: $drawingData)
        }
    }

    @ToolbarContentBuilder
    private var editorToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            if note.pdfData != nil {
                Button {
                    showingDeletePDFAlert = true
                } label: {
                    Image(systemName: "doc.badge.minus")
                }
            }

            Button {
                showingPDFImporter = true
            } label: {
                Image(systemName: "doc.badge.plus")
            }

            Button {
                exportNote()
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
        }
    }

    // MARK: - Actions

    private func loadNoteData() {
        title = note.title ?? "Untitled"
        drawingData = note.drawingData ?? Data()
        annotationsData = note.annotationsData ?? Data()
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
                let image = drawing.image(
                    from: bounds.insetBy(dx: -20, dy: -20),
                    scale: 2.0
                )
                items.append(image)
            }
        }

        if !items.isEmpty {
            shareItems = items
            showingShareSheet = true
        }
    }

    private func exportAnnotatedPDF(pdfData: Data) -> Data? {
        guard let document = PDFDocument(data: pdfData) else { return nil }
        let annotations = PageAnnotations.decode(from: annotationsData)
        guard document.pageCount > 0 else { return nil }

        let firstPage = document.page(at: 0)!
        let defaultBounds = firstPage.bounds(for: .mediaBox)
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

                if let pageDrawingData = annotations.pages[i],
                   let drawing = try? PKDrawing(data: pageDrawingData) {
                    let image = drawing.image(from: bounds, scale: 2.0)
                    image.draw(in: bounds)
                }
            }
        }
    }

    // MARK: - Thumbnails

    private func generateDrawingThumbnail() {
        guard !drawingData.isEmpty,
              let drawing = try? PKDrawing(data: drawingData) else {
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
            let rect = aspectFitRect(for: image.size, in: targetSize)
            image.draw(in: rect)
        }

        note.thumbnailData = thumbnail.jpegData(compressionQuality: 0.7)
    }

    private func generatePDFThumbnail(from data: Data) {
        guard let document = PDFDocument(data: data),
              let page = document.page(at: 0) else { return }
        let thumbnail = page.thumbnail(of: CGSize(width: 400, height: 300), for: .mediaBox)
        note.thumbnailData = thumbnail.jpegData(compressionQuality: 0.7)
    }

    // MARK: - Helpers

    private func save() {
        try? viewContext.save()
    }

    private func saveAll() {
        note.title = title
        note.drawingData = drawingData
        note.annotationsData = annotationsData
        note.updatedAt = Date()
        save()
    }

    private func aspectFitRect(for imageSize: CGSize, in containerSize: CGSize) -> CGRect {
        let scaleX = containerSize.width / imageSize.width
        let scaleY = containerSize.height / imageSize.height
        let scale = min(scaleX, scaleY)
        let w = imageSize.width * scale
        let h = imageSize.height * scale
        return CGRect(
            x: (containerSize.width - w) / 2,
            y: (containerSize.height - h) / 2,
            width: w,
            height: h
        )
    }
}
