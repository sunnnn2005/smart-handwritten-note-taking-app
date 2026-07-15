# PaperFlow QA Checklist

## Library

- [x] Launch app on iPad simulator.
- [x] Install latest build on physical iPad.
- [ ] Launch app on physical iPad. Blocked if device is locked.
- [x] Recents opens without selecting a note.
- [x] Favorites empty state appears when no favorites exist.
- [x] Folder row opens file grid, not editor.
- [ ] Create folder.
- [ ] Rename folder.
- [ ] Duplicate folder.
- [ ] Delete folder confirmation.
- [x] Search filters notes.
- [x] New creates a note in the current folder.
- [x] PDF import creates an imported note placeholder.

## Editor

- [ ] Open note from library.
- [ ] Return button goes back to folder/library.
- [x] A folder item opens as a notebook/file instead of a single loose page.
- [x] Current file shows page number such as `Page 1 / 2`.
- [x] Add page creates a new blank page inside the current file.
- [x] Previous/next page buttons switch pages inside the same file.
- [x] Each page has independent handwriting, template, elements, and headings.
- [ ] Pen draws.
- [ ] Highlighter draws translucent ink.
- [ ] Eraser removes strokes.
- [ ] Undo works.
- [ ] Redo works.
- [ ] Clear note works.
- [ ] Template switching preserves drawing.
- [ ] Text tool inserts editable text.
- [ ] Sticky note inserts and edits.
- [ ] Tape inserts and reveals.
- [ ] Shape inserts and moves.
- [ ] Favorite toggle updates library.
- [ ] Duplicate note works.
- [ ] Delete note confirmation.
- [ ] Export note opens share sheet.

## Heading Recognition

- [ ] Write `# Test Heading`.
- [ ] Scan Heading does not crash.
- [ ] Scan Heading finds heading.
- [ ] Multiple headings are detected.
- [ ] Scanning page with no handwriting shows clear failure.
- [ ] Heading updates note title.

## Persistence

- [ ] Drawing persists after returning to library.
- [ ] Drawing persists after app relaunch.
- [ ] Folder changes persist after app relaunch.
- [ ] Text/sticky/tape/shape elements persist after app relaunch.
- [x] Outline entries are included in local persistence snapshot.

## Bugs Found And Fixed

- [x] Converted files from single-page notes into multi-page notebooks.
- [x] Removed misleading fake Select behavior and replaced it with actionable New/Import menu behavior.
- [x] Replaced leftover SmartNotes branding in the template library with PaperFlow.
- [x] Synced floating page elements with parent state so they do not keep stale text or position after refresh.
- [x] Fixed sidebar long-title wrapping by scaling folder/resource row text.
- [x] Kept disabled future features honest: PDF import is currently a placeholder, document scanning is not exposed as a working action.
- [x] Verified simulator build succeeds.
- [x] Verified physical iPad debug build succeeds and installs.
- [x] Verified HeadingParser unit tests pass.

## Architecture Gap

- [ ] Upgrade data model from `folder -> single-page notes` to `folder -> notebook/file -> multiple pages`. This is the main mismatch with the intended Notes+ style product.

## Known Simulator Limits

- Apple Pencil pressure cannot be fully validated in simulator.
- Real handwriting OCR quality must be validated on physical iPad.
