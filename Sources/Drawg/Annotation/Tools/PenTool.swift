import AppKit

class PenTool: AnnotationTool {
    var color: NSColor = .red
    var strokeWidth: CGFloat = 3.0
    private var currentPath: NSBezierPath?

    func mouseDown(at point: NSPoint) {
        currentPath = NSBezierPath()
        currentPath?.move(to: point)
    }

    func mouseDragged(to point: NSPoint) {
        currentPath?.line(to: point)
    }

    func mouseUp(at point: NSPoint) -> Annotation? {
        currentPath?.line(to: point)
        guard let path = currentPath else { return nil }

        let annotation = Annotation(type: .pen, color: color, strokeWidth: strokeWidth)
        annotation.path = path
        currentPath = nil
        return annotation
    }

    func drawPreview(in context: NSGraphicsContext) {
        guard let path = currentPath else { return }
        color.setStroke()
        path.lineWidth = strokeWidth
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.stroke()
    }
}
