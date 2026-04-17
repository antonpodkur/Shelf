import AppKit
import SwiftUI

final class ShelfPanel: NSPanel {
    init<Content: View>(content: Content) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 400),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )

        isFloatingPanel = true
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = false
        isReleasedWhenClosed = false
        hidesOnDeactivate = false

        let hostingView = NSHostingView(rootView: content)
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        let visualEffect = NSVisualEffectView()
        visualEffect.translatesAutoresizingMaskIntoConstraints = false
        visualEffect.material = .popover
        visualEffect.state = .active
        visualEffect.blendingMode = .behindWindow
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 12
        visualEffect.layer?.masksToBounds = true

        visualEffect.addSubview(hostingView)
        contentView = visualEffect

        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: visualEffect.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor),
        ])
    }

    private var clickMonitor: Any?

    override var canBecomeKey: Bool { true }

    override func makeKeyAndOrderFront(_ sender: Any?) {
        super.makeKeyAndOrderFront(sender)
        startMonitoringClicks()
    }

    override func close() {
        stopMonitoringClicks()
        super.close()
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            close()
        } else {
            super.keyDown(with: event)
        }
    }

    private func startMonitoringClicks() {
        stopMonitoringClicks()
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp, .rightMouseUp]) { [weak self] event in
            guard let self, self.isVisible else { return }
            if let eventWindow = event.window, eventWindow == self {
                return
            }
            self.close()
        }
    }

    private func stopMonitoringClicks() {
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
        }
    }
}
