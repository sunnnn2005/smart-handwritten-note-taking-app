# Smart Handwritten Note-Taking App

An iPad note-taking app concept with Apple Pencil support and automatic table of
contents generation from handwritten headings. Users write headings with a
special marker such as `#`, and the app recognizes those headings with OCR and
turns them into navigable outline entries.

## Why This Project

This project is personal, product-minded, and technically distinctive. It shows
iOS development, human-computer interaction thinking, OCR, local persistence,
and a workflow designed around a real student pain point.

## Tech Stack

- Swift
- SwiftUI
- PencilKit
- Vision OCR
- Swift Package Manager
- Core Data or SwiftData

## MVP Features

- Create a notebook
- Add handwritten pages with Apple Pencil
- Save pages locally
- Detect handwritten headings that begin with `#`
- Generate a table of contents from detected headings
- Tap a heading to jump to the matching page
- Testable heading parsing logic in `SmartNotesCore`

## Resume Bullets

- Created an iPad note-taking app with Apple Pencil support, handwritten page
  creation, page navigation, and persistent local note storage.
- Integrated Vision OCR to detect handwritten headings marked with a special
  symbol such as `#`, automatically converting recognized titles into a table of
  contents.
- Implemented outline-based navigation that maps detected headings to note pages,
  allowing users to jump between handwritten sections without manually typing
  titles.

## Suggested Xcode Setup

1. Open `Package.swift` in Xcode to inspect and test `SmartNotesCore`.
2. Create a new iOS app in Xcode named `SmartNotes`.
3. Choose SwiftUI as the interface.
4. Add the files in `SmartNotes/` to the Xcode project.
5. Add the local package target `SmartNotesCore` to the app target.
6. Run on an iPad simulator or physical iPad. Apple Pencil testing works best on
   a real device.

## Local Verification

Build the core package:

```bash
swift build
```

Run core tests:

```bash
swift test
```

Note: `SmartNotes/` contains the iPad app layer and should be compiled from an
Xcode iOS app target. The Swift package focuses on UI-independent heading
parsing logic so the most important OCR parsing behavior can be tested without
an iPad simulator.

## Architecture

See `docs/architecture.md` for the app layers, OCR flow, and design tradeoffs.

## Project Roadmap

- Add multi-notebook support
- Add OCR confidence scoring and edit flow
- Add PDF export
- Add search across recognized headings
- Add iCloud sync
- Add a small onboarding flow explaining the `# Heading` gesture
