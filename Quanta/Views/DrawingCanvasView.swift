import SwiftUI
import PencilKit

struct DrawingCanvasView: UIViewRepresentable {
    @Binding var drawingData: Data
    var selectedTool: CanvasTool = .pen
    var selectedColor: Color = .black
    var selectedSize: ToolSize = .medium
    var isOverlay: Bool = false
    var onUndoManagerReady: ((UndoManager?) -> Void)?
    var onPageChange: ((Int, Int) -> Void)?

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.delegate = context.coordinator
        canvas.drawingPolicy = .pencilOnly
        canvas.overrideUserInterfaceStyle = .light
        canvas.showsVerticalScrollIndicator = !isOverlay

        if isOverlay {
            canvas.backgroundColor = .clear
            canvas.isOpaque = false
            canvas.isScrollEnabled = false
        } else {
            canvas.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1)
            canvas.isOpaque = true
            canvas.alwaysBounceVertical = true
            context.coordinator.canvas = canvas
            context.coordinator.setupPages(in: canvas)
        }

        if !drawingData.isEmpty, let drawing = try? PKDrawing(data: drawingData) {
            canvas.drawing = drawing
        }

        canvas.tool = context.coordinator.pkTool(for: selectedTool, color: selectedColor, size: selectedSize)

        DispatchQueue.main.async {
            onUndoManagerReady?(canvas.undoManager)
        }

        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        let c = context.coordinator

        if c.lastTool != selectedTool || c.lastColorDesc != selectedColor.description || c.lastSize != selectedSize {
            uiView.tool = c.pkTool(for: selectedTool, color: selectedColor, size: selectedSize)
            c.lastTool = selectedTool
            c.lastColorDesc = selectedColor.description
            c.lastSize = selectedSize
        }

        guard !c.isUpdating else { return }
        let current = uiView.drawing.dataRepresentation()
        if current != drawingData {
            c.isUpdating = true
            if drawingData.isEmpty {
                uiView.drawing = PKDrawing()
            } else if let drawing = try? PKDrawing(data: drawingData) {
                uiView.drawing = drawing
            }
            c.isUpdating = false
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate, UIScrollViewDelegate {
        let parent: DrawingCanvasView
        weak var canvas: PKCanvasView?
        var isUpdating = false
        var lastTool: CanvasTool = .pen
        var lastColorDesc = ""
        var lastSize: ToolSize = .medium
        var pageLayers: [CALayer] = []
        var pageCount = 3
        var pageWidth: CGFloat = 0
        var pageHeight: CGFloat = 0

        init(parent: DrawingCanvasView) {
            self.parent = parent
        }

        func setupPages(in canvas: PKCanvasView) {
            let screenWidth = UIScreen.main.bounds.width
            let margin: CGFloat = 40
            pageWidth = screenWidth - margin * 2
            pageHeight = pageWidth * QuantaTheme.pageRatio
            rebuildLayout(in: canvas)
        }

        func rebuildLayout(in canvas: PKCanvasView) {
            let gap = QuantaTheme.pageGap
            let totalHeight = CGFloat(pageCount) * (pageHeight + gap) + gap
            canvas.contentSize = CGSize(width: UIScreen.main.bounds.width, height: totalHeight)

            for layer in pageLayers { layer.removeFromSuperlayer() }
            pageLayers.removeAll()

            let xOffset = (UIScreen.main.bounds.width - pageWidth) / 2

            for i in 0..<pageCount {
                let y = gap + CGFloat(i) * (pageHeight + gap)
                let layer = CALayer()
                layer.frame = CGRect(x: xOffset, y: y, width: pageWidth, height: pageHeight)
                layer.backgroundColor = UIColor.white.cgColor
                layer.cornerRadius = 3
                layer.shadowColor = UIColor.black.cgColor
                layer.shadowOpacity = 0.3
                layer.shadowOffset = CGSize(width: 0, height: 4)
                layer.shadowRadius = 10
                canvas.layer.insertSublayer(layer, at: 0)
                pageLayers.append(layer)
            }
        }

        // MARK: - PKCanvasViewDelegate

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            guard !isUpdating else { return }
            parent.drawingData.wrappedValue = canvasView.drawing.dataRepresentation()

            guard !parent.isOverlay else { return }

            // Auto-add page when drawing near the bottom of the last page
            let gap = QuantaTheme.pageGap
            let lastPageBottom = gap + CGFloat(pageCount - 1) * (pageHeight + gap) + pageHeight
            if canvasView.drawing.bounds.maxY > lastPageBottom - pageHeight * 0.15 {
                pageCount += 1
                rebuildLayout(in: canvasView)
                parent.onPageChange?(currentPageIndex(in: canvasView), pageCount)
            }
        }

        // MARK: - UIScrollViewDelegate

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard !parent.isOverlay else { return }
            parent.onPageChange?(currentPageIndex(in: scrollView), pageCount)
        }

        func currentPageIndex(in scrollView: UIScrollView) -> Int {
            let gap = QuantaTheme.pageGap
            let center = scrollView.contentOffset.y + scrollView.bounds.height / 2
            let step = pageHeight + gap
            let index = Int((center - gap / 2) / step)
            return max(0, min(index, pageCount - 1))
        }

        // MARK: - Tool mapping

        func pkTool(for tool: CanvasTool, color: Color, size: ToolSize) -> PKTool {
            let uiColor = UIColor(color)
            let width = size.width(for: tool)
            switch tool {
            case .pen:
                return PKInkingTool(.pen, color: uiColor, width: width)
            case .highlighter:
                return PKInkingTool(.marker, color: uiColor.withAlphaComponent(0.3), width: width)
            case .eraser:
                return PKEraserTool(.bitmap, width: width)
            case .lasso:
                return PKLassoTool()
            }
        }
    }
}
