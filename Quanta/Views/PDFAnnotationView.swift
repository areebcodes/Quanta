import SwiftUI
import PDFKit
import PencilKit

struct PageAnnotations: Codable {
    var pages: [Int: Data]

    init(pages: [Int: Data] = [:]) {
        self.pages = pages
    }

    static func decode(from data: Data) -> PageAnnotations {
        guard !data.isEmpty,
              let decoded = try? JSONDecoder().decode(PageAnnotations.self, from: data) else {
            return PageAnnotations()
        }
        return decoded
    }

    func encode() -> Data {
        (try? JSONEncoder().encode(self)) ?? Data()
    }

    enum CodingKeys: String, CodingKey { case pages }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let stringKeyed = try container.decode([String: Data].self, forKey: .pages)
        var result: [Int: Data] = [:]
        for (key, value) in stringKeyed {
            if let intKey = Int(key) { result[intKey] = value }
        }
        pages = result
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var stringKeyed: [String: Data] = [:]
        for (key, value) in pages { stringKeyed[String(key)] = value }
        try container.encode(stringKeyed, forKey: .pages)
    }
}

struct PDFAnnotationView: View {
    let pdfData: Data
    @Binding var annotationsData: Data
    var selectedTool: CanvasTool
    var selectedColor: Color
    var selectedSize: ToolSize = .medium
    var onUndoManagerReady: ((UndoManager?) -> Void)?

    @State private var currentPage = 0
    @State private var pageCount = 0
    @State private var annotations = PageAnnotations()
    @State private var currentDrawing = Data()
    @State private var pageImage: UIImage?

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                ZStack {
                    QuantaTheme.darkBg

                    if let image = pageImage {
                        let fitSize = fitSize(for: image.size, in: geo.size)
                        ZStack {
                            // Page with shadow
                            RoundedRectangle(cornerRadius: 3)
                                .fill(.white)
                                .frame(width: fitSize.width, height: fitSize.height)
                                .shadow(color: .black.opacity(0.3), radius: 10, y: 4)

                            Image(uiImage: image)
                                .resizable()
                                .frame(width: fitSize.width, height: fitSize.height)
                                .clipShape(RoundedRectangle(cornerRadius: 3))

                            DrawingCanvasView(
                                drawingData: $currentDrawing,
                                selectedTool: selectedTool,
                                selectedColor: selectedColor,
                                selectedSize: selectedSize,
                                isOverlay: true,
                                onUndoManagerReady: onUndoManagerReady
                            )
                            .frame(width: fitSize.width, height: fitSize.height)
                        }
                    }
                }
            }

            if pageCount > 1 {
                pageNavigation
            }
        }
        .onAppear {
            loadPDF()
            annotations = PageAnnotations.decode(from: annotationsData)
            loadPageAnnotation()
        }
        .onChange(of: currentDrawing) { _, newValue in
            annotations.pages[currentPage] = newValue
            annotationsData = annotations.encode()
        }
    }

    private var pageNavigation: some View {
        HStack(spacing: 24) {
            Button { changePage(to: currentPage - 1) } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
            }
            .disabled(currentPage <= 0)

            Text("Page \(currentPage + 1) of \(pageCount)")
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.6))

            Button { changePage(to: currentPage + 1) } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
            }
            .disabled(currentPage >= pageCount - 1)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(QuantaTheme.toolbarBg)
    }

    private func loadPDF() {
        guard let document = PDFDocument(data: pdfData) else { return }
        pageCount = document.pageCount
        renderCurrentPage()
    }

    private func renderCurrentPage() {
        guard let document = PDFDocument(data: pdfData),
              let page = document.page(at: currentPage) else { return }
        let bounds = page.bounds(for: .mediaBox)
        pageImage = page.thumbnail(of: CGSize(width: bounds.width * 2, height: bounds.height * 2), for: .mediaBox)
    }

    private func changePage(to newPage: Int) {
        guard newPage >= 0, newPage < pageCount else { return }
        annotations.pages[currentPage] = currentDrawing
        annotationsData = annotations.encode()
        currentPage = newPage
        renderCurrentPage()
        loadPageAnnotation()
    }

    private func loadPageAnnotation() {
        currentDrawing = annotations.pages[currentPage] ?? Data()
    }

    private func fitSize(for imageSize: CGSize, in containerSize: CGSize) -> CGSize {
        let padding: CGFloat = 32
        let available = CGSize(width: containerSize.width - padding * 2, height: containerSize.height - padding * 2)
        let scale = min(available.width / imageSize.width, available.height / imageSize.height)
        return CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    }
}
