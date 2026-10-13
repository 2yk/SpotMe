import SwiftUI
import SwiftData
import RepCoachCore

/// One workout (board 8.7): its time, sets, heart rate and effort, every exercise's sets in plan order, and what
/// was not done. Tick-off items are left out.
struct SessionScreen: View {
    @Environment(TodayModel.self) private var today
    let row: HistoryModel.SessionRow
    let onExercise: (String) -> Void

    /// One exercise of the session: what was done, as the plan lists it.
    private struct Done: Identifiable {
        let id: String
        let name: String
        let kind: ItemKind
        let sets: [SetLog]
    }

    var body: some View {
        let (done, missed) = exercises
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("\(row.date.weekdayDayMonthYear) · \(row.done) of \(row.total) done")
                    .font(PhoneFont.sub)
                    .foregroundStyle(Theme.text2)
                    .padding(.horizontal, 6)
                tiles
                ForEach(done) { exercise in
                    Button { onExercise(exercise.id) } label: { card(exercise) }
                        .buttonStyle(.plain)
                }
                if !missed.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Not done").depthEyebrow().padding(.leading, 6)
                        VStack(spacing: 0) {
                            ForEach(missed, id: \.self) { name in
                                Text(name)
                                    .font(PhoneFont.headline)
                                    .foregroundStyle(Theme.text2)
                                    .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
                                    .padding(.horizontal, 16)
                                if name != missed.last { DepthDivider(inset: 16) }
                            }
                        }
                        .depthRows()
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(Theme.canvas)
        .navigationTitle(row.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Parts

    private var tiles: some View {
        let session = row.session
        let seconds = session.activeSeconds ?? session.endedAt.map { $0.timeIntervalSince(session.date) }
        let sets = session.countedSetCount
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())], spacing: 10) {
            SessionTile(label: "Time", value: seconds.map { Self.clock(Int($0.rounded())) } ?? "—")
            SessionTile(label: "Sets", value: "\(sets)")
            SessionTile(label: "Avg BPM", value: session.averageHeartRate.map { "\(Int($0.rounded()))" } ?? "—",
                        tint: session.averageHeartRate == nil ? .white : Theme.red)
            if let effort = session.effort {
                let band = EffortBand(effort)
                SessionTile(label: "Effort", value: "\(effort)", note: band.word, noteColor: band.color)
            } else {
                SessionTile(label: "Effort", value: "—")
            }
        }
    }

    private func card(_ exercise: Done) -> some View {
        let top = exercise.sets.map(\.weight).max() ?? 0
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(exercise.name).font(PhoneFont.headline).foregroundStyle(.white)
                Spacer()
                if top > 0 {
                    Text(Format.kg(top)).font(PhoneFont.foot).foregroundStyle(Theme.text3)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), alignment: .leading,
                      spacing: 8) {
                ForEach(Array(exercise.sets.enumerated()), id: \.offset) { _, set in
                    SetCapsule(text: Self.label(set, kind: exercise.kind))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .depthCard()
    }

    // MARK: Data

    /// The day's exercises in plan order with what was logged, and the names of the ones with nothing logged.
    private var exercises: ([Done], [String]) {
        let session = row.session
        let day = today.editedPlan.days.first { $0.key == session.dayKey }
        var used = Set<PersistentIdentifier>()
        var done: [Done] = []
        var missed: [String] = []
        func make(_ log: ExerciseLog, kind: ItemKind, name: String) -> Done? {
            let sets = log.orderedCountedSets
            guard !sets.isEmpty else { return nil }
            return Done(id: log.exerciseId, name: name, kind: kind, sets: sets)
        }
        for item in day?.items ?? [] where item.kind != .checklist {
            let log = session.logs.first { ($0.slotExerciseId ?? $0.exerciseId) == item.exerciseId }
            if let log {
                used.insert(log.persistentModelID)
                let swapped = log.exerciseId != item.exerciseId
                let logged = swapped ? Self.item(log.exerciseId, library: today.library) : item
                if let entry = make(log, kind: logged.kind, name: logged.name) {
                    done.append(entry)
                    continue
                }
            }
            missed.append(item.name)
        }
        // Logged for something the plan no longer has on that day.
        for log in session.logs where !used.contains(log.persistentModelID) {
            let logged = Self.item(log.exerciseId, library: today.library)
            if logged.kind != .checklist, let entry = make(log, kind: logged.kind, name: logged.name) { done.append(entry) }
        }
        return (done, missed)
    }

    private static func item(_ id: String, library: [PlanItem]) -> PlanItem {
        library.first { $0.exerciseId == id }
            ?? ExerciseDatabase.shared?.exercise(id: id).map(PlanItem.init(database:))
            ?? PlanItem(name: id, exerciseId: id, group: "", kind: .reps)
    }

    /// "22.5 × 10", "12", "40s".
    static func label(_ set: SetLog, kind: ItemKind) -> String {
        let count = kind == .timed ? "\(set.seconds ?? set.reps)s" : "\(set.reps)"
        return set.weight > 0 ? "\(Format.weight(set.weight)) × \(count)" : count
    }

    /// "48:12", or "1:02:15" past an hour.
    static func clock(_ seconds: Int) -> String {
        let s = max(0, seconds)
        return s >= 3600 ? String(format: "%d:%02d:%02d", s / 3600, s % 3600 / 60, s % 60)
                         : String(format: "%d:%02d", s / 60, s % 60)
    }
}

/// A set as a capsule: "22.5 × 10".
struct SetCapsule: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, minHeight: 34)
            .background(Capsule().fill(Theme.raised))
    }
}

private struct SessionTile: View {
    let label: String
    let value: String
    var tint: Color = .white
    var note: String?
    var noteColor: Color = Theme.text2

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).depthEyebrow()
            Text(value).font(PhoneFont.number).foregroundStyle(tint).monospacedDigit()
            Text(note ?? " ")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(noteColor)
                .opacity(note == nil ? 0 : 1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassTile()
    }
}
