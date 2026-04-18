import AppKit
import Foundation

@MainActor
enum ClipboardPasteService {
    static func paste(into store: ShelfStore) {
        let pb = NSPasteboard.general

        if let urls = pb.readObjects(forClasses: [NSURL.self], options: [
            .urlReadingFileURLsOnly: true
        ]) as? [URL], !urls.isEmpty {
            let existing = Set(store.items.map { $0.vaultURL.standardizedFileURL.path })
            let incoming = urls.filter { !existing.contains($0.standardizedFileURL.path) }
            if !incoming.isEmpty {
                store.add(from: incoming)
            }
            return
        }

        if let text = pb.string(forType: .string),
           !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            pasteAsTempFile(data: Data(text.utf8), extension: "txt", into: store)
            return
        }

        if let pngData = pb.data(forType: .png) {
            pasteAsTempFile(data: pngData, extension: "png", into: store)
            return
        }

        if let tiffData = pb.data(forType: .tiff),
           let rep = NSBitmapImageRep(data: tiffData),
           let pngData = rep.representation(using: .png, properties: [:]) {
            pasteAsTempFile(data: pngData, extension: "png", into: store)
            return
        }

        NSSound.beep()
    }

    private static func pasteAsTempFile(data: Data, extension ext: String, into store: ShelfStore) {
        let tempParent = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)

        do {
            try FileManager.default.createDirectory(at: tempParent, withIntermediateDirectories: true)

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd-HHmmss"
            let filename = "pasted-\(formatter.string(from: Date())).\(ext)"
            let fileURL = tempParent.appendingPathComponent(filename)

            try data.write(to: fileURL)
            store.add(from: [fileURL])
        } catch {
            print("[Shelf] Paste failed: \(error)")
            NSSound.beep()
        }

        try? FileManager.default.removeItem(at: tempParent)
    }
}
