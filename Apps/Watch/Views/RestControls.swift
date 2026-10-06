import SwiftUI

/// The bottom of the rest and break screens: +30 in the left corner, Undo in the middle, and a round button in
/// the right corner (skip the rest, or start the next exercise now).
struct RestControls: View {
    /// +30 s; nil leaves the corner empty.
    var addTime: (() -> Void)?
    /// Undo the last set; nil hides it (a ramp-up isn't logged).
    var undo: (() -> Void)?
    let endSymbol: String
    let endLabel: String
    let end: () -> Void
    @Environment(\.dimmed) private var dimmed

    var body: some View {
        HStack(spacing: 0) {
            if let addTime {
                Button(action: addTime) {
                    Text("+30").role(.row.weight(.bold))
                }
                .buttonStyle(RoundButtonStyle())
                .accessibilityLabel("Add 30 seconds")
            } else {
                Color.clear.frame(width: pt(38), height: pt(38))
            }
            Spacer(minLength: 0)
            if let undo {
                Button(action: undo) {
                    HStack(spacing: pt(4)) {
                        Image(systemName: "arrow.uturn.backward").font(.system(size: pt(12), weight: .semibold))
                        Text("Undo")
                    }
                }
                .buttonStyle(TextButtonStyle())
                .fixedSize()
                .accessibilityLabel("Undo last set")
            }
            Spacer(minLength: 0)
            Button(action: end) {
                Image(systemName: endSymbol).font(.system(size: pt(13), weight: .bold))
            }
            .buttonStyle(RoundButtonStyle())
            .accessibilityLabel(endLabel)
        }
        .padding(.horizontal, pt(18))
        .padding(.bottom, pt(17))
        .opacity(dimmed ? 0.35 : 1)
    }
}
