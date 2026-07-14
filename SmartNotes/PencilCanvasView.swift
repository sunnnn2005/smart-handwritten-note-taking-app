import PencilKit
import SwiftUI

struct PencilCanvasView: UIViewRepresentable {
    let pageID: UUID
    var drawing: PKDrawing
    var onDrawingChange: (PKDrawing) -> Void

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.delegate = context.coordinator
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .label, width: 4)
        canvasView.backgroundColor = .systemBackground
        canvasView.drawing = drawing
        return canvasView
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        if canvasView.drawing != drawing {
            canvasView.drawing = drawing
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onDrawingChange: onDrawingChange)
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        let onDrawingChange: (PKDrawing) -> Void

        init(onDrawingChange: @escaping (PKDrawing) -> Void) {
            self.onDrawingChange = onDrawingChange
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            onDrawingChange(canvasView.drawing)
        }
    }
}
