import SwiftUI
import UniformTypeIdentifiers

struct ShelfPanelContent: View {
    @Bindable var store: ShelfStore
    let previewController: QuickLookPreviewController
    @State private var isDropTargeted = false
    @State private var undoItems: [ShelfItem]?
    @State private var showUndoBanner = false
    @State private var dropIndicatorIndex: Int?
    @State private var hoveredItemID: ShelfItem.ID?

    var body: some View {
        VStack(spacing: 0) {
            if store.isEmpty && !showUndoBanner {
                emptyState
            } else {
                itemList
                Divider()
                ShelfFooter(
                    itemCount: store.items.count,
                    totalSize: store.formattedTotalSize,
                    onExportFolder: { ExportService.exportAsFolder(items: store.items) },
                    onExportZip: { ExportService.exportAsZip(items: store.items) },
                    onClear: clearWithUndo
                )
            }

            if showUndoBanner {
                undoBanner
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isDropTargeted ? Color.accentColor : .clear, lineWidth: 2)
        )
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            handleIncomingDrop(providers, at: nil)
            return true
        }
        .onChange(of: hoveredItemID) { _, newID in
            let url = newID.flatMap { id in store.items.first(where: { $0.id == id })?.vaultURL }
            NSLog("[ShelfContent] hoveredItemID changed -> \(newID?.uuidString ?? "nil"), url=\(url?.lastPathComponent ?? "nil")")
            previewController.updateCurrent(url)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray.and.arrow.down")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            Text("Drop files here")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                .foregroundStyle(.quaternary)
                .padding(16)
        )
    }

    private var itemList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(store.items.enumerated()), id: \.element.id) { index, item in
                    dropSlot(at: index)

                    ShelfItemRow(
                        item: item,
                        onRemove: {
                            withAnimation {
                                store.remove(item: item)
                            }
                        },
                        onHoverChange: { hovering in
                            if hovering {
                                hoveredItemID = item.id
                            } else if hoveredItemID == item.id {
                                hoveredItemID = nil
                            }
                        }
                    )
                    .draggable(item.vaultURL) {
                        ShelfItemRow(item: item, onRemove: {})
                            .frame(width: 280)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                dropSlot(at: store.items.count)
            }
            .padding(.vertical, 4)
        }
    }

    private func dropSlot(at index: Int) -> some View {
        let isActive = dropIndicatorIndex == index
        return ZStack {
            Rectangle()
                .fill(Color.clear)
                .frame(height: isActive ? 10 : 6)
            if isActive {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor)
                    .frame(height: 2)
                    .padding(.horizontal, 12)
                    .transition(.opacity)
            } else if index > 0 && index < store.items.count {
                Divider().padding(.leading, 62)
            }
        }
        .contentShape(Rectangle())
        .dropDestination(for: URL.self) { urls, _ in
            handleSlotDrop(urls, at: index)
            dropIndicatorIndex = nil
            return true
        } isTargeted: { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                dropIndicatorIndex = hovering ? index : (dropIndicatorIndex == index ? nil : dropIndicatorIndex)
            }
        }
    }

    private var undoBanner: some View {
        HStack {
            Text("Shelf cleared")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            Spacer()

            Button("Undo") {
                if let items = undoItems {
                    store.restore(items: items)
                }
                dismissUndo()
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color.accentColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func handleSlotDrop(_ urls: [URL], at index: Int) {
        let (existingIndices, newURLs) = splitByMembership(urls)

        if !existingIndices.isEmpty {
            withAnimation {
                store.move(fromOffsets: IndexSet(existingIndices), toOffset: index)
            }
        }
        if !newURLs.isEmpty {
            store.insert(from: newURLs, at: index)
        }
    }

    private func splitByMembership(_ urls: [URL]) -> (existing: [Int], new: [URL]) {
        var existing: [Int] = []
        var new: [URL] = []
        for url in urls {
            if let idx = store.items.firstIndex(where: { $0.vaultURL == url }) {
                existing.append(idx)
            } else {
                new.append(url)
            }
        }
        return (existing, new)
    }

    private func handleIncomingDrop(_ providers: [NSItemProvider], at index: Int?) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { data, _ in
                guard let urlData = data as? Data,
                      let url = URL(dataRepresentation: urlData, relativeTo: nil) else { return }
                DispatchQueue.main.async {
                    if store.items.contains(where: { $0.vaultURL == url }) {
                        return
                    }
                    if let index {
                        store.insert(from: [url], at: index)
                    } else {
                        store.add(from: [url])
                    }
                }
            }
        }
    }

    private func clearWithUndo() {
        withAnimation {
            undoItems = store.clearAll()
            showUndoBanner = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            dismissUndo()
        }
    }

    private func dismissUndo() {
        let itemsToPurge = undoItems
        withAnimation {
            showUndoBanner = false
            undoItems = nil
        }
        if let itemsToPurge {
            store.purgeVaultFiles(for: itemsToPurge)
        }
    }
}
