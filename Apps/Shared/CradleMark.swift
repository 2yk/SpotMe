import SwiftUI

/// The SpotMe mark drawn as shapes: a dot resting in a cradle. Vector, so it stays sharp at any size and
/// works where images don't, like watch face complications.
struct CradleMark: View {
    var dot: Color = Theme.volt
    var cradle: Color = .white

    var body: some View {
        ZStack {
            CradleShape(part: .cradle).fill(cradle)
            CradleShape(part: .dot).fill(dot)
        }
        .aspectRatio(CradleShape.aspectRatio, contentMode: .fit)
    }
}

/// One part of the mark, fitted into its rect. Geometry from docs/brand/mark.svg: a dot of radius 150 at the
/// centre of an arc of radius 251 and width 122 with round caps, sweeping 196° underneath it. The artwork is
/// 624 × 462 without the glow.
struct CradleShape: Shape {
    enum Part {
        case dot, cradle
    }

    var part: Part

    static let aspectRatio: CGFloat = 624.0 / 462.0

    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width / 624, rect.height / 462)
        let center = CGPoint(x: rect.midX, y: rect.midY - (231 - 150) * scale)
        switch part {
        case .dot:
            let radius = 150 * scale
            return Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
                                          width: radius * 2, height: radius * 2))
        case .cradle:
            var arc = Path()
            // Angles grow clockwise on screen, so this runs from just above the right, under the dot, to the left.
            arc.addArc(center: center, radius: 251 * scale, startAngle: .degrees(-8), endAngle: .degrees(188),
                       clockwise: false)
            return arc.strokedPath(StrokeStyle(lineWidth: 122 * scale, lineCap: .round))
        }
    }
}
