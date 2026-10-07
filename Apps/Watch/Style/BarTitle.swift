import SwiftUI

extension View {
    /// The short title beside the system bar's clock, in `color` (volt; ice on a break; amber when paused). The
    /// bar keeps its clock and nothing else: workout screens have no back button (List, on the controls page,
    /// is the way to Today).
    /// - Parameters:
    ///   - root: Today, the first screen of the stack.
    ///   - close: a sheet: a close icon beside the title.
    ///   - edge: a screen with the edge timer (break, hold): the title sits a little lower and further in, clear
    ///     of the line, and is drawn as content, not as the navigation title.
    func barTitle(_ title: String, _ color: Color = Theme.volt, root: Bool = false, close: Bool = false,
                  edge: Bool = false) -> some View {
        modifier(BarTitle(title: title, color: color, root: root, close: close, edge: edge))
    }
}

private struct BarTitle: ViewModifier {
    let title: String
    let color: Color
    let root: Bool
    let close: Bool
    let edge: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if close {
            // A sheet shows one item in the bar's leading corner, and it is the system's own close button, so
            // the title is laid over the bar beside it.
            NavigationStack {
                content
                    .navigationTitle("")
                    .overlay(alignment: .topLeading) {
                        titleText
                            .padding(.leading, pt(51))
                            .padding(.top, pt(27))
                            .ignoresSafeArea()
                            .allowsHitTesting(false)
                    }
                    .containerBackground(.black, for: .navigation)
            }
        } else {
            // Today and the workout screens have no back button: the title goes on the clock's line, at the
            // left, as Today's "0/15" does. With the edge timer it clears the line.
            content
                .navigationTitle("")
                .navigationBarBackButtonHidden(true)
                .overlay(alignment: .topLeading) {
                    titleText
                        .padding(.leading, pt(edge ? Self.edgeLeading : Self.leading))
                        .padding(.top, pt(edge ? Self.edgeTop : Self.top))
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
        }
    }

    /// Today's title: 22 pt from the left, on the clock's line.
    static let leading: CGFloat = 22
    static let top: CGFloat = 16
    /// On the edge-timer screens: 26 pt from the left and 5 pt lower (board 52 / 34 px at 2×).
    static let edgeLeading: CGFloat = 26
    static let edgeTop: CGFloat = 21

    private var titleText: some View {
        Text(title).role(.bar, color).lineLimit(1)
    }
}
