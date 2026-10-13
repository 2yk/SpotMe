import SwiftUI
import SwiftData
import Charts
import RepCoachCore

/// Where a push in History leads.
enum HistoryRoute: Hashable {
    case session(UUID)
    case exercise(String)
    case body
    case point(BodyPoint)
}

/// The weeks, the body and every workout, newest first (boards 8.1, 8.3).
struct HistoryScreen: View {
    @Environment(TodayModel.self) private var today
    @Environment(\.modelContext) private var context
    @Environment(PhoneSync.self) private var sync
    @Query(sort: \BodyMeasurement.date, order: .reverse) private var measurements: [BodyMeasurement]
    @State private var model = HistoryModel()
    @State private var path: [HistoryRoute] = []
    @State private var export = SetsExport(csv: "", date: .now, sessions: 0)
    @State private var showsAllSessions = false

    /// Rows shown before "Show older".
    private static let firstRows = 30

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if model.sessions.isEmpty {
                        BodyCard(measurements: measurements) { path.append(.body) }
                        EmptyHistory()
                    } else {
                        WeeklySetsCard(weeks: model.weeks, sessions: model.sessionCount)
                        BodyCard(measurements: measurements) { path.append(.body) }
                        sessionList
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .background(Theme.canvas.ignoresSafeArea())
            .voltWash()
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ExportSetsLink(export: export) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Export all sets as CSV")
                }
            }
            .navigationDestination(for: HistoryRoute.self) { route in
                switch route {
                case .session(let id):
                    if let row = model.sessions.first(where: { $0.id == id }) {
                        SessionScreen(row: row, onExercise: { path.append(.exercise($0)) })
                    }
                case .exercise(let id):
                    if let exercise = exercise(id) {
                        ExerciseHistoryScreen(exercise: exercise)
                    }
                case .body:
                    BodyLogScreen()
                case .point(let point):
                    BodyPointScreen(point: point)
                }
            }
            .task {
                load()
                #if DEBUG
                PhoneScript.history(path: $path, model: model, today: today)
                #endif
            }
            .refreshable { load() }
            .onChange(of: sync.sessionsChanged) { load() }
            .onChange(of: today.editedPlan) { load() }
        }
    }

    private var sessionList: some View {
        let rows = showsAllSessions ? model.sessions : Array(model.sessions.prefix(Self.firstRows))
        return VStack(alignment: .leading, spacing: 8) {
            Text("Sessions").depthEyebrow().padding(.leading, 6)
            VStack(spacing: 0) {
                ForEach(rows) { row in
                    Button { path.append(.session(row.id)) } label: { SessionRowView(row: row) }
                        .buttonStyle(RowPressStyle())
                    if row.id != rows.last?.id { DepthDivider(inset: 16) }
                }
                if rows.count < model.sessions.count {
                    DepthDivider(inset: 16)
                    Button("Show older") { showsAllSessions = true }
                        .font(PhoneFont.headline)
                        .foregroundStyle(Theme.volt)
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
            }
            .depthRows()
            if let first = model.firstSessionDate {
                Text("\(model.sessionCount == 1 ? "1 session" : "\(model.sessionCount) sessions") since \(first.formatted(.dateTime.day().month(.abbreviated)))")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.text3)
                    .padding(.horizontal, 6)
            }
        }
        .padding(.top, 4)
    }

    private func exercise(_ id: String) -> HistoryModel.Exercise? {
        if let found = model.exercises.first(where: { $0.id == id }) { return found }
        let item = today.library.first { $0.exerciseId == id }
            ?? ExerciseDatabase.shared?.exercise(id: id).map(PlanItem.init(database:))
        return item.map { HistoryModel.exercise(for: $0, dayTitle: HistoryModel.notInPlan, context: context) }
    }

    private func load() {
        model.load(plan: today.editedPlan, library: today.library, context: context)
        export = SetsExport.current(context: context, today: today)
    }
}

// MARK: Cards

private struct WeeklySetsCard: View {
    let weeks: [HistoryModel.Week]
    let sessions: Int

    var body: some View {
        // Weeks before the first session carry nothing.
        let shown = Array(weeks.drop(while: { $0.sets == 0 }))
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sets per week").depthEyebrow(Theme.volt)
                    Text("\(weeks.last?.sets ?? 0) this week").font(PhoneFont.title2)
                }
                Spacer()
                Text(sessions == 1 ? "1 session" : "\(sessions) sessions")
                    .font(PhoneFont.foot)
                    .foregroundStyle(Theme.text2)
            }
            Chart(shown) { week in
                BarMark(x: .value("Week", Self.label(week)), y: .value("Sets", week.sets), width: .ratio(0.62))
                    .foregroundStyle(week.id == weeks.last?.id ? Theme.volt : Color(hex: 0x3A3A3C))
                    .cornerRadius(6)
            }
            .chartXAxis {
                // With many weeks every second label is left out, counting back from the newest.
                AxisMarks { value in
                    AxisValueLabel {
                        if let label = value.as(String.self), labelled(shown).contains(label) {
                            Text(label).font(PhoneFont.foot).foregroundStyle(Theme.text3).fixedSize()
                        }
                    }
                }
            }
            .chartYAxis(.hidden)
            .environment(\.calendar, HistoryModel.calendar)
            .frame(height: 120)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .depthCard()
    }

    private static func label(_ week: HistoryModel.Week) -> String {
        week.start.formatted(.dateTime.day().month(.abbreviated))
    }

    private func labelled(_ shown: [HistoryModel.Week]) -> [String] {
        guard shown.count > 5 else { return shown.map(Self.label) }
        return shown.enumerated().filter { (shown.count - 1 - $0.offset) % 2 == 0 }.map { Self.label($0.element) }
    }
}

/// The body in short: weight, arm and waist with how they moved, and a way in to the whole log.
private struct BodyCard: View {
    let measurements: [BodyMeasurement]
    let open: () -> Void

    var body: some View {
        let entries = measurements.map(\.entry)
        let change = BodyLog.change(entries)
        Button(action: open) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Body").depthEyebrow(Theme.volt)
                    Spacer()
                    if BodyLog.isDue(entries) {
                        Chip(text: entries.isEmpty ? "START" : "DUE", tint: Theme.volt)
                    }
                }
                if let latest = entries.max(by: { $0.date < $1.date }) {
                    HStack(spacing: 8) {
                        ForEach([BodyPoint.weight, .arm, .waist]) { point in
                            BodyTile(point: point, value: latest.values[point], change: change?.deltas[point])
                        }
                    }
                    Text("Measured \(latest.date.formatted(.dateTime.day().month(.abbreviated)))")
                        .font(PhoneFont.foot)
                        .foregroundStyle(Theme.text3)
                } else {
                    Text("Measure yourself every two weeks: weight, arms, waist and the rest. SpotMe warns you if your waist grows while your arms don't.")
                        .font(PhoneFont.sub)
                        .foregroundStyle(Theme.text2)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .depthCard()
        }
        .buttonStyle(.plain)
    }
}

/// One body point's latest value and its change, in a glass tile.
private struct BodyTile: View {
    let point: BodyPoint
    let value: Double?
    let change: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(point == .arm ? "Arm" : point.title).depthEyebrow()
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value.map { Format.weight($0) + (point.isWeight ? "" : "″") } ?? "—")
                    .font(PhoneFont.number)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if point.isWeight, value != nil {
                    Text("kg").font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(Theme.text2)
                }
            }
            if let change {
                BodyChangeText(point: point, change: change)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 94, alignment: .topLeading)
        .glassTile()
    }
}

/// "+0.25″" in mint when it moved the way the phase wants, ember when not, grey when it didn't move.
struct BodyChangeText: View {
    let point: BodyPoint
    let change: Double

    var body: some View {
        let text = point.formatChange(change)
        let moved = text != "±0″" && text != "±0"
        let good = point.risingIsBad ? change < 0 : change > 0
        Text(text)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(!moved ? Theme.text3 : good ? Theme.mint : Theme.ember)
    }
}

// MARK: Rows

private struct SessionRowView: View {
    let row: HistoryModel.SessionRow

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text(row.name).font(PhoneFont.headline).foregroundStyle(.white)
                Text(row.detail)
                    .font(PhoneFont.sub)
                    .foregroundStyle(Theme.text2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if row.isFinished {
                Image(systemName: "checkmark")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.mint)
                    .frame(width: 20)
            } else {
                Text("\(row.done) of \(row.total)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.text2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(minHeight: 64)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
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
            Text("No sessions yet").font(PhoneFont.title2)
            Text("Log a workout on your watch. Finished sessions show up here once they sync.")
                .font(PhoneFont.body)
                .foregroundStyle(Theme.text2)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}
