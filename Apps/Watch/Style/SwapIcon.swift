import SwiftUI

/// The swap icon of the design (`M7 7h11l-3-3M17 17H6l3 3` on a 24 × 24 grid): an arrow to the right above an
/// arrow to the left.
struct SwapIcon: View {
    /// Points: the square it is drawn in (the design's 20 px icon is 10 pt).
    var size: CGFloat = 10
    var color: Color = Theme.text3

    var body: some View {
        SwapShape()
            .stroke(color, style: StrokeStyle(lineWidth: size * 2.1 / 24, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

private struct SwapShape: Shape {
    func path(in rect: CGRect) -> Path {
        let k = min(rect.width, rect.height) / 24
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * k, y: rect.minY + y * k) }
        var path = Path()
        path.move(to: point(7, 7))
        path.addLine(to: point(18, 7))
        path.addLine(to: point(15, 4))
        path.move(to: point(17, 17))
        path.addLine(to: point(6, 17))
        path.addLine(to: point(9, 20))
        return path
    }
}
