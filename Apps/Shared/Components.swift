import SwiftUI
import RepCoachCore

/// A small filled capsule: "+reps", "Set 3/5", "Deload".
struct Chip: View {
    let text: String
    let tint: Color
    var size: CGFloat = 11

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .heavy, design: .rounded))
            .foregroundStyle(.black)
            .padding(.horizontal, size * 0.55)
            .padding(.vertical, size * 0.2)
            .background(Capsule().fill(tint))
            .fixedSize()
    }
}

/// The round icon in front of an item: its kind, or a checkmark once it's done.
struct ItemBadge: View {
    let item: PlanItem
    var status: ItemStatus = .pending
    var size: CGFloat = 28

    var body: some View {
        let (symbol, tint): (String, Color) = switch status {
        case .done: ("checkmark", Theme.mint)
        case .skipped: ("forward.fill", Theme.tertiary)
        case .pending, .inProgress: (item.symbol, item.tint)
        }
        Image(systemName: symbol)
            .font(.system(size: size * 0.43, weight: .bold))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(Circle().fill(tint.opacity(0.17)))
    }
}
