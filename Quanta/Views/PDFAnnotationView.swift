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

    // Custom coding to handle Int keys in JSON (JSON only supports String keys)
    enum CodingKeys: String, CodingKey {
        case pages
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let stringKeyedPages = try container.decode([String: Data].self, forKey: .pages)
        var intKeyedPages: [Int: Data] = [:]
        for (key, value) in stringKeyedPages {
            if let intKey = Int(key) {
                intKeyedPages[intKey] = value
            }
        }
        pages = intKeyedPages
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var stringKeyedPages: [String: Data] = [:]
        for (key, value) in pages {
            stringKeyedPages[String(key)] = value
        }
        try container.encode(stringKeyedPages, forKey: .pages)
    }
}

struct PDFAnnotationView: View {
    let pdfData: Data
    @Binding var annotationsData: Data

    @State private var currentPage = 0
    @State private var pageCount = 0
    @State private var annotations = PageAnnotations()
    @State private var currentDrawing = Data()
    @State private var pageImage: UIImage?

    var body: some View {
        VStack(spacing: 0) {
            // PDF page with drawing overlay
            GeometryReader { geo in
                ZStack {
                    Color(.systemGray5)

                    if let image = pageImage {
                        let pageSize = fitSize(
                            for: image.size,
                            in: geo.size
                        )

                        ZStack {
                            Image(uiImage: image)
                                .resizable()
                                .frame(width: pageSize.width, height: pageSize.height)

                            DrawingCanvasView(drawingData: $currentDrawing, isOverlay: true)
                                .frame(width: pageSize.width, height: pageSize.height)
                        }
                    }
                }
            }

            // Page navigation bar
            if pageCount > 1 {
                pageNavigationBar
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

    private var pageNavigationBar: some View {
        HStack(spacing: 20) {
            Button {
                changePage(to: currentPage - 1)
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
            }
            .disabled(currentPage <= 0)

            Text("Page \(currentPage + 1) of \(pageCount)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)

            Button {
                changePage(to: currentPage + 1)
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
            }
            .disabled(currentPage >= pageCount - 1)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }

    // MARK: - Logic

    private func loadPDF() {
        guard let document = PDFDocument(data: pdfData) else { return }
        pageCount = document.pageCount
        renderCurrentPage()
    }

    private func renderCurrentPage() {
        guard let document = PDFDocument(data: pdfData),
              let page = document.page(at: currentPage) else { return }
        let bounds = page.bounds(for: .mediaBox)
        let scale: CGFloat = 2.0
        let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)
        pageImage = page.thumbnail(of: size, for: .mediaBox)
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
        let scaleX = containerSize.width / imageSize.width
        let scaleY = containerSize.height / imageSize.height
        let scale = min(scaleX, scaleY)
        return CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )
    }
}
