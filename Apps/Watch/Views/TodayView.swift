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
    /// The open row being swapped (from its swipe action).
    @State private var swapping: PlanItem?

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
            .barTitle("\(today.queue.doneCount)/\(today.queue.totalCount)", titleColor, root: true)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .workout:
                    WorkoutPager(onList: { path.removeAll() })
                        .navigationBarBackButtonHidden(true)
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
            .sheet(item: $workout.effortPrompt, onDismiss: { workout.effortClosed() }) { prompt in
                EffortView(initial: prompt.initial)
            }
            .sheet(item: $workout.summary) { summary in
                WorkoutSummaryView(summary: summary)
            }
            .sheet(item: $swapping) { item in
                SwapSheet(item: item) { choice in
                    swapping = nil
                    workout.swap(item, to: choice)
                }
            }
            .sheet(isPresented: $confirmingFinish) { EndWorkoutSheet() }
            .sheet(isPresented: $confirmingDiscard) { EndWorkoutSheet(startsDiscarding: true) }
        }
        // On the stack, not its root: Start workout pushes the workout screen before this can fire.
        .sheet(isPresented: startProblemShown) { HealthAlertSheet(message: workout.startProblem ?? "") }
        #if DEBUG
        .task {
            ScreenScript.run(today: today, workout: workout, path: $path, choosingDay: $choosingDay,
                             confirmingFinish: $confirmingFinish, confirmingDiscard: $confirmingDiscard,
                             swapping: $swapping, open: open)
        }
        #endif
    }

    private var list: some View {
        List {
            // The day, the live strip and the one big button are one block, 6 pt between them.
            VStack(spacing: pt(6)) {
                if workout.isDayFinished {
                    // Finished: the day, how it went, and what is left to do again.
                    DayLine(day: today.day, isDeload: today.isDeload) { choosingDay = true }
                    FinishedCard(detail: finishedDetail) { workout.summary = workout.finishedSummary() }
                    if !openItems.isEmpty {
                        StartAgainButton(left: openItems.count) {
                            workout.startAgain()
                            path = [.workout]
                        }
                    }
                } else if today.queue.isComplete {
                    AllDoneCard(count: today.queue.totalCount, day: today.day.headline,
                                minutes: today.session.map { Int(Date.now.timeIntervalSince($0.date) / 60) },
                                onFinish: workout.canFinish ? { Task { await workout.finishWorkout() } } : nil)
                } else {
                    if workout.health.isActive {
                        RunningHeader(day: today.day, isDeload: today.isDeload, paused: workout.isPaused) {
                            choosingDay = true
                        }
                    } else {
                        DayHeader(day: today.day, isDeload: today.isDeload) { choosingDay = true }
                    }
                    if !isRestDay {
                        StartButton(started: workout.hasStarted, paused: workout.isPaused, next: workout.currentName) {
                            workout.startOrContinue()
                            path = [.workout]
                        }
                    }
                }
            }
            .listRowBackground(Color.clear)
            .listRowInsets(rowInsets(top: Metrics.rootTop, bottom: pt(-1.5)))

            if workout.isDayFinished, !openItems.isEmpty {
                eyebrow("Not done")
            }
            ForEach(openItems) { item in
                Button {
                    // On a finished day a tap on an open row is Start again, starting on that row.
                    if workout.isDayFinished { workout.startAgain(opening: item) } else { workout.open(item) }
                    path = [.workout]
                } label: {
                    ItemRow(item: item, showsWeight: !workout.isDayFinished)
                }
                .buttonStyle(RowButtonStyle())
                .listRowBackground(Color.clear)
                .listRowInsets(rowInsets())
                .swipeActions(edge: .trailing) {
                    if today.canSwap(item) {
                        Button { swapping = item } label: {
                            Label("Swap", systemImage: "arrow.left.arrow.right")
                        }
                        .tint(Theme.ice)
                    }
                    if item.kind == .checklist {
                        Button { withAnimation(.snappy) { workout.tickOff(item) } } label: {
                            Label("Done", systemImage: "checkmark")
                        }
                        .tint(Theme.mint)
                    }
                    Button { withAnimation { workout.skip(item) } } label: {
                        Label("Skip today", systemImage: "forward.fill")
                    }
                    .tint(Theme.ember)
                }
            }

            if !today.queue.finished.isEmpty {
                eyebrow("Done")
                ForEach(today.queue.finished) { item in
                    // A row skipped for the day says "tap to do it": a tap opens it again and starts it.
                    Button {
                        guard today.status(of: item).isSkipped else { return }
                        workout.reopen(item)
                        if workout.isDayFinished { workout.startAgain(opening: item) } else { workout.open(item) }
                        path = [.workout]
                    } label: {
                        ItemRow(item: item)
                    }
                    .buttonStyle(RowButtonStyle())
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
                .listRowInsets(rowInsets(top: pt(8), bottom: Metrics.bottom))
                .id(Self.endOfList)
            }
        }
        .listStyle(.plain)
        // Rows are as tall as their content: the list's own minimum would leave holes round short ones.
        .environment(\.defaultMinListRowHeight, 1)
        // The design lays Today out from the whole screen; the list runs under the bar and off the bottom edge.
        .ignoresSafeArea()
        .topFade()
    }

    /// NOT DONE, DONE.
    private func eyebrow(_ text: String) -> some View {
        Text(text)
            .role(.eyebrow, Theme.text3)
            .padding(EdgeInsets(top: pt(10), leading: pt(4), bottom: pt(0), trailing: 0))
            .frame(maxWidth: .infinity, alignment: .leading)
            .listRowBackground(Color.clear)
            .listRowInsets(rowInsets())
    }

    /// Volt; amber while paused; mint once the day is finished.
    private var titleColor: Color {
        workout.isPaused ? Theme.amber : workout.isDayFinished ? Theme.mint : Theme.volt
    }

    /// The Finished card's second line: "48 min · Hard 7", or "48 min · 342 kcal" without an effort.
    private var finishedDetail: String {
        guard let summary = workout.finishedSummary() else { return "" }
        var parts: [String] = []
        if let seconds = summary.duration { parts.append("\(max(1, Int((seconds / 60).rounded()))) min") }
        if let effort = summary.effort {
            parts.append("\(EffortBand(effort).word) \(effort)")
        } else if let kcal = summary.energy {
            parts.append("\(Int(kcal.rounded())) kcal")
        }
        return parts.joined(separator: " · ")
    }

    /// The list adds some room between rows of its own, so the insets are small: rows come out 4 pt apart.
    private func rowInsets(top: CGFloat = pt(-1.5), bottom: CGFloat = pt(-1.5)) -> EdgeInsets {
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

    /// Complication taps: spotme://start opens SpotMe where things are; spotme://today just opens today. It never
    /// starts a second session: a workout under way (a rest, a break or paused included) is picked up on the
    /// screen it was on, a finished day opens Today's Finished state, and only a day with nothing started
    /// starts.
    private func open(_ url: URL) {
        guard url.scheme == "spotme" else { return }
        path.removeAll()
        let running = workout.isRunning
        // A workout under way stays on its own day; going to today's would drop its screen.
        if !running { today.showToday() }
        switch OpenFromOutside.decide(isRunning: running, isFinished: workout.isDayFinished,
                                      isComplete: today.queue.isComplete, wantsStart: url.host == "start") {
        case .continueWorkout, .startToday:
            workout.startOrContinue()
            path = [.workout]
        case .showToday:
            break
        }
    }

    private var startProblemShown: Binding<Bool> {
        Binding(get: { workout.startProblem != nil }, set: { if !$0 { workout.startProblem = nil } })
    }
}

/// The day as one line, "WEDNESDAY · PUSH A", with the chevron that opens the days.
private struct DayLine: View {
    let day: PlanDay
    let isDeload: Bool
    let action: () -> Void

    var body: some View {
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
            .padding(.vertical, pt(-9))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Once the day is finished: how long it took and how hard it was. A tap opens the summary.
private struct FinishedCard: View {
    let detail: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: pt(7)) {
                Image(systemName: "checkmark")
                    .font(.system(size: pt(15), weight: .heavy))
                    .foregroundStyle(Theme.mint)
                    .frame(width: pt(26), height: pt(26))
                    .background(Circle().fill(Theme.mint.opacity(0.16)))
                VStack(alignment: .leading, spacing: 0) {
                    Text("Finished").role(.row)
                    Text(detail).role(.detail, Theme.text2).lineLimit(1).minimumScaleFactor(0.8)
                }
                Spacer(minLength: 0)
            }
            .padding(EdgeInsets(top: pt(7), leading: pt(10), bottom: pt(8), trailing: pt(10)))
            .frame(maxWidth: .infinity, alignment: .leading)
            .surface(radius: 17)
            .contentShape(Rectangle())
        }
        .buttonStyle(RowButtonStyle())
        .accessibilityLabel("Finished, \(detail)")
        .accessibilityHint("Shows the summary")
    }
}

/// After a Finish with items left: the same session carries on with them.
private struct StartAgainButton: View {
    let left: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Text("Start again")
                Text("\(left) left").role(.detail.weight(.bold), Theme.text2)
            }
        }
        .buttonStyle(NeutralButtonStyle(height: 54))
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
        VStack(spacing: pt(4)) {
            DayLine(day: day, isDeload: isDeload, action: action)
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
