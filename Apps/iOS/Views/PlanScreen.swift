import SwiftUI
import SwiftData
import RepCoachCore

/// All seven days as the user has them (boards 9.1, 9.2), in look B: the day strip, the day's name and time, and its
/// sections as on Today, each row with its figure and "4 × 6–10 · +2.5 kg · 2:30 rest". Tap an exercise to rename it
/// or change its sets, reps, rest, increment or start weight; Edit to reorder and remove; + for a new exercise or
/// one from another day; the more menu rearranges the weekdays. plan.json itself never changes; history is kept.
struct PlanScreen: View {
    @Environment(AppModel.self) private var app
    @Environment(TodayModel.self) private var today
    @Environment(\.modelContext) private var context
    @Environment(PhoneSync.self) private var sync
    @Query private var settings: [ExerciseSettings]
    @State private var dayKey: String?
    @State private var path: [String] = []
    @State private var editing = false
    @State private var adding: AddExerciseSheet.Source?
    @State private var rearranging = false
    @State private var confirmingReset = false
    @State private var scroll = ScrollPosition()

    var body: some View {
        let key = dayKey ?? today.dayKey
        // The day as the user has it, on the weekday it stands on now.
        let day = today.editedPlan.days.first { $0.key == key } ?? today.editedPlan.days[0]
        // The plan's own day, which edits are made against.
        let original = app.plan.days.first { $0.key == day.key } ?? app.plan.days[0]
        NavigationStack(path: $path) {
            Group {
                if editing {
                    PlanEditList(day: day, original: original)
                } else {
                    content(day: day, original: original)
                }
            }
            .background(Theme.canvas.ignoresSafeArea())
            .navigationTitle("Plan")
            .navigationDestination(for: String.self) { exerciseId in
                PlanItemEditor(exerciseId: exerciseId, day: original)
            }
            .sheet(item: $adding) { source in
                AddExerciseSheet(day: original, source: source)
            }
            .sheet(isPresented: $rearranging) {
                RearrangeDaysSheet()
            }
            .toolbar { toolbar(day: day, original: original) }
            .confirmationDialog("Reset every day and exercise to the plan?", isPresented: $confirmingReset,
                                titleVisibility: .visible) {
                Button("Reset everything", role: .destructive, action: resetAll)
            } message: {
                Text("Names, prescriptions, added or removed exercises and the order of the days go back to the plan. Your history is kept.")
            }
            #if DEBUG
            .task { script(day: day) }
            #endif
        }
    }

    // MARK: A day

    private func content(day: PlanDay, original: PlanDay) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                DayStrip(days: today.plan.days, selected: day.key, todayWeekday: today.todayWeekday) { key in
                    withAnimation(.snappy) { dayKey = key }
                }
                header(day)
                ForEach(day.sections) { section in
                    DepthSection(title: section.title) {
                        ForEach(section.items) { item in
                            Button { path.append(item.exerciseId) } label: { PlanRow(item: item) }
                                .buttonStyle(RowPressStyle())
                                .contextMenu {
                                    Button("Remove from \(day.title)", systemImage: "minus.circle", role: .destructive) {
                                        withAnimation { remove(item.exerciseId, from: original) }
                                    }
                                }
                            if item.id != section.items.last?.id { DepthDivider() }
                        }
                    }
                }
                addRow
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .scrollPosition($scroll)
        .voltWash()
    }

    /// "Push A · Chest & Shoulders + Core A" and its time.
    private func header(_ day: PlanDay) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // The board breaks before "+ Core A".
            Text(day.focus.replacingOccurrences(of: " + ", with: "\n+ "))
                .font(PhoneFont.title2)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 16)
                Text(day.time).font(PhoneFont.sub)
            }
            .foregroundStyle(Theme.text2)
            .accessibilityElement(children: .combine)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var addRow: some View {
        Button { adding = .new } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .frame(width: 20)
                Text("Add exercise").font(PhoneFont.headline)
            }
            .foregroundStyle(Theme.volt)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(RowPressStyle())
        .depthRows()
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private func toolbar(day: PlanDay, original: PlanDay) -> some ToolbarContent {
        if !editing {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button("Rearrange days", systemImage: "arrow.up.arrow.down") { rearranging = true }
                    Button("Reset \(day.title) to the plan", systemImage: "arrow.uturn.backward") {
                        withAnimation { today.editPlan { $0.reset(original) }; sync.sendContext() }
                    }
                    .disabled(!today.planEdits.isEdited(original))
                    Button("Reset everything to the plan", systemImage: "arrow.counterclockwise", role: .destructive) {
                        confirmingReset = true
                    }
                    .disabled(settings.isEmpty && today.planEdits.days.isEmpty && today.planEdits.schedule.isEmpty)
                } label: {
                    Image(systemName: "ellipsis")
                }
                .accessibilityLabel("More")
            }
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button { adding = .new } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Add exercise")
            Button(editing ? "Done" : "Edit") {
                withAnimation(.snappy) { editing.toggle() }
            }
            .fontWeight(editing ? .bold : .regular)
        }
    }

    // MARK: Changes

    private func remove(_ exerciseId: String, from day: PlanDay) {
        today.editPlan { $0.remove(exerciseId, from: day) }
        sync.sendContext()
    }

    /// Every day back to the plan's list and weekday and every exercise to its own name and prescription. The
    /// user's own exercises stay defined, so their history still shows and a new one never takes over their id.
    private func resetAll() {
        settings.forEach(context.delete)
        try? context.save()
        today.editPlan {
            $0.days = [:]
            $0.resetSchedule()
        }
        today.refresh()
        sync.sendContext()
    }

    #if DEBUG
    /// `-tab plan -sheet rearrange`, or `-screen editor`: drives the demo to a sheet or a pushed screen for
    /// screenshots (editor, editor-edited, plan-edit, add, add-plan, rearrange). `-scroll 600` scrolls the day.
    private func script(day: PlanDay) {
        let offset = UserDefaults.standard.double(forKey: "scroll")
        if offset > 0 { scroll.scrollTo(y: offset) }
        switch LaunchOptions.screen ?? UserDefaults.standard.string(forKey: "sheet") {
        case "editor":
            if let item = day.items.first(where: { $0.kind == .weighted }) { path = [item.exerciseId] }
        case "editor-edited":
            // The first weighted lift with a fifth set instead of the plan's, as the board shows it.
            if let item = day.items.first(where: { $0.kind == .weighted }) {
                let row = ExerciseSettings(exerciseId: item.exerciseId)
                row.overrides = ExerciseOverrides(sets: (item.sets ?? 3) + 1)
                context.insert(row)
                try? context.save()
                today.refresh()
                path = [item.exerciseId]
            }
        case "plan-edit":
            editing = true
        case "add":
            adding = .new
        case "add-plan":
            adding = .plan
        case "rearrange":
            rearranging = true
        default:
            break
        }
    }
    #endif
}

/// One exercise of a day: its figure, its name, and what it asks.
private struct PlanRow: View {
    let item: PlanItem

    var body: some View {
        HStack(spacing: 12) {
            RowFigure(item: item)
            VStack(alignment: .leading, spacing: 0) {
                Text(item.name)
                    .font(PhoneFont.headline)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Text(item.planLine())
                    .font(PhoneFont.sub)
                    .foregroundStyle(Theme.text2)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 16))
        .frame(minHeight: 64)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
