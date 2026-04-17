import Foundation
import UniformTypeIdentifiers

struct ShelfItem: Identifiable, Codable, Equatable {
    let id: UUID
    let filename: String
    let sourcePath: String
    let sizeInBytes: Int64
    let dateAdded: Date
    let vaultRelativePath: String
    let contentType: String?

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: sizeInBytes, countStyle: .file)
    }

    var vaultURL: URL {
        VaultManager.vaultDirectory
            .appendingPathComponent(id.uuidString)
            .appendingPathComponent(filename)
    }

    var isFolder: Bool {
        guard let type = contentType,
              let utType = UTType(type) else { return false }
        return utType.conforms(to: .folder)
    }
}
