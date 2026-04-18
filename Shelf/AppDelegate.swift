import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panel: ShelfPanel!
    private var observation: Any?
    let store = ShelfStore()
    let previewController = QuickLookPreviewController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPanel()
        observeStoreChanges()
        updateIcon()
        SettingsOpener.prime()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "tray", accessibilityDescription: "Shelf")
        button.action = #selector(statusItemClicked(_:))
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])

        let dropView = StatusItemDropView(frame: button.bounds)
        dropView.autoresizingMask = [.width, .height]
        dropView.onDrop = { [weak self] urls in
            self?.store.add(from: urls)
        }
        button.addSubview(dropView)
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePanel()
        }
    }

    private func observeStoreChanges() {
        observation = withObservationTracking {
            _ = store.items.count
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                self?.updateIcon()
                self?.observeStoreChanges()
            }
        }
    }

    private func updateIcon() {
        guard let button = statusItem.button else { return }
        let symbolName = store.isEmpty ? "tray" : "tray.full"
        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Shelf")
    }

    private func setupPanel() {
        let content = ShelfPanelContent(store: store, previewController: previewController)
        panel = ShelfPanel(content: content, previewController: previewController) { [weak self] in
            guard let self else { return }
            ClipboardPasteService.paste(into: self.store)
        }
    }

    private func togglePanel() {
        if panel.isVisible {
            panel.close()
        } else {
            showPanel()
        }
    }

    private func showPanel() {
        guard let button = statusItem.button else { return }
        let buttonFrame = button.window?.convertToScreen(button.frame) ?? .zero

        let panelWidth: CGFloat = 360
        let panelHeight: CGFloat = 400

        let x = buttonFrame.midX - panelWidth / 2
        let y = buttonFrame.minY - panelHeight - 4

        panel.setFrame(NSRect(x: x, y: y, width: panelWidth, height: panelHeight), display: true)
        panel.makeKeyAndOrderFront(nil)
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(withTitle: "Open Shelf", action: #selector(openShelfAction), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Paste", action: #selector(pasteAction), keyEquivalent: "v")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Export as Folder\u{2026}", action: #selector(exportFolderAction), keyEquivalent: "")
        menu.addItem(withTitle: "Export as Zip\u{2026}", action: #selector(exportZipAction), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Clear Shelf", action: #selector(clearShelfAction), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Preferences\u{2026}", action: #selector(preferencesAction), keyEquivalent: ",")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit", action: #selector(quitAction), keyEquivalent: "q")

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func openShelfAction() {
        showPanel()
    }

    @objc private func exportFolderAction() {
        ExportService.exportAsFolder(items: store.items)
    }

    @objc private func exportZipAction() {
        ExportService.exportAsZip(items: store.items)
    }

    @objc private func preferencesAction() {
        SettingsOpener.open()
    }

    @objc private func pasteAction() {
        ClipboardPasteService.paste(into: store)
    }

    @objc private func clearShelfAction() {
        _ = store.clearAll()
    }

    @objc private func quitAction() {
        NSApp.terminate(nil)
    }
}
