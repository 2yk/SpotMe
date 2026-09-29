import SwiftUI
import RepCoachCore

/// Adds an exercise to a day: a new one, or one from another day (which brings its history with it). It goes
/// after the day's last exercise, ahead of the cooldown; Edit on the Plan tab moves it.
struct AddExerciseSheet: View {
    /// The plan's own day, which edits are made against.
    let day: PlanDay
    @Environment(AppModel.self) private var app
    @Environment(TodayModel.self) private var today
    @Environment(PhoneSync.self) private var sync
    @Environment(\.dismiss) private var dismiss
    @State private var source = Source.new
    @State private var search = ""
    @State private var draft = Draft()
    @FocusState private var nameFocused: Bool

    enum Source: Hashable {
        case new, plan
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Add", selection: $source) {
                        Text("New exercise").tag(Source.new)
                        Text("From the plan").tag(Source.plan)
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
                switch source {
                case .new: newExercise
                case .plan: fromThePlan
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.canvas)
            .navigationTitle("Add to \(day.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if source == .new {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add", action: addNew)
                            .fontWeight(.bold)
                            .disabled(draft.trimmedName.isEmpty)
                    }
                }
            }
            .onAppear {
                draft.group = today.editedPlan.days.first { $0.key == day.key }?.items
                    .last { $0.kind != .checklist }?.group ?? "Extra"
                nameFocused = true
            }
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: A new exercise

    @ViewBuilder
    private var newExercise: some View {
        Section {
            TextField("Name", text: $draft.name)
                .textInputAutocapitalization(.words)
                .focused($nameFocused)
            Picker("Logged as", selection: $draft.kind) {
                ForEach(Draft.Kind.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            TextField("Section", text: $draft.group)
                .textInputAutocapitalization(.words)
        } footer: {
            Text(draft.kind.explanation)
        }
        .listRowBackground(Theme.card)

        if draft.kind != .checklist {
            Section("Prescription") {
                Stepper("Sets  \(draft.sets)", value: $draft.sets, in: 1...10)
                switch draft.kind {
                case .weighted, .reps:
                    Stepper("Reps, low  \(draft.repMin)", value: $draft.repMin, in: 1...max(1, draft.repMax))
                    Stepper("Reps, high  \(draft.repMax)", value: $draft.repMax, in: max(1, draft.repMin)...50)
                case .timed:
                    Stepper("Seconds, low  \(draft.secMin)", value: $draft.secMin, in: 5...max(5, draft.secMax),
                            step: 5)
                    Stepper("Seconds, high  \(draft.secMax)", value: $draft.secMax, in: max(5, draft.secMin)...600,
                            step: 5)
                case .checklist:
                    EmptyView()
                }
                Stepper("Rest  \(Format.clock(draft.rest))", value: $draft.rest, in: 15...600, step: 15)
                Toggle("Per side", isOn: $draft.perSide)
                if draft.kind != .weighted {
                    Toggle("Can add weight", isOn: $draft.loadable)
                }
                if draft.kind == .weighted || draft.loadable {
                    Picker("Increment", selection: $draft.increment) {
                        ForEach([0.5, 1, 1.25, 2, 2.5, 5, 10], id: \.self) { Text(Format.kg($0)).tag($0) }
                    }
                }
            }
            .listRowBackground(Theme.card)
        }
    }

    private func addNew() {
        let taken = Set(today.library.map(\.exerciseId))
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
        Section {
            TextField("Search", text: $search)
                .textInputAutocapitalization(.never)
        }
        .listRowBackground(Theme.card)
        Section {
            if candidates.isEmpty {
                Text("Nothing else to add").foregroundStyle(Theme.secondary)
            }
            ForEach(candidates) { item in
                Button { add(item) } label: {
                    HStack(spacing: 12) {
                        ItemBadge(item: item, size: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name).font(.rounded(.body, .semibold)).foregroundStyle(.white)
                            Text(detail(item))
                                .font(.rounded(.footnote))
                                .foregroundStyle(Theme.secondary)
                        }
                    }
                }
            }
        } footer: {
            Text("It keeps its history and its prescription, and a change to either shows on every day it's on.")
        }
        .listRowBackground(Theme.card)
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
