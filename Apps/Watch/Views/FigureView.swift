import SwiftUI
import RepCoachCore

/// A plan exercise's figure and cue, if it has one. The user's own exercises have none; nothing shows for them.
struct ExerciseFigure {
    let figure: Figure
    let cue: String
    let crop: FigureCrop

    @MainActor private static var crops: [String: FigureCrop] = [:]

    @MainActor
    static func of(_ item: PlanItem) -> ExerciseFigure? {
        #if DEBUG
        // `-figures NO`: the screens as they look without one, for the boards that show that.
        if LaunchOptions.demo, UserDefaults.standard.string(forKey: "figures") == "NO" { return nil }
        #endif
        guard let found = FigureLibrary.shared?.figure(forExercise: item.exerciseId) else { return nil }
        let crop = crops[found.figure.id] ?? FigureRenderer.crop(found.figure)
        crops[found.figure.id] = crop
        return ExerciseFigure(figure: found.figure, cue: found.cue, crop: crop)
    }
}

/// An exercise drawn from its two poses, in a `Canvas`. Moving, it runs its reps at one angle; still (Always On,
/// Reduce Motion, a small button) it shows the end pose over a ghost of the start. `yaw` turns it about the
/// vertical axis, which is what the Crown does on the How screen.
struct FigureView: View {
    let exercise: ExerciseFigure
    /// Degrees; the figure's opening view unless the Crown turned it.
    var yaw: Double
    /// Points: the square the figure is drawn in.
    var size: CGFloat
    var moving = true
    @Environment(\.dimmed) private var dimmed
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if moving && !dimmed && !reduceMotion {
            TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
                canvas(k: Self.position(at: context.date, tempo: exercise.figure.tempo))
            }
        } else {
            canvas(k: nil)
        }
    }

    /// Where in the rep: 0 at the start pose, 1 at the end pose and back, eased.
    static func position(at date: Date, tempo: Double) -> Double {
        let phase = (date.timeIntervalSinceReferenceDate / max(tempo, 0.5)).truncatingRemainder(dividingBy: 1)
        return FigureRenderer.ease(phase < 0.5 ? 2 * phase : 2 - 2 * phase)
    }

    /// `k` nil: the still.
    private func canvas(k: Double?) -> some View {
        let figure = exercise.figure, crop = exercise.crop
        return Canvas { context, canvasSize in
            let scale = canvasSize.width / crop.side
            // Stills under 45 pt draw the end pose alone, with lines 1.4 times wider.
            let small = k == nil && canvasSize.width < 45
            let widen = small ? 1.4 : 1.0
            func at(_ p: FigurePoint) -> CGPoint { CGPoint(x: (p.x - crop.x) * scale, y: (p.y - crop.y) * scale) }

            var floor = Path()
            floor.move(to: CGPoint(x: 0, y: (figure.floor - crop.y) * scale))
            floor.addLine(to: CGPoint(x: canvasSize.width, y: (figure.floor - crop.y) * scale))
            context.stroke(floor, with: .color(Self.color(FigureRenderer.floorColor)),
                           lineWidth: 2 * scale * widen)

            func draw(_ pose: Figure.Pose, opacity: Double) {
                var layer = context
                layer.opacity = opacity
                for item in FigureRenderer.drawList(figure, pose: pose, yaw: yaw) {
                    Self.draw(item, in: &layer, scale: scale, widen: widen, at: at)
                }
            }
            if let k {
                draw(FigureRenderer.pose(figure, k: k), opacity: 1)
            } else {
                if !small { draw(figure.start, opacity: 0.3) }
                draw(figure.end, opacity: 1)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private static func color(_ rgb: UInt32) -> Color {
        Color(red: Double(rgb >> 16 & 0xFF) / 255, green: Double(rgb >> 8 & 0xFF) / 255, blue: Double(rgb & 0xFF) / 255)
    }

    private static func draw(_ item: FigureItem, in context: inout GraphicsContext, scale: Double, widen: Double,
                             at: (FigurePoint) -> CGPoint) {
        func stroke(_ width: Double, dashed: Bool) -> StrokeStyle {
            StrokeStyle(lineWidth: width * scale * widen, lineCap: .round, lineJoin: .round,
                        dash: dashed ? [5 * scale, 4 * scale] : [])
        }
        switch item {
        case .line(let points, let width, let rgb, let opacity, let dashed):
            var path = Path()
            path.addLines(points.map(at))
            context.stroke(path, with: .color(color(rgb).opacity(opacity)), style: stroke(width, dashed: dashed))
        case .polygon(let points, let width, let rgb, let fill, let fillOpacity, let opacity):
            var path = Path()
            path.addLines(points.map(at))
            path.closeSubpath()
            if let fill { context.fill(path, with: .color(color(fill).opacity(fillOpacity * opacity))) }
            context.stroke(path, with: .color(color(rgb).opacity(opacity)), style: stroke(width, dashed: false))
        case .circle(let center, let radius, let rgb, let opacity):
            let c = at(center), r = radius * scale * (widen > 1 ? 1.15 : 1)
            context.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)),
                         with: .color(color(rgb).opacity(opacity)))
        }
    }
}
