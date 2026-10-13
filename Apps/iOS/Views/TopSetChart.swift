import SwiftUI
import RepCoachCore

/// One session's top set, for the exercise sheet's PROGRESS card: the heaviest set of a weighted exercise, else the
/// best reps (or seconds).
struct TopSet: Identifiable, Equatable {
    let date: Date
    /// On the chart's line: the weight, or the reps (seconds).
    let value: Double
    /// Above the dot: the reps of the top set (the same number for a reps or timed exercise).
    let reps: Int
    let timed: Bool

    var id: Date { date }

    /// The last `limit` sessions of `entries` (newest first), oldest first, for a chart left to right.
    static func series(_ entries: [HistoryEntry], kind: ItemKind, limit: Int = 8) -> [TopSet] {
        entries.prefix(limit).reversed().compactMap { entry -> TopSet? in
            if kind == .weighted {
                guard let top = entry.sets.max(by: { ($0.weight, $0.reps) < ($1.weight, $1.reps) }) else { return nil }
                return TopSet(date: entry.date, value: top.weight, reps: top.reps, timed: false)
            }
            guard let best = entry.sets.map(\.reps).max() else { return nil }
            return TopSet(date: entry.date, value: Double(best), reps: best, timed: kind == .timed)
        }
    }
}

/// The top set per session as a volt line with a glow, its reps above each dot (design board 7.5). Drawn by hand,
/// as the board is: grid lines, a soft area, the line, 8 pt dots, the reps over them and the dates under them.
struct TopSetChart: View {
    let points: [TopSet]
    var height: CGFloat = 160

    private static let left: CGFloat = 30
    private static let top: CGFloat = 32
    private static let bottom: CGFloat = 32
    private static let side: CGFloat = 26

    var body: some View {
        let axis = ChartAxis(values: points.map(\.value))
        GeometryReader { geo in
            let width = geo.size.width
            let plotTop = Self.top, plotBottom = geo.size.height - Self.bottom
            let x: (Int) -> CGFloat = { index in
                guard points.count > 1 else { return (Self.left + width) / 2 }
                let span = width - Self.left - 2 * Self.side
                return Self.left + Self.side + span * CGFloat(index) / CGFloat(points.count - 1)
            }
            let y: (Double) -> CGFloat = { value in
                let fraction = (value - axis.domain.lowerBound) / (axis.domain.upperBound - axis.domain.lowerBound)
                return plotBottom - CGFloat(fraction) * (plotBottom - plotTop)
            }
            let dots = points.enumerated().map { CGPoint(x: x($0.offset), y: y($0.element.value)) }
            ZStack(alignment: .topLeading) {
                Path { path in
                    for tick in axis.ticks {
                        path.move(to: CGPoint(x: Self.left, y: y(tick)))
                        path.addLine(to: CGPoint(x: width, y: y(tick)))
                    }
                }
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                ForEach(axis.ticks, id: \.self) { tick in
                    Text(Format.weight(tick))
                        .font(PhoneFont.foot)
                        .foregroundStyle(Theme.text3)
                        .frame(width: Self.left - 4, alignment: .leading)
                        .position(x: (Self.left - 4) / 2, y: y(tick))
                }
                if dots.count > 1 {
                    Path { path in
                        path.move(to: CGPoint(x: dots[0].x, y: plotBottom))
                        dots.forEach { path.addLine(to: $0) }
                        path.addLine(to: CGPoint(x: dots[dots.count - 1].x, y: plotBottom))
                        path.closeSubpath()
                    }
                    .fill(LinearGradient(colors: [Theme.volt.opacity(0.18), Theme.volt.opacity(0)],
                                         startPoint: .top, endPoint: .bottom))
                    Path { path in
                        path.addLines(dots)
                    }
                    .stroke(Theme.volt, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .lineGlow()
                }
                ForEach(Array(dots.enumerated()), id: \.offset) { index, dot in
                    Circle().fill(Theme.volt).frame(width: 8, height: 8).position(dot)
                    Text("\(points[index].reps)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .position(x: dot.x, y: dot.y - 17)
                }
                ForEach(labelled, id: \.self) { index in
                    Text(points[index].date, format: .dateTime.day().month(.abbreviated))
                        .font(PhoneFont.foot)
                        .foregroundStyle(Theme.text3)
                        .fixedSize()
                        .position(x: x(index), y: geo.size.height - 11)
                }
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Top set per session")
        .accessibilityValue(points.map { "\(Format.weight($0.value)) for \($0.reps)" }.joined(separator: ", "))
    }

    /// Every session's date while they fit; from the newest back, every other one when there are many.
    private var labelled: [Int] {
        let all = Array(points.indices)
        guard all.count > 5 else { return all }
        return all.filter { (all.count - 1 - $0) % 2 == 0 }
    }
}

/// Grid lines and the scale for a series: a few round values, one step of room below and a little above.
struct ChartAxis {
    let ticks: [Double]
    let domain: ClosedRange<Double>

    /// Three lines when they can be had: the smallest round step that covers the series with three.
    init(values: [Double]) {
        let low = values.min() ?? 0, high = values.max() ?? 1
        var ticks: [Double] = [], step = 100.0
        for candidate in [1, 2, 2.5, 5, 10, 20, 25, 50, 100] as [Double] {
            let first = (low / candidate).rounded(.down) * candidate
            var last = (high / candidate).rounded(.up) * candidate
            if last - high < candidate * 0.01 { last += candidate }
            let count = Int(((last - first) / candidate).rounded()) + 1
            ticks = (0..<count).map { first + Double($0) * candidate }
            step = candidate
            if count <= 3 { break }
        }
        self.ticks = ticks
        domain = max(0, ticks[0] - step)...(ticks[ticks.count - 1] + step * 0.2)
    }
}
