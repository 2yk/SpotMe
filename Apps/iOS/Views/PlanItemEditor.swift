import SwiftUI
import SwiftData
import RepCoachCore

/// One exercise: its name and prescription, stored as overrides in `ExerciseSettings` (plan.json itself is never
/// changed), and taking it off the day. A new name shows everywhere the exercise does; history is kept.
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

    var body: some View {
        Form {
            Section {
                HStack(spacing: 14) {
                    ItemBadge(item: item, size: 48)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.group).eyebrow(item.tint, size: 11)
                        Text(effective.name).font(.rounded(.title2, .bold))
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 4, bottom: 8, trailing: 4))
                if let note = item.note {
                    Text(note)
                        .font(.rounded(.subheadline))
                        .foregroundStyle(Theme.secondary)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 8, trailing: 4))
                }
            }

            Section {
                TextField(item.name, text: $name)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .onSubmit(saveName)
            } header: {
                Text("Name")
            } footer: {
                if overrides.name != nil {
                    Text("In the plan: \(item.name)")
                }
            }
            .listRowBackground(Theme.card)

            if let steps = item.steps {
                Section("Steps") {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        Label {
                            Text(step)
                        } icon: {
                            Text("\(index + 1)").font(.number(13, weight: .heavy)).foregroundStyle(Theme.ice)
                        }
                    }
                }
                .listRowBackground(Theme.card)
            }

            if item.kind != .checklist {
                Section("Prescription") {
                    Stepper(value: number(\.sets, plan: item.sets ?? 1), in: 1...10) {
                        ValueRow(title: "Sets", value: "\(effective.sets ?? 1)", plan: item.sets.map { "\($0)" })
                    }
                    if hasReps {
                        Stepper(value: number(\.repMin, plan: item.repMin ?? 8), in: 1...max(1, effective.repMax ?? 50)) {
                            ValueRow(title: "Reps, low", value: "\(effective.repMin ?? 0)", plan: item.repMin.map { "\($0)" })
                        }
                        Stepper(value: number(\.repMax, plan: item.repMax ?? 12), in: max(1, effective.repMin ?? 1)...50) {
                            ValueRow(title: "Reps, high", value: "\(effective.repMax ?? 0)", plan: item.repMax.map { "\($0)" })
                        }
                    }
                    Stepper(value: number(\.restSec, plan: item.restSec ?? 60), in: 15...600, step: 15) {
                        ValueRow(title: "Rest", value: Format.clock(effective.restSec ?? 60),
                                 plan: item.restSec.map(Format.clock))
                    }
                }
                .listRowBackground(Theme.card)

                if item.kind == .weighted {
                    Section {
                        Picker("Increment", selection: incrementBinding) {
                            ForEach(Self.increments, id: \.self) { Text(Format.kg($0)).tag($0) }
                        }
                        Stepper(value: startWeightBinding, in: 0...300, step: effective.increment ?? 2.5) {
                            ValueRow(title: "Start weight", value: overrides.startWeight.map(Format.kg) ?? "Not set",
                                     plan: nil)
                        }
                    } header: {
                        Text("Weight")
                    } footer: {
                        Text("The increment is the smallest jump available. The start weight is only used the first time, before there's any history.")
                    }
                    .listRowBackground(Theme.card)
                }
            }

            if !overrides.isEmpty {
                Section {
                    Button("Reset to plan", role: .destructive) {
                        update { $0 = ExerciseOverrides() }
                        name = item.name
                    }
                } footer: {
                    Text("History is kept. The watch picks up changes before its next session.")
                }
                .listRowBackground(Theme.card)
            }

            if isOnDay {
                Section {
                    Button("Remove from \(day.title)", role: .destructive) { confirmingRemove = true }
                } footer: {
                    Text("Its history is kept, and you can add it back with Add exercise.")
                }
                .listRowBackground(Theme.card)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.canvas)
        .navigationTitle(effective.name)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Remove \(effective.name) from \(day.title)?", isPresented: $confirmingRemove,
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

/// "Sets  5  (plan 4)": the value in the accent colour when it differs from the plan.
private struct ValueRow: View {
    let title: String
    let value: String
    let plan: String?

    var body: some View {
        let edited = plan != nil && plan != value
        HStack {
            Text(title)
            Spacer()
            if edited, let plan {
                Text("plan \(plan)").font(.rounded(.footnote)).foregroundStyle(Theme.tertiary)
            }
            Text(value)
                .font(.rounded(.body, .semibold))
                .monospacedDigit()
                .foregroundStyle(edited ? Theme.volt : Theme.secondary)
        }
    }
}
