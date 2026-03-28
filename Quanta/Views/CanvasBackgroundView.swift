import SwiftUI

struct CanvasBackgroundView: View {
    let style: CanvasStyle
    let lineSpacing: CGFloat = 28
    let lineColor = Color(.systemGray4).opacity(0.5)
    let dotColor = Color(.systemGray4).opacity(0.6)

    var body: some View {
        switch style {
        case .blank:
            Color.white
        case .ruled:
            Canvas { context, size in
                var y: CGFloat = lineSpacing
                while y < size.height {
                    let path = Path { p in
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: size.width, y: y))
                    }
                    context.stroke(path, with: .color(lineColor), lineWidth: 0.5)
                    y += lineSpacing
                }
                // Left margin line
                let marginPath = Path { p in
                    p.move(to: CGPoint(x: 72, y: 0))
                    p.addLine(to: CGPoint(x: 72, y: size.height))
                }
                context.stroke(marginPath, with: .color(Color.red.opacity(0.2)), lineWidth: 0.5)
            }
            .background(Color.white)
        case .grid:
            Canvas { context, size in
                // Horizontal
                var y: CGFloat = lineSpacing
                while y < size.height {
                    let path = Path { p in
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: size.width, y: y))
                    }
                    context.stroke(path, with: .color(lineColor), lineWidth: 0.5)
                    y += lineSpacing
                }
                // Vertical
                var x: CGFloat = lineSpacing
                while x < size.width {
                    let path = Path { p in
                        p.move(to: CGPoint(x: x, y: 0))
                        p.addLine(to: CGPoint(x: x, y: size.height))
                    }
                    context.stroke(path, with: .color(lineColor), lineWidth: 0.5)
                    x += lineSpacing
                }
            }
            .background(Color.white)
        case .dotted:
            Canvas { context, size in
                var y: CGFloat = lineSpacing
                while y < size.height {
                    var x: CGFloat = lineSpacing
                    while x < size.width {
                        let rect = CGRect(x: x - 1.5, y: y - 1.5, width: 3, height: 3)
                        context.fill(Circle().path(in: rect), with: .color(dotColor))
                        x += lineSpacing
                    }
                    y += lineSpacing
                }
            }
            .background(Color.white)
        }
    }
}
