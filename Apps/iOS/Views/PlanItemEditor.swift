import SwiftUI
import SwiftData
import RepCoachCore

/// One exercise (board 9.3): its name and prescription, stored as overrides in `ExerciseSettings` (plan.json itself
/// is never changed), and taking it off the day. A new name shows everywhere the exercise does; history is kept.
struct PlanItemEditor: View {
    let exerciseId: String
    /// The plan's own day it was opened from.
    let day: PlanDay
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(TodayModel.self) private var today
    @Environment(PhoneSync.self) private var sync
    @Query private var allSettings: [ExerciseSettings]
    @State private var name = ""
    @State private var confirmingRemove = false

    private static let increments: [Double] = [0.5, 1, 1.25, 2, 2.5, 5, 10]

    /// As the plan (or the user, for their own exercise) defined it, before overrides.
    private var item: PlanItem {
        today.baseItem(exerciseId) ?? PlanItem(name: "Exercise", exerciseId: exerciseId, group: "", kind: .checklist)
    }
    private var settings: ExerciseSettings? { allSettings.first { $0.exerciseId == exerciseId } }
    private var overrides: ExerciseOverrides { settings?.overrides ?? ExerciseOverrides() }
    private var effective: PlanItem { item.applying(overrides) }
    private var hasReps: Bool { item.kind == .weighted || item.kind == .reps }
    private var isOnDay: Bool { today.planEdits.itemIds(for: day).contains(exerciseId) }
    /// Where the day stands now: the weekday its workout was rearranged to.
    private var dayTitle: String { today.plan.days.first { $0.key == day.key }?.title ?? day.title }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                SpotFormGroup(title: "Name", footnotes: overrides.name == nil ? [] : ["In the plan: \(item.name)"]) {
                    SpotTextRow(prompt: item.name, text: $name, onSubmit: saveName)
                }
                if let steps = item.steps { stepsGroup(steps) }
                if item.kind != .checklist {
                    prescriptionGroup
                    if item.kind == .weighted { weightGroup }
                }
                if !overrides.isEmpty {
                    SpotFormGroup(footnotes: ["History is kept. The watch picks up changes before its next session."]) {
                        SpotActionRow(title: "Reset to plan", color: Theme.pulse) {
                            update { $0 = ExerciseOverrides() }
                            name = item.name
                        }
                    }
                }
                if isOnDay {
                    SpotFormGroup(footnotes: ["Its history is kept, and you can add it back with Add exercise."]) {
                        SpotActionRow(title: "Remove from \(dayTitle)", color: Theme.pulse) { confirmingRemove = true }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.canvas.ignoresSafeArea())
        .navigationTitle(effective.name)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Remove \(effective.name) from \(dayTitle)?", isPresented: $confirmingRemove,
                            titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                today.editPlan { $0.remove(exerciseId, from: day) }
                sync.sendContext()
                dismiss()
            }
        }
        .onAppear { name = effective.name }
        .onDisappear {
            saveName()
            today.refresh()
        }
    }

    // MARK: Parts

    /// "CHEST", the name and the exercise's note.
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.group).depthEyebrow()
            Text(effective.name).font(PhoneFont.title2)
            if let note = item.note {
                Text(note)
                    .font(PhoneFont.sub)
                    .foregroundStyle(Theme.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func stepsGroup(_ steps: [String]) -> some View {
        SpotFormGroup(title: "Steps") {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.volt)
                        .frame(width: 20, alignment: .leading)
                    Text(step).font(PhoneFont.body)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(minHeight: 52)
            }
        }
    }

    private var prescriptionGroup: some View {
        SpotFormGroup(title: "Prescription") {
            SpotStepperRow(title: "Sets", value: number(\.sets, plan: item.sets ?? 1), range: 1...10, step: 1,
                           text: { "\($0)" }, plan: item.sets.map { "\($0)" },
                           decrementLabel: "Fewer sets", incrementLabel: "More sets")
            if hasReps {
                SpotStepperRow(title: "Reps, low", value: number(\.repMin, plan: item.repMin ?? 8),
                               range: 1...max(1, effective.repMax ?? 50), step: 1, text: { "\($0)" },
                               plan: item.repMin.map { "\($0)" }, decrementLabel: "Lower", incrementLabel: "Higher")
                SpotStepperRow(title: "Reps, high", value: number(\.repMax, plan: item.repMax ?? 12),
                               range: max(1, effective.repMin ?? 1)...50, step: 1, text: { "\($0)" },
                               plan: item.repMax.map { "\($0)" }, decrementLabel: "Lower", incrementLabel: "Higher")
            }
            SpotStepperRow(title: "Rest", value: number(\.restSec, plan: item.restSec ?? 60), range: 15...600,
                           step: 15, text: { Format.clock($0) }, plan: item.restSec.map { Format.clock($0) },
                           decrementLabel: "Shorter", incrementLabel: "Longer")
        }
    }

    private var weightGroup: some View {
        SpotFormGroup(
            title: "Weight",
            footnotes: ["The increment is the smallest jump available. The start weight is only used the first time, before there's any history."]
        ) {
            SpotMenuRow(title: "Increment", selection: incrementBinding,
                        options: Self.increments.map { (value: $0, title: Format.kg($0)) },
                        highlighted: overrides.increment != nil)
            SpotStepperRow(title: "Start weight", value: startWeightBinding, range: 0...300,
                           step: effective.increment ?? 2.5, text: { Format.kg($0) },
                           decrementLabel: "Lighter", incrementLabel: "Heavier",
                           placeholder: overrides.startWeight == nil ? "Not set" : nil)
        }
    }

    // MARK: Bindings

    /// A blank name, or the plan's own, clears the override.
    private func saveName() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let wanted = trimmed.isEmpty || trimmed == item.name ? nil : trimmed
        guard wanted != overrides.name else { return }
        update { $0.name = wanted }
        if trimmed.isEmpty { name = item.name }
    }

    /// Setting the plan's own value clears the override.
    private func number(_ key: WritableKeyPath<ExerciseOverrides, Int?>, plan: Int) -> Binding<Int> {
        Binding(
            get: { overrides[keyPath: key] ?? plan },
            set: { value in update { $0[keyPath: key] = value == plan ? nil : value } }
        )
    }

    private var incrementBinding: Binding<Double> {
        Binding(
            get: { overrides.increment ?? item.increment ?? 2.5 },
            set: { value in update { $0.increment = value == item.increment ? nil : value } }
        )
    }

    private var startWeightBinding: Binding<Double> {
        Binding(
            get: { overrides.startWeight ?? 0 },
            set: { value in update { $0.startWeight = value > 0 ? value : nil } }
        )
    }

    private func update(_ change: (inout ExerciseOverrides) -> Void) {
        var next = overrides
        change(&next)
        if next.isEmpty {
            if let settings { context.delete(settings) }
        } else if let settings {
            settings.overrides = next
        } else {
            let created = ExerciseSettings(exerciseId: exerciseId)
            created.overrides = next
            context.insert(created)
        }
        try? context.save()
        today.refresh()
        sync.sendContext()
    }
}
