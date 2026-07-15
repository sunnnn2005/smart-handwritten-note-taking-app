# PaperFlow App Store Readiness

## Current MVP Status

- App name and display name: PaperFlow.
- Core handwriting: PencilKit drawing, pen, highlighter, eraser, undo, redo.
- Core differentiator: handwritten `# Heading` recognition creates note titles and outline entries.
- Library: folders, recents, favorites, search, create note, create folder.
- Persistence: local JSON snapshot with PencilKit drawing data and note elements.
- Export: current page image export through the iOS share sheet.
- Tests: heading parser unit tests.

## Fixed Before Submission

- Folder selection opens a file grid instead of immediately opening the editor.
- Local auto-save is debounced to avoid excessive writes while drawing.
- Delete actions require confirmation.
- Empty folders show a clear empty state.
- Placeholder marketplace/cloud actions were removed or disabled.
- App metadata includes privacy strings for future camera, microphone, and photo usage.

## Required Before Real App Store Submission

- Create a real AppIcon asset set and launch screen polish.
- Replace debug/development signing with App Store distribution signing.
- Add full Privacy Nutrition Label answers in App Store Connect.
- Add Terms of Use and Privacy Policy links if any cloud, account, or AI features are added.
- Implement real PDF page rendering and annotation export before advertising PDF annotation.
- Add screenshot set for iPad and iPhone sizes.
- Test on at least one physical iPad and one iPhone layout.
- Run Release archive validation in Xcode Organizer.

## Strong Next Product Milestones

- Multi-page notebooks instead of one-page note files.
- Page thumbnail sidebar in the editor.
- Rename note and move note to folder.
- Full PDF import using PDFKit page backgrounds.
- PDF export that includes background, ink, text, shapes, and stickers.
- Image insertion from Photos/Files.
- Lasso selection and move/delete.
- In-app onboarding for the `# Heading` workflow.
