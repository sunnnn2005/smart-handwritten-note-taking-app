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
- Detect handwritten headings that begin with `#`, `##`, or `###`
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
- Built a testable heading parser that normalizes OCR variants such as full-width
  hash marks and supports multi-level table-of-contents entries.

## Run on iPad

The repository includes `SmartNotes.xcodeproj`, which contains:

- `SmartNotes`: the iOS app target
- `SmartNotesCore`: the reusable heading parser framework

To test on a real iPad:

1. Open `SmartNotes.xcodeproj` in Xcode.
2. Select the `SmartNotes` scheme.
3. Connect your iPad with USB or use Xcode wireless debugging.
4. In the project signing settings, choose your Apple ID team.
5. Select your iPad as the run destination.
6. Press Run.

Apple Pencil testing works best on a real iPad. The simulator can compile the
app, but it cannot fully validate the handwriting workflow.

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
Xcode iOS app target. `SmartNotes.xcodeproj` is included for running the app on
simulator or device. The Swift package focuses on UI-independent heading parsing
logic so the most important OCR parsing behavior can be tested without an iPad
simulator.

Build the iOS app target without code signing:

```bash
xcodebuild -project SmartNotes.xcodeproj -scheme SmartNotes -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project SmartNotes.xcodeproj -scheme SmartNotes -configuration Debug -sdk iphoneos -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

## Architecture

See `docs/architecture.md` for the app layers, OCR flow, and design tradeoffs.

## Project Roadmap

- Add multi-notebook support
- Add OCR confidence scoring and edit flow
- Add PDF export
- Add search across recognized headings
- Add iCloud sync
- Add a small onboarding flow explaining the `# Heading` gesture
