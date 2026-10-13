import SwiftUI
import RepCoachCore

/// Edit mode of the Plan tab (board 9.2): one card with every exercise of the day, a red minus to take it off the
/// day and the system's handle to drag it. The list is the system's, so reordering is the system's too; each row
/// paints its own slice of the look B card behind it.
struct PlanEditList: View {
    @Environment(TodayModel.self) private var today
    @Environment(PhoneSync.self) private var sync
    /// The day as the user has it.
    let day: PlanDay
    /// The plan's own day, which edits are made against.
    let original: PlanDay

    var body: some View {
        let items = day.items
        List {
            Text("Drag to reorder")
                .depthEyebrow()
                .padding(.leading, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .moveDisabled(true)
                .accessibilityAddTraits(.isHeader)
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                EditRow(item: item, dayTitle: day.title) {
                    withAnimation { remove(item.exerciseId) }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(CardSlice(index: index, count: items.count))
                .listRowSeparator(.hidden)
            }
            .onMove(perform: move)
        }
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, 0)
        .environment(\.editMode, .constant(.active))
        .scrollContentBackground(.hidden)
        .padding(.horizontal, 16)
    }

    private func remove(_ exerciseId: String) {
        today.editPlan { $0.remove(exerciseId, from: original) }
        sync.sendContext()
    }

    private func move(_ source: IndexSet, to destination: Int) {
        var ids = day.items.map(\.exerciseId)
        ids.move(fromOffsets: source, toOffset: destination)
        today.editPlan { $0.setItemIds(ids, for: original) }
        sync.sendContext()
    }
}

private struct EditRow: View {
    let item: PlanItem
    let dayTitle: String
    let remove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: remove) {
                Image(systemName: "minus")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Theme.pulse))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .padding(-10)
            .accessibilityLabel("Remove \(item.name) from \(dayTitle)")
            VStack(alignment: .leading, spacing: 0) {
                Text(item.name)
                    .font(PhoneFont.headline)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Text(item.planLine(group: true))
                    .font(PhoneFont.sub)
                    .foregroundStyle(Theme.text2)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .padding(.vertical, 10)
        .frame(minHeight: 64)
    }
}

/// Row `index` of `count` in one look B card: its share of the gradient, the corners at the ends of the card, the lit
/// top edge on the first and a hairline under every row but the last.
struct CardSlice: View {
    let index: Int
    let count: Int
    var radius: CGFloat = 28

    var body: some View {
        let first = index == 0
        let last = index == count - 1
        let shape = UnevenRoundedRectangle(topLeadingRadius: first ? radius : 0,
                                           bottomLeadingRadius: last ? radius : 0,
                                           bottomTrailingRadius: last ? radius : 0,
                                           topTrailingRadius: first ? radius : 0, style: .continuous)
        shape
            .fill(LinearGradient(colors: [Self.shade(Double(index) / Double(max(count, 1))),
                                          Self.shade(Double(index + 1) / Double(max(count, 1)))],
                                 startPoint: .top, endPoint: .bottom))
            .overlay(alignment: .top) {
                if first {
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 1)
                        .mask(LinearGradient(colors: [.clear, .black, .black, .clear],
                                             startPoint: .leading, endPoint: .trailing))
                }
            }
            .overlay(alignment: .bottom) {
                if !last { DepthDivider(inset: 16) }
            }
            .clipShape(shape)
    }

    /// The card's gradient at `t` (0 top, 1 bottom).
    private static func shade(_ t: Double) -> Color {
        let top = (r: 0x26, g: 0x26, b: 0x2A), bottom = (r: 0x14, g: 0x14, b: 0x16)
        func mix(_ a: Int, _ b: Int) -> Double { (Double(a) + (Double(b) - Double(a)) * t) / 255 }
        return Color(red: mix(top.r, bottom.r), green: mix(top.g, bottom.g), blue: mix(top.b, bottom.b))
    }
}
