import Foundation
import PencilKit

@MainActor
final class NotebookStore: ObservableObject {
    @Published var pages: [NotebookPage] = [
        NotebookPage(title: "Page 1")
    ]
    @Published var selectedPageID: UUID?
    @Published var outline: [OutlineEntry] = []

    var selectedPage: NotebookPage? {
        guard let selectedPageID else {
            return pages.first
        }
        return pages.first { $0.id == selectedPageID }
    }

    init() {
        selectedPageID = pages.first?.id
    }

    func addPage() {
        let page = NotebookPage(title: "Page \(pages.count + 1)")
        pages.append(page)
        selectedPageID = page.id
    }

    func updateDrawing(_ drawing: PKDrawing, for pageID: UUID) {
        guard let index = pages.firstIndex(where: { $0.id == pageID }) else {
            return
        }
        pages[index].drawing = drawing
    }

    func selectPage(_ pageID: UUID) {
        selectedPageID = pageID
    }

    func replaceOutlineEntry(for pageID: UUID, title: String, level: Int = 1) {
        outline.removeAll { $0.pageID == pageID }
        outline.append(OutlineEntry(id: UUID(), pageID: pageID, title: title, level: level))
        outline.sort { first, second in
            pageIndex(for: first.pageID) < pageIndex(for: second.pageID)
        }

        if let pageIndex = pages.firstIndex(where: { $0.id == pageID }) {
            pages[pageIndex].title = title
        }
    }

    private func pageIndex(for pageID: UUID) -> Int {
        pages.firstIndex { $0.id == pageID } ?? Int.max
    }
}
