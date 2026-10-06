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
    /// Where a sheet's content starts: under the system's close button, which is the same size as the back button.
    static var sheetTop: CGFloat { pt(56) }
    /// Today has no back button, so its content starts right under the clock.
    static var rootTop: CGFloat { pt(40) }
}

extension View {
    /// The design's content column: the sides, the top and the bottom set from the whole screen, whatever the
    /// system's safe area is.
    func screenColumn(top: CGFloat = Metrics.top) -> some View {
        // A GeometryReader that ignores the safe area is the whole screen, in sheets too, where the bottom
        // inset otherwise stays: the column is exactly that size, less its margins.
        GeometryReader { geometry in
            self
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, Metrics.side)
                .padding(.top, top)
                .padding(.bottom, Metrics.bottom)
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
    }

    /// For lists and scrolling screens whose content starts under the bar's buttons: the system's own fade at
    /// the top edge would blur the first lines even at rest, so it is off, and a black fade of the design's
    /// height takes its place, which only shows once content has scrolled up under it.
    func topFade() -> some View {
        modifier(TopFade())
    }
}

private struct TopFade: ViewModifier {
    func body(content: Content) -> some View {
        Group {
            if #available(watchOS 26, *) {
                content.scrollEdgeEffectHidden(true, for: .top)
            } else {
                content
            }
        }
        .overlay(alignment: .top) {
            LinearGradient(stops: [.init(color: .black, location: 0), .init(color: .black, location: 0.62),
                                   .init(color: .black.opacity(0), location: 1)],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: pt(48))
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
    }
}

/// A size from the design, in points on the 46 mm watch, scaled to this one.
func pt(_ value: CGFloat) -> CGFloat {
    (value * Metrics.scale * 2).rounded() / 2
}
