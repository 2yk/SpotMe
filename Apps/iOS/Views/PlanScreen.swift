import SwiftUI
import SwiftData
import RepCoachCore

/// All seven days as the user has them. Tap an exercise to rename it or change its sets, reps, rest, increment
/// or start weight. Swipe to remove it from the day, Edit to reorder, Add exercise for a new one or one from
/// another day. plan.json itself never changes; history is always kept.
struct PlanScreen: View {
    @Environment(AppModel.self) private var app
    @Environment(TodayModel.self) private var today
    @Environment(\.modelContext) private var context
    @Environment(PhoneSync.self) private var sync
    @Query private var settings: [ExerciseSettings]
    @State private var dayKey: String?
    @State private var path: [String] = []
    @State private var editing = false
    @State private var adding = false
    @State private var confirmingReset = false

    var body: some View {
        let key = dayKey ?? today.dayKey
        let day = today.editedPlan.days.first { $0.key == key } ?? today.editedPlan.days[0]
        // The plan's own day, which edits are made against.
        let original = app.plan.days.first { $0.key == day.key } ?? app.plan.days[0]
        let edited = Set(settings.filter { !$0.overrides.isEmpty }.map(\.exerciseId))
        let planned = Set(original.items.map(\.exerciseId))
        NavigationStack(path: $path) {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 18) {
                        DayStrip(days: app.plan.days, selected: day.key) { key in
                            withAnimation(.snappy) { dayKey = key }
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text(day.focus).font(.rounded(.title3, .bold))
                            Label(day.time, systemImage: "clock")
                                .font(.rounded(.subheadline, .medium))
                                .foregroundStyle(Theme.secondary)
                        }
                        .padding(.horizontal, 6)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 6, trailing: 0))
                }

                if editing {
                    Section {
                        ForEach(day.items) { item in
                            PlanRow(item: item, edited: edited.contains(item.exerciseId),
                                    added: !planned.contains(item.exerciseId), showsGroup: true)
                        }
                        .onMove { source, destination in move(source, to: destination, in: day, original: original) }
                        .onDelete { offsets in
                            offsets.map { day.items[$0].exerciseId }.forEach { remove($0, from: original) }
                        }
                    } header: {
                        Text("Drag to reorder").eyebrow(Theme.tertiary, size: 12)
                    }
                    .listRowBackground(Theme.card)
                } else {
                    ForEach(day.sections) { section in
                        Section {
                            ForEach(section.items) { item in
                                NavigationLink(value: item.exerciseId) {
                                    PlanRow(item: item, edited: edited.contains(item.exerciseId),
                                            added: !planned.contains(item.exerciseId), showsGroup: false)
                                }
                                .swipeActions {
                                    Button("Remove", systemImage: "trash", role: .destructive) {
                                        withAnimation { remove(item.exerciseId, from: original) }
                                    }
                                }
                            }
                        } header: {
                            Text(section.title).eyebrow(Theme.tertiary, size: 12)
                        }
                        .listRowBackground(Theme.card)
                    }
                }

                Section {
                    Button { adding = true } label: {
                        Label("Add exercise", systemImage: "plus.circle.fill")
                            .font(.rounded(.body, .semibold))
                            .foregroundStyle(Theme.volt)
                    }
                } footer: {
                    if today.planEdits.isEdited(original) {
                        Text("\(day.title) is changed from the plan. Its history is kept either way.")
                    }
                }
                .listRowBackground(Theme.card)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.canvas)
            .environment(\.editMode, .constant(editing ? .active : .inactive))
            .navigationTitle("Plan")
            .navigationDestination(for: String.self) { exerciseId in
                PlanItemEditor(exerciseId: exerciseId, day: original)
            }
            .sheet(isPresented: $adding) {
                AddExerciseSheet(day: original)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("Reset \(day.title) to the plan", systemImage: "arrow.uturn.backward") {
                            withAnimation { today.editPlan { $0.reset(original) }; sync.sendContext() }
                        }
                        .disabled(!today.planEdits.isEdited(original))
                        Button("Reset everything to the plan", systemImage: "arrow.counterclockwise",
                               role: .destructive) {
                            confirmingReset = true
                        }
                        .disabled(settings.isEmpty && today.planEdits.days.isEmpty)
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                    .accessibilityLabel("More")
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { adding = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add exercise")
                    Button(editing ? "Done" : "Edit") {
                        withAnimation(.snappy) { editing.toggle() }
                    }
                    .fontWeight(editing ? .bold : .regular)
                }
            }
            .confirmationDialog("Reset every day and exercise to the plan?", isPresented: $confirmingReset,
                                titleVisibility: .visible) {
                Button("Reset everything", role: .destructive, action: resetAll)
            } message: {
                Text("Names, prescriptions and added or removed exercises go back to the plan. Your history is kept.")
            }
            #if DEBUG
            .task {
                switch LaunchOptions.screen {
                case "editor":
                    if let item = day.items.first(where: { $0.kind == .weighted }) { path = [item.exerciseId] }
                case "plan-edit":
                    editing = true
                case "add":
                    adding = true
                default:
                    break
                }
            }
            #endif
        }
    }

    private func remove(_ exerciseId: String, from day: PlanDay) {
        today.editPlan { $0.remove(exerciseId, from: day) }
        sync.sendContext()
    }

    private func move(_ source: IndexSet, to destination: Int, in day: PlanDay, original: PlanDay) {
        var ids = day.items.map(\.exerciseId)
        ids.move(fromOffsets: source, toOffset: destination)
        today.editPlan { $0.setItemIds(ids, for: original) }
        sync.sendContext()
    }

    /// Every day back to the plan's list and every exercise to its own name and prescription. The user's own
    /// exercises stay defined, so their history still shows and a new one never takes over their id.
    private func resetAll() {
        settings.forEach(context.delete)
        try? context.save()
        today.editPlan { $0.days = [:] }
        today.refresh()
        sync.sendContext()
    }
}

private struct PlanRow: View {
    let item: PlanItem
    /// Its prescription or name differs from the plan.
    let edited: Bool
    /// It's on this day because the user put it there.
    let added: Bool
    let showsGroup: Bool

    var body: some View {
        HStack(spacing: 14) {
            ItemBadge(item: item, size: 36)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name).font(.rounded(.body, .semibold))
                Text(line)
                    .font(.rounded(.subheadline))
                    .foregroundStyle(Theme.secondary)
            }
            Spacer(minLength: 8)
            if added {
                Chip(text: "Added", tint: Theme.volt)
            } else if edited {
                Chip(text: "Edited", tint: Theme.ice)
            }
        }
        .padding(.vertical, 4)
    }

    private var line: String {
        var parts = [Format.prescription(item, TargetPlanner.target(for: item, history: [], deload: false))]
        if item.kind == .weighted, let increment = item.increment { parts.append("+\(Format.kg(increment))") }
        if let rest = item.restSec { parts.append("\(Format.clock(rest)) rest") }
        if showsGroup { parts.insert(item.group, at: 0) }
        return parts.filter { !$0.isEmpty }.joined(separator: " · ")
    }
}
