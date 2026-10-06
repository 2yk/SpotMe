import SwiftUI
import WatchKit

/// The design is drawn for the 46 mm watch (208 × 248 pt). Smaller watches scale every size by one factor, so
/// there is a single layout: 42 mm comes out at 0.9.
enum Metrics {
    static let scale: CGFloat = min(1, WKInterfaceDevice.current().screenBounds.width / 208)

    /// Space on each side of the content column.
    static var side: CGFloat { pt(8) }
    /// Between the content's last element and the bottom of the screen.
    static var bottom: CGFloat { pt(15) }
    /// Where the content starts: just under the system bar's back button and clock. The system reserves more
    /// than that (62 pt on the 46 mm), so screens ignore the safe area and start here.
    static var top: CGFloat { pt(50) }
}

extension View {
    /// The design's content column: the sides, the top and the bottom set from the whole screen, whatever the
    /// system's safe area is.
    func screenColumn() -> some View {
        padding(.horizontal, Metrics.side)
            .padding(.top, Metrics.top)
            .padding(.bottom, Metrics.bottom)
            .ignoresSafeArea()
    }
}

/// A size from the design, in points on the 46 mm watch, scaled to this one.
func pt(_ value: CGFloat) -> CGFloat {
    (value * Metrics.scale * 2).rounded() / 2
}
