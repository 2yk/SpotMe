import SwiftUI

extension View {
    /// The short title in the system navigation bar, in `color` (volt; ice on rest and break; amber when paused),
    /// after the back button. The bar keeps its clock; nothing else goes in it.
    /// - Parameters:
    ///   - root: the first screen of a stack: no back button.
    ///   - close: a sheet: a close icon instead of the chevron.
    func barTitle(_ title: String, _ color: Color = Theme.volt, root: Bool = false, close: Bool = false) -> some View {
        modifier(BarTitle(title: title, color: color, root: root, close: close))
    }
}

private struct BarTitle: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dimmed) private var dimmed
    let title: String
    let color: Color
    let root: Bool
    let close: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if close {
            // A sheet shows one item in the bar's leading corner, and it is the system's own close button, so
            // the title is laid over the bar beside it.
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
        } else {
            content
                .navigationTitle("")
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        HStack(spacing: pt(6)) {
                            if !root { button }
                            titleText
                        }
                    }
                }
        }
    }

    /// The back chevron, or the close icon of a sheet: a 30 pt raised circle.
    private var button: some View {
        Button { dismiss() } label: {
            Image(systemName: close ? "xmark" : "chevron.left")
                .font(.system(size: pt(14), weight: .bold))
                .foregroundStyle(.white)
                .frame(width: pt(30), height: pt(30))
                .background(Circle().fill(Theme.raised))
                .opacity(dimmed ? 0.35 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(close ? "Close" : "Back")
    }

    private var titleText: some View {
        Text(title).role(.bar, color).lineLimit(1)
    }
}
