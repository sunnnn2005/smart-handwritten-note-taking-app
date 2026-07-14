# Product Spec

## Problem

When taking class notes on an iPad, creating page titles and organizing a table
of contents often requires switching from handwriting to typing or manually
creating pages. This interrupts the note-taking flow.

## Solution

Let users keep writing with Apple Pencil. When the user writes a heading with a
marker such as `# Regression Notes`, the app detects the heading, recognizes the
text, and adds it to the notebook outline automatically.

## Core User Flow

1. User opens a notebook.
2. User writes notes naturally with Apple Pencil.
3. User writes a heading with `#` at the beginning.
4. User taps "Scan Headings" or the app scans after a short idle period.
5. The recognized heading appears in the table of contents.
6. User taps a table-of-contents row to jump to that page.

## MVP Constraints

- The first version scans one page at a time.
- The first version treats headings as page-level anchors.
- OCR mistakes can be corrected later in the roadmap.
- Local persistence is enough for MVP; cloud sync is not required.

## Deep-Dive Talking Points

- Why a handwriting-first workflow is better for lectures.
- Why special-marker recognition is more reliable than guessing every title.
- How OCR confidence and user correction would improve accuracy.
- How local page storage maps to notebook navigation.
- How this differs from a generic drawing app.
