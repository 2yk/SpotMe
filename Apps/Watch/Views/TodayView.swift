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
            .barTitle("\(today.queue.doneCount)/\(today.queue.totalCount)", workout.isPaused ? Theme.amber : Theme.volt, root: true)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .workout:
                    WorkoutPager(onList: { path.removeAll() })
                #if DEBUG
                case .complications:
                    ComplicationGallery()
                #endif
                }
            }
            .onOpenURL(perform: open)
            // Another day picked, or midnight: a workout step from the old day no longer applies.
            .onChange(of: today.dayKey) { workout.reconcile() }
            .sheet(isPresented: $choosingDay) {
                DayPickerView()
            }
            .sheet(item: $workout.summary) { summary in
                WorkoutSummaryView(summary: summary)
            }
            .sheet(isPresented: $confirmingFinish) { EndWorkoutSheet() }
            .sheet(isPresented: $confirmingDiscard) { EndWorkoutSheet(startsDiscarding: true) }
        }
        // On the stack, not its root: Start workout pushes the workout screen before this can fire.
        .sheet(isPresented: startProblemShown) { HealthAlertSheet(message: workout.startProblem ?? "") }
        #if DEBUG
        .task {
            ScreenScript.run(today: today, workout: workout, path: $path, choosingDay: $choosingDay,
                             confirmingFinish: $confirmingFinish, confirmingDiscard: $confirmingDiscard, open: open)
        }
        #endif
    }

    private var list: some View {
        List {
            if !today.queue.isComplete {
                Group {
                    if workout.health.isActive {
                        RunningHeader(day: today.day, isDeload: today.isDeload, paused: workout.isPaused) {
                            choosingDay = true
                        }
                    } else {
                        DayHeader(day: today.day, isDeload: today.isDeload) { choosingDay = true }
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(rowInsets(top: Metrics.top, bottom: pt(4)))
            }

            Group {
                if today.queue.isComplete {
                    AllDoneCard(count: today.queue.totalCount, day: today.day.headline,
                                minutes: today.session.map { Int(Date.now.timeIntervalSince($0.date) / 60) },
                                onFinish: workout.canFinish ? { Task { await workout.finishWorkout() } } : nil)
                } else if today.day.items.contains(where: { $0.kind != .checklist }) || !today.queue.upNext.isEmpty,
                          !isRestDay {
                    StartButton(started: workout.hasStarted, paused: workout.isPaused, next: workout.currentName) {
                        workout.startOrContinue()
                        path = [.workout]
                    }
                }
            }
            .listRowBackground(Color.clear)
            .listRowInsets(rowInsets(top: today.queue.isComplete ? Metrics.top : pt(4), bottom: pt(4)))

            ForEach(openItems) { item in
                Button {
                    workout.open(item)
                    path = [.workout]
                } label: {
                    ItemRow(item: item)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowInsets(rowInsets())
                .swipeActions(edge: .trailing) {
                    if item.kind == .checklist {
                        Button { withAnimation(.snappy) { workout.tickOff(item) } } label: {
                            Label("Done", systemImage: "checkmark")
                        }
                        .tint(Theme.mint)
                    }
                    Button { withAnimation { workout.skip(item) } } label: {
                        Label("Skip", systemImage: "forward.fill")
                    }
                    .tint(Theme.ember)
                }
            }

            if !today.queue.finished.isEmpty {
                Text("Done")
                    .role(.eyebrow, Theme.text3)
                    .padding(EdgeInsets(top: pt(10), leading: pt(4), bottom: pt(0), trailing: 0))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .listRowBackground(Color.clear)
                    .listRowInsets(rowInsets())
                ForEach(today.queue.finished) { item in
                    ItemRow(item: item)
                        .listRowBackground(Color.clear)
                        .listRowInsets(rowInsets())
                        .swipeActions(edge: .trailing) {
                            Button { withAnimation { workout.reopen(item) } } label: {
                                Label("Reopen", systemImage: "arrow.uturn.backward")
                            }
                            .tint(Theme.ice)
                        }
                }
            }

            if workout.canFinish || workout.canDiscard {
                VStack(spacing: pt(2)) {
                    if workout.canFinish, !today.queue.isComplete {
                        Button("Finish workout", action: askToFinish)
                            .buttonStyle(NeutralButtonStyle(height: 40, font: .row))
                    }
                    if workout.canDiscard {
                        Button { confirmingDiscard = true } label: {
                            HStack(spacing: pt(5)) {
                                Image(systemName: "trash").font(.system(size: pt(12), weight: .semibold))
                                Text("Discard workout")
                            }
                        }
                        .buttonStyle(TextButtonStyle(color: Theme.red))
                    }
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .listRowInsets(rowInsets(top: pt(10), bottom: Metrics.bottom))
                .id(Self.endOfList)
            }
        }
        .listStyle(.plain)
        // The design lays Today out from the whole screen; the list runs under the bar and off the bottom edge.
        .ignoresSafeArea()
    }

    private func rowInsets(top: CGFloat = pt(2), bottom: CGFloat = pt(2)) -> EdgeInsets {
        EdgeInsets(top: top, leading: Metrics.side, bottom: bottom, trailing: Metrics.side)
    }

    /// Nothing to train today: the day's items are all tick-offs and notes (Saturday).
    private var isRestDay: Bool {
        !today.day.items.contains { $0.kind != .checklist }
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
}

/// The one big button: Start workout, or Continue with what's next.
private struct StartButton: View {
    let started: Bool
    let paused: Bool
    let next: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if started {
                VStack(spacing: 0) {
                    Text("Continue")
                    if let next {
                        Text(paused ? "Paused · \(next)" : next)
                            .role(.small.weight(.bold), .black.opacity(0.66))
                            .lineLimit(paused ? 2 : 1)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: pt(160))
                    }
                }
            } else {
                HStack(spacing: pt(6)) {
                    Image(systemName: "play.fill").font(.system(size: pt(13)))
                    Text("Start workout")
                }
            }
        }
        .buttonStyle(PrimaryButtonStyle(tint: paused ? Theme.amber : Theme.volt, height: started ? 54 : 48))
    }
}

/// Before the workout: the day, its name and what it trains.
private struct DayHeader: View {
    let day: PlanDay
    let isDeload: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: pt(3)) {
                    Text(day.title).role(.eyebrow, Theme.volt)
                    Image(systemName: "chevron.down")
                        .font(.system(size: pt(9), weight: .bold))
                        .foregroundStyle(Theme.text3)
                    if isDeload {
                        Text("Deload")
                            .role(.eyebrow, .black)
                            .padding(.horizontal, pt(5))
                            .padding(.vertical, pt(1))
                            .background(Capsule().fill(Theme.ember))
                    }
                }
                Text(day.headline).role(.titleXL).lineLimit(2).minimumScaleFactor(0.8)
                Text(day.subtitle)
                    .role(.detail, Theme.text2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .padding(.horizontal, pt(6))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}

/// While the Health workout runs: the day as one line, then heart rate and time.
private struct RunningHeader: View {
    @Environment(HealthWorkout.self) private var health
    let day: PlanDay
    let isDeload: Bool
    let paused: Bool
    let action: () -> Void

    var body: some View {
        VStack(spacing: pt(6)) {
            Button(action: action) {
                HStack(spacing: pt(3)) {
                    Text("\(day.title) · \(day.headline)").role(.eyebrow, Theme.volt).lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: pt(9), weight: .bold))
                        .foregroundStyle(Theme.text3)
                    if isDeload {
                        Text("Deload")
                            .role(.eyebrow, .black)
                            .padding(.horizontal, pt(5))
                            .padding(.vertical, pt(1))
                            .background(Capsule().fill(Theme.ember))
                    }
                }
                .padding(.horizontal, pt(6))
                .frame(maxWidth: .infinity, minHeight: pt(30), alignment: .leading)
            }
            .buttonStyle(.plain)
            HStack(alignment: .firstTextBaseline, spacing: pt(3)) {
                Image(systemName: "heart.fill")
                    .font(.system(size: pt(13), weight: .bold))
                    .foregroundStyle(Theme.red)
                Text(health.heartRate.map { "\(Int($0.rounded()))" } ?? "--").role(.titleXL)
                Text(paused ? "Paused" : "bpm").role(.eyebrow, paused ? Theme.amber : Theme.text3)
                Spacer(minLength: pt(4))
                ElapsedTime(size: 20)
            }
            .padding(.horizontal, pt(6))
        }
    }
}

/// Everything is done: Finish workout while the session is still open.
private struct AllDoneCard: View {
    let count: Int
    let day: String
    let minutes: Int?
    /// Offered once everything is done, while the session is still open.
    let onFinish: (() -> Void)?

    var body: some View {
        VStack(spacing: pt(3)) {
            Image(systemName: "checkmark")
                .font(.system(size: pt(24), weight: .heavy))
                .foregroundStyle(Theme.mint)
                .frame(width: pt(44), height: pt(44))
                .background(Circle().fill(Theme.mint.opacity(0.16)))
            Text("All \(count) done").role(.titleXL)
            Text(minutes.map { "\(day) · \($0) min" } ?? day).role(.detail, Theme.text2)
            if let onFinish {
                Button("Finish workout", action: onFinish)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, pt(5))
            }
        }
        .frame(maxWidth: .infinity)
    }
}
