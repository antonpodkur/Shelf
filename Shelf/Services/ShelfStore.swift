import Foundation
import Observation
import SwiftUI

@Observable
final class ShelfStore {
    private(set) var items: [ShelfItem] = []

    var totalSize: Int64 {
        items.reduce(0) { $0 + $1.sizeInBytes }
    }

    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    var isEmpty: Bool { items.isEmpty }

    init() {
        load()
    }

    func add(from urls: [URL]) {
        for url in urls {
            do {
                let item = try VaultManager.copyIn(from: url)
                items.append(item)
            } catch {
                print("[Shelf] Failed to add \(url.lastPathComponent): \(error)")
            }
        }
        save()
    }

    func remove(item: ShelfItem) {
        VaultManager.remove(item: item)
        items.removeAll { $0.id == item.id }
        save()
    }

    func remove(at offsets: IndexSet) {
        let toRemove = offsets.map { items[$0] }
        for item in toRemove {
            VaultManager.remove(item: item)
        }
        items.remove(atOffsets: offsets)
        save()
    }

    func clearAll() -> [ShelfItem] {
        let removed = items
        items.removeAll()
        save()
        return removed
    }

    func purgeVaultFiles(for purgedItems: [ShelfItem]) {
        VaultManager.removeAll(items: purgedItems)
    }

    func restore(items restoredItems: [ShelfItem]) {
        items.append(contentsOf: restoredItems)
        save()
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(items)
            let tempURL = VaultManager.appSupportDirectory.appendingPathComponent("shelf.json.tmp")
            try data.write(to: tempURL, options: .atomic)
            try FileManager.default.moveItem(at: tempURL, to: VaultManager.shelfJSONURL)
        } catch {
            if let data = try? JSONEncoder().encode(items) {
                try? data.write(to: VaultManager.shelfJSONURL, options: .atomic)
            }
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: VaultManager.shelfJSONURL.path) else { return }
        do {
            let data = try Data(contentsOf: VaultManager.shelfJSONURL)
            let loaded = try JSONDecoder().decode([ShelfItem].self, from: data)
            items = loaded.filter { VaultManager.vaultFileExists(for: $0) }
            if items.count != loaded.count {
                save()
            }
        } catch {
            print("[Shelf] Failed to load shelf.json: \(error)")
        }
    }
}
