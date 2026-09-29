import SwiftUI
import RepCoachCore

/// Between exercises: a break that starts the next item by itself, what's next (tap it to pick another), and
/// how the last exercise went. With nothing left, the end of the day.
struct NextUpView: View {
    @Environment(TodayModel.self) private var today
    @Environment(WorkoutModel.self) private var workout
    let summaries: [ExerciseFlow.Summary]
    let onList: () -> Void
    let onFinish: () -> Void
    @State private var choosing = false

    var body: some View {
        let next = today.queue.upNext
        if let first = next.first {
            GeometryReader { geometry in
                // Room below the ring for four lines, clear of the buttons at the bottom.
                let ring = max(50, min(geometry.size.width * 0.52, geometry.size.height - 106))
                VStack(spacing: 3) {
                    countdown(size: ring)
                    Button { choosing = true } label: {
                        HStack(spacing: 3) {
                            Text(next.map(\.name).joined(separator: " + "))
                                .font(.rounded(.footnote, .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundStyle(Theme.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Pick another exercise to do next")
                    Text(today.detailLine(for: first))
                        .font(.rounded(.caption2, .medium))
                        .foregroundStyle(Theme.secondary)
                        .lineLimit(1)
                    if let summary = summaries.first {
                        // How the exercise just finished went, e.g. "✓ All sets 10 · next time 22.5 kg".
                        Text("\(Image(systemName: "checkmark")) \(summary.line.text)")
                            .font(.rounded(.caption2, .semibold))
                            .foregroundStyle(summary.line.tone.color)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    if workout.breakTime != nil {
                        Button { workout.extendBreak(by: 30) } label: {
                            Image(systemName: "goforward.30")
                        }
                        .accessibilityLabel("Add 30 seconds")
                    }
                    Spacer()
                    Button { workout.advance() } label: {
                        Image(systemName: "play.fill")
                    }
                    .accessibilityLabel("Start \(first.name) now")
                }
            }
            // The break waits while the list is open, so it can't move on underneath it.
            .sheet(isPresented: $choosing, onDismiss: workout.resumeBreak) {
                NextPicker { item in
                    today.promote(item)
                    choosing = false
                }
            }
            .onChange(of: choosing) { if choosing { workout.pauseBreak() } }
            #if DEBUG
            .task { if LaunchOptions.screen == "next-picker" { choosing = true } }
            #endif
        } else {
            AllDoneView(summaries: summaries, onFinish: onFinish, onList: onList)
        }
    }

    @ViewBuilder
    private func countdown(size: CGFloat) -> some View {
        if let rest = workout.breakTime {
            ZStack {
                TimelineView(.periodic(from: .now, by: 0.5)) { context in
                    ProgressRing(progress: rest.endsAt.timeIntervalSince(context.date) / rest.duration,
                                 tint: Theme.ice, lineWidth: 7)
                }
                VStack(spacing: -2) {
                    // The system timer text doesn't shrink to fit, so size it from the ring.
                    Text(timerInterval: Date.now...max(Date.now, rest.endsAt), countsDown: true)
                        .font(.number(min(32, size * 0.34)))
                        .monospacedDigit()
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                    Text("Next").eyebrow(Theme.ice, size: size < 64 ? 8 : 10)
                }
            }
            .frame(width: size, height: size)
        } else {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: min(44, size * 0.6), weight: .bold))
                .foregroundStyle(Theme.mint)
                .frame(width: size, height: size)
        }
    }
}

/// The other open items, to do one of them next instead.
private struct NextPicker: View {
    @Environment(TodayModel.self) private var today
    let onPick: (PlanItem) -> Void

    var body: some View {
        let upNext = Set(today.queue.upNext.map(\.exerciseId))
        List(today.day.items.filter { !today.status(of: $0).isFinished && !upNext.contains($0.exerciseId) }) { item in
            Button { onPick(item) } label: { ItemRow(item: item) }
        }
        .navigationTitle("Do next")
    }
}

/// The end of the day's plan: how the last exercise went, then Finish workout.
struct AllDoneView: View {
    @Environment(TodayModel.self) private var today
    @Environment(WorkoutModel.self) private var workout
    let summaries: [ExerciseFlow.Summary]
    let onFinish: () -> Void
    let onList: () -> Void
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(Theme.mint)
                    .symbolEffect(.bounce, value: appeared)
                Text("All \(today.queue.totalCount) done").font(.rounded(.title3, .bold))
                ForEach(summaries) { summary in
                    VStack(spacing: 1) {
                        Text(summary.name)
                            .font(.rounded(.footnote, .bold))
                        Text(summary.line.text)
                            .font(.rounded(.caption2, .semibold))
                            .foregroundStyle(summary.line.tone.color)
                    }
                    .multilineTextAlignment(.center)
                }
                if workout.canFinish {
                    Button("Finish workout", action: onFinish)
                        .buttonStyle(PrimaryButtonStyle(tint: Theme.mint))
                        .padding(.top, 4)
                }
                Button("Back to list", action: onList)
                    .buttonStyle(.plain)
                    .font(.rounded(.footnote, .semibold))
                    .foregroundStyle(Theme.secondary)
            }
        }
        .navigationTitle("")
        .onAppear { appeared = true }
    }
}
