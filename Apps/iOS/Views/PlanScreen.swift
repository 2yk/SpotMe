import SwiftUI
import SwiftData
import RepCoachCore

/// All seven days. Tap an exercise to change its sets, reps, rest, increment or start weight.
struct PlanScreen: View {
    @Environment(AppModel.self) private var app
    @Environment(TodayModel.self) private var today
    @Environment(\.modelContext) private var context
    @Query private var settings: [ExerciseSettings]
    @State private var dayKey: String?
    @State private var path: [PlanItem] = []
    @State private var confirmingReset = false

    var body: some View {
        let day = app.plan.days.first { $0.key == (dayKey ?? today.dayKey) } ?? app.plan.days[0]
        let overrides = Dictionary(settings.map { ($0.exerciseId, $0.overrides) }, uniquingKeysWith: { first, _ in first })
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
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
                    ForEach(day.sections) { section in
                        CardSection(title: section.title) {
                            ForEach(section.items) { item in
                                NavigationLink(value: item) {
                                    PlanRow(item: item, overrides: overrides[item.exerciseId])
                                }
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
            .navigationTitle("Plan")
            .navigationDestination(for: PlanItem.self) { item in
                PlanItemEditor(item: item)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Reset all to bundled plan", systemImage: "arrow.counterclockwise", role: .destructive) {
                            confirmingReset = true
                        }
                        .disabled(settings.isEmpty)
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                    .accessibilityLabel("More")
                }
            }
            .confirmationDialog("Reset every exercise to the bundled plan?", isPresented: $confirmingReset,
                                titleVisibility: .visible) {
                Button("Reset all", role: .destructive, action: resetAll)
            } message: {
                Text("Your history is kept.")
            }
            #if DEBUG
            .task {
                if LaunchOptions.screen == "editor", let item = day.items.first(where: { $0.kind == .weighted }) {
                    path = [item]
                }
            }
            #endif
        }
    }

    private func resetAll() {
        settings.forEach(context.delete)
        try? context.save()
        today.refresh()
    }
}

private struct PlanRow: View {
    let item: PlanItem
    let overrides: ExerciseOverrides?

    var body: some View {
        HStack(spacing: 14) {
            ItemBadge(item: item, size: 36)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name).font(.rounded(.body, .semibold))
                Text(line(item.applying(overrides)))
                    .font(.rounded(.subheadline))
                    .foregroundStyle(Theme.secondary)
            }
            Spacer(minLength: 8)
            if let overrides, !overrides.isEmpty {
                Chip(text: "Edited", tint: Theme.ice)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private func line(_ item: PlanItem) -> String {
        var parts = [Format.prescription(item, TargetPlanner.target(for: item, history: [], deload: false))]
        if item.kind == .weighted, let increment = item.increment { parts.append("+\(Format.kg(increment))") }
        if let rest = item.restSec { parts.append("\(Format.clock(rest)) rest") }
        return parts.joined(separator: " · ")
    }
}
