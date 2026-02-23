import AppKit

class RegionSelectionView: NSView {
    private var startPoint: NSPoint?
    private var currentPoint: NSPoint?
    private let onRegionSelected: (NSRect) -> Void
    private let onCancel: () -> Void
    private var crosshairCursor: NSCursor

    init(frame: NSRect,
         onRegionSelected: @escaping (NSRect) -> Void,
         onCancel: @escaping () -> Void) {
        self.onRegionSelected = onRegionSelected
        self.onCancel = onCancel
        self.crosshairCursor = NSCursor.crosshair
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: crosshairCursor)
    }

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            onCancel()
        }
    }

    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
        currentPoint = startPoint
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard let start = startPoint else { return }
        currentPoint = convert(event.locationInWindow, from: nil)

        let rect = selectionRect(from: start, to: currentPoint!)
        if rect.width > 2 && rect.height > 2 {
            onRegionSelected(rect)
        }

        startPoint = nil
        currentPoint = nil
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let start = startPoint, let current = currentPoint else {
            // Draw semi-transparent overlay when no selection
            NSColor.black.withAlphaComponent(0.3).setFill()
            bounds.fill()
            return
        }

        let rect = selectionRect(from: start, to: current)

        // Draw dimmed overlay
        NSColor.black.withAlphaComponent(0.3).setFill()
        bounds.fill()

        // Cut out the selected region (clear it)
        NSColor.clear.setFill()
        rect.fill(using: .copy)

        // Draw selection border
        NSColor.white.setStroke()
        let borderPath = NSBezierPath(rect: rect)
        borderPath.lineWidth = 1.0
        borderPath.stroke()

        // Draw dashed inner border
        NSColor.white.withAlphaComponent(0.5).setStroke()
        let dashPath = NSBezierPath(rect: rect.insetBy(dx: 1, dy: 1))
        dashPath.lineWidth = 0.5
        dashPath.setLineDash([4, 4], count: 2, phase: 0)
        dashPath.stroke()

        // Draw dimension label
        let dimensionText = "\(Int(rect.width)) × \(Int(rect.height))"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.white,
            .backgroundColor: NSColor.black.withAlphaComponent(0.7)
        ]
        let textSize = dimensionText.size(withAttributes: attributes)
        let labelRect = NSRect(
            x: rect.midX - textSize.width / 2 - 4,
            y: rect.minY - textSize.height - 8,
            width: textSize.width + 8,
            height: textSize.height + 4
        )

        // Background for label
        let bgPath = NSBezierPath(roundedRect: labelRect, xRadius: 4, yRadius: 4)
        NSColor.black.withAlphaComponent(0.7).setFill()
        bgPath.fill()

        // Draw text
        let textPoint = NSPoint(
            x: labelRect.origin.x + 4,
            y: labelRect.origin.y + 2
        )
        dimensionText.draw(at: textPoint, withAttributes: attributes)
    }

    private func selectionRect(from start: NSPoint, to end: NSPoint) -> NSRect {
        let x = min(start.x, end.x)
        let y = min(start.y, end.y)
        let width = abs(end.x - start.x)
        let height = abs(end.y - start.y)
        return NSRect(x: x, y: y, width: width, height: height)
    }
}
