import SwiftUI
import RepCoachCore

/// The watch home: up next on top, then what's left, then what's done.
struct TodayView: View {
    @Environment(TodayModel.self) private var today
    @Environment(WorkoutModel.self) private var workout
    @State private var path: [Route] = []
    @State private var choosingDay = false
    @State private var confirmingFinish = false

    enum Route: Hashable {
        case exercise
        case checklist(PlanItem)
    }

    /// Scroll target for the Start / Finish workout button.
    static let endOfList = "end-of-list"

    var body: some View {
        @Bindable var workout = workout
        NavigationStack(path: $path) {
            ScrollViewReader { proxy in
                list
                    #if DEBUG
                    .task { await ScreenScript.scroll(proxy, today: today) }
                    #endif
            }
            .navigationTitle("\(today.queue.doneCount)/\(today.queue.totalCount)")
            .containerBackground(Theme.volt.gradient.opacity(0.3), for: .navigation)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .exercise:
                    if let flow = workout.flow {
                        ExerciseView(flow: flow) {
                            workout.end()
                            path.removeAll()
                        }
                    }
                case .checklist(let item):
                    ChecklistView(item: item) { path.removeAll() }
                }
            }
            .sheet(isPresented: $choosingDay) {
                DayPickerView()
            }
            .sheet(item: $workout.summary) { summary in
                WorkoutSummaryView(summary: summary)
            }
            .confirmationDialog("Finish workout?", isPresented: $confirmingFinish) {
                Button("Finish") { Task { await workout.finishWorkout() } }
                Button("Keep going", role: .cancel) {}
            } message: {
                Text(workout.health.isRunning ? "It will be saved to Health." : "Marks today's session done.")
            }
        }
        #if DEBUG
        .task { ScreenScript.run(today: today, workout: workout, path: $path, choosingDay: $choosingDay) }
        #endif
    }

    private var list: some View {
        List {
            DayHeader(day: today.day, isDeload: today.isDeload) { choosingDay = true }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: 6, bottom: 4, trailing: 6))

            if workout.health.isRunning {
                WorkoutBar()
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
            }

            if today.queue.isComplete {
                AllDoneCard(count: today.queue.totalCount,
                            onFinish: workout.canFinish ? { confirmingFinish = true } : nil)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            } else if !today.queue.upNext.isEmpty {
                Button { start(today.queue.upNext) } label: {
                    UpNextCard(items: today.queue.upNext)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            ForEach(today.queue.remaining) { item in
                Button { withAnimation(.snappy) { today.promote(item) } } label: {
                    ItemRow(item: item)
                }
                .swipeActions(edge: .trailing) {
                    if item.kind == .checklist {
                        Button { tickOff(item) } label: {
                            Label("Done", systemImage: "checkmark")
                        }
                        .tint(Theme.mint)
                    }
                    Button { withAnimation { today.skip(item) } } label: {
                        Label("Skip", systemImage: "forward.fill")
                    }
                    .tint(Theme.ember)
                }
            }

            if !today.queue.finished.isEmpty {
                Section {
                    ForEach(today.queue.finished) { item in
                        ItemRow(item: item)
                            .swipeActions(edge: .trailing) {
                                Button { withAnimation { today.reopen(item) } } label: {
                                    Label("Reopen", systemImage: "arrow.uturn.backward")
                                }
                                .tint(Theme.ice)
                            }
                    }
                } header: {
                    Text("Done").eyebrow(Theme.tertiary)
                }
            }

            if workout.canFinish, !today.queue.isComplete {
                Button("Finish workout") { confirmingFinish = true }
                    .buttonStyle(SecondaryButtonStyle(tint: Theme.pulse))
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
                    .id(Self.endOfList)
            } else if workout.canStart, !workout.canFinish {
                Button { workout.startWorkout() } label: {
                    Label("Start workout", systemImage: "play.fill")
                }
                .buttonStyle(SecondaryButtonStyle(tint: Theme.volt))
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
                .id(Self.endOfList)
            }
        }
    }

    private func start(_ items: [PlanItem]) {
        guard let first = items.first else { return }
        if first.kind == .checklist {
            // One tap to done; warmups open their steps first.
            if first.steps == nil {
                tickOff(first)
            } else {
                path.append(.checklist(first))
            }
        } else {
            workout.begin(items)
            path.append(.exercise)
        }
    }

    /// Checklist items only: never starts the Health workout.
    private func tickOff(_ item: PlanItem) {
        withAnimation(.snappy) { today.complete(item) }
        Haptics.play(.logged)
    }
}

private struct DayHeader: View {
    let day: PlanDay
    let isDeload: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Text(day.title).eyebrow(Theme.volt)
                        if isDeload {
                            Text("Deload")
                                .eyebrow(.black, size: 9)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(Capsule().fill(Theme.ember))
                        }
                    }
                    Text(day.shortFocus)
                        .font(.rounded(.footnote, .medium))
                        .foregroundStyle(Theme.secondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.tertiary)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct AllDoneCard: View {
    let count: Int
    /// Offered once everything is done, while the session is still open.
    let onFinish: (() -> Void)?

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(Theme.mint)
            Text("All \(count) done").font(.rounded(.headline, .bold))
            Text("Great session.").font(.rounded(.footnote)).foregroundStyle(Theme.secondary)
            if let onFinish {
                Button("Finish workout", action: onFinish)
                    .buttonStyle(PrimaryButtonStyle(tint: Theme.mint))
                    .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 10)
        .glowCard(Theme.mint)
    }
}
