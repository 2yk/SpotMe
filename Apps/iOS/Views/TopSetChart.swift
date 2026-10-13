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

/// The top set per session as a volt line with a glow, its reps above each dot (design board 7.5).
struct TopSetChart: View {
    let points: [TopSet]

    var body: some View {
        SeriesChart(dates: points.map(\.date), main: points.map(\.value), labels: points.map { "\($0.reps)" },
                    height: 160, top: 32)
            .accessibilityLabel("Top set per session")
            .accessibilityValue(points.map { "\(Format.weight($0.value)) for \($0.reps)" }.joined(separator: ", "))
    }
}

/// A line chart in look B, drawn by hand as the boards are (7.5, 8.2, 8.8): grid lines with their values on the
/// left, a volt line with a glow and a soft area under it, 8 pt dots, an optional dashed white second line, and the
/// dates under it. Points are evenly spaced, one per measurement.
struct SeriesChart: View {
    let dates: [Date]
    let main: [Double]
    var second: [Double]?
    /// Written above each dot of the main line.
    var labels: [String]?
    var height: CGFloat = 220
    /// Room above the top grid line (for `labels`) and under the bottom one (for the dates).
    var top: CGFloat = 20
    var bottom: CGFloat = 32
    var maxTicks = 4
    var format: (Double) -> String = { Format.weight($0) }

    private static let side: CGFloat = 26
    /// Room for the values on the left.
    var left: CGFloat = 30

    var body: some View {
        let axis = ChartAxis(values: main + (second ?? []), maxTicks: maxTicks)
        GeometryReader { geo in
            let width = geo.size.width
            let plotTop = top, plotBottom = geo.size.height - bottom
            let x: (Int) -> CGFloat = { index in
                guard main.count > 1 else { return (left + width) / 2 }
                let span = width - left - 2 * Self.side
                return left + Self.side + span * CGFloat(index) / CGFloat(main.count - 1)
            }
            let y: (Double) -> CGFloat = { value in
                let fraction = (value - axis.domain.lowerBound) / (axis.domain.upperBound - axis.domain.lowerBound)
                return plotBottom - CGFloat(fraction) * (plotBottom - plotTop)
            }
            let dots = main.enumerated().map { CGPoint(x: x($0.offset), y: y($0.element)) }
            ZStack(alignment: .topLeading) {
                Path { path in
                    for tick in axis.ticks {
                        path.move(to: CGPoint(x: left, y: y(tick)))
                        path.addLine(to: CGPoint(x: width, y: y(tick)))
                    }
                }
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                ForEach(axis.ticks, id: \.self) { tick in
                    Text(format(tick))
                        .font(PhoneFont.foot)
                        .foregroundStyle(Theme.text3)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(width: left - 4, alignment: .leading)
                        .position(x: (left - 4) / 2, y: y(tick))
                }
                if let second, second.count > 1 {
                    Path { path in
                        path.addLines(second.enumerated().map { CGPoint(x: x($0.offset), y: y($0.element)) })
                    }
                    .stroke(Color.white.opacity(0.6), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 5]))
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
                    if let labels, labels.indices.contains(index) {
                        Text(labels[index])
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .position(x: dot.x, y: dot.y - 17)
                    }
                }
                ForEach(labelled, id: \.self) { index in
                    Text(dates[index], format: .dateTime.day().month(.abbreviated))
                        .font(PhoneFont.foot)
                        .foregroundStyle(Theme.text3)
                        .fixedSize()
                        .position(x: x(index), y: geo.size.height - 11)
                }
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
    }

    /// Every date while there are five or fewer; from the newest back, every second or third one when there are
    /// more.
    private var labelled: [Int] {
        let count = min(dates.count, main.count)
        let stride = max(1, Int((Double(count) / 5).rounded(.up)))
        return (0..<count).filter { (count - 1 - $0) % stride == 0 }
    }
}

/// Grid lines and the scale for a series: a few round values, one step of room below and a little above.
struct ChartAxis {
    let ticks: [Double]
    let domain: ClosedRange<Double>

    /// The smallest round step that covers the series with at most `maxTicks` lines.
    init(values: [Double], maxTicks: Int = 3) {
        let low = values.min() ?? 0, high = values.max() ?? 1
        var ticks: [Double] = [], step = 100.0
        // A flat series (one session, or the same number every time) still gets lines a few per cent apart.
        let minStep = high - low < 1e-9 ? max(high * 0.05, 0.1) : 0
        for candidate in [0.1, 0.25, 0.5, 1, 2, 2.5, 4, 5, 10, 20, 25, 50, 100] as [Double] where candidate >= minStep {
            let first = (low / candidate).rounded(.down) * candidate
            var last = (high / candidate).rounded(.up) * candidate
            if last - high < candidate * 0.01 { last += candidate }
            let count = Int(((last - first) / candidate).rounded()) + 1
            ticks = (0..<count).map { first + Double($0) * candidate }
            step = candidate
            if count <= maxTicks { break }
        }
        self.ticks = ticks
        domain = max(0, ticks[0] - step)...(ticks[ticks.count - 1] + step * 0.2)
    }
}
