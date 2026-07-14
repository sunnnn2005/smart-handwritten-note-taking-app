import Foundation
import PencilKit

struct NotebookPage: Identifiable {
    let id: UUID
    var title: String
    var drawing: PKDrawing

    init(id: UUID = UUID(), title: String = "Untitled Page", drawing: PKDrawing = PKDrawing()) {
        self.id = id
        self.title = title
        self.drawing = drawing
    }
}

struct OutlineEntry: Identifiable {
    let id: UUID
    let pageID: UUID
    let title: String
    let level: Int
}
