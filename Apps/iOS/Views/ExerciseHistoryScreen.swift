import SwiftUI
import Charts
import RepCoachCore

/// One exercise over time: top set and estimated 1RM, then every session with every set.
struct ExerciseHistoryScreen: View {
    let exercise: HistoryModel.Exercise

    var body: some View {
        let item = exercise.item
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 10) {
                    if item.kind == .weighted {
                        StatTile(label: "Top set", value: Format.weight(exercise.points.map(\.value).max() ?? 0),
                                 unit: "kg", tint: item.tint)
                        StatTile(label: "Best e1RM", value: Format.weight(exercise.points.compactMap(\.e1rm).max() ?? 0),
                                 unit: "kg", tint: Theme.ice)
                    } else {
                        StatTile(label: item.kind == .timed ? "Longest" : "Best set",
                                 value: "\(Int(exercise.points.map(\.value).max() ?? 0))",
                                 unit: item.kind == .timed ? "s" : "reps", tint: item.tint)
                    }
                    StatTile(label: "Sessions", value: "\(exercise.entries.count)")
                }

                if exercise.points.count > 1 {
                    ProgressChart(exercise: exercise)
                }

                Text("Sessions").eyebrow(Theme.tertiary, size: 12).padding(.leading, 6)
                ForEach(exercise.entries, id: \.sessionId) { entry in
                    SessionCard(entry: entry, item: item)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(Theme.canvas)
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ProgressChart: View {
    let exercise: HistoryModel.Exercise

    var body: some View {
        let item = exercise.item
        let points = exercise.points
        let values = points.map(\.value) + points.compactMap(\.e1rm)
        let low = (values.min() ?? 0) * 0.9
        let high = (values.max() ?? 1) * 1.05
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Legend(color: item.tint, text: item.kind == .weighted ? "Top set" : "Best set")
                if item.kind == .weighted {
                    Legend(color: Theme.ice, text: "Est. 1RM", dashed: true)
                }
            }
            Chart {
                ForEach(points) { point in
                    AreaMark(x: .value("Date", point.date), yStart: .value("Base", low),
                             yEnd: .value("Top set", point.value))
                        .interpolationMethod(.monotone)
                        .foregroundStyle(LinearGradient(colors: [item.tint.opacity(0.32), item.tint.opacity(0)],
                                                        startPoint: .top, endPoint: .bottom))
                    LineMark(x: .value("Date", point.date), y: .value("Top set", point.value),
                             series: .value("Series", "top"))
                        .interpolationMethod(.monotone)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                        .foregroundStyle(item.tint)
                    PointMark(x: .value("Date", point.date), y: .value("Top set", point.value))
                        .symbolSize(point.isDeload ? 20 : 36)
                        .foregroundStyle(point.isDeload ? Theme.ember : item.tint)
                    if let e1rm = point.e1rm {
                        LineMark(x: .value("Date", point.date), y: .value("Est. 1RM", e1rm),
                                 series: .value("Series", "e1rm"))
                            .interpolationMethod(.monotone)
                            .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 5]))
                            .foregroundStyle(Theme.ice)
                    }
                }
            }
            .chartYScale(domain: low...high)
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear, count: 2)) { _ in
                    AxisGridLine().foregroundStyle(Theme.hairline)
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated)).foregroundStyle(Theme.tertiary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine().foregroundStyle(Theme.hairline)
                    AxisValueLabel().foregroundStyle(Theme.tertiary)
                }
            }
            .frame(height: 220)
        }
        .padding(18)
        .card(Theme.card, radius: 24)
    }
}

private struct Legend: View {
    let color: Color
    let text: String
    var dashed = false

    var body: some View {
        HStack(spacing: 6) {
            Capsule()
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: dashed ? [3, 3] : []))
                .frame(width: 16, height: 3)
            Text(text).font(.rounded(.footnote, .semibold)).foregroundStyle(Theme.secondary)
        }
    }
}

private struct SessionCard: View {
    let entry: HistoryEntry
    let item: PlanItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(entry.date, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated))
                    .font(.rounded(.headline, .bold))
                if entry.isDeload { Chip(text: "Deload", tint: Theme.ember) }
                Spacer()
                Text("\(entry.sets.count) sets").font(.rounded(.footnote, .medium)).foregroundStyle(Theme.tertiary)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(Array(entry.sets.enumerated()), id: \.offset) { _, set in
                    Text(label(for: set))
                        .font(.rounded(.subheadline, .semibold))
                        .monospacedDigit()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(Theme.cardRaised))
                }
            }
        }
        .padding(16)
        .card(Theme.card, radius: 20)
    }

    private func label(for set: LoggedSet) -> String {
        let count = item.kind == .timed ? "\(set.reps)s" : "\(set.reps)"
        return set.weight > 0 ? "\(Format.weight(set.weight)) × \(count)" : count
    }
}
