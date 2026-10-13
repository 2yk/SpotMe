import SwiftUI
import RepCoachCore

/// Swap, from the exercise sheet (board 7.8): the exercises that can take the item's place for today, each with
/// why it fits. One tap swaps, takes the sheet away and leaves the exercise sheet showing the new exercise; the
/// watch gets it at once.
struct SwapSheet: View {
    @Environment(TodayModel.self) private var today
    @Environment(\.dismiss) private var dismiss
    /// The plan's exercise the item stands in for: stays the same through a swap.
    let slotId: String

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let item = today.item(inSlot: slotId) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        header(item)
                        choices(item)
                        Text("For today only. It takes these sets and reps and keeps its own history. Your watch updates right away.")
                            .font(PhoneFont.foot)
                            .foregroundStyle(Theme.text3)
                            .padding(.horizontal, 6)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 76)
                    .padding(.bottom, 32)
                }
                .scrollIndicators(.hidden)
            }
            SheetCloseButton()
                .padding(.trailing, 12)
                .padding(.top, 20)
        }
        .background(Theme.sheet)
        .sheetSurface()
    }

    private func header(_ item: PlanItem) -> some View {
        let target = today.target(for: item)
        var line = Format.prescription(item, target)
        if let rest = item.restSec { line += " · \(Format.clock(rest)) rest" }
        return VStack(alignment: .leading, spacing: 4) {
            Text("Swap · Today").depthEyebrow()
            Text(item.name).font(PhoneFont.title)
            Text(line).font(PhoneFont.sub).foregroundStyle(Theme.text2)
        }
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func choices(_ item: PlanItem) -> some View {
        let choices = today.swapChoices(for: item)
        // The 44 pt slot is there for every row once any of them has a figure, so the names line up.
        let figures = choices.contains { ExerciseFigure.of(exerciseId: $0.id) != nil }
        return VStack(alignment: .leading, spacing: 8) {
            Text("Same movement, your equipment")
                .depthEyebrow()
                .padding(.leading, 6)
            VStack(spacing: 0) {
                ForEach(choices) { choice in
                    Button {
                        today.swap(item, to: choice)
                        dismiss()
                    } label: { row(choice, figures: figures) }
                        .buttonStyle(RowPressStyle())
                    if choice.id != choices.last?.id { DepthDivider(inset: 16) }
                }
            }
            .depthRows()
        }
    }

    private func row(_ choice: SwapChoice, figures: Bool) -> some View {
        HStack(spacing: 12) {
            if figures { ChoiceFigure(exerciseId: choice.id) }
            VStack(alignment: .leading, spacing: 0) {
                Text(choice.name)
                    .font(PhoneFont.headline)
                    .foregroundStyle(.white)
                Text(choice.why)
                    .font(PhoneFont.sub)
                    .foregroundStyle(Theme.text2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if choice.takeCare { Chip(text: "TAKE CARE", tint: Theme.ember, size: 11) }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(minHeight: 64)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint(choice.isOriginal ? "Takes the swap back" : "Swaps it in for today")
    }
}

extension TodayModel {
    /// The item on today's list that stands in the plan's slot `slotId`: the exercise itself, or the one swapped
    /// into its place.
    func item(inSlot slotId: String) -> PlanItem? {
        day.items.first { slot(of: $0).exerciseId == slotId }
    }
}

/// The 44 pt still of a swap choice, by its database id; the slot stays empty without a figure.
private struct ChoiceFigure: View {
    let exerciseId: String

    var body: some View {
        Group {
            if let figure = ExerciseFigure.of(exerciseId: exerciseId) {
                FigureView(exercise: figure, yaw: figure.figure.openingYaw, size: 44, moving: false)
            } else {
                Color.clear
            }
        }
        .frame(width: 44, height: 44)
        .accessibilityHidden(true)
    }
}
