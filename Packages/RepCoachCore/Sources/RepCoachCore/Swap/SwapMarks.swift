import Foundation

/// One swap for one day: `slot` (a plan exercise) is `exercise` today. `exercise == slot` takes the swap back.
public struct SwapMark: Codable, Hashable, Sendable {
    /// The plan day, "wednesday".
    public var dayKey: String
    /// The calendar date, "2026-10-07": a swap is for that day only.
    public var date: String
    /// The plan's exerciseId.
    public var slot: String
    /// The exerciseId standing in for it.
    public var exercise: String
    /// When it was made; the later mark for a slot wins, on either device.
    public var at: Date

    public init(dayKey: String, date: String, slot: String, exercise: String, at: Date = .now) {
        self.dayKey = dayKey
        self.date = date
        self.slot = slot
        self.exercise = exercise
        self.at = at
    }

    var key: String { "\(dayKey)|\(date)|\(slot)" }
}

/// Today's swaps, as both devices keep them: the later mark for each slot wins, so a swap made on the watch and
/// one made on the phone settle on the same answer whichever arrives first. Travels whole, over `sendMessage`
/// when the other device is reachable and in the application context otherwise.
public struct SwapMarks: Codable, Equatable, Sendable {
    public private(set) var marks: [SwapMark]

    public init(marks: [SwapMark] = []) {
        self.marks = marks
    }

    public var isEmpty: Bool { marks.isEmpty }

    /// "2026-10-07", in `calendar`'s time zone.
    public static func stamp(_ date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    /// The swaps in force for that day: slot → the exercise standing in for it. Slots taken back are absent.
    public func swaps(dayKey: String, date: String) -> [String: String] {
        var result: [String: String] = [:]
        for mark in marks where mark.dayKey == dayKey && mark.date == date && mark.exercise != mark.slot {
            result[mark.slot] = mark.exercise
        }
        return result
    }

    /// Records a mark; it replaces an earlier one for the same slot and day, never a later one. Returns whether
    /// anything changed.
    @discardableResult
    public mutating func record(_ mark: SwapMark) -> Bool {
        if let index = marks.firstIndex(where: { $0.key == mark.key }) {
            guard marks[index].at < mark.at else { return false }
            marks[index] = mark
        } else {
            marks.append(mark)
        }
        return true
    }

    /// Folds in the other device's marks. Returns whether anything changed.
    @discardableResult
    public mutating func merge(_ other: SwapMarks) -> Bool {
        var changed = false
        for mark in other.marks where record(mark) { changed = true }
        return changed
    }

    /// Drops marks for days before `date` (a swap is for one day).
    public mutating func prune(before date: String) {
        marks.removeAll { $0.date < date }
    }

    /// Takes back every swap of that day: the slots stay marked, as taken back, so the other device clears
    /// them too.
    public mutating func clear(dayKey: String, date: String, at: Date = .now) {
        for mark in marks where mark.dayKey == dayKey && mark.date == date && mark.exercise != mark.slot {
            record(SwapMark(dayKey: dayKey, date: date, slot: mark.slot, exercise: mark.slot, at: at))
        }
    }

    // MARK: Storing and sending

    private static let defaultsKey = "swapMarks"

    public static func load(from defaults: UserDefaults) -> SwapMarks {
        defaults.data(forKey: defaultsKey).flatMap { try? JSONDecoder().decode(SwapMarks.self, from: $0) }
            ?? SwapMarks()
    }

    public func save(to defaults: UserDefaults) {
        if let data = try? JSONEncoder().encode(self) { defaults.set(data, forKey: Self.defaultsKey) }
    }

    /// The `sendMessage` payload.
    public var message: [String: Any] {
        guard let data = try? JSONEncoder().encode(self) else { return [:] }
        return [Self.messageKey: data]
    }

    public init?(message: [String: Any]) {
        guard let data = message[Self.messageKey] as? Data,
              let marks = try? JSONDecoder().decode(Self.self, from: data) else { return nil }
        self = marks
    }

    static let messageKey = "swapMarks"
}
