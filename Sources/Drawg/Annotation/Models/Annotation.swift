import AppKit

enum AnnotationType {
    case pen
    case rectangle
    case arrow
    case text
}

class Annotation {
    let id: UUID
    let type: AnnotationType
    var path: NSBezierPath?
    var color: NSColor
    var strokeWidth: CGFloat
    var text: String?
    var textRect: NSRect?
    var fontSize: CGFloat

    // Arrow-specific
    var startPoint: NSPoint?
    var endPoint: NSPoint?

    init(type: AnnotationType,
         color: NSColor = .red,
         strokeWidth: CGFloat = 3.0,
         fontSize: CGFloat = 16.0) {
        self.id = UUID()
        self.type = type
        self.color = color
        self.strokeWidth = strokeWidth
        self.fontSize = fontSize
    }

    func draw() {
        color.setStroke()
        color.setFill()

        switch type {
        case .pen:
            guard let path = path else { return }
            path.lineWidth = strokeWidth
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            path.stroke()

        case .rectangle:
            guard let path = path else { return }
            path.lineWidth = strokeWidth
            path.stroke()

        case .arrow:
            guard let start = startPoint, let end = endPoint else { return }
            drawArrow(from: start, to: end)

        case .text:
            guard let text = text, let rect = textRect else { return }
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: fontSize, weight: .medium),
                .foregroundColor: color
            ]
            text.draw(in: rect, withAttributes: attributes)
        }
    }

    private func drawArrow(from start: NSPoint, to end: NSPoint) {
        let linePath = NSBezierPath()
        linePath.lineWidth = strokeWidth
        linePath.lineCapStyle = .round
        linePath.move(to: start)
        linePath.line(to: end)
        linePath.stroke()

        // Arrowhead
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
