import Foundation
import PencilKit
import SmartNotesCore

@MainActor
final class NotebookStore: ObservableObject {
    @Published var folders: [NoteFolder]
    @Published var pages: [NotebookPage]
    @Published var selectedPageID: UUID?
    @Published var selectedSection: LibrarySection = .recents
    @Published var outline: [OutlineEntry] = []
    @Published var saveStatus = "Saved"
    private var saveTask: Task<Void, Never>?

    var selectedPage: NotebookPage? {
        guard let selectedPageID else {
            return nil
        }
        return pages.first { $0.id == selectedPageID }
    }

    var selectedSheet: NotebookSheet? {
        selectedPage?.currentSheet
    }

    init() {
        if let snapshot = Self.loadSnapshot() {
            folders = snapshot.folders.map(NoteFolder.init)
            pages = snapshot.pages.compactMap(NotebookPage.init)
            outline = snapshot.outline.map(OutlineEntry.init)
        } else {
            let folder108 = NoteFolder(name: "STA 108")
            let folder131 = NoteFolder(name: "MAT 22A")
            let folderSTA = NoteFolder(name: "Data Science")
            let myNotes = NoteFolder(name: "My Notes")

            folders = [folder108, folder131, folderSTA, myNotes]
            pages = [
                NotebookPage(folderID: folder108.id, title: "Regression Review", sheets: [NotebookSheet(template: .cornell)], isFavorite: true),
                NotebookPage(folderID: folder131.id, title: "Lecture 1", sheets: [NotebookSheet(template: .grid)]),
                NotebookPage(folderID: folder131.id, title: "Lecture 2", sheets: [NotebookSheet(template: .ruled)]),
                NotebookPage(folderID: folderSTA.id, title: "EDA Checklist", sheets: [NotebookSheet(template: .dotted)]),
                NotebookPage(folderID: myNotes.id, title: "Welcome to IndexNote"),
                NotebookPage(folderID: myNotes.id, title: "Weekly Planner", sheets: [NotebookSheet(template: .dailyPlanner)]),
                NotebookPage(folderID: myNotes.id, title: "Oversized Pages", sheets: [NotebookSheet(template: .dotted)])
            ]
            outline = []
        }
        selectedPageID = nil
    }

    func addFolder(named name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            return
        }

        let folder = NoteFolder(name: trimmedName)
        folders.append(folder)
        selectedSection = .folder(folder.id)
        selectedPageID = nil
        saveSoon()
    }

    func renameFolder(_ folderID: UUID, to name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, let index = folders.firstIndex(where: { $0.id == folderID }) else {
            return
        }

        folders[index].name = trimmedName
        saveSoon()
    }

    func renamePage(_ pageID: UUID, to title: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, let index = pages.firstIndex(where: { $0.id == pageID }) else {
            return
        }

        pages[index].title = trimmedTitle
        pages[index].updatedAt = Date()
        saveSoon()
    }

    func duplicateFolder(_ folderID: UUID) {
        guard let folder = folders.first(where: { $0.id == folderID }) else {
            return
        }

        let copyFolder = NoteFolder(name: "\(folder.name) Copy")
        let copiedPages = pages.filter { $0.folderID == folderID }.map { page in
            let copiedSheets = page.sheets.map { $0.copyWithNewIdentity() }
            return NotebookPage(
                folderID: copyFolder.id,
                title: "\(page.title) Copy",
                sheets: copiedSheets,
                selectedSheetID: copiedSheets.first?.id,
                isFavorite: page.isFavorite
            )
        }

        folders.append(copyFolder)
        pages.append(contentsOf: copiedPages)
        selectedSection = .folder(copyFolder.id)
        selectedPageID = nil
        saveSoon()
    }

    func deleteFolder(_ folderID: UUID) {
        guard folders.count > 1 else {
            return
        }

        folders.removeAll { $0.id == folderID }
        let removedSheetIDs = Set(pages.filter { $0.folderID == folderID }.flatMap { $0.sheets.map(\.id) })
        pages.removeAll { $0.folderID == folderID }
        outline.removeAll { removedSheetIDs.contains($0.pageID) }
        selectedSection = .recents
        selectedPageID = nil
        saveSoon()
    }

    func addPage() {
        let folderID = selectedFolderID ?? folders.first?.id ?? NoteFolder(name: "My Notes").id
        let page = NotebookPage(folderID: folderID, title: "Blank")
        pages.append(page)
        selectedPageID = page.id
        saveSoon()
    }

    func importPDFPlaceholder(named fileName: String) {
        let folderID = selectedFolderID ?? folders.first?.id ?? NoteFolder(name: "My Notes").id
        let cleanName = fileName.replacingOccurrences(of: ".pdf", with: "", options: .caseInsensitive)
        let page = NotebookPage(folderID: folderID, title: cleanName.isEmpty ? "Imported PDF" : cleanName)
        pages.append(page)
        selectedPageID = page.id
        saveSoon()
    }

    func openLibrary(_ section: LibrarySection) {
        selectedSection = section
        selectedPageID = nil
    }

    var selectedFolderID: UUID? {
        if case let .folder(folderID) = selectedSection {
            return folderID
        }

        return folders.first { $0.name == "My Notes" }?.id ?? folders.first?.id
    }

    func folderName(for folderID: UUID) -> String {
        folders.first { $0.id == folderID }?.name ?? "Folder"
    }

    func pages(for section: LibrarySection) -> [NotebookPage] {
        switch section {
        case .recents:
            return pages.sorted { $0.updatedAt > $1.updatedAt }
        case .favorites:
            return pages.filter(\.isFavorite).sorted { $0.updatedAt > $1.updatedAt }
        case .folder(let folderID):
            return pages.filter { $0.folderID == folderID }.sorted { $0.updatedAt > $1.updatedAt }
        case .templateLibrary, .fonts:
            return []
        }
    }

    func count(for section: LibrarySection) -> Int {
        pages(for: section).count
    }

    func duplicatePage(_ pageID: UUID) {
        guard let page = page(with: pageID) else {
            return
        }

        let copiedSheets = page.sheets.map { $0.copyWithNewIdentity() }
        let selectedIndex = page.sheets.firstIndex { $0.id == page.selectedSheetID } ?? 0
        let copy = NotebookPage(
            folderID: page.folderID,
            title: "\(page.title) Copy",
            sheets: copiedSheets,
            selectedSheetID: copiedSheets.indices.contains(selectedIndex) ? copiedSheets[selectedIndex].id : copiedSheets.first?.id,
            isFavorite: page.isFavorite
        )
        pages.append(copy)
        selectedPageID = copy.id
        saveSoon()
    }

    func deletePage(_ pageID: UUID) {
        guard let index = pages.firstIndex(where: { $0.id == pageID }) else {
            return
        }

        pages.remove(at: index)
        outline.removeAll { entry in
            pages.allSatisfy { document in
                document.sheets.allSatisfy { $0.id != entry.pageID }
            }
        }
        if pages.isEmpty {
            selectedPageID = nil
            selectedSection = folders.first.map { .folder($0.id) } ?? .recents
        } else if selectedPageID == pageID {
            selectedPageID = nil
        }
        saveSoon()
    }

    func updateDrawing(_ drawing: PKDrawing, for pageID: UUID) {
        guard let location = sheetLocation(for: pageID) else {
            return
        }
        pages[location.documentIndex].sheets[location.sheetIndex].drawing = drawing
        touchDocument(at: location.documentIndex)
        saveSoon()
    }

    func clearDrawing(for pageID: UUID) {
        updateDrawing(PKDrawing(), for: pageID)
        outline.removeAll { $0.pageID == pageID }
    }

    func updateTemplate(_ template: PageTemplate, for pageID: UUID) {
        guard let location = sheetLocation(for: pageID) else {
            return
        }

        pages[location.documentIndex].sheets[location.sheetIndex].template = template
        touchDocument(at: location.documentIndex)
        saveSoon()
    }

    func addElement(_ kind: PageElementKind, to pageID: UUID) {
        guard let location = sheetLocation(for: pageID) else {
            return
        }

        let offset = CGFloat(pages[location.documentIndex].sheets[location.sheetIndex].elements.count * 20)
        let element: PageElement

        switch kind {
        case .textBox:
            element = PageElement(kind: .textBox, text: "Typed note", x: 120 + offset, y: 120 + offset)
        case .stickyNote:
            element = PageElement(kind: .stickyNote, text: "Sticky note", x: 140 + offset, y: 140 + offset, width: 210, height: 150)
        case .tape:
            element = PageElement(kind: .tape, text: "Tap to reveal", x: 160 + offset, y: 180 + offset, width: 240, height: 44)
        case .shape:
            element = PageElement(kind: .shape, text: "Rectangle", x: 180 + offset, y: 200 + offset, width: 180, height: 110)
        }

        pages[location.documentIndex].sheets[location.sheetIndex].elements.append(element)
        touchDocument(at: location.documentIndex)
        saveSoon()
    }

    func updateElement(_ element: PageElement, on pageID: UUID) {
        guard let location = sheetLocation(for: pageID),
              let elementIndex = pages[location.documentIndex].sheets[location.sheetIndex].elements.firstIndex(where: { $0.id == element.id }) else {
            return
        }

        pages[location.documentIndex].sheets[location.sheetIndex].elements[elementIndex] = element
        touchDocument(at: location.documentIndex)
        saveSoon()
    }

    func deleteElement(_ elementID: UUID, from pageID: UUID) {
        guard let location = sheetLocation(for: pageID) else {
            return
        }

        pages[location.documentIndex].sheets[location.sheetIndex].elements.removeAll { $0.id == elementID }
        touchDocument(at: location.documentIndex)
        saveSoon()
    }

    func selectPage(_ pageID: UUID) {
        selectedPageID = pageID
    }

    func toggleFavorite(_ pageID: UUID) {
        guard let index = pages.firstIndex(where: { $0.id == pageID }) else {
            return
        }

        pages[index].isFavorite.toggle()
        pages[index].updatedAt = Date()
        saveSoon()
    }

    func page(with pageID: UUID) -> NotebookPage? {
        pages.first { $0.id == pageID }
    }

    func sheet(with sheetID: UUID) -> NotebookSheet? {
        sheetLocation(for: sheetID).map { pages[$0.documentIndex].sheets[$0.sheetIndex] }
    }

    func addSheet(to documentID: UUID) {
        guard let documentIndex = pages.firstIndex(where: { $0.id == documentID }) else {
            return
        }

        let sheet = NotebookSheet(template: pages[documentIndex].currentSheet.template)
        pages[documentIndex].sheets.append(sheet)
        pages[documentIndex].selectedSheetID = sheet.id
        touchDocument(at: documentIndex)
        saveSoon()
    }

    func selectNextSheet(in documentID: UUID) {
        moveSheetSelection(in: documentID, by: 1)
    }

    func selectPreviousSheet(in documentID: UUID) {
        moveSheetSelection(in: documentID, by: -1)
    }

    func deleteCurrentSheet(in documentID: UUID) {
        guard let documentIndex = pages.firstIndex(where: { $0.id == documentID }),
              pages[documentIndex].sheets.count > 1,
              let sheetIndex = pages[documentIndex].sheets.firstIndex(where: { $0.id == pages[documentIndex].selectedSheetID }) else {
            return
        }

        let removedSheetID = pages[documentIndex].sheets[sheetIndex].id
        pages[documentIndex].sheets.remove(at: sheetIndex)
        outline.removeAll { $0.pageID == removedSheetID }
        let nextIndex = min(sheetIndex, pages[documentIndex].sheets.count - 1)
        pages[documentIndex].selectedSheetID = pages[documentIndex].sheets[nextIndex].id
        touchDocument(at: documentIndex)
        saveSoon()
    }

    func selectSheet(_ sheetID: UUID, in documentID: UUID) {
        guard let documentIndex = pages.firstIndex(where: { $0.id == documentID }),
              pages[documentIndex].sheets.contains(where: { $0.id == sheetID }) else {
            return
        }

        pages[documentIndex].selectedSheetID = sheetID
        pages[documentIndex].updatedAt = Date()
        saveSoon()
    }

    func duplicateCurrentSheet(in documentID: UUID) {
        guard let documentIndex = pages.firstIndex(where: { $0.id == documentID }) else {
            return
        }

        let copy = pages[documentIndex].currentSheet.copyWithNewIdentity()
        guard let currentIndex = pages[documentIndex].sheets.firstIndex(where: { $0.id == pages[documentIndex].selectedSheetID }) else {
            pages[documentIndex].sheets.append(copy)
            pages[documentIndex].selectedSheetID = copy.id
            touchDocument(at: documentIndex)
            saveSoon()
            return
        }

        pages[documentIndex].sheets.insert(copy, at: currentIndex + 1)
        pages[documentIndex].selectedSheetID = copy.id
        touchDocument(at: documentIndex)
        saveSoon()
    }

    func replaceOutlineEntries(for pageID: UUID, headings: [ParsedHeading]) {
        outline.removeAll { $0.pageID == pageID }
        outline.append(contentsOf: headings.enumerated().map { index, heading in
            OutlineEntry(id: UUID(), pageID: pageID, title: heading.title, level: heading.level, position: index)
        })
        outline.sort { first, second in
            let firstPageIndex = pageIndex(for: first.pageID)
            let secondPageIndex = pageIndex(for: second.pageID)

            if firstPageIndex == secondPageIndex {
                return first.position < second.position
            }

            return firstPageIndex < secondPageIndex
        }

        if let location = sheetLocation(for: pageID) {
            pages[location.documentIndex].sheets[location.sheetIndex].title = headings.first?.title
            touchDocument(at: location.documentIndex)
        }
        saveSoon()
    }

    func addOutlineEntry(title: String, level: Int, to sheetID: UUID) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty,
              (1...3).contains(level),
              let location = sheetLocation(for: sheetID) else {
            return
        }

        let duplicate = outline.contains { entry in
            entry.pageID == sheetID &&
            entry.level == level &&
            entry.title.localizedCaseInsensitiveCompare(trimmedTitle) == .orderedSame
        }
        guard !duplicate else {
            return
        }

        outline.append(OutlineEntry(
            id: UUID(),
            pageID: sheetID,
            title: trimmedTitle,
            level: level,
            position: outline.filter { $0.pageID == sheetID }.count
        ))
        pages[location.documentIndex].sheets[location.sheetIndex].title = trimmedTitle
        touchDocument(at: location.documentIndex)
        saveSoon()
    }

    func deleteOutlineEntry(_ entryID: UUID) {
        let affectedSheetID = outline.first { $0.id == entryID }?.pageID
        outline.removeAll { $0.id == entryID }
        if let affectedSheetID,
           let location = sheetLocation(for: affectedSheetID) {
            pages[location.documentIndex].sheets[location.sheetIndex].title = outlineEntries(for: affectedSheetID).first?.title
            touchDocument(at: location.documentIndex)
        }
        saveSoon()
    }

    func outlineEntries(for pageID: UUID) -> [OutlineEntry] {
        outline
            .filter { $0.pageID == pageID }
            .sorted { $0.position < $1.position }
    }

    func outlineEntries(in documentID: UUID) -> [OutlineEntry] {
        guard let document = pages.first(where: { $0.id == documentID }) else {
            return []
        }

        let sheetOrder = Dictionary(uniqueKeysWithValues: document.sheets.enumerated().map { ($0.element.id, $0.offset) })
        return outline
            .filter { sheetOrder[$0.pageID] != nil }
            .sorted { first, second in
                let firstPageIndex = sheetOrder[first.pageID] ?? Int.max
                let secondPageIndex = sheetOrder[second.pageID] ?? Int.max

                if firstPageIndex == secondPageIndex {
                    return first.position < second.position
                }

                return firstPageIndex < secondPageIndex
            }
    }

    func effectiveSectionTitle(for sheetID: UUID, in documentID: UUID) -> String? {
        guard let document = pages.first(where: { $0.id == documentID }),
              let sheetIndex = document.sheets.firstIndex(where: { $0.id == sheetID }) else {
            return nil
        }

        if let directTitle = document.sheets[sheetIndex].title?.trimmingCharacters(in: .whitespacesAndNewlines),
           !directTitle.isEmpty {
            return directTitle
        }

        let sheetOrder = Dictionary(uniqueKeysWithValues: document.sheets.enumerated().map { ($0.element.id, $0.offset) })
        let previousEntries = outline
            .filter { entry in
                guard let entryIndex = sheetOrder[entry.pageID] else {
                    return false
                }
                return entryIndex <= sheetIndex
            }
            .sorted { first, second in
                let firstIndex = sheetOrder[first.pageID] ?? Int.min
                let secondIndex = sheetOrder[second.pageID] ?? Int.min

                if firstIndex == secondIndex {
                    return first.position < second.position
                }

                return firstIndex < secondIndex
            }

        return previousEntries.last(where: { $0.level == 1 })?.title ?? previousEntries.last?.title
    }

    func saveImmediately() {
        saveTask?.cancel()
        do {
            try Self.save(PersistedNotebookSnapshot(
                folders: folders.map(PersistedFolder.init),
                pages: pages.map(PersistedPage.init),
                outline: outline.map(PersistedOutlineEntry.init)
            ))
            saveStatus = "Saved"
        } catch {
            saveStatus = "Save failed"
        }
    }

    private func pageIndex(for pageID: UUID) -> Int {
        pages.firstIndex { document in
            document.sheets.contains { $0.id == pageID }
        } ?? Int.max
    }

    private func sheetLocation(for sheetID: UUID) -> (documentIndex: Int, sheetIndex: Int)? {
        for documentIndex in pages.indices {
            if let sheetIndex = pages[documentIndex].sheets.firstIndex(where: { $0.id == sheetID }) {
                return (documentIndex, sheetIndex)
            }
        }
        return nil
    }

    private func moveSheetSelection(in documentID: UUID, by offset: Int) {
        guard let documentIndex = pages.firstIndex(where: { $0.id == documentID }),
              let currentIndex = pages[documentIndex].sheets.firstIndex(where: { $0.id == pages[documentIndex].selectedSheetID }) else {
            return
        }

        let nextIndex = min(max(currentIndex + offset, 0), pages[documentIndex].sheets.count - 1)
        pages[documentIndex].selectedSheetID = pages[documentIndex].sheets[nextIndex].id
        saveSoon()
    }

    private func touchDocument(at index: Int) {
        pages[index].sheets[pages[index].sheets.firstIndex { $0.id == pages[index].selectedSheetID } ?? 0].updatedAt = Date()
        pages[index].updatedAt = Date()
    }

    private func saveSoon() {
        saveStatus = "Saving..."
        let snapshot = PersistedNotebookSnapshot(
            folders: folders.map(PersistedFolder.init),
            pages: pages.map(PersistedPage.init),
            outline: outline.map(PersistedOutlineEntry.init)
        )

        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else {
                return
            }
            do {
                try Self.save(snapshot)
                saveStatus = "Saved"
            } catch {
                saveStatus = "Save failed"
            }
        }
    }

    private static var snapshotURL: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("IndexNote", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("library.json")
    }

    private static var legacySnapshotURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PaperFlow", isDirectory: true)
            .appendingPathComponent("library.json")
    }

    private static func save(_ snapshot: PersistedNotebookSnapshot) throws {
        let data = try JSONEncoder().encode(snapshot)
        try data.write(to: snapshotURL, options: [.atomic])
    }

    private static func loadSnapshot() -> PersistedNotebookSnapshot? {
        let url = FileManager.default.fileExists(atPath: snapshotURL.path) ? snapshotURL : legacySnapshotURL
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONDecoder().decode(PersistedNotebookSnapshot.self, from: data)
    }

}

private struct PersistedNotebookSnapshot: Codable {
    var folders: [PersistedFolder]
    var pages: [PersistedPage]
    var outline: [PersistedOutlineEntry] = []
}

private struct PersistedFolder: Codable {
    var id: UUID
    var name: String

    init(_ folder: NoteFolder) {
        id = folder.id
        name = folder.name
    }
}

private struct PersistedPage: Codable {
    var id: UUID
    var folderID: UUID
    var title: String
    var drawingData: Data?
    var template: PageTemplate.RawValue?
    var elements: [PersistedElement]?
    var sheets: [PersistedSheet]?
    var selectedSheetID: UUID?
    var isFavorite: Bool
    var updatedAt: Date

    init(_ page: NotebookPage) {
        id = page.id
        folderID = page.folderID
        title = page.title
        drawingData = nil
        template = nil
        elements = nil
        sheets = page.sheets.map(PersistedSheet.init)
        selectedSheetID = page.selectedSheetID
        isFavorite = page.isFavorite
        updatedAt = page.updatedAt
    }
}

private struct PersistedSheet: Codable {
    var id: UUID
    var title: String?
    var drawingData: Data
    var template: PageTemplate.RawValue
    var elements: [PersistedElement]
    var updatedAt: Date

    init(_ sheet: NotebookSheet) {
        id = sheet.id
        title = sheet.title
        drawingData = sheet.drawing.dataRepresentation()
        template = sheet.template.rawValue
        elements = sheet.elements.map(PersistedElement.init)
        updatedAt = sheet.updatedAt
    }
}

private struct PersistedElement: Codable {
    var id: UUID
    var kind: PageElementKind.RawValue
    var text: String
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var isRevealed: Bool

    init(_ element: PageElement) {
        id = element.id
        kind = element.kind.rawValue
        text = element.text
        x = Double(element.x)
        y = Double(element.y)
        width = Double(element.width)
        height = Double(element.height)
        isRevealed = element.isRevealed
    }
}

private struct PersistedOutlineEntry: Codable {
    var id: UUID
    var pageID: UUID
    var title: String
    var level: Int
    var position: Int

    init(_ entry: OutlineEntry) {
        id = entry.id
        pageID = entry.pageID
        title = entry.title
        level = entry.level
        position = entry.position
    }
}

private extension NoteFolder {
    init(_ persisted: PersistedFolder) {
        self.init(id: persisted.id, name: persisted.name)
    }
}

private extension NotebookPage {
    init?(_ persisted: PersistedPage) {
        let sheets: [NotebookSheet]

        if let persistedSheets = persisted.sheets, !persistedSheets.isEmpty {
            sheets = persistedSheets.map(NotebookSheet.init)
        } else {
            let drawing = persisted.drawingData.flatMap { try? PKDrawing(data: $0) } ?? PKDrawing()
            let template = persisted.template.flatMap(PageTemplate.init(rawValue:)) ?? .blank
            let elements = persisted.elements?.compactMap(PageElement.init) ?? []
            sheets = [NotebookSheet(drawing: drawing, template: template, elements: elements, updatedAt: persisted.updatedAt)]
        }

        self.init(
            id: persisted.id,
            folderID: persisted.folderID,
            title: persisted.title,
            sheets: sheets,
            selectedSheetID: persisted.selectedSheetID,
            isFavorite: persisted.isFavorite,
            updatedAt: persisted.updatedAt
        )
    }
}

private extension NotebookSheet {
    init(_ persisted: PersistedSheet) {
        let drawing = (try? PKDrawing(data: persisted.drawingData)) ?? PKDrawing()
        let template = PageTemplate(rawValue: persisted.template) ?? .blank
        let elements = persisted.elements.compactMap(PageElement.init)
        self.init(id: persisted.id, title: persisted.title, drawing: drawing, template: template, elements: elements, updatedAt: persisted.updatedAt)
    }

    func copyWithNewIdentity() -> NotebookSheet {
        NotebookSheet(title: title, drawing: drawing, template: template, elements: elements, updatedAt: Date())
    }
}

private extension PageElement {
    init?(_ persisted: PersistedElement) {
        guard let kind = PageElementKind(rawValue: persisted.kind) else {
            return nil
        }

        self.init(
            id: persisted.id,
            kind: kind,
            text: persisted.text,
            x: CGFloat(persisted.x),
            y: CGFloat(persisted.y),
            width: CGFloat(persisted.width),
            height: CGFloat(persisted.height),
            isRevealed: persisted.isRevealed
        )
    }
}

private extension OutlineEntry {
    init(_ persisted: PersistedOutlineEntry) {
        self.init(
            id: persisted.id,
            pageID: persisted.pageID,
            title: persisted.title,
            level: persisted.level,
            position: persisted.position
        )
    }
}
