import SwiftUI
import RepCoachCore

// The phone's look, "B · Depth" (design/reviews/10-look-b-today.md): black, gradient cards with a lit top edge,
// glass tiles, a faint volt wash at the top of the tab screens, and a glowing primary button.

extension Color {
    /// 0xRRGGBB.
    init(hex: UInt32, opacity: Double = 1) {
        self.init(red: Double(hex >> 16 & 0xFF) / 255, green: Double(hex >> 8 & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255, opacity: opacity)
    }
}

extension Date {
    /// "Wed 7 Oct": the weekday, then the day and month, whatever the region's order.
    var weekdayDayMonth: String {
        "\(formatted(.dateTime.weekday(.abbreviated))) \(formatted(.dateTime.day().month(.abbreviated)))"
    }

    /// "Wed 7 Oct 2026".
    var weekdayDayMonthYear: String {
        "\(weekdayDayMonth) \(formatted(.dateTime.year()))"
    }
}

extension Theme {
    /// A sheet's surface.
    static let sheet = Color(hex: 0x0B0B0C)
    /// The strip of dimmed screen above a sheet.
    static let sheetStrip = Color(hex: 0x0E0E10)
    static let depthTop = Color(hex: 0x26262A)
    static let depthBottom = Color(hex: 0x141416)
    /// The ember warning card's fill.
    static let emberWash = Color(red: 1.0, green: 0.58, blue: 0.26).opacity(0.14)
}

/// The type scale of design/reviews/2-iphone.md, in points (1 pt = 1 px on the boards).
enum PhoneFont {
    static let largeTitle = Font.system(size: 34, weight: .heavy, design: .rounded)
    static let title = Font.system(size: 28, weight: .heavy, design: .rounded)
    static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
    static let number = Font.system(size: 24, weight: .bold, design: .rounded)
    static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 17, weight: .medium, design: .rounded)
    static let sub = Font.system(size: 15, weight: .medium, design: .rounded)
    static let foot = Font.system(size: 13, weight: .medium, design: .rounded)
    static let eyebrow = Font.system(size: 12, weight: .heavy, design: .rounded)
}

extension View {
    /// 12 / 16 / 800, 0.06 em, uppercase: section titles and tile labels.
    func depthEyebrow(_ color: Color = Theme.text3) -> some View {
        font(PhoneFont.eyebrow).tracking(0.72).textCase(.uppercase).foregroundStyle(color)
    }

    /// The card of look B: a 170° gradient and a 1 px light top edge. Padding is the caller's.
    func depthCard(radius: CGFloat = 28) -> some View {
        background { DepthSurface(radius: radius) }
    }

    /// A card holding rows: no padding, the rows clipped to its corners.
    func depthRows(radius: CGFloat = 28) -> some View {
        clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .depthCard(radius: radius)
    }

    /// Stat tiles: glass, 18 pt corners.
    func glassTile(radius: CGFloat = 18) -> some View {
        background {
            let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
            shape
                .fill(LinearGradient(colors: [.white.opacity(0.08), .white.opacity(0.03)],
                                     startPoint: .top, endPoint: .bottom))
                .overlay { TopLight(radius: radius, opacity: 0.10) }
        }
    }

    /// The volt wash behind a tab screen's title.
    func voltWash() -> some View {
        background(alignment: .top) {
            EllipticalGradient(colors: [Theme.volt.opacity(0.06), Theme.volt.opacity(0)],
                               center: UnitPoint(x: 0.7, y: 0.3), startRadiusFraction: 0, endRadiusFraction: 0.7)
                .frame(height: 420)
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    /// The glow under a line chart's line.
    func lineGlow() -> some View {
        shadow(color: Theme.volt.opacity(0.55), radius: 6)
    }
}

/// The gradient card surface.
struct DepthSurface: View {
    var radius: CGFloat = 28
    var tint: Color?

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        if let tint {
            shape
                .fill(LinearGradient(colors: [tint.opacity(0.22), tint.opacity(0.08)],
                                     startPoint: UnitPoint(x: 0.4, y: 0), endPoint: UnitPoint(x: 0.6, y: 1)))
                .overlay { TopLight(radius: radius, color: tint, opacity: 0.45) }
        } else {
            shape
                .fill(LinearGradient(colors: [Theme.depthTop, Theme.depthBottom],
                                     startPoint: UnitPoint(x: 0.4, y: 0), endPoint: UnitPoint(x: 0.6, y: 1)))
                .overlay { TopLight(radius: radius, opacity: 0.08) }
        }
    }
}

/// `inset 0 1px 0 rgba(255,255,255,a)`: a hairline along the top edge that fades out down the corners.
struct TopLight: View {
    var radius: CGFloat
    var color: Color = .white
    var opacity: Double

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .strokeBorder(color.opacity(opacity), lineWidth: 1)
            .mask(alignment: .top) {
                LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: max(radius, 6))
            }
            .allowsHitTesting(false)
    }
}

/// A card with a titled eyebrow and rows: the section of Today and Plan.
struct DepthSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .depthEyebrow()
                .padding(.leading, 6)
            VStack(spacing: 0) { content }
                .depthRows()
        }
    }
}

/// A 1 px line between rows, `rgba(255,255,255,0.10)`, inset from the left.
struct DepthDivider: View {
    var inset: CGFloat = 68

    var body: some View {
        Rectangle()
            .fill(Theme.line)
            .frame(height: 1)
            .padding(.leading, inset)
    }
}

/// The primary button of look B: a volt pill with a lit top edge and a glow.
struct PrimaryButtonStyle: ButtonStyle {
    var height: CGFloat = 56

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background {
                Capsule()
                    .fill(Theme.volt)
                    .overlay { TopLight(radius: height / 2, color: .white, opacity: 0.5) }
                    .shadow(color: Theme.volt.opacity(0.35), radius: 15, y: 10)
            }
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}

/// A row that dims while pressed and otherwise keeps the card's look.
struct RowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.white.opacity(0.06) : .clear)
    }
}

/// The 30 pt grey circle with a cross of a sheet's close button, in a 44 pt target.
struct SheetCloseButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(Theme.text2)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Theme.raised))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Close")
    }
}

extension View {
    /// A sheet's surface and shape: `#0B0B0C` with 28 pt top corners and the grabber.
    func sheetSurface() -> some View {
        presentationBackground(Theme.sheet)
            .presentationCornerRadius(28)
            .presentationDragIndicator(.visible)
    }
}
