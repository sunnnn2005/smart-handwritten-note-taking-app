# PaperFlow Notes+ Course Workflow Audit

## What A Real Course Note Session Needs

Sources reviewed: Notes+ App Store listing, Notes+ website, Notes+ split-screen/table study posts, and general iPad note-taking app feature references.

1. Create a course folder such as `STA 108`.
2. Create one file per lecture, such as `Lecture 01 - Linear Regression`.
3. Open a lecture file and take notes across many pages.
4. Add pages fast during lecture without breaking writing flow.
5. Move backward and forward between pages.
6. Use templates per page: blank, ruled, grid, dotted, Cornell, planner.
7. Import lecture materials such as PDFs, PPTs, images, and web pages.
8. Reference course content while writing, ideally with split view, PiP, screenshot, or linked document support.
9. Use note-taking tools beyond pen: highlighter, eraser, text, shapes, tape/cover, lasso, tables, images, audio.
10. Search and organize notes by folders, favorites, recents, and clear file names.

## Current PaperFlow Status

- Course folders exist.
- Lecture files exist as notebook documents.
- Each file now supports multiple pages.
- Page add, previous page, next page, delete current page, and page count exist.
- Each page has independent handwriting, template, inserted elements, and heading scan.
- Lecture files can be renamed from the file grid context menu.
- Scan Heading can turn handwritten `# Title` into a file title and contents panel entry.
- Local save persists folders, files, pages, elements, and headings.

## Bugs Fixed During This Pass

- Duplicating a file or folder used to reuse internal page IDs, which could make headings and page state collide. Copies now get fresh page IDs.
- Loaded files with invalid selected page IDs now fall back to the first page.
- Long-press file actions now include rename.

## Biggest Remaining Gaps

- PDF import is still a placeholder; imported PDFs do not become annotated page backgrounds yet.
- There is no page thumbnail strip or grid view inside the editor.
- There is no lasso, image insertion, table tool, audio recording, split document view, or video/PiP study mode yet.
- There is no true handwriting search across all pages.
- Export currently exports only the current page image, not the full multi-page notebook PDF.
- There is no drag-and-drop file moving between folders yet.
- App Store readiness still needs icon, privacy review, crash QA, release archive, and real-device Apple Pencil test coverage.
