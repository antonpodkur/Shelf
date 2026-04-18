import AppKit
import SwiftUI

@MainActor
enum SettingsOpener {
    private static var window: NSWindow?
    private static var openAction: (@MainActor () -> Void)?

    static func prime() {
        _ = ensureHostingWindow()
    }

    static func open() {
        NSApp.activate(ignoringOtherApps: true)
        _ = ensureHostingWindow()

        DispatchQueue.main.async {
            openAction?()
        }
    }

    @discardableResult
    private static func ensureHostingWindow() -> NSWindow {
        if let window {
            return window
        }
        let bridge = OpenSettingsBridge { action in
            openAction = action
        }
        let controller = NSHostingController(rootView: bridge)
        let newWindow = NSWindow(contentViewController: controller)
        newWindow.styleMask = [.borderless]
        newWindow.setFrame(NSRect(x: -10_000, y: -10_000, width: 20, height: 20), display: false)
        newWindow.alphaValue = 0.0
        newWindow.ignoresMouseEvents = true
        newWindow.isReleasedWhenClosed = false
        newWindow.orderFrontRegardless()
        window = newWindow
        return newWindow
    }
}

private struct OpenSettingsBridge: View {
    let onCapture: (@MainActor @escaping () -> Void) -> Void

    var body: some View {
        Capture(onCapture: onCapture)
            .frame(width: 1, height: 1)
    }

    private struct Capture: View {
        @Environment(\.openSettings) private var openSettings
        let onCapture: (@MainActor @escaping () -> Void) -> Void

        var body: some View {
            Color.clear
                .onAppear {
                    onCapture { openSettings() }
                }
        }
    }
}
