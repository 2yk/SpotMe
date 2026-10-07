import Foundation

/// Where today's session stands, as the watch app tells its complication through the app group's defaults. The
/// complication can't read the app's store, so this is all it knows: Start workout before anything has been
/// done, the next item while the workout runs, Done once the day is finished.
public struct ComplicationState: Codable, Equatable, Sendable {
    public enum Phase: String, Codable, Sendable {
        case notStarted, running, finished
    }

    /// The calendar day it is for, "2026-10-07"; yesterday's state is no state.
    public var date: String
    public var phase: Phase
    /// While running: the open item up next ("Cable Lateral Raise", or a superset's "A + B").
    public var next: String?
    /// Items done (or skipped) and the day's items.
    public var done: Int
    public var total: Int

    public init(date: String, phase: Phase, next: String? = nil, done: Int = 0, total: Int = 0) {
        self.date = date
        self.phase = phase
        self.next = next
        self.done = done
        self.total = total
    }

    /// The app group the watch app and its complication share.
    public static let groupId = "group.com.yeshu.RepCoach"
    private static let key = "complicationState"

    public static var shared: UserDefaults? { UserDefaults(suiteName: groupId) }

    /// Stores the state. Returns whether it differs from what was stored, so the complication is only asked to
    /// redraw when it has something new to say.
    @discardableResult
    public func save(to defaults: UserDefaults? = ComplicationState.shared) -> Bool {
        guard let defaults else { return false }
        let old = Self.load(from: defaults, on: nil)
        guard old != self, let data = try? JSONEncoder().encode(self) else { return false }
        defaults.set(data, forKey: Self.key)
        return true
    }

    /// The stored state, when it is for `date` (any date when nil).
    public static func load(from defaults: UserDefaults? = ComplicationState.shared, on date: String?) -> ComplicationState? {
        guard let data = defaults?.data(forKey: key),
              let state = try? JSONDecoder().decode(Self.self, from: data) else { return nil }
        return date == nil || state.date == date ? state : nil
    }
}
