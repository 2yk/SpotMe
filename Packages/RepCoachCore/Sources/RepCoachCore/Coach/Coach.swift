import Foundation

/// One-line coaching messages. Only the wording lives here; every number comes from `ProgressionEngine`.
public enum Coach {
    public enum Tone: Sendable {
        case neutral, up, down, done
    }

    public struct Line: Equatable, Sendable {
        public var text: String
        public var tone: Tone

        public init(_ text: String, _ tone: Tone) {
            self.text = text
            self.tone = tone
        }
    }

    /// Between sets of a weighted exercise: "6 reps, below 8 · drop to 17.5 kg", "Too light · 22.5 kg next".
    public static func nextSet(_ next: NextSetTarget, reps: Int, repMin: Int, repMax: Int) -> Line {
        switch next.reason {
        case .dropWeight:
            Line("\(reps) reps, below \(repMin) · drop to \(Format.kg(next.weight))", .down)
        case .raiseWeight:
            Line("Too light · \(Format.kg(next.weight)) next", .up)
        case .keep where reps > repMax:
            Line("Above range · stay at \(Format.kg(next.weight))", .neutral)
        case .keep:
            Line("In range · stay at \(Format.kg(next.weight))", .neutral)
        }
    }

    /// Short tag for today's target: "+reps", "+2.5 kg", "lighter", "deload", "set weight".
    public static func tag(_ target: SessionTarget, increment: Double) -> String {
        switch target.reason {
        case .firstTime: "set weight"
        case .increase: "+\(Format.kg(increment))"
        case .repeatWeight: "+reps"
        case .decrease: "lighter"
        case .deload: "deload"
        }
    }

    /// Why today's target is what it is, in a sentence, for the phone's item detail.
    public static func explain(_ target: SessionTarget, increment: Double) -> String {
        switch target.reason {
        case .firstTime: "No history yet. Pick a starting weight on the watch."
        case .increase: "Every set hit the top of the range last time. Up \(Format.kg(increment))."
        case .repeatWeight: "Same weight as last time. Aim to beat its reps."
        case .decrease: "Two tough sessions in a row at this weight. Lighter, to build back up."
        case .deload: "Deload week: half the sets at about 85%."
        }
    }

    /// After the last set of a weighted exercise: "All sets 10 · next time 22.5 kg".
    /// - Parameters:
    ///   - today: the sets just logged.
    ///   - next: `ProgressionEngine.firstTarget` with today's sets at the front of the history.
    public static func weightedSummary(today: [LoggedSet], next: SessionTarget, prescription: Prescription,
                                       deload: Bool) -> Line {
        if deload {
            return Line("Deload logged · progression picks up next week", .done)
        }
        switch next.reason {
        case .increase:
            let reps = Set(today.prefix(prescription.sets).map(\.reps))
            let what = reps.count == 1 ? "All sets \(reps.first!)" : "Top of the range"
            return Line("\(what) · next time \(Format.kg(next.weight ?? 0))", .up)
        case .decrease:
            return Line("Two tough sessions · next time \(Format.kg(next.weight ?? 0))", .down)
        case .repeatWeight, .firstTime, .deload:
            if let weight = today.first?.weight,
               ProgressionEngine.isAtTop(today, weight: weight, p: prescription) {
                return Line("At the top · repeat it next time to go up", .up)
            }
            return Line("Same weight next time · aim for more reps", .neutral)
        }
    }

    /// After the last set of a `reps` or `timed` item.
    public static func rangeSummary(topReached: Bool, top: Int?, timed: Bool) -> Line {
        if topReached {
            return Line("Top of range. Add weight or make it harder next time.", .up)
        }
        guard let top else { return Line("Logged", .done) }
        return Line("Aim for \(top)\(timed ? "s" : " reps") on every set", .neutral)
    }

    /// After the max-rep set: "12 reps · volume sets of 7".
    public static func amrapSummary(reps: Int, volumeReps: Int) -> Line {
        Line("\(reps) reps · volume sets of \(volumeReps)", .up)
    }
}
