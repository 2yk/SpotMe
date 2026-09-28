import SwiftUI
import RepCoachCore

/// The day's plan, read-mostly: handy for checking tomorrow's session the night before.
struct TodayScreen: View {
    @Environment(TodayModel.self) private var today
    @State private var detail: PlanItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    DayStrip(days: today.plan.days, selected: today.dayKey) { key in
                        withAnimation(.snappy) { today.select(key) }
                    }
                    DayCard()
                    if today.queue.isComplete {
                        AllDoneHero(count: today.queue.totalCount)
                    }
                    ForEach(today.day.sections) { section in
                        CardSection(title: section.title) {
                            ForEach(section.items) { item in
                                Button { detail = item } label: { TodayRow(item: item) }
                                    .buttonStyle(.plain)
                                if item.id != section.items.last?.id { RowDivider() }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .background(Theme.canvas)
            .navigationTitle(today.isToday ? "Today" : today.day.title)
            .sheet(item: $detail) { item in
                ItemDetailSheet(item: item)
            }
            #if DEBUG
            .task {
                if LaunchOptions.screen == "detail" { detail = today.day.items.first { $0.kind == .weighted } }
            }
            #endif
        }
    }
}

private struct DayCard: View {
    @Environment(TodayModel.self) private var today

    var body: some View {
        let done = today.queue.doneCount
        let total = today.queue.totalCount
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 8) {
                    Text(today.day.title).eyebrow(Theme.volt, size: 12)
                    if today.isDeload { Chip(text: "Deload week", tint: Theme.ember) }
                }
                Text(today.day.focus)
                    .font(.rounded(.title2, .bold))
                    .fixedSize(horizontal: false, vertical: true)
                Label(today.day.time, systemImage: "clock")
                    .font(.rounded(.subheadline, .medium))
                    .foregroundStyle(Theme.secondary)
            }
            Spacer(minLength: 0)
            ZStack {
                ProgressRing(progress: total == 0 ? 0 : Double(done) / Double(total), tint: Theme.volt, lineWidth: 8)
                VStack(spacing: -2) {
                    Text("\(done)").font(.number(24)).monospacedDigit()
                    Text("of \(total)").eyebrow(Theme.tertiary, size: 10)
                }
            }
            .frame(width: 76, height: 76)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(done) of \(total) done")
        }
        .padding(18)
        .card(Theme.card, radius: 24)
    }
}

private struct AllDoneHero: View {
    let count: Int

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(Theme.mint)
            VStack(alignment: .leading, spacing: 2) {
                Text("All \(count) done").font(.rounded(.title3, .bold))
                Text("Great session. Recovery starts now.").font(.rounded(.subheadline)).foregroundStyle(Theme.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .glowCard(Theme.mint, radius: 28)
    }
}

private struct TodayRow: View {
    @Environment(TodayModel.self) private var today
    let item: PlanItem

    var body: some View {
        let status = today.status(of: item)
        HStack(spacing: 14) {
            ItemBadge(item: item, status: status, size: 36)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.rounded(.body, .semibold))
                    .foregroundStyle(status.isFinished ? Theme.secondary : .white)
                Text(today.detailLine(for: item))
                    .font(.rounded(.subheadline))
                    .foregroundStyle(Theme.secondary)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .opacity(status.isFinished ? 0.6 : 1)
    }
}
