import SwiftUI
import PencilKit

struct DrawingCanvasView: UIViewRepresentable {
    @Binding var drawingData: Data
    var isOverlay: Bool = false

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.delegate = context.coordinator
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = isOverlay ? .clear : .white
        canvas.isOpaque = !isOverlay
        canvas.tool = PKInkingTool(.pen, color: .black, width: 3)

        if !drawingData.isEmpty, let drawing = try? PKDrawing(data: drawingData) {
            canvas.drawing = drawing
        }

        // Show PencilKit tool picker
        let toolPicker = PKToolPicker()
        toolPicker.setVisible(true, forFirstResponder: canvas)
        toolPicker.addObserver(canvas)
        canvas.becomeFirstResponder()
        context.coordinator.toolPicker = toolPicker

        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        let coordinator = context.coordinator
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
        var toolPicker: PKToolPicker?
        var isUpdating = false

        init(drawingData: Binding<Data>) {
            self.drawingData = drawingData
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            guard !isUpdating else { return }
            drawingData.wrappedValue = canvasView.drawing.dataRepresentation()
        }
    }
}
