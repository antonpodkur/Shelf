import AppKit
import Quartz

final class QuickLookPreviewController: NSObject, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    private var currentURL: URL?

    func updateCurrent(_ url: URL?) {
        NSLog("[QL] updateCurrent: \(url?.path ?? "nil")")
        guard let url else { return }
        currentURL = url
        if QLPreviewPanel.sharedPreviewPanelExists(), QLPreviewPanel.shared().isVisible {
            QLPreviewPanel.shared().reloadData()
        }
    }

    func toggle() {
        NSLog("[QL] toggle called, currentURL=\(currentURL?.path ?? "nil")")
        guard let url = currentURL else {
            NSLog("[QL] toggle: no currentURL, bailing")
            return
        }
        guard FileManager.default.fileExists(atPath: url.path) else {
            NSLog("[QL] toggle: file does not exist at \(url.path)")
            return
        }
        let panel = QLPreviewPanel.shared()!
        if QLPreviewPanel.sharedPreviewPanelExists(), panel.isVisible {
            NSLog("[QL] toggle: panel visible, ordering out")
            panel.orderOut(nil)
            return
        }
        NSLog("[QL] toggle: activating app + showing panel for \(url.lastPathComponent)")
        NSApp.activate(ignoringOtherApps: true)
        panel.dataSource = self
        panel.delegate = self
        panel.reloadData()
        panel.makeKeyAndOrderFront(nil)
        NSLog("[QL] toggle: after makeKeyAndOrderFront, isVisible=\(panel.isVisible)")
    }

    func isPreviewVisible() -> Bool {
        QLPreviewPanel.sharedPreviewPanelExists() && QLPreviewPanel.shared().isVisible
    }

    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        currentURL == nil ? 0 : 1
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        currentURL as NSURL?
    }
}
