import SwiftUI

/// Full-width capsule with a black label: the one primary action on a screen. Volt, or the state's colour.
struct PrimaryButtonStyle: ButtonStyle {
    var tint = Theme.volt
    var height: CGFloat = 44

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .role(.button, .black)
            .lineLimit(1)
            .frame(maxWidth: .infinity, minHeight: pt(height), maxHeight: pt(height))
            .background(Capsule().fill(tint))
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Raised fill, white label: Finish workout, Keep going. `label` is red for Discard.
struct NeutralButtonStyle: ButtonStyle {
    var height: CGFloat = 38
    var label = Color.white
    var font = TextRole.button

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .role(font, label)
            .lineLimit(1)
            .frame(maxWidth: .infinity, minHeight: pt(height), maxHeight: pt(height))
            .background(Capsule().fill(Theme.raised))
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Stop and Discard: red fill, black label.
extension PrimaryButtonStyle {
    static var destructive: PrimaryButtonStyle { PrimaryButtonStyle(tint: Theme.red) }
}

/// No fill, 30 pt high: Skip, Discard workout, Undo.
struct TextButtonStyle: ButtonStyle {
    var color = Theme.text2

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: pt(13), weight: .semibold, design: .rounded))
            .foregroundStyle(color)
            .lineLimit(1)
            .frame(maxWidth: .infinity, minHeight: pt(30))
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

/// A tappable row or card: the label as it is, a little dimmer while pressed, with no padding of its own.
struct RowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

/// The 38 pt round button in the corners of the rest and break screens.
struct RoundButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .frame(width: pt(38), height: pt(38))
            .background(Circle().fill(Theme.raised))
            .opacity(configuration.isPressed ? 0.7 : 1)
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension View {
    /// A card in the design's sizes: row, tile, summary.
    func surface(radius: CGFloat = 17, fill: Color = Theme.card) -> some View {
        background(RoundedRectangle(cornerRadius: pt(radius), style: .continuous).fill(fill))
    }
}
