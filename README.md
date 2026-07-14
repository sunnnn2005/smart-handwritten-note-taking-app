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
- Core Data or SwiftData

## MVP Features

- Create a notebook
- Add handwritten pages with Apple Pencil
- Save pages locally
- Detect handwritten headings that begin with `#`
- Generate a table of contents from detected headings
- Tap a heading to jump to the matching page

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

1. Create a new iOS app in Xcode named `SmartNotes`.
2. Choose SwiftUI as the interface.
3. Add the files in `SmartNotes/` to the Xcode project.
4. Run on an iPad simulator or physical iPad. Apple Pencil testing works best on
   a real device.

## Project Roadmap

- Add multi-notebook support
- Add OCR confidence scoring and edit flow
- Add PDF export
- Add search across recognized headings
- Add iCloud sync
- Add a small onboarding flow explaining the `# Heading` gesture
