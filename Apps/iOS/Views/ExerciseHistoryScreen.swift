import SwiftUI
import RepCoachCore

/// One exercise over time (board 8.2): top set and estimated 1RM, then every session with every set.
struct ExerciseHistoryScreen: View {
    let exercise: HistoryModel.Exercise

    var body: some View {
        let item = exercise.item
        let points = exercise.points
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    if item.kind == .weighted {
                        DepthTile(label: "Top set", value: Format.weight(points.map(\.value).max() ?? 0), unit: "kg",
                                  tint: Theme.volt)
                        DepthTile(label: "Best e1RM", value: Format.weight(points.compactMap(\.e1rm).max() ?? 0), unit: "kg")
                    } else {
                        DepthTile(label: item.kind == .timed ? "Longest" : "Best set",
                                  value: "\(Int(points.map(\.value).max() ?? 0))",
                                  unit: item.kind == .timed ? "s" : "reps", tint: Theme.volt)
                    }
                    DepthTile(label: "Sessions", value: "\(exercise.entries.count)")
                }

                if points.count > 1 {
                    chart(item, points)
                }

                Text("Sessions").depthEyebrow().padding(.leading, 6).padding(.top, 8)
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

    private func chart(_ item: PlanItem, _ points: [HistoryModel.Point]) -> some View {
        let weighted = item.kind == .weighted
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Legend(text: weighted ? "Top set" : "Best set")
                if weighted { Legend(text: "Est. 1RM", dashed: true) }
            }
            SeriesChart(dates: points.map(\.date), main: points.map(\.value),
                        second: weighted ? points.compactMap(\.e1rm) : nil, height: 220, top: 14, bottom: 32)
                .accessibilityLabel("\(weighted ? "Top set" : "Best set") over time")
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .depthCard()
    }
}

private struct Legend: View {
    let text: String
    var dashed = false

    var body: some View {
        HStack(spacing: 6) {
            Path { path in
                path.move(to: CGPoint(x: 1.5, y: 1.5))
                path.addLine(to: CGPoint(x: 14.5, y: 1.5))
            }
            .stroke(dashed ? Color.white.opacity(0.6) : Theme.volt,
                    style: StrokeStyle(lineWidth: dashed ? 2 : 3, lineCap: .round, dash: dashed ? [3, 3] : []))
            .frame(width: 16, height: 3)
            Text(text)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.text2)
        }
    }
}

private struct SessionCard: View {
    let entry: HistoryEntry
    let item: PlanItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(entry.date.weekdayDayMonth)
                    .font(PhoneFont.headline)
                if entry.isDeload { Chip(text: "DELOAD", tint: Theme.ember) }
                Spacer()
                Text("\(entry.sets.count) sets").font(PhoneFont.foot).foregroundStyle(Theme.text3)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), alignment: .leading,
                      spacing: 8) {
                ForEach(Array(entry.sets.enumerated()), id: \.offset) { _, set in
                    SetCapsule(text: label(for: set))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .depthCard()
    }

    private func label(for set: LoggedSet) -> String {
        let count = item.kind == .timed ? "\(set.reps)s" : "\(set.reps)"
        return set.weight > 0 ? "\(Format.weight(set.weight)) × \(count)" : count
    }
}
