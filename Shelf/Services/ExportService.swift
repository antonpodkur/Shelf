import AppKit
import Foundation
import UniformTypeIdentifiers

enum ExportService {
    static func exportAsFolder(items: [ShelfItem]) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.prompt = "Export Here"
        panel.message = "Choose a destination for the exported files."

        guard panel.runModal() == .OK, let destination = panel.url else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let folderName = "Shelf-export-\(formatter.string(from: Date()))"
        let exportDir = destination.appendingPathComponent(folderName)

        do {
            try FileManager.default.createDirectory(at: exportDir, withIntermediateDirectories: true)

            var usedNames = Set<String>()
            for item in items {
                let name = uniqueName(for: item.filename, in: &usedNames)
                let dest = exportDir.appendingPathComponent(name)
                try FileManager.default.copyItem(at: item.vaultURL, to: dest)
            }

            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: exportDir.path)
        } catch {
            showError("Export failed: \(error.localizedDescription)")
        }
    }

    static func exportAsZip(items: [ShelfItem]) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let defaultName = "shelf-export-\(formatter.string(from: Date())).zip"

        let panel = NSSavePanel()
        panel.nameFieldStringValue = defaultName
        panel.allowedContentTypes = [.zip]

        guard panel.runModal() == .OK, let destination = panel.url else { return }

        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)

        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

            var usedNames = Set<String>()
            for item in items {
                let name = uniqueName(for: item.filename, in: &usedNames)
                let dest = tempDir.appendingPathComponent(name)
                try FileManager.default.copyItem(at: item.vaultURL, to: dest)
            }

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
            process.arguments = ["-c", "-k", "--keepParent", tempDir.path, destination.path]
            try process.run()
            process.waitUntilExit()

            try? FileManager.default.removeItem(at: tempDir)

            if process.terminationStatus == 0 {
                NSWorkspace.shared.selectFile(destination.path, inFileViewerRootedAtPath: destination.deletingLastPathComponent().path)
            } else {
                showError("Zip creation failed.")
            }
        } catch {
            try? FileManager.default.removeItem(at: tempDir)
            showError("Export failed: \(error.localizedDescription)")
        }
    }

    private static func uniqueName(for name: String, in usedNames: inout Set<String>) -> String {
        var candidate = name
        var counter = 2
        while usedNames.contains(candidate) {
            let ext = (name as NSString).pathExtension
            let base = (name as NSString).deletingPathExtension
            if ext.isEmpty {
                candidate = "\(base) (\(counter))"
            } else {
                candidate = "\(base) (\(counter)).\(ext)"
            }
            counter += 1
        }
        usedNames.insert(candidate)
        return candidate
    }

    private static func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Export Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }
}
