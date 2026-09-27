import Foundation

/// Settings edited on the iPhone and sent to the watch.
public struct TrainingSettings: Codable, Hashable, Sendable {
    /// Day one of week one. Every `Plan.deloadEveryNthWeek`th week from here is a deload. nil: none scheduled.
    public var programStart: Date?
    /// When "This week is a deload" was switched on. It lapses when that week ends.
    public var manualDeloadSetOn: Date?
    /// Haptics at 10 seconds left and at the end of rest.
    public var restHaptics: Bool

    public init(programStart: Date? = nil, manualDeloadSetOn: Date? = nil, restHaptics: Bool = true) {
        self.programStart = programStart
        self.manualDeloadSetOn = manualDeloadSetOn
        self.restHaptics = restHaptics
    }

    /// 1-based program week containing `date`; nil without a start date or before it.
    public func programWeek(on date: Date, calendar: Calendar = .current) -> Int? {
        guard let programStart,
              let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: programStart),
                                                 to: calendar.startOfDay(for: date)).day,
              days >= 0 else { return nil }
        return days / 7 + 1
    }

    /// The manual toggle covers the program week it was set in (the calendar week without a start date).
    public func manualDeloadActive(on date: Date, calendar: Calendar = .current) -> Bool {
        guard let setOn = manualDeloadSetOn else { return false }
        if let week = programWeek(on: date, calendar: calendar),
           let setWeek = programWeek(on: setOn, calendar: calendar) {
            return week == setWeek
        }
        return calendar.isDate(date, equalTo: setOn, toGranularity: .weekOfYear)
    }

    /// Whole weeks until the next scheduled deload; 0 during one. nil without a start date.
    public func weeksUntilDeload(on date: Date, plan: Plan, calendar: Calendar = .current) -> Int? {
        guard plan.deloadEveryNthWeek > 0, let week = programWeek(on: date, calendar: calendar) else { return nil }
        let n = plan.deloadEveryNthWeek
        return (n - week % n) % n
    }

    public func isDeload(on date: Date, plan: Plan, calendar: Calendar = .current) -> Bool {
        if manualDeloadActive(on: date, calendar: calendar) { return true }
        guard let programStart else { return false }
        return plan.isDeloadWeek(programStart: programStart, today: date, calendar: calendar)
    }
}
