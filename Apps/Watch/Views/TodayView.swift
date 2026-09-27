import SwiftUI
import RepCoachCore

/// The watch home: up next on top, then what's left, then what's done.
struct TodayView: View {
    @Environment(TodayModel.self) private var today
    @Environment(WorkoutModel.self) private var workout
    @Environment(\.scenePhase) private var scenePhase
    @State private var path: [Route] = []
    @State private var choosingDay = false

    enum Route: Hashable {
        case exercise
        case checklist(PlanItem)
    }

    var body: some View {
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
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { today.wake() }
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

            if today.queue.isComplete {
                AllDoneCard(count: today.queue.totalCount)
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
        }
    }

    private func start(_ items: [PlanItem]) {
        guard let first = items.first else { return }
        if first.kind == .checklist {
            path.append(.checklist(first))
        } else {
            workout.begin(items)
            path.append(.exercise)
        }
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

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(Theme.mint)
            Text("All \(count) done").font(.rounded(.headline, .bold))
            Text("Great session.").font(.rounded(.footnote)).foregroundStyle(Theme.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .glowCard(Theme.mint)
    }
}
