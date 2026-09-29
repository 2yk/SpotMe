import Foundation

/// Every logged set as CSV, for a spreadsheet: one row per set, oldest first.
public enum SetsCSV {
    public static let header = ["Date", "Time", "Day", "Exercise", "Exercise ID", "Set", "Weight (kg)", "Reps",
                                "Seconds", "Deload", "Skipped", "Effort (1-10)", "Session"]

    /// - Parameters:
    ///   - sessions: in any order; rows come out by session date, then the order items were started, then set.
    ///   - names: exercise names by exerciseId, as the user has them; an id without one is written as it is.
    ///   - dayTitles: plan day titles by dayKey ("Monday").
    public static func make(sessions: [WorkoutSession], names: [String: String], dayTitles: [String: String],
                            calendar: Calendar = .current) -> String {
        var rows = [header]
        for session in sessions.sorted(by: { $0.date < $1.date }) {
            for log in session.logs.sorted(by: { $0.order < $1.order }) {
                for set in log.orderedSets {
                    rows.append([
                        isoDay(set.timestamp, calendar: calendar),
                        time(set.timestamp, calendar: calendar),
                        dayTitles[session.dayKey] ?? session.dayKey,
                        names[log.exerciseId] ?? log.exerciseId,
                        log.exerciseId,
                        "\(set.index)",
                        Format.weight(set.weight),
                        set.seconds == nil ? "\(set.reps)" : "",
                        set.seconds.map { "\($0)" } ?? "",
                        session.isDeload ? "yes" : "",
                        log.skipped ? "yes" : "",
                        session.effort.map { "\($0)" } ?? "",
                        session.id.uuidString,
                    ])
                }
            }
        }
        return rows.map { $0.map(escape).joined(separator: ",") }.joined(separator: "\n") + "\n"
    }

    /// Quoted when it holds a comma, a quote or a line break, with quotes doubled.
    static func escape(_ field: String) -> String {
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0.isNewline }) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    /// "2026-09-28", in `calendar`'s time zone.
    private static func isoDay(_ date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    /// "06:42", 24-hour, in `calendar`'s time zone.
    private static func time(_ date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", parts.hour ?? 0, parts.minute ?? 0)
    }
}
