import Foundation

/// One of the ten things the body log measures. Weight is in kilograms, the rest in inches.
public enum BodyPoint: String, CaseIterable, Identifiable, Hashable, Sendable {
    case weight, neck, shoulders, chest, arm, forearm, waist, hips, thigh, calf

    public var id: String { rawValue }

    /// The measurement sheet's groups, in order: weight, upper body, core, legs.
    public enum Group: String, CaseIterable, Sendable {
        case weight, upperBody, core, legs

        public var title: String {
            switch self {
            case .weight: "Weight"
            case .upperBody: "Upper body"
            case .core: "Core"
            case .legs: "Legs"
            }
        }

        public var points: [BodyPoint] { BodyPoint.allCases.filter { $0.group == self } }
    }

    public var title: String {
        switch self {
        case .weight: "Weight"
        case .neck: "Neck"
        case .shoulders: "Shoulders"
        case .chest: "Chest"
        case .arm: "Arm (flexed)"
        case .forearm: "Forearm"
        case .waist: "Waist"
        case .hips: "Hips"
        case .thigh: "Thigh"
        case .calf: "Calf"
        }
    }

    public var group: Group {
        switch self {
        case .weight: .weight
        case .neck, .shoulders, .chest, .arm, .forearm: .upperBody
        case .waist, .hips: .core
        case .thigh, .calf: .legs
        }
    }

    public var isWeight: Bool { self == .weight }

    /// What one tap on the stepper adds: 0.1 kg, or a quarter inch.
    public var step: Double { isWeight ? 0.1 : 0.25 }

    /// The range a stepper and the starting value allow.
    public var range: ClosedRange<Double> {
        switch self {
        case .weight: 30...250
        case .neck: 8...30
        case .shoulders: 25...80
        case .chest: 25...80
        case .arm: 8...30
        case .forearm: 6...24
        case .waist: 20...70
        case .hips: 25...80
        case .thigh: 12...45
        case .calf: 8...30
        }
    }

    /// Where a new measurement starts when nothing was measured before.
    public var startValue: Double {
        switch self {
        case .weight: 70
        case .neck: 15
        case .shoulders: 44
        case .chest: 38
        case .arm: 14
        case .forearm: 11
        case .waist: 32
        case .hips: 36
        case .thigh: 22
        case .calf: 14
        }
    }

    /// "72.4 kg", "14.25″".
    public func format(_ value: Double) -> String {
        isWeight ? Format.kg(value) : Format.inches(value)
    }

    /// "+0.3", "+0.25″", "−0.5″", "±0″": a change with its sign (kilograms carry no unit here).
    public func formatChange(_ change: Double) -> String {
        guard isWeight else { return Format.inchesChange(change) }
        let rounded = (change * 10).rounded() / 10
        if rounded == 0 { return "±0" }
        return (rounded > 0 ? "+" : "−") + Format.weight(abs(rounded))
    }

    /// The waist is the one point where a rise is bad news; for the others a rise is what the muscle-gain phase
    /// wants.
    public var risingIsBad: Bool { self == .waist }
}

/// The body log's rules: measure every two weeks, and watch the waist against the arms. In a muscle-gain phase the
/// arms should grow; a waist growing while they don't means more fat than muscle.
public enum BodyLog {
    public struct Entry: Equatable, Sendable {
        public var date: Date
        /// Whatever was measured: kilograms for the weight, inches for the rest.
        public var values: [BodyPoint: Double]

        public init(date: Date, values: [BodyPoint: Double]) {
            self.date = date
            self.values = values.filter { $0.value > 0 }
        }

        public init(date: Date, arm: Double?, waist: Double?) {
            var values: [BodyPoint: Double] = [:]
            if let arm { values[.arm] = arm }
            if let waist { values[.waist] = waist }
            self.init(date: date, values: values)
        }

        public var arm: Double? { values[.arm] }
        public var waist: Double? { values[.waist] }
    }

    /// How the latest measurement of each point compares with an earlier one.
    public struct Change: Equatable, Sendable {
        /// The earlier measurement's date, for the whole log ("change since 22 Sep").
        public var since: Date
        /// Latest minus earlier, per point that has been measured at least twice.
        public var deltas: [BodyPoint: Double]

        public init(since: Date, deltas: [BodyPoint: Double]) {
            self.since = since
            self.deltas = deltas
        }

        public var arm: Double? { deltas[.arm] }
        public var waist: Double? { deltas[.waist] }

        /// The waist rule: waist up more than an inch while the arms haven't grown (under a quarter inch). Without
        /// both measured there is nothing to compare.
        public var waistWarning: Bool {
            guard let waist, let arm else { return false }
            return waist > 1 + 1e-9 && arm < 0.25 - 1e-9
        }
    }

    /// Days between measurements.
    public static let interval = 14

    /// The latest measurement of each point against the newest earlier one at least 12 days before it (about the two
    /// weeks the log asks for), or the one just before it if none is that old. nil with fewer than two measurements.
    public static func change(_ entries: [Entry], calendar: Calendar = .current) -> Change? {
        let sorted = entries.sorted { $0.date > $1.date }
        guard sorted.count > 1 else { return nil }
        func earlier(than index: Int, having point: BodyPoint?) -> Entry? {
            let later = sorted[index]
            let before = sorted.dropFirst(index + 1).filter { point == nil || $0.values[point!] != nil }
            return before.first { days(from: $0.date, to: later.date, calendar: calendar) >= 12 } ?? before.first
        }
        guard let overall = earlier(than: 0, having: nil) else { return nil }
        var deltas: [BodyPoint: Double] = [:]
        for point in BodyPoint.allCases {
            guard let index = sorted.firstIndex(where: { $0.values[point] != nil }),
                  let now = sorted[index].values[point],
                  let before = earlier(than: index, having: point)?.values[point] else { continue }
            deltas[point] = now - before
        }
        return Change(since: overall.date, deltas: deltas)
    }

    /// One point over time, oldest first.
    public static func series(_ entries: [Entry], point: BodyPoint) -> [(date: Date, value: Double)] {
        entries.sorted { $0.date < $1.date }.compactMap { entry in
            entry.values[point].map { (entry.date, $0) }
        }
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
        var values: [BodyPoint: Double] = [:]
        for point in BodyPoint.allCases {
            if let value = self[point] { values[point] = value }
        }
        return BodyLog.Entry(date: date, values: values)
    }

    public subscript(point: BodyPoint) -> Double? {
        get {
            switch point {
            case .weight: weight
            case .neck: neck
            case .shoulders: shoulders
            case .chest: chest
            case .arm: arm
            case .forearm: forearm
            case .waist: waist
            case .hips: hips
            case .thigh: thigh
            case .calf: calf
            }
        }
        set {
            switch point {
            case .weight: weight = newValue
            case .neck: neck = newValue
            case .shoulders: shoulders = newValue
            case .chest: chest = newValue
            case .arm: arm = newValue
            case .forearm: forearm = newValue
            case .waist: waist = newValue
            case .hips: hips = newValue
            case .thigh: thigh = newValue
            case .calf: calf = newValue
            }
        }
    }
}
