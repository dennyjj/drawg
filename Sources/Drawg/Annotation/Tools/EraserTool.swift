import AppKit

class EraserTool: AnnotationTool {
    var color: NSColor = .red
    var strokeWidth: CGFloat = 3.0
    weak var canvasView: AnnotationCanvasView?

    private var currentPoint: NSPoint?
    private let eraserRadius: CGFloat = 10

    func mouseDown(at point: NSPoint) {
        currentPoint = point
        canvasView?.beginErasure()
        eraseAt(point)
    }

    func mouseDragged(to point: NSPoint) {
        currentPoint = point
        eraseAt(point)
    }

    func mouseUp(at point: NSPoint) -> Annotation? {
        currentPoint = point
        eraseAt(point)
        canvasView?.commitErasure()
        currentPoint = nil
        return nil
    }

    func drawPreview(in context: NSGraphicsContext) {
        guard let point = currentPoint else { return }
        NSColor.gray.withAlphaComponent(0.3).setFill()
        NSColor.gray.withAlphaComponent(0.6).setStroke()
        let rect = NSRect(
            x: point.x - eraserRadius,
            y: point.y - eraserRadius,
            width: eraserRadius * 2,
            height: eraserRadius * 2
        )
        let circle = NSBezierPath(ovalIn: rect)
        circle.fill()
        circle.lineWidth = 1
        circle.stroke()
    }

    private func eraseAt(_ point: NSPoint) {
        canvasView?.eraseAnnotations(near: point, radius: eraserRadius)
    }
}
