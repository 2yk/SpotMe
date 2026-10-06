import SwiftUI
import WatchKit

/// A 5 pt line that follows the screen's edge, inset 4.5 pt, on rest, break and hold. The track is the colour at
/// 18%; what is left is drawn solid and ends at top centre, and its start runs away clockwise as time passes.
/// Drawn from the same clock as the digits that sit beside it.
///
/// The line is `ContainerRelativeShape`, the display's own corner shape. Its path starts at 3 o'clock and runs
/// clockwise, so the arc is cut in two where it passes that point; where top centre falls along the path
/// comes from the screen's size and a corner radius that is only an estimate, which puts the end of the
/// line within a point or two of top centre.
struct EdgeTimer: View {
    /// What is left, 1 down to 0.
    var left: Double
    var tint: Color = Theme.ice
    var state = State.normal

    enum State {
        case normal
        /// Paused: the line is dimmer.
        case paused
        /// Wrist down (Always On): the track is dimmer too.
        case alwaysOn
    }

    var body: some View {
        ZStack {
            EdgeTrack(tint: tint, opacity: state == .alwaysOn ? 0.10 : 0.18)
            EdgeArc(from: 1 - min(max(left, 0), 1), to: 1, tint: tint, opacity: state == .normal ? 1 : 0.45)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// How far along the path (0...1, from 3 o'clock, clockwise) top centre is.
    static var topCentre: Double {
        let size = WKInterfaceDevice.current().screenBounds.size
        let inset = Double(pt(4.5))
        let width = Double(size.width) - 2 * inset
        let height = Double(size.height) - 2 * inset
        let radius = Double(pt(48)) - inset
        // From top centre clockwise to 3 o'clock: half the top edge, a corner, half the right edge.
        let toRight = (width / 2 - radius) + .pi * radius / 2 + (height / 2 - radius)
        let perimeter = 2 * (width - 2 * radius) + 2 * (height - 2 * radius) + 2 * .pi * radius
        return 1 - toRight / perimeter
    }
}

/// The faint full loop the line runs on.
struct EdgeTrack: View {
    let tint: Color
    var opacity = 0.18

    var body: some View {
        ContainerRelativeShape().inset(by: pt(4.5)).stroke(tint.opacity(opacity), lineWidth: pt(5))
    }
}

/// Part of the loop, from `from` to `to` (0 at top centre, 1 back at top centre, clockwise), with round ends.
struct EdgeArc: View {
    var from: Double
    var to: Double
    let tint: Color
    /// Applied to the arc as one piece, so where its two parts meet there is no darker or brighter dot.
    var opacity = 1.0

    var body: some View {
        let shape = ContainerRelativeShape().inset(by: pt(4.5))
        let style = StrokeStyle(lineWidth: pt(5), lineCap: .round)
        let top = EdgeTimer.topCentre
        let start = top + min(max(from, 0), 1)
        let end = top + min(max(to, 0), 1)
        if end > start {
            ZStack {
                if end <= 1 {
                    shape.trim(from: start, to: end).stroke(tint, style: style)
                } else if start >= 1 {
                    shape.trim(from: start - 1, to: end - 1).stroke(tint, style: style)
                } else {
                    shape.trim(from: start, to: 1).stroke(tint, style: style)
                    shape.trim(from: 0, to: end - 1).stroke(tint, style: style)
                }
            }
            .compositingGroup()
            .opacity(opacity)
        }
    }
}
