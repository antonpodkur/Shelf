import Foundation
import UniformTypeIdentifiers

enum VaultManager {
    static let appSupportDirectory: URL = {
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Shelf")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }()

    static let vaultDirectory: URL = {
        let url = appSupportDirectory.appendingPathComponent("vault")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }()

    static var shelfJSONURL: URL {
        appSupportDirectory.appendingPathComponent("shelf.json")
    }

    static func copyIn(from sourceURL: URL) throws -> ShelfItem {
        let id = UUID()
        let itemDir = vaultDirectory.appendingPathComponent(id.uuidString)
        try FileManager.default.createDirectory(at: itemDir, withIntermediateDirectories: true)

        let filename = sourceURL.lastPathComponent
        let destination = itemDir.appendingPathComponent(filename)
        try FileManager.default.copyItem(at: sourceURL, to: destination)

        let resourceValues = try sourceURL.resourceValues(forKeys: [.fileSizeKey, .contentTypeKey, .isDirectoryKey])
        let size: Int64
        if resourceValues.isDirectory == true {
            size = folderSize(at: sourceURL)
        } else {
            size = Int64(resourceValues.fileSize ?? 0)
        }
        let contentType = resourceValues.contentType?.identifier

        return ShelfItem(
            id: id,
            filename: filename,
            sourcePath: sourceURL.path,
            sizeInBytes: size,
            dateAdded: Date(),
            vaultRelativePath: "\(id.uuidString)/\(filename)",
            contentType: contentType
        )
    }

    static func remove(item: ShelfItem) {
        let itemDir = vaultDirectory.appendingPathComponent(item.id.uuidString)
        try? FileManager.default.removeItem(at: itemDir)
    }

    static func removeAll(items: [ShelfItem]) {
        for item in items {
            remove(item: item)
        }
    }

    static func vaultFileExists(for item: ShelfItem) -> Bool {
        FileManager.default.fileExists(atPath: item.vaultURL.path)
    }

    private static func folderSize(at url: URL) -> Int64 {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) else {
            return 0
        }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += Int64(size)
            }
        }
        return total
    }
}
