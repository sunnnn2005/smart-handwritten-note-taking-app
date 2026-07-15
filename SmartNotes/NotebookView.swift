import PencilKit
import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct NotebookView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = NotebookStore()
    @State private var scanStatus: String?
    @State private var isScanning = false
    @State private var searchText = ""
    @State private var selectedTool: NoteTool = .pen
    @State private var selectedColor: InkColor = .black
    @State private var strokeWidth: CGFloat = 4
    @State private var canvasCommand: CanvasCommand?
    @State private var isResourceExpanded = true
    @State private var isShowingNewFolder = false
    @State private var isShowingSettings = false
    @State private var newFolderName = ""
    @State private var folderNameDraft = ""
    @State private var editingFolderID: UUID?
    @State private var noteTitleDraft = ""
    @State private var editingPageID: UUID?
    @State private var shareImage: ShareImage?
    @State private var pendingPageDeleteID: UUID?
    @State private var pendingFolderDeleteID: UUID?
    @State private var isImportingPDF = false
    @State private var editorSidebarTab: EditorSidebarTab = .pages
    @State private var isShowingManualOutline = false
    @State private var manualOutlineTitle = ""
    @State private var manualOutlineLevel = 1
    @State private var isEditorSidebarVisible = false

    var body: some View {
        NavigationSplitView {
            librarySidebar
        } detail: {
            if let page = store.selectedPage, let sheet = store.selectedSheet {
                editor(for: page, sheet: sheet)
            } else {
                libraryDetail
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $isShowingNewFolder) {
            newFolderSheet
        }
        .sheet(isPresented: $isShowingSettings) {
            settingsSheet
        }
        .sheet(isPresented: $isShowingManualOutline) {
            manualOutlineSheet
        }
        .sheet(item: $shareImage) { item in
            ShareSheet(items: [item.image])
        }
        .fileImporter(isPresented: $isImportingPDF, allowedContentTypes: [.pdf], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else {
                    scanStatus = "Import canceled."
                    return
                }
                store.importPDFPlaceholder(named: url.lastPathComponent)
                scanStatus = "Imported \(url.lastPathComponent). PDF annotation rendering is next."
            case .failure(let error):
                scanStatus = "Import failed: \(error.localizedDescription)"
            }
        }
        .confirmationDialog("Delete this note?", isPresented: Binding(
            get: { pendingPageDeleteID != nil },
            set: { if !$0 { pendingPageDeleteID = nil } }
        ), titleVisibility: .visible) {
            Button("Delete Note", role: .destructive) {
                if let pendingPageDeleteID {
                    deletePage(pendingPageDeleteID)
                }
                pendingPageDeleteID = nil
            }
            Button("Cancel", role: .cancel) {
                pendingPageDeleteID = nil
            }
        } message: {
            Text("This removes the note and its handwriting from IndexNote.")
        }
        .confirmationDialog("Delete this folder?", isPresented: Binding(
            get: { pendingFolderDeleteID != nil },
            set: { if !$0 { pendingFolderDeleteID = nil } }
        ), titleVisibility: .visible) {
            Button("Delete Folder", role: .destructive) {
                if let pendingFolderDeleteID {
                    store.deleteFolder(pendingFolderDeleteID)
                }
                pendingFolderDeleteID = nil
            }
            Button("Cancel", role: .cancel) {
                pendingFolderDeleteID = nil
            }
        } message: {
            Text("All notes inside this folder will be removed.")
        }
        .alert("Rename Note", isPresented: Binding(
            get: { editingPageID != nil },
            set: { if !$0 { editingPageID = nil } }
        )) {
            TextField("Lecture title", text: $noteTitleDraft)
            Button("Cancel", role: .cancel) {
                editingPageID = nil
            }
            Button("Save") {
                if let editingPageID {
                    store.renamePage(editingPageID, to: noteTitleDraft)
                }
                editingPageID = nil
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                store.saveImmediately()
            }
        }
    }

    private var librarySidebar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Text("IndexNote")
                    .font(.system(size: 27, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer()
                Button {
                    isShowingSettings = true
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 26, weight: .bold))
                }
                Button {
                    isResourceExpanded.toggle()
                } label: {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 25, weight: .bold))
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 22)

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    sidebarRow(title: "Recents", icon: "clock", count: nil, section: .recents)
                    sidebarRow(title: "Favorites", icon: "heart", count: nil, section: .favorites)

                    Button {
                        isResourceExpanded.toggle()
                    } label: {
                        HStack {
                            Text("Resource")
                                .font(.system(size: 28, weight: .bold))
                            Spacer()
                            Image(systemName: isResourceExpanded ? "chevron.down" : "chevron.right")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                    }
                    .buttonStyle(.plain)

                    if isResourceExpanded {
                        sidebarRow(title: "Template Library", icon: "book.closed", count: nil, section: .templateLibrary)
                        sidebarRow(title: "Fonts", icon: "textformat", count: nil, section: .fonts)
                    }

                    Text("Folders")
                        .font(.system(size: 28, weight: .bold))
                        .padding(.horizontal, 24)
                        .padding(.top, 18)

                    ForEach(store.folders) { folder in
                        sidebarRow(title: folder.name, icon: "folder", count: store.count(for: .folder(folder.id)), section: .folder(folder.id))
                            .contextMenu {
                                Button("Rename") {
                                    folderNameDraft = folder.name
                                    editingFolderID = folder.id
                                }
                                Button("Duplicate Folder") {
                                    store.duplicateFolder(folder.id)
                                }
                                Button("Delete Folder", role: .destructive) {
                                    pendingFolderDeleteID = folder.id
                                }
                            }
                    }
                }
                .padding(.bottom, 16)
            }

            Divider()
            HStack {
                Button {
                    isShowingNewFolder = true
                } label: {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 30, weight: .semibold))
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(24)
        }
        .background(Color(red: 0.10, green: 0.11, blue: 0.12))
        .alert("Rename Folder", isPresented: Binding(
            get: { editingFolderID != nil },
            set: { if !$0 { editingFolderID = nil } }
        )) {
            TextField("Folder name", text: $folderNameDraft)
            Button("Cancel", role: .cancel) {
                editingFolderID = nil
            }
            Button("Save") {
                if let editingFolderID {
                    store.renameFolder(editingFolderID, to: folderNameDraft)
                }
                editingFolderID = nil
            }
        }
    }

    private func sidebarRow(title: String, icon: String, count: Int?, section: LibrarySection) -> some View {
        Button {
            store.openLibrary(section)
            scanStatus = nil
        } label: {
            HStack(spacing: 18) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .frame(width: 34)
                Text(title)
                    .font(.system(size: 24, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Spacer()
                if let count {
                    Text("\(count)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(store.selectedSection == section ? Color.pink : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 18)
        }
        .buttonStyle(.plain)
    }

    private var libraryDetail: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Button {
                    isShowingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 24, weight: .bold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.12))

                if isFolderSection {
                    Menu {
                        Button("New Blank Note") {
                            addPage()
                        }
                        Button("Choose PDF File") {
                            isImportingPDF = true
                        }
                        Button("Folder Actions") {
                            scanStatus = "Long press a folder or note to rename, favorite, duplicate, or delete."
                        }
                    } label: {
                        Label("New", systemImage: "plus")
                            .font(.system(size: 21, weight: .bold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.pink)
                }

                Spacer()

                Button {
                    isShowingNewFolder = true
                } label: {
                    Image(systemName: "folder.badge.plus")
                }
                .buttonStyle(.bordered)

                Button {
                    addPage()
                } label: {
                    Label("Note", systemImage: "square.and.pencil")
                        .font(.system(size: 21, weight: .bold))
                }
                .buttonStyle(.bordered)

                Menu {
                    Button("Choose PDF File") {
                        isImportingPDF = true
                    }
                    Button("Scan Document") {
                        scanStatus = "Document scanning will be added after PDF rendering."
                    }
                    .disabled(true)
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                        .font(.system(size: 21, weight: .bold))
                }
                .buttonStyle(.bordered)
            }

            Text(libraryTitle)
                .font(.system(size: 46, weight: .bold))
            Text(store.saveStatus)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(store.saveStatus == "Saved" ? .green : .secondary)

            searchBar

            switch store.selectedSection {
            case .templateLibrary:
                templateLibraryView
            case .fonts:
                fontsView
            case .favorites where filteredPages.isEmpty:
                emptyFavoritesView
            default:
                notesGrid
            }

            Spacer()
            footerSummary
        }
        .padding(.horizontal, 32)
        .padding(.top, 18)
        .background(Color.black)
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 28, weight: .bold))
            TextField("Search", text: $searchText)
                .font(.system(size: 28, weight: .bold))
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 20)
        .frame(height: 62)
        .background(Color(red: 0.12, green: 0.12, blue: 0.13))
        .clipShape(Capsule())
    }

    private var notesGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 38)], alignment: .leading, spacing: 46) {
                if filteredPages.isEmpty {
                    emptyFolderCard
                }

                ForEach(filteredPages) { page in
                    Button {
                        store.selectPage(page.id)
                    } label: {
                        NoteTile(page: page)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Rename") {
                            noteTitleDraft = page.title
                            editingPageID = page.id
                        }
                        Button(page.isFavorite ? "Remove Favorite" : "Add Favorite") {
                            store.toggleFavorite(page.id)
                        }
                        Button("Duplicate") {
                            store.duplicatePage(page.id)
                        }
                        Button("Delete", role: .destructive) {
                            pendingPageDeleteID = page.id
                        }
                    }
                }
            }
            .padding(.top, 30)
            .padding(.bottom, 80)
        }
    }

    private var emptyFolderCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 54, weight: .semibold))
                .foregroundStyle(.pink)
            Text("No notes yet")
                .font(.system(size: 22, weight: .bold))
            Text("Tap New to create the first note in this folder.")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 220, height: 180)
    }

    private var emptyFavoritesView: some View {
        Text("Favorited files are displayed here. You can long press on a file to add it to your favorites.")
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.top, 12)
    }

    private var templateLibraryView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                HStack(spacing: 36) {
                    Text("Planner Notebook").foregroundStyle(.pink)
                    Text("Basic")
                    Text("Vocabulary Notebook")
                    Text("Reading Notebook")
                }
                .font(.system(size: 24, weight: .bold))

                VStack(alignment: .leading, spacing: 12) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(colors: [.white, .purple.opacity(0.18)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(height: 420)
                        .overlay {
                            VStack(spacing: 12) {
                                Text("MINIMALIST & STUDY FRIENDLY")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(.black.opacity(0.7))
                                Text("DIGITAL PLANNER")
                                    .font(.system(size: 50, weight: .bold, design: .serif))
                                    .foregroundStyle(.black)
                                HStack(spacing: 22) {
                                    PlannerPreview(title: "Weekly Planner")
                                    PlannerPreview(title: "Course Notes")
                                }
                            }
                        }
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Undated Study Planner")
                                .font(.system(size: 24, weight: .bold))
                            Text("IndexNote")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("Free")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.pink)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.top, 10)
        }
    }

    private var fontsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Preview handwriting-friendly fonts for cleaner, more structured notes.")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 34) {
                    Text("All")
                    Text("Serif")
                    Text("Sans-Serif")
                    Text("Handwritten").foregroundStyle(.pink)
                    Text("Symbols")
                    Text("Monospace")
                    Text("Display")
                }
                .font(.system(size: 21, weight: .bold))
                .padding(.top, 10)

                ForEach(fontSamples, id: \.0) { sample in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(sample.0)
                            .foregroundStyle(.secondary)
                            .font(.system(size: 18, weight: .bold))
                        Text("Make every word beautiful")
                            .font(.custom(sample.1, size: 30))
                    }
                    Divider()
                }
            }
            .padding(.top, 12)
        }
    }

    private var fontSamples: [(String, String)] {
        [
            ("Alex Brush", "Snell Roundhand"),
            ("Allura", "Zapfino"),
            ("Amatic SC", "AvenirNextCondensed-Bold"),
            ("Architects Daughter", "Chalkboard SE"),
            ("Bad Script", "Marker Felt")
        ]
    }

    private var footerSummary: some View {
        Text("\(filteredPages.count) Item\(filteredPages.count == 1 ? "" : "s"), On My iPad ⓘ")
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 10)
    }

    private var filteredPages: [NotebookPage] {
        let pages = store.pages(for: store.selectedSection)
        guard !searchText.isEmpty else {
            return pages
        }

        return pages.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    private var libraryTitle: String {
        switch store.selectedSection {
        case .recents:
            "Recents"
        case .favorites:
            "Favorites"
        case .templateLibrary:
            "Template Library"
        case .fonts:
            "Fonts"
        case .folder(let folderID):
            store.folderName(for: folderID)
        }
    }

    private var isFolderSection: Bool {
        if case .folder = store.selectedSection {
            return true
        }

        return false
    }

    private var newFolderSheet: some View {
        VStack(spacing: 22) {
            Text("New Folder")
                .font(.system(size: 28, weight: .bold))
            Image(systemName: "folder")
                .font(.system(size: 72, weight: .medium))
                .foregroundStyle(.pink)
            TextField("Name", text: $newFolderName)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 24, weight: .semibold))
                .padding(.horizontal, 40)
            HStack {
                Button("Cancel") {
                    newFolderName = ""
                    isShowingNewFolder = false
                }
                .buttonStyle(.bordered)
                Spacer()
                Button("Create") {
                    store.addFolder(named: newFolderName)
                    newFolderName = ""
                    isShowingNewFolder = false
                }
                .buttonStyle(.borderedProminent)
                .tint(.pink)
                .disabled(newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 40)
        }
        .presentationDetents([.height(330)])
        .padding(.vertical, 24)
    }

    private var settingsSheet: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Label("Dark mode optimized for iPad", systemImage: "moon")
                    Label("IndexNote accent color", systemImage: "paintpalette")
                        .foregroundStyle(.pink)
                }
                Section("Default Tools") {
                    HStack {
                        Label("Default tool", systemImage: selectedTool.iconName)
                        Spacer()
                        Text(selectedTool.rawValue.capitalized)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Label("Stroke width", systemImage: "line.diagonal")
                        Slider(value: $strokeWidth, in: 2...12, step: 1)
                    }
                }
                Section("Data") {
                    Label("Local auto-save is on", systemImage: "externaldrive.badge.checkmark")
                    Label("AI summary sidebar reserved for future milestone", systemImage: "sparkles")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        isShowingSettings = false
                    }
                }
            }
        }
    }

    private func editor(for page: NotebookPage, sheet: NotebookSheet) -> some View {
        VStack(spacing: 0) {
            editorTopBar(page: page, sheet: sheet)

            drawingToolBar

            if let scanStatus {
                Text(scanStatus)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }

            HStack(spacing: 0) {
                if isEditorSidebarVisible {
                    editorSidebar(for: page)
                        .frame(width: 282)
                        .background(Color(uiColor: .secondarySystemBackground))
                    Divider()
                }

                pageCanvas(page, sheet: sheet)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.11, green: 0.11, blue: 0.12))
        }
        .background(Color.black)
    }

    private func editorTopBar(page: NotebookPage, sheet: NotebookSheet) -> some View {
        HStack(spacing: 18) {
            HStack(spacing: 8) {
                Button {
                    store.selectedPageID = nil
                } label: {
                    Image(systemName: "chevron.left")
                }
                Button {
                    withAnimation(.snappy(duration: 0.2)) {
                        isEditorSidebarVisible.toggle()
                    }
                } label: {
                    Image(systemName: isEditorSidebarVisible ? "sidebar.left" : "list.bullet")
                }
                Button {
                    editorSidebarTab = .pages
                    withAnimation(.snappy(duration: 0.2)) {
                        isEditorSidebarVisible = true
                    }
                } label: {
                    Image(systemName: "rectangle.split.1x2")
                }
            }
            .editorCapsule()

            Menu {
                Button("Rename Note") {
                    editingPageID = page.id
                    noteTitleDraft = page.title
                }
                Button(page.isFavorite ? "Remove Favorite" : "Add Favorite") {
                    store.toggleFavorite(page.id)
                }
            } label: {
                HStack(spacing: 8) {
                    Text(page.title)
                        .font(.system(size: 20, weight: .bold))
                        .lineLimit(1)
                    Image(systemName: "chevron.down.circle.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: 260, alignment: .leading)

            Spacer()

            HStack(spacing: 12) {
                if let sectionTitle = store.effectiveSectionTitle(for: sheet.id, in: page.id) {
                    Label(sectionTitle, systemImage: "number")
                        .font(.caption.bold())
                        .foregroundStyle(.pink)
                        .lineLimit(1)
                }
                Text("Page \(page.currentPageNumber) / \(page.pageCount)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(store.saveStatus)
                    .font(.caption.bold())
                    .foregroundStyle(store.saveStatus == "Saved" ? .green : .secondary)
            }
            .frame(maxWidth: 360)

            Spacer()

            HStack(spacing: 10) {
                Button {
                    store.selectPreviousSheet(in: page.id)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(page.currentPageNumber <= 1)
                Button {
                    store.selectNextSheet(in: page.id)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(page.currentPageNumber >= page.pageCount)
                Button {
                    store.addSheet(to: page.id)
                } label: {
                    Image(systemName: "doc.badge.plus")
                }
                Button {
                    scan(sheetID: sheet.id)
                } label: {
                    Image(systemName: isScanning ? "waveform.path.ecg" : "number")
                }
                .disabled(isScanning)
                Button {
                    editorSidebarTab = .outline
                    withAnimation(.snappy(duration: 0.2)) {
                        isEditorSidebarVisible = true
                    }
                } label: {
                    Image(systemName: "magnifyingglass")
                }
                Menu {
                    Picker("Template", selection: Binding(
                        get: { sheet.template },
                        set: { store.updateTemplate($0, for: sheet.id) }
                    )) {
                        ForEach(PageTemplate.allCases) { template in
                            Text(template.title).tag(template)
                        }
                    }
                    Button("Export Note") {
                        shareImage = ShareImage(image: renderPageImage(sheet))
                    }
                    Button("Duplicate Note") {
                        store.duplicatePage(page.id)
                    }
                    Button("Clear Current Page", role: .destructive) {
                        clearPage(sheet.id)
                    }
                    Button("Delete Current Page", role: .destructive) {
                        store.deleteCurrentSheet(in: page.id)
                    }
                    Button("Delete Note", role: .destructive) {
                        pendingPageDeleteID = page.id
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            .editorCapsule()
        }
        .font(.system(size: 24, weight: .bold))
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(Color.black)
    }

    private func pageCanvas(_ page: NotebookPage, sheet: NotebookSheet) -> some View {
        GeometryReader { proxy in
            let availableWidth = max(proxy.size.width - 48, 320)
            let availableHeight = max(proxy.size.height - 32, 426)
            let pageWidth = min(availableWidth, availableHeight / 1.33, 980)
            let pageHeight = pageWidth * 1.33

            ScrollView([.horizontal, .vertical]) {
                ZStack {
                    PageTemplateView(template: sheet.template)

                    PencilCanvasView(
                        pageID: sheet.id,
                        drawing: sheet.drawing,
                        selectedTool: drawingTool,
                        selectedColor: selectedColor,
                        strokeWidth: strokeWidth,
                        command: canvasCommand
                    ) { pageID, drawing in
                        store.updateDrawing(drawing, for: pageID)
                    }

                    ForEach(sheet.elements) { element in
                        PageElementView(element: element) { updatedElement in
                            store.updateElement(updatedElement, on: sheet.id)
                        } onDelete: {
                            store.deleteElement(element.id, from: sheet.id)
                        }
                        .id(element.id)
                    }
                }
                .frame(width: pageWidth, height: pageHeight)
                .background(Color.white)
                .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 10)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func outlinePanel(for sheet: NotebookSheet) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Contents")
                .font(.system(size: 24, weight: .bold))
                .padding(.top, 18)

            ForEach(store.outlineEntries(for: sheet.id)) { entry in
                HStack(spacing: 8) {
                    Text(String(repeating: "#", count: entry.level))
                        .font(.caption.bold())
                        .foregroundStyle(.pink)
                    Text(entry.title)
                        .font(.system(size: 17, weight: .semibold))
                        .lineLimit(2)
                    Spacer()
                }
                .padding(.leading, CGFloat(max(entry.level - 1, 0)) * 14)
            }

            Spacer()
        }
        .padding(.horizontal, 18)
    }

    private func editorSidebar(for page: NotebookPage) -> some View {
        VStack(spacing: 12) {
            Picker("Navigation", selection: $editorSidebarTab) {
                ForEach(EditorSidebarTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding([.horizontal, .top], 12)

            switch editorSidebarTab {
            case .pages:
                pageSidebar(for: page)
            case .outline:
                outlineSidebar(for: page)
            }
        }
    }

    private func pageSidebar(for page: NotebookPage) -> some View {
        VStack(spacing: 10) {
            HStack {
                Text("Pages")
                    .font(.headline)
                Spacer()
                Button {
                    store.addSheet(to: page.id)
                } label: {
                    Image(systemName: "plus")
                }
            }
            .padding(.horizontal, 14)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Array(page.sheets.enumerated()), id: \.element.id) { index, sheet in
                        Button {
                            store.selectSheet(sheet.id, in: page.id)
                        } label: {
                            HStack(spacing: 10) {
                                SheetThumbnail(sheet: sheet)
                                    .frame(width: 54, height: 74)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 5)
                                            .stroke(page.selectedSheetID == sheet.id ? Color.pink : Color.clear, lineWidth: 3)
                                    }
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Page \(index + 1)")
                                        .font(.system(size: 15, weight: .bold))
                                    Text(pageTitle(for: sheet, in: page, index: index))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                                Spacer()
                            }
                            .padding(8)
                            .background(page.selectedSheetID == sheet.id ? Color.pink.opacity(0.16) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
            }

            HStack {
                Button {
                    store.duplicateCurrentSheet(in: page.id)
                } label: {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }
                .font(.caption.bold())
                Spacer()
                Button(role: .destructive) {
                    store.deleteCurrentSheet(in: page.id)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .font(.caption.bold())
                .disabled(page.pageCount <= 1)
            }
            .padding(12)
        }
    }

    private func outlineSidebar(for page: NotebookPage) -> some View {
        VStack(spacing: 10) {
            HStack {
                Text("Outline")
                    .font(.headline)
                Spacer()
                Button {
                    manualOutlineTitle = store.selectedSheet.flatMap { store.effectiveSectionTitle(for: $0.id, in: page.id) } ?? ""
                    manualOutlineLevel = 1
                    isShowingManualOutline = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            .padding(.horizontal, 14)

            if store.outlineEntries(in: page.id).isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "number")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.pink)
                    Text("Write # Unit 1, then Detect Outline.")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                Spacer()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(store.outlineEntries(in: page.id)) { entry in
                            Button {
                                store.selectSheet(entry.pageID, in: page.id)
                            } label: {
                                HStack(spacing: 8) {
                                    Text(String(repeating: "#", count: entry.level))
                                        .font(.caption.bold())
                                        .foregroundStyle(.pink)
                                        .frame(width: 34, alignment: .leading)
                                    Text(entry.title)
                                        .font(.system(size: 15, weight: .semibold))
                                        .lineLimit(2)
                                    Spacer()
                                }
                                .padding(.leading, CGFloat(entry.level - 1) * 16)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 8)
                                .background(page.selectedSheetID == entry.pageID ? Color.pink.opacity(0.16) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("Jump to Page") {
                                    store.selectSheet(entry.pageID, in: page.id)
                                }
                                Button("Delete", role: .destructive) {
                                    store.deleteOutlineEntry(entry.id)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                }
            }
        }
    }

    private func pageTitle(for sheet: NotebookSheet, in page: NotebookPage, index: Int) -> String {
        store.effectiveSectionTitle(for: sheet.id, in: page.id) ?? "Page \(index + 1)"
    }

    private var manualOutlineSheet: some View {
        NavigationStack {
            Form {
                Section("Outline Item") {
                    TextField("Title", text: $manualOutlineTitle)
                    Stepper("Level \(manualOutlineLevel)", value: $manualOutlineLevel, in: 1...3)
                }
                Section {
                    Text("This creates an outline entry for the current page using its stable page ID.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add to Outline")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isShowingManualOutline = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let sheetID = store.selectedSheet?.id {
                            store.addOutlineEntry(title: manualOutlineTitle, level: manualOutlineLevel, to: sheetID)
                        }
                        isShowingManualOutline = false
                    }
                    .disabled(manualOutlineTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
    private var drawingTool: NoteTool {
        switch selectedTool {
        case .pen, .highlighter, .eraser:
            selectedTool
        case .text, .tape, .shape:
            .pen
        }
    }

    private var drawingToolBar: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                Button { canvasCommand = CanvasCommand(action: .undo) } label: { Image(systemName: "arrow.uturn.backward") }
                Button { canvasCommand = CanvasCommand(action: .redo) } label: { Image(systemName: "arrow.uturn.forward") }
            }
            .foregroundStyle(.secondary)

            Divider()
                .frame(height: 34)

            HStack(spacing: 10) {
                ForEach(NoteTool.allCases) { tool in
                    Button {
                        chooseTool(tool)
                    } label: {
                        Image(systemName: tool.iconName)
                            .font(.system(size: 20, weight: .bold))
                            .frame(width: 42, height: 42)
                            .foregroundStyle(selectedTool == tool ? .white : .secondary)
                            .background(selectedTool == tool ? Color.pink.opacity(0.9) : Color.clear)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()
                .frame(height: 34)

            HStack(spacing: 9) {
                ForEach(InkColor.allCases) { inkColor in
                    Button {
                        selectedColor = inkColor
                        if selectedTool == .eraser {
                            selectedTool = .pen
                        }
                    } label: {
                        Circle()
                            .fill(inkColor.color)
                            .frame(width: 24, height: 24)
                            .overlay {
                                Circle()
                                    .stroke(selectedColor == inkColor ? Color.white : Color.clear, lineWidth: 2)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }

            Slider(value: $strokeWidth, in: 2...12, step: 1)
                .frame(width: 120)

            Divider()
                .frame(height: 34)

            Button {
                if let sheetID = store.selectedSheet?.id {
                    store.addElement(.stickyNote, to: sheetID)
                }
            } label: {
                Image(systemName: "note.text")
            }
            .foregroundStyle(.secondary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .background(Color.black)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(height: 1)
        }
    }

    private func chooseTool(_ tool: NoteTool) {
        guard store.selectedPageID != nil else {
            return
        }

        switch tool {
        case .text:
            if let sheetID = store.selectedSheet?.id {
                store.addElement(.textBox, to: sheetID)
            }
            selectedTool = .pen
        case .tape:
            if let sheetID = store.selectedSheet?.id {
                store.addElement(.tape, to: sheetID)
            }
            selectedTool = .pen
        case .shape:
            if let sheetID = store.selectedSheet?.id {
                store.addElement(.shape, to: sheetID)
            }
            selectedTool = .pen
        case .pen, .highlighter, .eraser:
            selectedTool = tool
        }
    }

    private func addPage() {
        store.addPage()
        scanStatus = nil
    }

    private func clearPage(_ pageID: UUID) {
        canvasCommand = CanvasCommand(action: .clear)
        store.clearDrawing(for: pageID)
        scanStatus = nil
    }

    private func deletePage(_ pageID: UUID) {
        store.deletePage(pageID)
        scanStatus = nil
    }

    private func scan(sheetID: UUID) {
        guard let sheet = store.sheet(with: sheetID) else {
            return
        }

        isScanning = true
        scanStatus = "Scanning handwriting..."

        HeadingRecognizer.recognizeHeadings(from: sheet.drawing) { headings, errorMessage in
            Task { @MainActor in
                isScanning = false

                if let errorMessage {
                    scanStatus = "Scan failed: \(errorMessage)"
                    return
                }

                guard !headings.isEmpty else {
                    scanStatus = "No outline tag found. Write # Unit 1, ## Lecture, or ### Example, then detect again."
                    return
                }

                store.replaceOutlineEntries(for: sheet.id, headings: headings)
                scanStatus = "Added \(headings.count) outline item\(headings.count == 1 ? "" : "s")."
            }
        }
    }

    private func renderPageImage(_ sheet: NotebookSheet) -> UIImage {
        let renderer = ImageRenderer(content: ExportPageView(sheet: sheet).frame(width: 1024, height: 1366))
        renderer.scale = 2
        return renderer.uiImage ?? sheet.drawing.image(from: CGRect(x: 0, y: 0, width: 1024, height: 1366), scale: 1)
    }
}

private extension View {
    func editorCapsule() -> some View {
        self
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.10))
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            }
            .buttonStyle(.plain)
    }
}

struct NoteTile: View {
    let page: NotebookPage

    var body: some View {
        VStack(spacing: 14) {
            PageThumbnail(page: page)
                .frame(width: 126, height: 176)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .shadow(color: .black.opacity(0.22), radius: 10, x: 0, y: 8)
            HStack(spacing: 6) {
                Text(page.title)
                    .font(.system(size: 22, weight: .bold))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                if page.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.pink)
                }
            }
            .foregroundStyle(.white)
            .frame(width: 150)
        }
    }
}

struct PageThumbnail: View {
    let page: NotebookPage

    var body: some View {
        let sheet = page.currentSheet

        ZStack {
            Color.white
            MiniTemplateView(template: sheet.template)
                .opacity(0.8)
            if sheet.drawing.bounds.isEmpty {
                Text(page.title.prefix(18))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.7))
                    .padding(10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                Image(uiImage: sheet.drawing.image(from: sheet.drawing.bounds.insetBy(dx: -24, dy: -24), scale: 0.35))
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            }
            Text("\(page.pageCount)")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.black.opacity(0.55))
                .clipShape(Capsule())
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(6)
        }
    }
}

struct SheetThumbnail: View {
    let sheet: NotebookSheet

    var body: some View {
        ZStack {
            Color.white
            MiniTemplateView(template: sheet.template)
                .opacity(0.8)
            if !sheet.drawing.bounds.isEmpty {
                Image(uiImage: sheet.drawing.image(from: sheet.drawing.bounds.insetBy(dx: -24, dy: -24), scale: 0.25))
                    .resizable()
                    .scaledToFit()
                    .padding(5)
            }
        }
    }
}

struct MiniTemplateView: View {
    let template: PageTemplate

    var body: some View {
        Canvas { context, size in
            let subtle = Color.gray.opacity(0.25)

            switch template {
            case .blank:
                break
            case .ruled:
                drawHorizontalLines(in: &context, size: size, spacing: 12, color: subtle)
            case .grid:
                drawHorizontalLines(in: &context, size: size, spacing: 12, color: subtle)
                drawVerticalLines(in: &context, size: size, spacing: 12, color: subtle)
            case .dotted:
                drawDots(in: &context, size: size, spacing: 11, color: subtle)
            case .cornell:
                drawHorizontalLines(in: &context, size: size, spacing: 12, color: subtle)
                drawGuideLine(in: &context, from: CGPoint(x: size.width * 0.28, y: 0), to: CGPoint(x: size.width * 0.28, y: size.height), color: .blue.opacity(0.35))
                drawGuideLine(in: &context, from: CGPoint(x: 0, y: size.height * 0.78), to: CGPoint(x: size.width, y: size.height * 0.78), color: .blue.opacity(0.35))
            case .dailyPlanner:
                drawHorizontalLines(in: &context, size: size, spacing: 13, color: subtle)
                drawGuideLine(in: &context, from: CGPoint(x: 0, y: size.height * 0.16), to: CGPoint(x: size.width, y: size.height * 0.16), color: .pink.opacity(0.35))
                drawGuideLine(in: &context, from: CGPoint(x: size.width * 0.55, y: size.height * 0.16), to: CGPoint(x: size.width * 0.55, y: size.height), color: .pink.opacity(0.35))
            }
        }
    }

    private func drawHorizontalLines(in context: inout GraphicsContext, size: CGSize, spacing: CGFloat, color: Color) {
        var y = spacing
        while y < size.height {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(path, with: .color(color), lineWidth: 0.8)
            y += spacing
        }
    }

    private func drawVerticalLines(in context: inout GraphicsContext, size: CGSize, spacing: CGFloat, color: Color) {
        var x = spacing
        while x < size.width {
            var path = Path()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            context.stroke(path, with: .color(color), lineWidth: 0.8)
            x += spacing
        }
    }

    private func drawDots(in context: inout GraphicsContext, size: CGSize, spacing: CGFloat, color: Color) {
        var x = spacing
        while x < size.width {
            var y = spacing
            while y < size.height {
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.4, height: 1.4)), with: .color(color))
                y += spacing
            }
            x += spacing
        }
    }

    private func drawGuideLine(in context: inout GraphicsContext, from start: CGPoint, to end: CGPoint, color: Color) {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        context.stroke(path, with: .color(color), lineWidth: 1.2)
    }
}

struct ExportPageView: View {
    let sheet: NotebookSheet

    var body: some View {
        ZStack {
            PageTemplateView(template: sheet.template)
            Image(uiImage: sheet.drawing.image(from: CGRect(x: 0, y: 0, width: 1024, height: 1366), scale: 2))
                .resizable()
                .scaledToFit()

            ForEach(sheet.elements) { element in
                PageElementExportView(element: element)
            }
        }
        .background(Color.white)
    }
}

struct PageElementExportView: View {
    let element: PageElement

    var body: some View {
        elementBody
            .frame(width: element.width, height: element.height)
            .position(x: element.x, y: element.y)
    }

    @ViewBuilder
    private var elementBody: some View {
        switch element.kind {
        case .textBox:
            Text(element.text)
                .foregroundStyle(.primary)
                .padding(10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(Color.white.opacity(0.88))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        case .stickyNote:
            Text(element.text)
                .foregroundStyle(.black)
                .padding(10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(Color.yellow.opacity(0.45))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        case .tape:
            Text(element.isRevealed ? element.text : "Covered")
                .font(.headline)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .foregroundStyle(element.isRevealed ? Color.primary : Color.white)
                .background(element.isRevealed ? Color.mint.opacity(0.18) : Color.gray)
                .clipShape(RoundedRectangle(cornerRadius: 7))
        case .shape:
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.blue.opacity(0.12))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue, lineWidth: 3)
                    Text(element.text)
                        .font(.headline)
                        .foregroundStyle(.blue)
                }
        }
    }
}

struct PlannerPreview: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
            ForEach(0..<5) { _ in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.black.opacity(0.12))
                    .frame(height: 8)
            }
        }
        .padding(18)
        .frame(width: 240, height: 280)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 8)
    }
}

struct PageTemplateView: View {
    let template: PageTemplate

    var body: some View {
        Canvas { context, size in
            let subtle = Color.secondary.opacity(0.18)

            switch template {
            case .blank:
                break
            case .ruled:
                drawHorizontalLines(in: &context, size: size, spacing: 32, color: subtle)
            case .grid:
                drawHorizontalLines(in: &context, size: size, spacing: 32, color: subtle)
                drawVerticalLines(in: &context, size: size, spacing: 32, color: subtle)
            case .dotted:
                drawDots(in: &context, size: size, spacing: 28, color: subtle)
            case .cornell:
                drawHorizontalLines(in: &context, size: size, spacing: 32, color: subtle)
                drawGuideLine(in: &context, from: CGPoint(x: size.width * 0.28, y: 0), to: CGPoint(x: size.width * 0.28, y: size.height), color: .blue.opacity(0.22))
                drawGuideLine(in: &context, from: CGPoint(x: 0, y: size.height * 0.78), to: CGPoint(x: size.width, y: size.height * 0.78), color: .blue.opacity(0.22))
            case .dailyPlanner:
                drawHorizontalLines(in: &context, size: size, spacing: 36, color: subtle)
                drawGuideLine(in: &context, from: CGPoint(x: 0, y: 92), to: CGPoint(x: size.width, y: 92), color: .pink.opacity(0.22))
                drawGuideLine(in: &context, from: CGPoint(x: size.width * 0.55, y: 92), to: CGPoint(x: size.width * 0.55, y: size.height), color: .pink.opacity(0.22))
            }
        }
        .background(Color(uiColor: .systemBackground))
    }

    private func drawHorizontalLines(in context: inout GraphicsContext, size: CGSize, spacing: CGFloat, color: Color) {
        var y = spacing
        while y < size.height {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(path, with: .color(color), lineWidth: 1)
            y += spacing
        }
    }

    private func drawVerticalLines(in context: inout GraphicsContext, size: CGSize, spacing: CGFloat, color: Color) {
        var x = spacing
        while x < size.width {
            var path = Path()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            context.stroke(path, with: .color(color), lineWidth: 1)
            x += spacing
        }
    }

    private func drawDots(in context: inout GraphicsContext, size: CGSize, spacing: CGFloat, color: Color) {
        var x = spacing
        while x < size.width {
            var y = spacing
            while y < size.height {
                let rect = CGRect(x: x, y: y, width: 2, height: 2)
                context.fill(Path(ellipseIn: rect), with: .color(color))
                y += spacing
            }
            x += spacing
        }
    }

    private func drawGuideLine(in context: inout GraphicsContext, from start: CGPoint, to end: CGPoint, color: Color) {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        context.stroke(path, with: .color(color), lineWidth: 2)
    }
}

struct PageElementView: View {
    let element: PageElement
    @State private var draft: PageElement
    @State private var dragStart: CGPoint?
    let onChange: (PageElement) -> Void
    let onDelete: () -> Void

    init(element: PageElement, onChange: @escaping (PageElement) -> Void, onDelete: @escaping () -> Void) {
        self.element = element
        _draft = State(initialValue: element)
        self.onChange = onChange
        self.onDelete = onDelete
    }

    var body: some View {
        elementBody
            .frame(width: draft.width, height: draft.height)
            .position(x: draft.x, y: draft.y)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if dragStart == nil {
                            dragStart = CGPoint(x: draft.x, y: draft.y)
                        }

                        guard let dragStart else {
                            return
                        }

                        draft.x = dragStart.x + value.translation.width
                        draft.y = dragStart.y + value.translation.height
                        onChange(draft)
                    }
                    .onEnded { _ in
                        dragStart = nil
                    }
            )
            .contextMenu {
                Button("Delete", role: .destructive) {
                    onDelete()
                }
            }
            .onChange(of: draft) { _, newValue in
                onChange(newValue)
            }
            .onChange(of: element) { _, newValue in
                if newValue != draft {
                    draft = newValue
                }
            }
    }

    @ViewBuilder
    private var elementBody: some View {
        switch draft.kind {
        case .textBox:
            TextField("Text", text: $draft.text, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(10)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        case .stickyNote:
            TextEditor(text: $draft.text)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(Color.yellow.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        case .tape:
            Button {
                draft.isRevealed.toggle()
            } label: {
                Text(draft.isRevealed ? draft.text : "Covered - tap to reveal")
                    .font(.headline)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .foregroundStyle(draft.isRevealed ? Color.primary : Color.white)
                    .background(draft.isRevealed ? Color.mint.opacity(0.18) : Color.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
            }
            .buttonStyle(.plain)
        case .shape:
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.blue.opacity(0.12))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue, lineWidth: 3)
                    Text(draft.text)
                        .font(.headline)
                        .foregroundStyle(.blue)
                }
        }
    }
}

struct ShareImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
