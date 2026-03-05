import UIKit

public class ShapeView: UIView {

    public enum Shape {
        case rectangle
        case circle
        case arrow
    }

    var shape: Shape
    var strokeColor: UIColor
    var strokeWidth: CGFloat = 3.0

    init(shape: Shape, color: UIColor, size: CGSize) {
        self.shape = shape
        self.strokeColor = color
        super.init(frame: CGRect(origin: .zero, size: size))
        self.backgroundColor = .clear
        self.isOpaque = false
    }

    required init?(coder: NSCoder) {
        self.shape = .rectangle
        self.strokeColor = .red
        super.init(coder: coder)
    }

    override public func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        context.setStrokeColor(strokeColor.cgColor)
        context.setLineWidth(strokeWidth)

        let inset = strokeWidth / 2
        let drawRect = rect.insetBy(dx: inset, dy: inset)

        switch shape {
        case .rectangle:
            context.stroke(drawRect)

        case .circle:
            context.strokeEllipse(in: drawRect)

        case .arrow:
            let startX = drawRect.minX + drawRect.width * 0.05
            let endX = drawRect.maxX - drawRect.width * 0.05
            let midY = drawRect.midY
            let headLength = min(drawRect.width * 0.2, 20)
            let headWidth = min(drawRect.height * 0.35, 15)

            // Shaft
            context.move(to: CGPoint(x: startX, y: midY))
            context.addLine(to: CGPoint(x: endX, y: midY))
            context.strokePath()

            // Arrowhead
            context.move(to: CGPoint(x: endX - headLength, y: midY - headWidth))
            context.addLine(to: CGPoint(x: endX, y: midY))
            context.addLine(to: CGPoint(x: endX - headLength, y: midY + headWidth))
            context.strokePath()
        }
    }
}
