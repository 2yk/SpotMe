import SwiftUI
import RepCoachCore

/// Rearrange days (board 9.6): the seven weekdays, each with its workout and a handle. Dragging a workout onto
/// another weekday swaps the two (a rest day is a workout too). The weekdays keep their names, and history stays
/// with the workout: only which weekday it stands on changes (`PlanEdits.schedule`), on this phone and on the
/// watch, which gets it with the other plan edits.
struct RearrangeDaysSheet: View {
    @Environment(AppModel.self) private var app
    @Environment(TodayModel.self) private var today
    @Environment(PhoneSync.self) private var sync
    @Environment(\.dismiss) private var dismiss
    /// The workout keys on the weekdays, Monday to Sunday, as the sheet has them now.
    @State private var order: [String] = []
    /// The row a drag is over.
    @State private var targeted: String?
    #if DEBUG
    /// `-lift saturday`: draws that weekday's row lifted, as on the board.
    private let lifted = UserDefaults.standard.string(forKey: "lift")
    #endif

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Drag a workout to another day. The days keep their names.")
                        .font(PhoneFont.foot)
                        .foregroundStyle(Theme.text3)
                        .padding(.horizontal, 6)
                    card
                    Text("History stays with the workout, whichever day it moves to.")
                        .font(PhoneFont.foot)
                        .foregroundStyle(Theme.text3)
                        .padding(.horizontal, 16)
                        .padding(.top, 0)
                }
                .padding(.horizontal, 16)
                .padding(.top, 76)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            SpotSheetBar(title: "Rearrange days", trailing: "Done", onLeading: { dismiss() }, onTrailing: apply)
        }
        .background(Theme.sheet)
        .sheetSurface()
        .onAppear {
            if order.isEmpty { order = today.planEdits.workoutKeys(in: app.plan) }
        }
    }

    // MARK: Rows

    private var card: some View {
        let slots = app.plan.days
        return VStack(spacing: 0) {
            ForEach(Array(slots.enumerated()), id: \.element.key) { index, slot in
                let key = order.indices.contains(index) ? order[index] : slot.key
                let workout = slots.first { $0.key == key } ?? slot
                row(index: index, weekday: slot.title, workout: workout.focus, key: key)
                if index < slots.count - 1 { DepthDivider(inset: 16) }
            }
        }
        .depthRows()
    }

    private func row(index: Int, weekday: String, workout: String, key: String) -> some View {
        #if DEBUG
        let isLifted = lifted.map { weekday.lowercased() == $0.lowercased() } ?? false
        #else
        let isLifted = false
        #endif
        return RearrangeRow(weekday: weekday, workout: workout, lifted: isLifted || targeted == key)
            .draggable(key) {
                RearrangeRow(weekday: weekday, workout: workout, lifted: true)
                    .frame(width: 408)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.raised))
            }
            .dropDestination(for: String.self) { keys, _ in
                guard let dragged = keys.first else { return false }
                swap(dragged, with: key)
                return true
            } isTargeted: { over in
                if over { targeted = key } else if targeted == key { targeted = nil }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(weekday): \(workout)")
            .accessibilityHint("Drag to another day to swap them")
            .accessibilityActions {
                ForEach(Array(app.plan.days.enumerated()), id: \.element.key) { other, day in
                    if other != index, order.indices.contains(other) {
                        Button("Swap with \(day.title)") { swap(key, with: order[other]) }
                    }
                }
            }
    }

    /// The workouts `dragged` and `other` trade weekdays.
    private func swap(_ dragged: String, with other: String) {
        targeted = nil
        guard dragged != other, let from = order.firstIndex(of: dragged), let to = order.firstIndex(of: other)
        else { return }
        withAnimation(.snappy) { order.swapAt(from, to) }
    }

    private func apply() {
        today.editPlan { $0.arrange(order, on: app.plan) }
        sync.sendContext()
        dismiss()
    }
}

/// A weekday and the workout on it, with the handle. Lifted (while dragged, or hovered by a drag) it is the board's
/// raised row.
private struct RearrangeRow: View {
    let weekday: String
    let workout: String
    var lifted = false

    var body: some View {
        HStack(spacing: 12) {
            Text(weekday)
                .font(PhoneFont.headline)
                .foregroundStyle(.white)
                .frame(width: 100, alignment: .leading)
            Text(workout)
                .font(PhoneFont.sub)
                .foregroundStyle(Theme.text2)
                .frame(maxWidth: .infinity, alignment: .leading)
            DragHandleIcon()
                .stroke(Theme.text3, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 20, height: 20)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(minHeight: 64)
        .background {
            if lifted {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.raised)
                    .shadow(color: .black.opacity(0.6), radius: 12, y: 8)
            }
        }
        .offset(y: lifted ? -6 : 0)
        .contentShape(Rectangle())
        .zIndex(lifted ? 1 : 0)
    }
}

/// The board's handle: two short lines (`M5 9h14M5 15h14` in a 24 pt box).
struct DragHandleIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for y in [9.0, 15.0] {
            path.move(to: CGPoint(x: rect.minX + rect.width * 5 / 24, y: rect.minY + rect.height * y / 24))
            path.addLine(to: CGPoint(x: rect.minX + rect.width * 19 / 24, y: rect.minY + rect.height * y / 24))
        }
        return path
    }
}
