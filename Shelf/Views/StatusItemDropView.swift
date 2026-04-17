import AppKit

final class StatusItemDropView: NSView {
    var onDrop: (([URL]) -> Void)?

    private var isDragHighlighted = false {
        didSet { needsDisplay = true }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        if isDragHighlighted {
            NSColor.controlAccentColor.withAlphaComponent(0.3).setFill()
            let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 2, dy: 2), xRadius: 4, yRadius: 4)
            path.fill()
        }
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { false }

    override func hitTest(_ point: NSPoint) -> NSView? {
        if NSPasteboard(name: .drag).types?.isEmpty == false {
            return super.hitTest(point)
        }
        return nil
    }

    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        isDragHighlighted = true
        return .copy
    }

    override func draggingExited(_ sender: (any NSDraggingInfo)?) {
        isDragHighlighted = false
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        isDragHighlighted = false
    }

    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        isDragHighlighted = false
        guard let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [
            .urlReadingFileURLsOnly: true
        ]) as? [URL], !urls.isEmpty else {
            return false
        }
        onDrop?(urls)
        return true
    }
}
