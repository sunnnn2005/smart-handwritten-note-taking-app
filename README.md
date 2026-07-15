# IndexNote: Smart Handwritten Note-Taking App

IndexNote is an iPad-first handwritten note-taking app built with SwiftUI,
PencilKit, and Vision OCR. The core feature is automatic outline generation:
students can write headings such as `# Chapter 1`, `## Lecture 2`, or
`### Example`, scan the page, and turn handwritten headings into a navigable
table of contents.

## Highlights

- Apple Pencil writing experience built with PencilKit
- Folder-based note library with recent notes, favorites, templates, and
  multi-page notes
- Handwritten heading detection using Vision OCR
- Automatic table-of-contents generation from `#`, `##`, and `###` headings
- Section inheritance: a heading written on one page applies to following pages
  until the next heading
- Reusable Swift package for heading parsing with unit tests
- iPad simulator and physical iPad build support through Xcode

## Why This Project

This project solves a real student workflow problem: when taking handwritten
lecture notes on an iPad, creating a clean table of contents usually requires
manual typing or page-by-page organization. IndexNote keeps the workflow
handwritten while still making notes navigable.

The project demonstrates iOS development, OCR integration, local persistence,
product design, and testable parsing logic.

## Tech Stack

- Swift
- SwiftUI
- PencilKit
- Vision OCR
- Swift Package Manager
- XCTest
- Xcode iOS app target

## Core Features

- Create and organize notes inside folders
- Add, duplicate, delete, and navigate pages within a note
- Write directly on the canvas with Apple Pencil
- Choose drawing tools, colors, stroke width, page templates, and note elements
- Detect handwritten outline headings beginning with `#`
- Generate a navigable outline linked to stable page IDs
- Preserve document titles separately from page-level outline sections
- Persist notes locally between app launches

## Example Workflow

1. Create a note for a class lecture.
2. Write `# Chapter 1` on page 1.
3. Add pages and continue writing notes.
4. Write `# Chapter 2` on a later page.
5. Tap **Detect Outline** to scan handwritten headings.
6. Use the outline sidebar to jump between chapters.

Pages after `# Chapter 1` inherit that section title until the next `#` heading
appears.

## Resume Bullets

- Built an iPad-first note-taking app with Apple Pencil support, persistent
  handwritten pages, multi-page navigation, and folder-based organization.
- Integrated Vision OCR to detect handwritten headings marked with `#`,
  automatically converting recognized titles into navigable table-of-contents
  entries.
- Implemented section inheritance logic so a heading written on one page applies
  to following pages until the next heading, matching a real student
  note-taking workflow.
- Designed reusable heading parser logic supporting multi-level outline tags,
  OCR normalization, and unit tests for edge cases.

## Run on iPad

The repository includes `SmartNotes.xcodeproj`, which contains:

- `SmartNotes`: the iOS app target
- `SmartNotesCore`: the reusable heading parser framework

To test on a real iPad:

1. Open `SmartNotes.xcodeproj` in Xcode.
2. Select the `SmartNotes` scheme.
3. Connect an iPad with USB or use Xcode wireless debugging.
4. In project signing settings, choose an Apple ID team.
5. Select the iPad as the run destination.
6. Press Run.

Apple Pencil testing works best on a real iPad. The simulator can compile and
exercise the interface, but it cannot fully validate handwriting ergonomics.

## Local Verification

Run parser tests:

```bash
swift test
```

Build the iOS app target without code signing:

```bash
xcodebuild -project SmartNotes.xcodeproj -scheme SmartNotes -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

## Documentation

- [`docs/product-spec.md`](docs/product-spec.md)
- [`docs/architecture.md`](docs/architecture.md)
- [`docs/qa-checklist.md`](docs/qa-checklist.md)
- [`docs/app-store-readiness.md`](docs/app-store-readiness.md)

## Interview Talking Points

- Why page-level outline anchors should not overwrite the document title
- How OCR output is normalized before parsing
- How stable page IDs make outline navigation safer than using page indices
- Why Apple Pencil workflows need real-device testing
- How the parser is separated into a reusable Swift package for unit testing

## Project Roadmap

- Add searchable recognized text across all notes
- Add PDF export and import polish
- Add iCloud sync
- Add OCR confidence review and manual correction flow
- Add onboarding for the `# Heading` gesture
