import SwiftUI
import PencilKit

struct DrawingCanvasView: UIViewRepresentable {
    @Binding var drawingData: Data
    var selectedTool: CanvasTool = .pen
    var selectedColor: Color = .black
    var isOverlay: Bool = false
    var onUndoManagerReady: ((UndoManager?) -> Void)?

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.delegate = context.coordinator
        canvas.drawingPolicy = .pencilOnly
        canvas.backgroundColor = isOverlay ? .clear : .white
        canvas.isOpaque = !isOverlay
        canvas.overrideUserInterfaceStyle = .light
        canvas.alwaysBounceVertical = true
        canvas.showsVerticalScrollIndicator = false

        // Tall canvas for infinite-scroll feel
        canvas.contentSize = CGSize(width: UIScreen.main.bounds.width, height: 5000)

        // Load existing drawing
        if !drawingData.isEmpty, let drawing = try? PKDrawing(data: drawingData) {
            canvas.drawing = drawing
        }

        // Set initial tool
        canvas.tool = context.coordinator.pkTool(for: selectedTool, color: selectedColor)

        // Pass undo manager back
        DispatchQueue.main.async {
            onUndoManagerReady?(canvas.undoManager)
        }

        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        let coordinator = context.coordinator

        // Update tool only when changed
        if coordinator.currentTool != selectedTool || coordinator.currentColor != selectedColor.description {
            uiView.tool = coordinator.pkTool(for: selectedTool, color: selectedColor)
            coordinator.currentTool = selectedTool
            coordinator.currentColor = selectedColor.description
        }

        // Update drawing if changed externally
        guard !coordinator.isUpdating else { return }
        let currentData = uiView.drawing.dataRepresentation()
        if currentData != drawingData {
            coordinator.isUpdating = true
            if drawingData.isEmpty {
                uiView.drawing = PKDrawing()
            } else if let drawing = try? PKDrawing(data: drawingData) {
                uiView.drawing = drawing
            }
            coordinator.isUpdating = false
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(drawingData: $drawingData)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var drawingData: Binding<Data>
        var isUpdating = false
        var currentTool: CanvasTool = .pen
        var currentColor: String = ""

        init(drawingData: Binding<Data>) {
            self.drawingData = drawingData
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            guard !isUpdating else { return }
            drawingData.wrappedValue = canvasView.drawing.dataRepresentation()
        }

        func pkTool(for tool: CanvasTool, color: Color) -> PKTool {
            let uiColor = UIColor(color)
            switch tool {
            case .pen:
                return PKInkingTool(.pen, color: uiColor, width: 3)
            case .highlighter:
                return PKInkingTool(.marker, color: uiColor.withAlphaComponent(0.3), width: 15)
            case .eraser:
                return PKEraserTool(.bitmap)
            case .lasso:
                return PKLassoTool()
            }
        }
    }
}
