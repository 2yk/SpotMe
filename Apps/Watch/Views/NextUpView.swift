import SwiftUI
import RepCoachCore

/// Between exercises: a break that starts the next item by itself, what's next (tap it to pick another), and
/// how the last exercise went. With nothing left, the end of the day.
struct NextUpView: View {
    @Environment(TodayModel.self) private var today
    @Environment(WorkoutModel.self) private var workout
    @Environment(\.dimmed) private var dimmed
    let summaries: [ExerciseFlow.Summary]
    let onFinish: () -> Void
    @State private var choosing = false

    var body: some View {
        let next = today.queue.upNext
        if let first = next.first {
            let info = today.rowInfo(for: first)
            // Back to an exercise put off earlier: it says so, and picks up at its next set.
            let skippedEarlier = today.isWaiting(first)
            let figure = next.count == 1 ? ExerciseFigure.of(first) : nil
            ZStack(alignment: .top) {
                if let rest = workout.breakTime { EdgeCountdown(countdown: rest) }
                VStack(spacing: 0) {
                    countdown(role: skippedEarlier || figure != nil ? TextRole.breakTimer.size(36) : .breakTimer)
                    if skippedEarlier {
                        Text("Skipped earlier").role(.eyebrow, Theme.ice, single: true).padding(.top, pt(1))
                    }
                    if let figure {
                        // The figure moves beside the name and the target.
                        HStack(spacing: pt(7)) {
                            FigureView(exercise: figure, yaw: figure.figure.openingYaw, size: pt(62))
                            VStack(alignment: .leading, spacing: pt(1)) {
                                nameButton(next, alignment: .leading, lines: 3)
                                if skippedEarlier { resumeTarget(first) } else { target(info) }
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, pt(7))
                        .padding(.top, pt(2))
                    } else {
                        nameButton(next, alignment: .center, lines: 2)
                        if skippedEarlier { resumeTarget(first) } else { target(info) }
                    }
                    if let summary = summaries.first {
                        // How the exercise just finished went, e.g. "✓ All sets 10 · next time 22.5 kg".
                        HStack(alignment: .firstTextBaseline, spacing: pt(4)) {
                            Image(systemName: "checkmark").font(.system(size: pt(10), weight: .bold))
                            Text(summary.line.text)
                        }
                        .role(.small, summary.line.tone.color)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, pt(16))
                        .padding(.top, pt(3))
                        // Whatever space is left above the round buttons (4 pt clear): the lines that fit, cut
                        // with an ellipsis.
                        .frame(maxHeight: .infinity, alignment: .top)
                    }
                }
                .padding(.horizontal, Metrics.side)
                .padding(.top, figure == nil ? Metrics.top : Metrics.top - pt(6))
                .frame(height: Metrics.restControlsTop - pt(4), alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .overlay(alignment: .bottom) {
                RestControls(addTime: workout.breakTime != nil ? { workout.extendBreak(by: 30) } : nil,
                             undo: workout.canUndo ? { withAnimation(.snappy) { workout.undoLastSet() } } : nil,
                             endSymbol: "play.fill", endLabel: "Start \(first.name) now",
                             end: { workout.advance() })
            }
            .ignoresSafeArea()
            // The break waits while the list is open, so it can't move on underneath it.
            .sheet(isPresented: $choosing, onDismiss: workout.releaseBreak) {
                NextPicker { item in
                    today.promote(item)
                    choosing = false
                }
            }
            .onChange(of: choosing) { if choosing { workout.holdBreak() } }
            #if DEBUG
            .task { if LaunchOptions.screen == "next-picker" { choosing = true } }
            #endif
        } else {
            AllDoneView(summaries: summaries, onFinish: onFinish)
        }
    }

    /// The next item's name, with the chevron after its last word; a tap opens the list to pick another.
    private func nameButton(_ next: [PlanItem], alignment: HorizontalAlignment, lines: Int) -> some View {
        Button { choosing = true } label: {
            // The chevron follows the last word, wherever the name breaks.
            (Text(next.map(\.name).joined(separator: " + ")) + Text(" ")
                + Text(Image(systemName: "chevron.down")).font(.system(size: pt(11), weight: .bold))
                    .foregroundColor(Theme.text3))
                .role(alignment == .leading ? TextRole.title.size(14) : .title)
                .multilineTextAlignment(alignment == .leading ? .leading : .center)
                .lineLimit(lines)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, alignment == .leading ? 0 : pt(8))
                .frame(minHeight: pt(30))
        }
        .buttonStyle(.plain)
        .padding(.top, pt(2))
        .accessibilityLabel(next.map(\.name).joined(separator: " + "))
        .accessibilityHint("Pick another exercise to do next")
    }

    /// The time left; the big target for starting now, as well as the button at the bottom.
    @ViewBuilder
    private func countdown(role: TextRole) -> some View {
        if let rest = workout.breakTime {
            Button { workout.advance() } label: {
                CountdownDigits(countdown: rest, role: role)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Break before the next exercise")
            .accessibilityHint("Starts it now")
        } else {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: pt(40), weight: .bold))
                .foregroundStyle(Theme.mint)
                .frame(height: pt(48))
        }
    }

    /// "Set 2 of 3 · 17.5 kg": where a waiting exercise picks up.
    private func resumeTarget(_ item: PlanItem) -> some View {
        let parts = today.resumeLine(for: item).components(separatedBy: " · ")
        return HStack(spacing: pt(4)) {
            Text(parts[0]).foregroundStyle(Theme.text2)
            if parts.count > 1 {
                Text("·").foregroundStyle(Theme.text2)
                Text(parts[1]).role(TextRole(size: 13, line: 15, weight: .bold))
            }
        }
        .role(.detail.size(13).weight(.medium))
        .lineLimit(1)
        .padding(.top, pt(1))
    }

    /// "3 × 8–10 · ↑ 45 kg": the prescription, then today's weight with an arrow when it changed.
    private func target(_ info: RowInfo) -> some View {
        HStack(spacing: pt(4)) {
            Text(info.detail).foregroundStyle(Theme.text2)
            if info.weight != nil {
                Text("·").foregroundStyle(Theme.text2)
                RowWeight(info: info, size: 13)
            }
        }
        .role(.detail.size(13).weight(.medium))
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .padding(.top, pt(1))
    }
}

/// The other open items, to do one of them next instead.
private struct NextPicker: View {
    @Environment(TodayModel.self) private var today
    let onPick: (PlanItem) -> Void

    var body: some View {
        let upNext = Set(today.queue.upNext.map(\.exerciseId))
        ScrollView {
            VStack(spacing: pt(4)) {
                ForEach(today.day.items.filter { !today.status(of: $0).isFinished && !upNext.contains($0.exerciseId) }) { item in
                    Button { onPick(item) } label: { ItemRow(item: item) }
                        .buttonStyle(RowButtonStyle())
                }
            }
            .padding(.horizontal, Metrics.side)
            .padding(.top, Metrics.sheetTop)
            .padding(.bottom, Metrics.bottom)
        }
        .ignoresSafeArea()
        .topFade()
        .barTitle("Do next", close: true)
    }
}

/// The end of the day's plan: how the last exercise went, then Finish workout.
struct AllDoneView: View {
    @Environment(TodayModel.self) private var today
    @Environment(WorkoutModel.self) private var workout
    let summaries: [ExerciseFlow.Summary]
    let onFinish: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(spacing: pt(3)) {
            Spacer(minLength: 0)
            Image(systemName: "checkmark")
                .font(.system(size: pt(24), weight: .heavy))
                .foregroundStyle(Theme.mint)
                .frame(width: pt(44), height: pt(44))
                .background(Circle().fill(Theme.mint.opacity(0.16)))
                .symbolEffect(.bounce, value: appeared)
            Text("All \(today.queue.totalCount) done").role(.titleXL)
            if let last = summaries.last {
                Text(last.name).role(.small.weight(.bold)).lineLimit(1)
                Text(last.line.text)
                    .role(.small, last.line.tone.color)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, pt(8))
            }
            Spacer(minLength: 0)
            if workout.canFinish {
                Button("Finish workout", action: onFinish)
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .onAppear { appeared = true }
        .screenColumn()
    }
}
