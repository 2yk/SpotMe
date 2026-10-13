import RepCoachCore

extension PlanDay {
    /// "Push A": the day's focus before its " · ".
    var headline: String {
        focus.components(separatedBy: " · ")[0]
    }

    /// "Chest & Shoulders + Core A": what's after it, or the plan's time when the focus has nothing more.
    var subtitle: String {
        let parts = focus.components(separatedBy: " · ")
        return parts.count > 1 ? parts.dropFirst().joined(separator: " · ") : time
    }
}
