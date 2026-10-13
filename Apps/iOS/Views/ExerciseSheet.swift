import SwiftUI
import RepCoachCore

/// What a tap on an open row on Today opens.
struct SlotRef: Identifiable, Hashable {
    /// The plan's exercise of the slot: stays the same when the exercise in it is swapped.
    let id: String
}

/// One exercise (boards 7.5, 7.7): the figure, the name, today's target, how it has gone, Swap, last time and the
/// note. A tick-off item gets its steps instead (7.6).
struct ExerciseSheet: View {
    @Environment(TodayModel.self) private var today
    @Environment(\.modelContext) private var context
    let slotId: String
    @State private var swapping = false
    @State private var path: [String] = []

    init(slotId: String) {
        self.slotId = slotId
        #if DEBUG
        _swapping = State(initialValue: LaunchOptions.screen == "swap")
        #endif
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .topTrailing) {
                if let item = today.item(inSlot: slotId) {
                    if item.kind == .checklist {
                        TickOffContent(item: item)
                    } else {
                        content(item)
                    }
                }
                SheetCloseButton()
                    .padding(.trailing, 12)
                    .padding(.top, 20)
            }
            .background(Theme.sheet)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: String.self) { exerciseId in
                if let item = today.item(inSlot: slotId), item.exerciseId == exerciseId {
                    let exercise = HistoryModel.exercise(for: item, dayTitle: today.day.title, context: context)
                    ExerciseHistoryScreen(exercise: exercise)
                }
            }
        }
        .sheet(isPresented: $swapping) { SwapSheet(slotId: slotId) }
        .sheetSurface()
    }

    private func content(_ item: PlanItem) -> some View {
        let target = today.target(for: item)
        let entries = (try? today.history.entries(for: item.exerciseId, excluding: today.session?.id)) ?? []
        let progress = TopSet.series(entries, kind: item.kind)
        let figure = ExerciseFigure.of(item)
        return ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let figure {
                    FigureView(exercise: figure, yaw: figure.figure.openingYaw, size: 220)
                        .frame(maxWidth: .infinity)
                        .frame(height: 236)
                        .depthCard()
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.group).depthEyebrow()
                    Text(item.name).font(PhoneFont.title)
                }
                .padding(.horizontal, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                tiles(item, target)
                if !progress.isEmpty { progressCard(item, progress) }
                if today.canSwap(item) { swapRow }
                if let last = entries.first { lastTime(item, last) }
                if let note = item.note ?? figure?.cue {
                    Text(note)
                        .font(PhoneFont.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .depthCard()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 76)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
    }

    private func tiles(_ item: PlanItem, _ target: ItemTarget) -> some View {
        HStack(spacing: 8) {
            DepthTile(label: "Sets", value: "\(target.sets)")
            DepthTile(label: item.kind == .timed ? "Seconds" : "Reps", value: Format.perSet(item, target) ?? "max")
            if item.takesWeight {
                let direction = TargetDirection(target)
                DepthTile(label: "Weight", value: target.weight.map(Format.weight) ?? "—", unit: "kg",
                          tint: direction.color ?? .white, arrow: direction.arrow)
            } else if let rest = item.restSec {
                DepthTile(label: "Rest", value: Format.clock(rest))
            }
        }
    }

    private func progressCard(_ item: PlanItem, _ points: [TopSet]) -> some View {
        Button {
            path.append(item.exerciseId)
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Progress").depthEyebrow(Theme.volt)
                    Spacer()
                    Text(points.count == 1 ? "Last session" : "Last \(points.count) sessions")
                        .font(PhoneFont.foot)
                        .foregroundStyle(Theme.text3)
                }
                TopSetChart(points: points)
            }
            .padding(18)
            .depthCard()
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens this exercise's history")
    }

    private var swapRow: some View {
        Button { swapping = true } label: {
            HStack(spacing: 12) {
                SwapIcon(size: 22, color: Theme.volt)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Swap exercise").font(PhoneFont.headline).foregroundStyle(Theme.volt)
                    Text("For today. Your watch changes with it.")
                        .font(PhoneFont.sub)
                        .foregroundStyle(Theme.text2)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(RowPressStyle())
        .depthRows()
    }

    private func lastTime(_ item: PlanItem, _ last: HistoryEntry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("Last time").depthEyebrow()
                Spacer()
                Text(last.date.weekdayDayMonth)
                    .font(PhoneFont.foot)
                    .foregroundStyle(Theme.text3)
            }
            Text(Format.sets(last.sets, timed: item.kind == .timed))
                .font(PhoneFont.headline)
        }
        .padding(18)
        .depthCard()
    }
}

/// Which way today's weight goes from the last one: the engine's own reason for the target.
struct TargetDirection {
    enum Way { case up, down }
    let way: Way?

    init(_ target: ItemTarget) {
        switch target.session?.reason {
        case .increase: way = .up
        case .decrease, .deload: way = .down
        default: way = nil
        }
    }

    var color: Color? {
        switch way {
        case .up: Theme.volt
        case .down: Theme.ember
        case nil: nil
        }
    }

    var arrow: String? {
        switch way {
        case .up: "arrow.up"
        case .down: "arrow.down"
        case nil: nil
        }
    }
}

/// A target number in a glass tile: "SETS 3", "WEIGHT ↑ 45 kg".
struct DepthTile: View {
    let label: String
    let value: String
    var unit: String?
    var tint: Color = .white
    /// An SF symbol before the value.
    var arrow: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).depthEyebrow()
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                if let arrow {
                    Image(systemName: arrow)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(tint)
                        .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 3 }
                }
                Text(value)
                    .font(PhoneFont.number)
                    .foregroundStyle(tint)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if let unit {
                    Text(unit)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.text2)
                        .padding(.leading, 2)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassTile()
    }
}

/// A tick-off item (board 7.6): its steps, numbered, and Done.
struct TickOffContent: View {
    @Environment(TodayModel.self) private var today
    @Environment(\.dismiss) private var dismiss
    let item: PlanItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.group).depthEyebrow()
                    Text(item.name).font(PhoneFont.title)
                }
                .padding(.horizontal, 6)
                .frame(maxWidth: .infinity, alignment: .leading)

                if let steps = item.steps, !steps.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                                    .foregroundStyle(Theme.volt)
                                    .frame(width: 20, alignment: .leading)
                                Text(step)
                                    .font(PhoneFont.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            if index < steps.count - 1 { DepthDivider(inset: 48) }
                        }
                    }
                    .depthRows()
                } else if let note = item.note {
                    Text(note)
                        .font(PhoneFont.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .depthCard()
                }

                if !today.status(of: item).isFinished {
                    Button("Done") {
                        today.complete(item)
                        dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 76)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
    }
}
