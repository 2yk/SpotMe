import SwiftUI
import RepCoachCore

/// The watch home: one button to start (or continue) the workout, then the day's items in plan order, then
/// what's done. Tapping an item does it now; the workout then carries on through the rest by itself.
struct TodayView: View {
    @Environment(TodayModel.self) private var today
    @Environment(WorkoutModel.self) private var workout
    @State private var path: [Route] = []
    @State private var choosingDay = false
    @State private var confirmingFinish = false
    @State private var confirmingDiscard = false

    enum Route: Hashable {
        case workout
        #if DEBUG
        /// Screenshots of the complication.
        case complications
        #endif
    }

    /// Scroll target for the buttons at the end of the list.
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
                case .workout:
                    WorkoutScreen(onList: { path.removeAll() }, onFinish: askToFinish)
                #if DEBUG
                case .complications:
                    ComplicationGallery()
                #endif
                }
            }
            .onOpenURL(perform: open)
            .sheet(isPresented: $choosingDay) {
                DayPickerView()
            }
            .sheet(item: $workout.summary) { summary in
                WorkoutSummaryView(summary: summary)
            }
            .confirmationDialog("Finish workout?", isPresented: $confirmingFinish) {
                if workout.health.isRunning {
                    Button("Save to Health") { Task { await workout.finishWorkout() } }
                    Button("Don't save to Health", role: .destructive) {
                        Task { await workout.finishWorkout(saveToHealth: false) }
                    }
                } else {
                    Button("Finish") { Task { await workout.finishWorkout() } }
                }
                Button("Keep going", role: .cancel) {}
            } message: {
                Text(workout.health.isRunning ? "Your sets stay in SpotMe either way." : "Marks today's session done.")
            }
            .confirmationDialog("Discard workout?", isPresented: $confirmingDiscard) {
                Button("Discard", role: .destructive) { withAnimation(.snappy) { workout.discardWorkout() } }
                Button("Keep it", role: .cancel) {}
            } message: {
                Text("Everything logged today is deleted, here and on your iPhone. Nothing is saved to Health.")
            }
            .alert("Not saving to Health", isPresented: startProblemShown) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(workout.startProblem ?? "")
            }
        }
        #if DEBUG
        .task {
            ScreenScript.run(today: today, workout: workout, path: $path, choosingDay: $choosingDay,
                             confirmingFinish: $confirmingFinish, confirmingDiscard: $confirmingDiscard, open: open)
        }
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
                AllDoneCard(count: today.queue.totalCount, onFinish: workout.canFinish ? askToFinish : nil)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            } else {
                StartButton(started: workout.hasStarted, next: workout.currentName) {
                    workout.startOrContinue()
                    path = [.workout]
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 6, trailing: 0))
            }

            ForEach(openItems) { item in
                Button {
                    workout.open(item)
                    path = [.workout]
                } label: {
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

            if workout.canFinish || workout.canDiscard {
                VStack(spacing: 10) {
                    if workout.canFinish, !today.queue.isComplete {
                        Button("Finish workout", action: askToFinish)
                            .buttonStyle(SecondaryButtonStyle(tint: Theme.pulse))
                    }
                    if workout.canDiscard {
                        Button { confirmingDiscard = true } label: {
                            Label("Discard workout", systemImage: "trash")
                                .font(.rounded(.footnote, .semibold))
                                .foregroundStyle(Theme.ember)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
                .id(Self.endOfList)
            }
        }
    }

    /// Everything still to do, in plan order.
    private var openItems: [PlanItem] {
        today.day.items.filter { !today.status(of: $0).isFinished }
    }

    private func askToFinish() {
        path.removeAll()
        confirmingFinish = true
    }

    /// Complication taps: spotme://start opens today and gets the workout going; spotme://today just opens today.
    private func open(_ url: URL) {
        guard url.scheme == "spotme" else { return }
        path.removeAll()
        today.showToday()
        guard url.host == "start", !today.queue.isComplete else { return }
        workout.startOrContinue()
        path = [.workout]
    }

    private var startProblemShown: Binding<Bool> {
        Binding(get: { workout.startProblem != nil }, set: { if !$0 { workout.startProblem = nil } })
    }

    /// Checklist items, from the list: one swipe to done.
    private func tickOff(_ item: PlanItem) {
        withAnimation(.snappy) { today.complete(item) }
        Haptics.play(.logged)
    }
}

/// The one big button: Start workout, or Continue with what's next.
private struct StartButton: View {
    let started: Bool
    let next: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Label(started ? "Continue" : "Start workout", systemImage: "play.fill")
                if started, let next {
                    Text(next)
                        .font(.rounded(.caption2, .semibold))
                        .lineLimit(1)
                        .opacity(0.7)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PrimaryButtonStyle(tint: Theme.volt))
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
                    Text(day.focus)
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
