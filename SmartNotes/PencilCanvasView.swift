import PencilKit
import SwiftUI

struct PencilCanvasView: UIViewRepresentable {
    let pageID: UUID
    var drawing: PKDrawing
    var selectedTool: NoteTool
    var selectedColor: InkColor
    var strokeWidth: CGFloat
    var command: CanvasCommand?
    var onDrawingChange: (UUID, PKDrawing) -> Void

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.delegate = context.coordinator
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = resolvedTool
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.alwaysBounceVertical = true
        canvasView.isScrollEnabled = true
        canvasView.minimumZoomScale = 1
        canvasView.maximumZoomScale = 3
        canvasView.drawing = drawing

        context.coordinator.configureToolPicker(for: canvasView)
        return canvasView
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        if context.coordinator.pageID != pageID {
            context.coordinator.pageID = pageID
            canvasView.drawing = drawing
        }
        canvasView.tool = resolvedTool
        context.coordinator.handle(command, for: canvasView)
        context.coordinator.configureToolPicker(for: canvasView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(pageID: pageID, onDrawingChange: onDrawingChange)
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var pageID: UUID
        let onDrawingChange: (UUID, PKDrawing) -> Void
        private let toolPicker = PKToolPicker()
        private var handledCommandID: UUID?

        init(pageID: UUID, onDrawingChange: @escaping (UUID, PKDrawing) -> Void) {
            self.pageID = pageID
            self.onDrawingChange = onDrawingChange
        }

        func configureToolPicker(for canvasView: PKCanvasView) {
            toolPicker.addObserver(canvasView)
            toolPicker.setVisible(true, forFirstResponder: canvasView)

            if !canvasView.isFirstResponder {
                DispatchQueue.main.async {
                    canvasView.becomeFirstResponder()
                }
            }
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            onDrawingChange(pageID, canvasView.drawing)
        }

        func handle(_ command: CanvasCommand?, for canvasView: PKCanvasView) {
            guard let command, handledCommandID != command.id else {
                return
            }

            handledCommandID = command.id

            switch command.action {
            case .undo:
                canvasView.undoManager?.undo()
            case .redo:
                canvasView.undoManager?.redo()
            case .clear:
                canvasView.drawing = PKDrawing()
                onDrawingChange(pageID, canvasView.drawing)
            }
        }
    }

    private var resolvedTool: PKTool {
        switch selectedTool {
        case .pen, .text, .tape, .shape:
            PKInkingTool(.pen, color: selectedColor.uiColor, width: strokeWidth)
        case .highlighter:
            PKInkingTool(.marker, color: selectedColor.uiColor.withAlphaComponent(0.45), width: strokeWidth * 3)
        case .eraser:
            PKEraserTool(.bitmap)
        }
    }
}
