import Foundation
import PencilKit
import SwiftUI
import UIKit

enum NoteTool: String, CaseIterable, Identifiable {
    case pen
    case highlighter
    case eraser
    case text
    case tape
    case shape

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .pen:
            "pencil"
        case .highlighter:
            "highlighter"
        case .eraser:
            "eraser"
        case .text:
            "textformat"
        case .tape:
            "rectangle.fill.on.rectangle.fill"
        case .shape:
            "circle.square"
        }
    }
}

enum LibrarySection: Hashable {
    case recents
    case favorites
    case templateLibrary
    case fonts
    case folder(UUID)
}

enum EditorSidebarTab: String, CaseIterable, Identifiable {
    case pages = "Pages"
    case outline = "Outline"

    var id: String { rawValue }
}

struct NoteFolder: Identifiable, Hashable {
    let id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}

enum InkColor: String, CaseIterable, Identifiable {
    case black
    case red
    case blue
    case green
    case purple

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .black:
            .primary
        case .red:
            .red
        case .blue:
            .blue
        case .green:
            .green
        case .purple:
            .purple
        }
    }

    var uiColor: UIColor {
        switch self {
        case .black:
            .label
        case .red:
            .systemRed
        case .blue:
            .systemBlue
        case .green:
            .systemGreen
        case .purple:
            .systemPurple
        }
    }
}

enum PageTemplate: String, CaseIterable, Identifiable {
    case blank
    case ruled
    case grid
    case dotted
    case cornell
    case dailyPlanner

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dailyPlanner:
            "Daily Planner"
        default:
            rawValue.capitalized
        }
    }
}

struct CanvasCommand: Equatable {
    enum Action: Equatable {
        case undo
        case redo
        case clear
    }

    let id = UUID()
    let action: Action
}

enum PageElementKind: String {
    case textBox
    case stickyNote
    case tape
    case shape
}

struct PageElement: Identifiable, Equatable {
    let id: UUID
    var kind: PageElementKind
    var text: String
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat
    var isRevealed: Bool

    init(
        id: UUID = UUID(),
        kind: PageElementKind,
        text: String,
        x: CGFloat = 120,
        y: CGFloat = 120,
        width: CGFloat = 220,
        height: CGFloat = 96,
        isRevealed: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.text = text
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.isRevealed = isRevealed
    }
}

struct NotebookSheet: Identifiable {
    let id: UUID
    var title: String?
    var drawing: PKDrawing
    var template: PageTemplate
    var elements: [PageElement]
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String? = nil,
        drawing: PKDrawing = PKDrawing(),
        template: PageTemplate = .blank,
        elements: [PageElement] = [],
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.drawing = drawing
        self.template = template
        self.elements = elements
        self.updatedAt = updatedAt
    }
}

struct NotebookPage: Identifiable {
    let id: UUID
    var folderID: UUID
    var title: String
    var sheets: [NotebookSheet]
    var selectedSheetID: UUID
    var isFavorite: Bool
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        folderID: UUID,
        title: String = "Untitled Note",
        sheets: [NotebookSheet] = [NotebookSheet()],
        selectedSheetID: UUID? = nil,
        isFavorite: Bool = false,
        updatedAt: Date = Date()
    ) {
        let resolvedSheets = sheets.isEmpty ? [NotebookSheet()] : sheets
        let resolvedSelectedSheetID = selectedSheetID.flatMap { candidate in
            resolvedSheets.contains { $0.id == candidate } ? candidate : nil
        } ?? resolvedSheets[0].id

        self.id = id
        self.folderID = folderID
        self.title = title
        self.sheets = resolvedSheets
        self.selectedSheetID = resolvedSelectedSheetID
        self.isFavorite = isFavorite
        self.updatedAt = updatedAt
    }

    var currentSheet: NotebookSheet {
        sheets.first { $0.id == selectedSheetID } ?? sheets[0]
    }

    var pageCount: Int {
        sheets.count
    }

    var currentPageNumber: Int {
        (sheets.firstIndex { $0.id == selectedSheetID } ?? 0) + 1
    }
}

struct OutlineEntry: Identifiable {
    let id: UUID
    let pageID: UUID
    let title: String
    let level: Int
    let position: Int
}
