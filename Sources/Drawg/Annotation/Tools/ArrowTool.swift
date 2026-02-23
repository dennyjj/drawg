import AppKit

class ArrowTool: AnnotationTool {
    var color: NSColor = .red
    var strokeWidth: CGFloat = 3.0
    private var startPoint: NSPoint?
    private var currentPoint: NSPoint?

    func mouseDown(at point: NSPoint) {
        startPoint = point
        currentPoint = point
    }

    func mouseDragged(to point: NSPoint) {
        currentPoint = point
    }

    func mouseUp(at point: NSPoint) -> Annotation? {
        currentPoint = point
        guard let start = startPoint, let end = currentPoint else { return nil }

        let distance = hypot(end.x - start.x, end.y - start.y)
        guard distance > 3 else {
            startPoint = nil
            currentPoint = nil
            return nil
        }

        let annotation = Annotation(type: .arrow, color: color, strokeWidth: strokeWidth)
        annotation.startPoint = start
        annotation.endPoint = end

        startPoint = nil
        currentPoint = nil
        return annotation
    }

    func drawPreview(in context: NSGraphicsContext) {
        guard let start = startPoint, let end = currentPoint else { return }
        color.setStroke()
        color.setFill()

        let linePath = NSBezierPath()
        linePath.lineWidth = strokeWidth
        linePath.lineCapStyle = .round
        linePath.move(to: start)
        linePath.line(to: end)
        linePath.stroke()

        // Arrowhead preview
        let angle = atan2(end.y - start.y, end.x - start.x)
        let arrowLength: CGFloat = max(strokeWidth * 4, 12)
        let arrowAngle: CGFloat = .pi / 6

        let arrowPoint1 = NSPoint(
            x: end.x - arrowLength * cos(angle - arrowAngle),
            y: end.y - arrowLength * sin(angle - arrowAngle)
        )
        let arrowPoint2 = NSPoint(
            x: end.x - arrowLength * cos(angle + arrowAngle),
            y: end.y - arrowLength * sin(angle + arrowAngle)
        )

        let arrowHead = NSBezierPath()
        arrowHead.move(to: end)
        arrowHead.line(to: arrowPoint1)
        arrowHead.line(to: arrowPoint2)
        arrowHead.close()
        arrowHead.fill()
    }
}
