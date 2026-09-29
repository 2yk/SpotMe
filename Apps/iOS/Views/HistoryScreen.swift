import SwiftUI
import SwiftData
import Charts
import RepCoachCore

/// Every exercise with logged sets, grouped by plan day, newest numbers first.
struct HistoryScreen: View {
    @Environment(TodayModel.self) private var today
    @Environment(\.modelContext) private var context
    @Environment(PhoneSync.self) private var sync
    @State private var model = HistoryModel()
    @State private var path: [String] = []
    @State private var export = SetsExport(csv: "", date: .now, sessions: 0)
    @State private var showsBody = false

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if model.exercises.isEmpty {
                        bodyCard
                        EmptyHistory()
                    } else {
                        WeeklySetsCard(weeks: model.weeks, sessions: model.sessionCount)
                        bodyCard
                        ForEach(days, id: \.self) { day in
                            let exercises = model.exercises.filter { $0.dayTitle == day }
                            CardSection(title: day) {
                                ForEach(exercises) { exercise in
                                    NavigationLink(value: exercise.id) { HistoryRow(exercise: exercise) }
                                        .buttonStyle(.plain)
                                    if exercise.id != exercises.last?.id { RowDivider() }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .background(Theme.canvas)
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ExportSetsLink(export: export) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Export all sets as CSV")
                }
            }
            .navigationDestination(isPresented: $showsBody) { BodyLogScreen() }
            .navigationDestination(for: String.self) { id in
                if let exercise = model.exercises.first(where: { $0.id == id }) {
                    ExerciseHistoryScreen(exercise: exercise)
                }
            }
            .task {
                load()
                #if DEBUG
                if ["body", "body-warning", "body-add"].contains(LaunchOptions.screen) { showsBody = true }
                if LaunchOptions.screen == "exercise",
                   let first = model.exercises.first(where: { $0.item.kind == .weighted }) {
                    path = [first.id]
                }
                #endif
            }
            .refreshable { load() }
            .onChange(of: sync.sessionsChanged) { load() }
            .onChange(of: today.editedPlan) { load() }
        }
    }

    private var bodyCard: some View {
        Button { showsBody = true } label: { BodyLogCard() }
            .buttonStyle(.plain)
    }

    private func load() {
        model.load(plan: today.editedPlan, library: today.library, context: context)
        export = SetsExport.current(context: context, today: today)
    }

    private var days: [String] {
        var seen = Set<String>()
        return model.exercises.map(\.dayTitle).filter { seen.insert($0).inserted }
    }
}

private struct WeeklySetsCard: View {
    let weeks: [HistoryModel.Week]
    let sessions: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sets per week").eyebrow(Theme.volt, size: 12)
                    Text("\(weeks.last?.sets ?? 0) this week").font(.rounded(.title2, .bold))
                }
                Spacer()
                Text("\(sessions) sessions")
                    .font(.rounded(.subheadline, .medium))
                    .foregroundStyle(Theme.secondary)
            }
            Chart(weeks) { week in
                BarMark(x: .value("Week", week.start, unit: .weekOfYear), y: .value("Sets", week.sets), width: .ratio(0.62))
                    .foregroundStyle(week.id == weeks.last?.id ? Theme.volt : Theme.volt.opacity(0.35))
                    .cornerRadius(6)
            }
            .chartXAxis {
                // A centred label spans to the next value, so the last week needs one after it.
                AxisMarks(values: weeks.map(\.start) + nextWeek) { _ in
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated), centered: true)
                        .foregroundStyle(Theme.tertiary)
                }
            }
            .chartYAxis(.hidden)
            .environment(\.calendar, HistoryModel.calendar)
            .frame(height: 120)
        }
        .padding(18)
        .card(Theme.card, radius: 24)
    }

    private var nextWeek: [Date] {
        weeks.last.flatMap { HistoryModel.calendar.date(byAdding: .weekOfYear, value: 1, to: $0.start) }.map { [$0] } ?? []
    }
}

private struct HistoryRow: View {
    let exercise: HistoryModel.Exercise

    var body: some View {
        let item = exercise.item
        HStack(spacing: 14) {
            ItemBadge(item: item, size: 36)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name).font(.rounded(.body, .semibold))
                if let latest = exercise.entries.first {
                    Text(Format.sets(latest.sets, timed: item.kind == .timed))
                        .font(.rounded(.subheadline))
                        .foregroundStyle(Theme.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            if exercise.points.count > 1 {
                Sparkline(values: exercise.points.map(\.value), tint: item.tint)
                    .frame(width: 56, height: 26)
            }
            if let change = exercise.change, change > 0 {
                Text("+\(item.kind == .weighted ? Format.weight(change) : "\(Int(change))")")
                    .font(.rounded(.footnote, .bold))
                    .foregroundStyle(item.tint)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

private struct EmptyHistory: View {
    var body: some View {
        VStack(spacing: 14) {
            Image("Mark")
                .resizable()
                .scaledToFit()
                .frame(width: 76, height: 76)
                .accessibilityHidden(true)
            Text("No sessions yet").font(.rounded(.title2, .bold))
            Text("Log a workout on your watch. Finished sessions show up here once they sync.")
                .font(.rounded(.body))
                .foregroundStyle(Theme.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}
