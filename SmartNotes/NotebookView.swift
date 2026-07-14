import PencilKit
import SwiftUI

struct NotebookView: View {
    @StateObject private var store = NotebookStore()

    var body: some View {
        NavigationSplitView {
            List(selection: $store.selectedPageID) {
                Section("Table of Contents") {
                    if store.outline.isEmpty {
                        Text("Write # before a heading, then scan.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(store.outline) { entry in
                            Button {
                                store.selectPage(entry.pageID)
                            } label: {
                                Text(entry.title)
                                    .padding(.leading, CGFloat(entry.level - 1) * 12)
                            }
                        }
                    }
                }

                Section("Pages") {
                    ForEach(store.pages) { page in
                        Text(page.title).tag(page.id)
                    }
                }
            }
            .toolbar {
                Button("New Page") {
                    store.addPage()
                }
            }
        } detail: {
            if let page = store.selectedPage {
                VStack(spacing: 0) {
                    HStack {
                        Text(page.title)
                            .font(.headline)
                        Spacer()
                        Button("Scan Headings") {
                            scan(page)
                        }
                    }
                    .padding()

                    PencilCanvasView(pageID: page.id, drawing: page.drawing) { drawing in
                        store.updateDrawing(drawing, for: page.id)
                    }
                }
            } else {
                Text("Create a page to start writing.")
            }
        }
    }

    private func scan(_ page: NotebookPage) {
        HeadingRecognizer.recognizeHeading(from: page.drawing) { heading in
            guard let heading else {
                return
            }
            store.replaceOutlineEntry(for: page.id, title: heading.title, level: heading.level)
        }
    }
}
