import SwiftUI

/// One row of the design's type table: size / line height / weight, all in points on the 46 mm watch.
struct TextRole {
    var size: CGFloat
    var line: CGFloat
    var weight: Font.Weight
    var tracking: CGFloat = 0
    var capitals = false

    func size(_ size: CGFloat) -> TextRole {
        var copy = self
        copy.size = size
        return copy
    }

    func weight(_ weight: Font.Weight) -> TextRole {
        var copy = self
        copy.weight = weight
        return copy
    }

    static let timer = TextRole(size: 54, line: 52, weight: .heavy)
    static let value = TextRole(size: 36, line: 38, weight: .bold)
    static let valueSmall = TextRole(size: 28, line: 30, weight: .bold)
    static let valueWide = TextRole(size: 48, line: 50, weight: .bold)
    static let nextValue = TextRole(size: 28, line: 30, weight: .bold)
    /// The break's countdown: smaller than a rest's, to leave room for the next exercise.
    static let breakTimer = TextRole(size: 48, line: 48, weight: .heavy)
    static let titleXL = TextRole(size: 20, line: 22, weight: .heavy)
    static let title = TextRole(size: 17, line: 19, weight: .bold)
    static let button = TextRole(size: 17, line: 20, weight: .bold)
    static let row = TextRole(size: 15, line: 17, weight: .semibold)
    static let bar = TextRole(size: 15, line: 18, weight: .bold)
    static let detail = TextRole(size: 12, line: 15, weight: .medium)
    static let small = TextRole(size: 11, line: 14, weight: .semibold)
    static let eyebrow = TextRole(size: 10, line: 12, weight: .heavy, tracking: 0.6, capitals: true)
}

extension View {
    /// SF Rounded with tabular digits in `role`'s size and weight. A line is a little taller than its type, so
    /// the extra (or missing) height goes into the spacing between lines.
    /// - Parameter single: one line that is exactly the design's line height tall, so what's drawn under it sits
    ///   where the design puts it.
    func role(_ role: TextRole, _ color: Color = .white, single: Bool = false) -> some View {
        let size = pt(role.size)
        return font(.system(size: size, weight: role.weight, design: .rounded))
            .monospacedDigit()
            .tracking(role.tracking * size / 10)
            .textCase(role.capitals ? .uppercase : nil)
            .lineSpacing(pt(role.line) - size * 1.19)
            .foregroundStyle(color)
            .padding(.vertical, single ? (pt(role.line) - size * 1.19) / 2 : 0)
    }
}
