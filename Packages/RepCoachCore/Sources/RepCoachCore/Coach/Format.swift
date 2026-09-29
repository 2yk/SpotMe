import Foundation

/// Display strings shared by the watch and the phone. Weights are kg.
public enum Format {
    /// "22.5", "20", "6.25".
    public static func weight(_ kg: Double) -> String {
        let rounded = (kg * 100).rounded() / 100
        if rounded == rounded.rounded() { return String(Int(rounded)) }
        var text = String(format: "%.2f", rounded)
        while text.hasSuffix("0") { text.removeLast() }
        return text
    }

    /// "22.5 kg"
    public static func kg(_ kg: Double) -> String {
        "\(weight(kg)) kg"
    }

    /// "14.25″"
    public static func inches(_ inches: Double) -> String {
        "\(weight(inches))″"
    }

    /// "+0.5″", "−0.25″", "±0″": a change in inches, with its sign.
    public static func inchesChange(_ change: Double) -> String {
        let rounded = (change * 100).rounded() / 100
        if rounded == 0 { return "±0″" }
        return (rounded > 0 ? "+" : "−") + inches(abs(rounded))
    }

    /// "6–10", or "15" when both ends match.
    public static func range(_ low: Int, _ high: Int) -> String {
        low == high ? "\(low)" : "\(low)–\(high)"
    }

    /// "2:30"
    public static func clock(_ seconds: Int) -> String {
        let s = max(0, seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    /// Reps or seconds per set: "6–10", "8–10/side", "20–30s", "7". nil for checklist items and max-rep sets.
    public static func perSet(_ item: PlanItem, _ target: ItemTarget) -> String? {
        let side = item.perSide == true ? "/side" : ""
        if let low = target.secMin, let high = target.secMax { return range(low, high) + "s" + side }
        if let low = target.repMin, let high = target.repMax { return range(low, high) + side }
        return nil
    }

    /// A session's sets on one line: "25 kg × 10, 10, 9", "25×10, 22.5×12", "40s, 38s", "12, 12, 11".
    public static func sets(_ sets: [LoggedSet], timed: Bool = false) -> String {
        let counts = sets.map { timed ? "\($0.reps)s" : "\($0.reps)" }
        let weights = Set(sets.map(\.weight))
        guard let weight = weights.first, weight > 0 else { return counts.joined(separator: ", ") }
        if weights.count == 1 {
            return "\(kg(weight)) \(timed ? "·" : "×") " + counts.joined(separator: ", ")
        }
        return zip(sets, counts).map { "\(Format.weight($0.weight))×\($1)" }.joined(separator: ", ")
    }

    /// "4 × 6–10", "2 × 20s/side", "1 × max", "4 × 60%". Checklist items show their plan text ("30 min").
    public static func prescription(_ item: PlanItem, _ target: ItemTarget) -> String {
        switch item.kind {
        case .checklist:
            return item.display ?? ""
        case .amrap:
            return "\(target.sets) × max"
        case .percentOfMax where target.repMin == nil:
            return "\(target.sets) × \(Int(((item.percent ?? 0.6) * 100).rounded()))%"
        default:
            guard let perSet = perSet(item, target) else { return item.display ?? "" }
            return "\(target.sets) × \(perSet)"
        }
    }
}
