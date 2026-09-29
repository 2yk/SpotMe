import Foundation

/// How hard a session felt, 1 to 10, the way Apple's Workout and Fitness apps rate it (HealthKit's
/// `workoutEffortScore`). Stored on the session; the watch also saves it to Health.
public enum Effort {
    public static let range = 1...10

    public enum Level: CaseIterable, Sendable {
        case easy, moderate, hard, allOut

        /// "Easy", "Moderate", "Hard", "All Out".
        public var title: String {
            switch self {
            case .easy: "Easy"
            case .moderate: "Moderate"
            case .hard: "Hard"
            case .allOut: "All Out"
            }
        }
    }

    /// Easy 1–3, Moderate 4–6, Hard 7–9, All Out 10.
    public static func level(_ score: Int) -> Level {
        switch score {
        case ..<4: .easy
        case 4..<7: .moderate
        case 7..<10: .hard
        default: .allOut
        }
    }

    /// "7 · Hard"
    public static func text(_ score: Int) -> String {
        "\(score) · \(level(score).title)"
    }

    /// Anything outside 1–10 is left out.
    public static func valid(_ score: Int?) -> Int? {
        score.flatMap { range.contains($0) ? $0 : nil }
    }
}
