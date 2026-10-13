import SwiftUI
import RepCoachCore

/// Adds an exercise to a day (boards 9.4, 9.5): a new one, or one from another day (which brings its history with
/// it). It goes after the day's last exercise, ahead of the cooldown; Edit on the Plan tab moves it.
struct AddExerciseSheet: View {
    /// The plan's own day, which edits are made against.
    let day: PlanDay
    @Environment(AppModel.self) private var app
    @Environment(TodayModel.self) private var today
    @Environment(PhoneSync.self) private var sync
    @Environment(\.dismiss) private var dismiss
    @State private var source: Source
    @State private var search = ""
    @State private var draft = Draft()
    @FocusState private var nameFocused: Bool

    enum Source: Hashable, Identifiable {
        case new, plan

        var id: Self { self }
    }

    init(day: PlanDay, source: Source = .new) {
        self.day = day
        _source = State(initialValue: source)
        #if DEBUG
        // `-draftName "Close-Grip Push-up" -draftKind reps`: a filled form for a screenshot.
        var draft = Draft()
        draft.name = UserDefaults.standard.string(forKey: "draftName") ?? ""
        if UserDefaults.standard.string(forKey: "draftKind") == "reps" { draft.kind = .reps }
        _draft = State(initialValue: draft)
        #endif
    }

    /// The weekday its workout stands on now ("Wednesday").
    private var dayTitle: String { today.plan.days.first { $0.key == day.key }?.title ?? day.title }

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    SpotSegmented(selection: $source, options: [(value: .new, title: "New exercise"),
                                                                (value: .plan, title: "From the plan")])
                    switch source {
                    case .new: newExercise
                    case .plan: fromThePlan
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 76)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            SpotSheetBar(title: "Add to \(dayTitle)", trailing: source == .new ? "Add" : nil,
                         trailingEnabled: !draft.trimmedName.isEmpty, onLeading: { dismiss() }, onTrailing: addNew)
        }
        .background(Theme.sheet)
        .sheetSurface()
        .onAppear {
            // The section of the day's last exercise.
            draft.group = today.editedPlan.days.first { $0.key == day.key }?.items
                .last { $0.kind != .checklist }?.group ?? "Extra"
            #if DEBUG
            // A screenshot shouldn't have the keyboard over the form.
            if let group = UserDefaults.standard.string(forKey: "draftGroup") { draft.group = group }
            if LaunchOptions.screen == nil, UserDefaults.standard.string(forKey: "sheet") == nil { nameFocused = true }
            #else
            nameFocused = true
            #endif
        }
    }

    // MARK: A new exercise

    @ViewBuilder
    private var newExercise: some View {
        SpotFormGroup(footnotes: [draft.kind.explanation]) {
            SpotTextRow(prompt: "Name", text: $draft.name, focus: $nameFocused)
            SpotMenuRow(title: "Logged as", selection: $draft.kind,
                        options: Draft.Kind.allCases.map { (value: $0, title: $0.title) })
            SpotTextRow(prompt: "Section", text: $draft.group)
        }

        if draft.kind != .checklist {
            SpotFormGroup(title: "Prescription") {
                SpotStepperRow(title: "Sets", value: $draft.sets, range: 1...10, step: 1, text: { "\($0)" },
                               decrementLabel: "Fewer sets", incrementLabel: "More sets")
                switch draft.kind {
                case .weighted, .reps:
                    SpotStepperRow(title: "Reps, low", value: $draft.repMin, range: 1...max(1, draft.repMax), step: 1,
                                   text: { "\($0)" }, decrementLabel: "Lower", incrementLabel: "Higher")
                    SpotStepperRow(title: "Reps, high", value: $draft.repMax, range: max(1, draft.repMin)...50, step: 1,
                                   text: { "\($0)" }, decrementLabel: "Lower", incrementLabel: "Higher")
                case .timed:
                    SpotStepperRow(title: "Seconds, low", value: $draft.secMin, range: 5...max(5, draft.secMax),
                                   step: 5, text: { "\($0)" }, decrementLabel: "Lower", incrementLabel: "Higher")
                    SpotStepperRow(title: "Seconds, high", value: $draft.secMax, range: max(5, draft.secMin)...600,
                                   step: 5, text: { "\($0)" }, decrementLabel: "Lower", incrementLabel: "Higher")
                case .checklist:
                    EmptyView()
                }
                SpotStepperRow(title: "Rest", value: $draft.rest, range: 15...600, step: 15, text: { Format.clock($0) },
                               decrementLabel: "Shorter", incrementLabel: "Longer")
                SpotSwitchRow(title: "Per side", isOn: $draft.perSide)
                if draft.kind != .weighted {
                    SpotSwitchRow(title: "Can add weight", isOn: $draft.loadable)
                }
                if draft.kind == .weighted || draft.loadable {
                    SpotMenuRow(title: "Increment", selection: $draft.increment,
                                options: [0.5, 1, 1.25, 2, 2.5, 5, 10].map { (value: $0, title: Format.kg($0)) })
                }
            }
        }
    }

    private func addNew() {
        // Never an id that has history, even one no longer defined anywhere.
        let taken = Set(today.library.map(\.exerciseId)).union((try? today.history.loggedExerciseIds()) ?? [])
        let item = draft.item(id: PlanEdits.newExerciseId(name: draft.trimmedName, taken: taken))
        today.editPlan { $0.add(item, to: day, plan: app.plan) }
        sync.sendContext()
        dismiss()
    }

    // MARK: From the plan

    @ViewBuilder
    private var fromThePlan: some View {
        let onDay = Set(today.planEdits.itemIds(for: day))
        let candidates = today.library.filter { item in
            !onDay.contains(item.exerciseId)
                && (search.isEmpty || item.name.localizedCaseInsensitiveContains(search)
                    || item.group.localizedCaseInsensitiveContains(search))
        }
        SpotFormGroup {
            SpotTextRow(prompt: "Search", text: $search, capitalization: .never)
        }
        VStack(alignment: .leading, spacing: 0) {
            LazyVStack(spacing: 0) {
                if candidates.isEmpty {
                    Text("Nothing else to add")
                        .font(PhoneFont.body)
                        .foregroundStyle(Theme.text2)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                }
                ForEach(candidates) { item in
                    Button { add(item) } label: { candidateRow(item) }
                        .buttonStyle(RowPressStyle())
                    if item.id != candidates.last?.id { DepthDivider(inset: 16) }
                }
            }
            .depthRows()
            Text("It keeps its history and its prescription, and a change to either shows on every day it's on.")
                .font(PhoneFont.foot)
                .foregroundStyle(Theme.text3)
                .padding(.horizontal, 16)
                .padding(.top, 8)
        }
    }

    private func candidateRow(_ item: PlanItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(item.name).font(PhoneFont.headline).foregroundStyle(.white)
            Text(detail(item)).font(PhoneFont.foot).foregroundStyle(Theme.text2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private func add(_ item: PlanItem) {
        let base = today.baseItem(item.exerciseId) ?? item
        today.editPlan { $0.add(base, to: day, plan: app.plan) }
        sync.sendContext()
        dismiss()
    }

    /// "Thursday · 4 × 8–12", where the exercise is now and what it asks.
    private func detail(_ item: PlanItem) -> String {
        let days = today.editedPlan.days.filter { $0.items.contains { $0.exerciseId == item.exerciseId } }.map(\.title)
        let placement = days.isEmpty ? "Not on any day" : days.joined(separator: ", ")
        let prescription = Format.prescription(item, TargetPlanner.target(for: item, history: [], deload: false))
        return [placement, prescription].filter { !$0.isEmpty }.joined(separator: " · ")
    }
}

/// The form for a new exercise.
private struct Draft {
    enum Kind: CaseIterable {
        case weighted, reps, timed, checklist

        var title: String {
            switch self {
            case .weighted: "Weight and reps"
            case .reps: "Reps"
            case .timed: "Timed hold"
            case .checklist: "Tick off"
            }
        }

        var explanation: String {
            switch self {
            case .weighted: "Weight and reps each set. SpotMe picks the weight for every set and every session."
            case .reps: "Reps each set, with optional added weight."
            case .timed: "Seconds each set, with a timer on the watch."
            case .checklist: "Tick it off when it's done, like a warmup or a stretch."
            }
        }

        var itemKind: ItemKind {
            switch self {
            case .weighted: .weighted
            case .reps: .reps
            case .timed: .timed
            case .checklist: .checklist
            }
        }
    }

    var name = ""
    var kind = Kind.weighted
    var group = ""
    var sets = 3
    var repMin = 8
    var repMax = 12
    var secMin = 30
    var secMax = 45
    var rest = 90
    var perSide = false
    var loadable = false
    var increment = 2.5

    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    func item(id: String) -> PlanItem {
        let group = group.trimmingCharacters(in: .whitespacesAndNewlines)
        let counted = kind != .checklist
        return PlanItem(
            name: trimmedName, exerciseId: id, group: group.isEmpty ? "Extra" : group, kind: kind.itemKind,
            sets: counted ? sets : nil,
            repMin: kind == .weighted || kind == .reps ? repMin : nil,
            repMax: kind == .weighted || kind == .reps ? repMax : nil,
            secMin: kind == .timed ? secMin : nil,
            secMax: kind == .timed ? secMax : nil,
            perSide: counted ? perSide : nil,
            loadable: kind == .reps || kind == .timed ? loadable : nil,
            increment: kind == .weighted || loadable ? increment : nil,
            sessionsAtTopToProgress: kind == .weighted ? 1 : nil,
            restSec: counted ? rest : nil)
    }
}
