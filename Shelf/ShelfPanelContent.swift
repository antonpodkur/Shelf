import SwiftUI
import UniformTypeIdentifiers

struct ShelfPanelContent: View {
    @Bindable var store: ShelfStore
    @State private var isDropTargeted = false
    @State private var undoItems: [ShelfItem]?
    @State private var showUndoBanner = false

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
            handleDrop(providers)
            return true
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
                ForEach(store.items) { item in
                    ShelfItemRow(item: item) {
                        withAnimation {
                            store.remove(item: item)
                        }
                    }
                    .draggable(item.vaultURL) {
                        ShelfItemRow(item: item, onRemove: {})
                            .frame(width: 280)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    if item.id != store.items.last?.id {
                        Divider().padding(.leading, 62)
                    }
                }
            }
            .padding(.vertical, 4)
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

    private func handleDrop(_ providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { data, _ in
                guard let urlData = data as? Data,
                      let url = URL(dataRepresentation: urlData, relativeTo: nil) else { return }
                DispatchQueue.main.async {
                    store.add(from: [url])
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
