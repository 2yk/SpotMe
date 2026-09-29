import Foundation

/// The body log's rules: measure the flexed arm and the waist every two weeks, and watch the waist against the
/// arms. In a muscle-gain phase the arms should grow; a waist growing while they don't means more fat than
/// muscle.
public enum BodyLog {
    public struct Entry: Equatable, Sendable {
        public var date: Date
        /// Inches.
        public var arm: Double
        public var waist: Double

        public init(date: Date, arm: Double, waist: Double) {
            self.date = date
            self.arm = arm
            self.waist = waist
        }
    }

    /// How the latest measurement compares with an earlier one.
    public struct Change: Equatable, Sendable {
        /// The earlier measurement's date.
        public var since: Date
        /// Inches, latest minus earlier.
        public var arm: Double
        public var waist: Double

        /// The waist rule: waist up more than an inch while the arms haven't grown (under a quarter inch).
        public var waistWarning: Bool {
            waist > 1 + 1e-9 && arm < 0.25 - 1e-9
        }
    }

    /// Days between measurements.
    public static let interval = 14

    /// The latest measurement against the newest one at least 12 days before it (about the two weeks the log
    /// asks for), or the one just before it if none is that old. nil with fewer than two.
    public static func change(_ entries: [Entry], calendar: Calendar = .current) -> Change? {
        let sorted = entries.sorted { $0.date > $1.date }
        guard let latest = sorted.first, sorted.count > 1 else { return nil }
        let earlier = sorted.dropFirst().first { days(from: $0.date, to: latest.date, calendar: calendar) >= 12 }
            ?? sorted[1]
        return Change(since: earlier.date, arm: latest.arm - earlier.arm, waist: latest.waist - earlier.waist)
    }

    /// Nothing measured yet, or the last measurement is two weeks old.
    public static func isDue(_ entries: [Entry], on date: Date = .now, calendar: Calendar = .current) -> Bool {
        guard let last = entries.map(\.date).max() else { return true }
        return days(from: last, to: date, calendar: calendar) >= interval
    }

    private static func days(from start: Date, to end: Date, calendar: Calendar) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: end)).day ?? 0
    }
}

extension BodyMeasurement {
    public var entry: BodyLog.Entry {
        BodyLog.Entry(date: date, arm: arm, waist: waist)
    }
}
