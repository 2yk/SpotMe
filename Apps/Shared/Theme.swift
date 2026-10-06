import SwiftUI
import RepCoachCore

/// SpotMe's dark look, shared by the watch and the phone.
enum Theme {
    /// Signature accent: lifts, primary buttons, progress.
    static let volt = Color(red: 0.80, green: 1.00, blue: 0.24)
    /// Lighter-next-set warnings and max-rep work.
    static let ember = Color(red: 1.00, green: 0.58, blue: 0.26)
    /// Rest timers and bodyweight work.
    static let ice = Color(red: 0.39, green: 0.85, blue: 1.00)
    /// Heart rate.
    static let pulse = Color(red: 1.00, green: 0.27, blue: 0.41)
    /// Done.
    static let mint = Color(red: 0.28, green: 0.92, blue: 0.64)
    /// Timed holds.
    static let violet = Color(red: 0.69, green: 0.57, blue: 1.00)
    /// A paused workout.
    static let amber = Color(red: 1.00, green: 0.82, blue: 0.20)

    static let canvas = Color.black
    static let card = Color(white: 0.11)
    static let cardRaised = Color(white: 0.16)
    static let hairline = Color.white.opacity(0.08)
    static let secondary = Color.white.opacity(0.62)
    static let tertiary = Color.white.opacity(0.36)

    // The watch redesign's tokens (design/handoff/watch-1/BUILD.md, section 3). The phone keeps the older
    // ones above until its own redesign.
    /// Stop, End, Discard and heart rate.
    static let red = pulse
    /// Round and neutral buttons.
    static let raised = Color(red: 0.173, green: 0.173, blue: 0.180)
    /// Supporting text.
    static let text2 = Color(red: 0.722, green: 0.722, blue: 0.741)
    /// Units and hints.
    static let text3 = Color(red: 0.557, green: 0.557, blue: 0.576)
    /// Tile outline.
    static let line = Color.white.opacity(0.10)
    /// Eyebrows and reasons with the wrist down.
    static let dimmedText = Color(red: 0.431, green: 0.431, blue: 0.451)
}

extension Font {
    /// Big numbers: weights, reps, timers.
    static func number(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func rounded(_ style: Font.TextStyle, _ weight: Font.Weight = .semibold) -> Font {
        .system(style, design: .rounded, weight: weight)
    }
}

extension View {
    /// Small uppercase label: "UP NEXT", "SET 2 OF 4".
    func eyebrow(_ color: Color = Theme.secondary, size: CGFloat = 11) -> some View {
        font(.system(size: size, weight: .heavy, design: .rounded))
            .tracking(0.9)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }

    /// A plain dark card.
    func card(_ fill: Color = Theme.card, radius: CGFloat = 16) -> some View {
        background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(fill))
    }

    /// A card lit by `tint`: the up-next card, highlighted values.
    func glowCard(_ tint: Color, radius: CGFloat = 22) -> some View {
        background {
            let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
            shape
                .fill(LinearGradient(colors: [tint.opacity(0.34), tint.opacity(0.07)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(shape.strokeBorder(LinearGradient(colors: [tint.opacity(0.75), tint.opacity(0.12)],
                                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                                            lineWidth: 1))
        }
    }
}

/// A progress ring with a soft track and a rounded, gradient arc.
struct ProgressRing: View {
    var progress: Double
    var tint: Color
    var lineWidth: CGFloat = 8

    var body: some View {
        let value = min(max(progress, 0), 1)
        ZStack {
            Circle().stroke(tint.opacity(0.16), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: value)
                .stroke(AngularGradient(colors: [tint.opacity(0.5), tint], center: .center,
                                        startAngle: .degrees(0), endAngle: .degrees(max(1, 360 * value))),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

extension Coach.Tone {
    var color: Color {
        switch self {
        case .up: Theme.volt
        case .down: Theme.ember
        case .done: Theme.mint
        case .neutral: Theme.secondary
        }
    }
}

extension PlanItem {
    var tint: Color {
        switch kind {
        case .weighted: Theme.volt
        case .reps: Theme.ice
        case .timed: Theme.violet
        case .amrap, .percentOfMax: Theme.ember
        case .checklist: Color(white: 0.82)
        }
    }

    var symbol: String {
        switch kind {
        case .weighted: return "dumbbell.fill"
        case .reps: return "figure.core.training"
        case .timed: return "timer"
        case .amrap: return "flame.fill"
        case .percentOfMax: return "repeat"
        case .checklist:
            let group = group.lowercased()
            if group.contains("warmup") { return "flame" }
            if group.contains("cooldown") { return "figure.cooldown" }
            if group.contains("mobility") { return "figure.flexibility" }
            if group.contains("neck") { return "figure.mind.and.body" }
            if group.contains("recovery") { return "moon.zzz.fill" }
            return "sparkles"
        }
    }

    /// Weight is entered for weighted items and optional for loadable ones.
    var takesWeight: Bool { kind == .weighted || loadable == true }
}
