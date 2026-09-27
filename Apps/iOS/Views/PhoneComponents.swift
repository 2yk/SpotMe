import SwiftUI
import Charts
import RepCoachCore

/// Mon … Sun. The selected day is filled; today has a dot.
struct DayStrip: View {
    let days: [PlanDay]
    let selected: String
    let onSelect: (String) -> Void

    var body: some View {
        let todayWeekday = Calendar.current.component(.weekday, from: .now)
        HStack(spacing: 6) {
            ForEach(days) { day in
                let isSelected = day.key == selected
                let isToday = day.weekday == todayWeekday
                Button { onSelect(day.key) } label: {
                    VStack(spacing: 6) {
                        Text(day.title.prefix(3))
                            .font(.rounded(.footnote, .bold))
                        Circle()
                            .fill(isToday ? (isSelected ? Color.black : Theme.volt) : .clear)
                            .frame(width: 5, height: 5)
                    }
                    .foregroundStyle(isSelected ? .black : isToday ? Theme.volt : Theme.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 11)
                    .padding(.bottom, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(isSelected ? Theme.volt : Theme.card)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isToday ? "\(day.title), today" : day.title)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}

/// A titled group of rows on one dark card.
struct CardSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .eyebrow(Theme.tertiary, size: 12)
                .padding(.leading, 6)
            VStack(spacing: 0) { content }
                .card(Theme.card, radius: 22)
        }
    }
}

/// Hairline between rows, starting after the badge.
struct RowDivider: View {
    var inset: CGFloat = 64

    var body: some View {
        Rectangle()
            .fill(Theme.hairline)
            .frame(height: 1)
            .padding(.leading, inset)
    }
}

/// A labelled number: "TOP SET 25 kg".
struct StatTile: View {
    let label: String
    let value: String
    var unit: String?
    var tint: Color = .white

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).eyebrow(Theme.tertiary, size: 10)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.number(24))
                    .foregroundStyle(tint)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if let unit {
                    Text(unit).font(.rounded(.footnote, .bold)).foregroundStyle(Theme.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .card(Theme.card, radius: 18)
    }
}

/// A tiny trend line for list rows.
struct Sparkline: View {
    let values: [Double]
    let tint: Color

    var body: some View {
        Chart(Array(values.enumerated()), id: \.offset) { index, value in
            LineMark(x: .value("Session", index), y: .value("Value", value))
                .interpolationMethod(.monotone)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                .foregroundStyle(tint)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: .automatic(includesZero: false))
        .accessibilityHidden(true)
    }
}

extension PlanDay {
    struct Section: Identifiable {
        let id: Int
        let title: String
        var items: [PlanItem]
    }

    /// Consecutive items sharing a `group`, in plan order.
    var sections: [Section] {
        var result: [Section] = []
        for item in items {
            if let last = result.indices.last, result[last].title == item.group {
                result[last].items.append(item)
            } else {
                result.append(Section(id: result.count, title: item.group, items: [item]))
            }
        }
        return result
    }
}
