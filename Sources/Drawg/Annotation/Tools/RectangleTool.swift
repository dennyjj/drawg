import AppKit

class RectangleTool: AnnotationTool {
    var color: NSColor = .red
    var strokeWidth: CGFloat = 3.0
    private var startPoint: NSPoint?
    private var currentPoint: NSPoint?
    private var isShiftHeld = false

    func mouseDown(at point: NSPoint) {
        startPoint = point
        currentPoint = point
        isShiftHeld = NSEvent.modifierFlags.contains(.shift)
    }

    func mouseDragged(to point: NSPoint) {
        currentPoint = point
        isShiftHeld = NSEvent.modifierFlags.contains(.shift)
    }

    func mouseUp(at point: NSPoint) -> Annotation? {
        currentPoint = point
        guard let start = startPoint, let end = currentPoint else { return nil }

        let rect = makeRect(from: start, to: end)
        guard rect.width > 1 && rect.height > 1 else {
            startPoint = nil
            currentPoint = nil
            return nil
        }

        let path = NSBezierPath(rect: rect)
        let annotation = Annotation(type: .rectangle, color: color, strokeWidth: strokeWidth)
        annotation.path = path

        startPoint = nil
        currentPoint = nil
        return annotation
    }

    func drawPreview(in context: NSGraphicsContext) {
        guard let start = startPoint, let end = currentPoint else { return }
        let rect = makeRect(from: start, to: end)
        color.setStroke()
        let path = NSBezierPath(rect: rect)
        path.lineWidth = strokeWidth
        path.stroke()
    }

    private func makeRect(from start: NSPoint, to end: NSPoint) -> NSRect {
        var width = end.x - start.x
        var height = end.y - start.y

        if isShiftHeld {
            let side = min(abs(width), abs(height))
            width = width >= 0 ? side : -side
            height = height >= 0 ? side : -side
        }

        let x = width >= 0 ? start.x : start.x + width
        let y = height >= 0 ? start.y : start.y + height

        return NSRect(x: x, y: y, width: abs(width), height: abs(height))
    }
}
