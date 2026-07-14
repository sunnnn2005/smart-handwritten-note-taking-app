# Architecture

## Product Goal

Smart Handwritten Note-Taking App is designed around a handwriting-first workflow:
students can write notes naturally with Apple Pencil and mark headings with `#`
to generate a table of contents automatically.

## Layers

### iOS App Layer

Path: `SmartNotes/`

- `NotebookView.swift` renders the split-view note interface.
- `PencilCanvasView.swift` wraps `PKCanvasView` for Apple Pencil input.
- `NotebookStore.swift` stores pages, selected page state, and outline entries.
- `HeadingRecognizer.swift` runs Vision OCR over a `PKDrawing`.

### Core Logic Layer

Path: `Sources/SmartNotesCore/`

- `HeadingParser.swift` normalizes OCR text and extracts headings marked with
  `#`, `##`, or `###`.
- This layer is intentionally UI-independent so it can be tested with `swift test`.

### Testing Layer

Path: `Tests/SmartNotesCoreTests/`

- Tests heading extraction, whitespace cleanup, full-width hash handling, and
  ignored non-heading text.

## OCR Flow

1. User writes on a PencilKit canvas.
2. App converts the `PKDrawing` into an image.
3. Vision OCR returns candidate text observations.
4. `HeadingParser` scans recognized text for lines starting with heading markers
   such as `#`, full-width `＃`, or OCR fallback `♯`.
5. The app creates or updates an outline entry for the current page.
6. User taps the outline entry to jump back to that page.

## Design Tradeoffs

- A special marker such as `#` is more reliable than guessing which handwritten
  text is intended to be a heading.
- Heading extraction is page-level in the MVP; section-level anchors can be added
  later by storing bounding boxes from Vision OCR.
- OCR correction is not in the MVP, but the architecture can support editable
  outline titles later.
- The parser supports three heading levels so the table of contents can grow
  from a flat page list into a nested outline.
