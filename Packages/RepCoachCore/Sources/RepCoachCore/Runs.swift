import Foundation

extension PlanItem {
    /// A run from the plan ("Run · NRC Recovery" and the like). Runs are logged in Nike Run Club.
    public var isRun: Bool {
        kind == .checklist && (group == "Run" || group.hasPrefix("Run ·"))
    }
}

extension PlanDay {
    /// The day without its run, in the items and in the words:
    /// "Recovery Run + Pull A · Strength & Thickness" → "Pull A · Strength & Thickness",
    /// "~30 min run + ~65 min gym" → "~65 min gym", "~70 min · no run" → "~70 min".
    public func withoutRuns() -> PlanDay {
        var day = self
        day.items.removeAll { $0.isRun }
        day.focus = Self.dropping(focus, at: " + ") { $0.hasSuffix("Run") }
        let mentionsRun = { (part: String) in
            part.range(of: #"\brun\b"#, options: [.regularExpression, .caseInsensitive]) != nil
        }
        day.time = Self.dropping(Self.dropping(time, at: " + ", where: mentionsRun), at: " · ", where: mentionsRun)
        return day
    }

    /// Drops the parts of `text` between `separator`s that `isRun` matches.
    /// Leaves `text` alone if nothing would be left.
    private static func dropping(_ text: String, at separator: String, where isRun: (String) -> Bool) -> String {
        let kept = text.components(separatedBy: separator).filter { !isRun($0) }
        return kept.isEmpty ? text : kept.joined(separator: separator)
    }
}

extension Plan {
    /// The plan as the apps show it: `plan.json` keeps the runs, the apps leave them to Nike Run Club.
    public func withoutRuns() -> Plan {
        var plan = self
        plan.days = days.map { $0.withoutRuns() }
        return plan
    }
}
