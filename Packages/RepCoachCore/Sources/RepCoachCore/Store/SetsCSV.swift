import Foundation

/// Every logged set as CSV, for a spreadsheet: one row per set, oldest first. Ramp-up sets are listed, marked in
/// the Ramp-up column; "Set" is the order performed in the exercise, ramp-ups included. Effort (1 to 10, when
/// it was given) is on every row of its session.
public enum SetsCSV {
    public static let header = ["Date", "Time", "Day", "Exercise", "Exercise ID", "Set", "Weight (kg)", "Reps",
                                "Seconds", "Deload", "Skipped", "Session", "Ramp-up", "Effort"]

    /// - Parameters:
    ///   - sessions: in any order; rows come out by session date, then the order items were started, then set.
    ///   - names: exercise names by exerciseId, as the user has them; an id without one is written as it is.
    ///   - calendar: reads the date, the time and the weekday of each session. The Day column is the weekday the
    ///     session was done on, from its own date: moving a workout to another weekday (Rearrange days) never
    ///     relabels the sessions already done.
    public static func make(sessions: [WorkoutSession], names: [String: String],
                            calendar: Calendar = .current) -> String {
        var rows = [header]
        for session in sessions.sorted(by: { $0.date < $1.date }) {
            for log in session.logs.sorted(by: { $0.order < $1.order }) {
                for set in log.orderedSets {
                    rows.append([
                        isoDay(set.timestamp, calendar: calendar),
                        time(set.timestamp, calendar: calendar),
                        weekday(of: session.date, calendar: calendar),
                        names[log.exerciseId] ?? log.exerciseId,
                        log.exerciseId,
                        "\(set.index)",
                        Format.weight(set.weight),
                        set.seconds == nil ? "\(set.reps)" : "",
                        set.seconds.map { "\($0)" } ?? "",
                        session.isDeload ? "yes" : "",
                        log.skipped ? "yes" : "",
                        session.id.uuidString,
                        set.isRampUp ? "yes" : "",
                        session.effort.map { "\($0)" } ?? "",
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

    /// "Monday", in English and in `calendar`'s time zone, whatever the phone's language.
    static func weekday(of date: Date, calendar: Calendar) -> String {
        let names = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return names[(calendar.component(.weekday, from: date) - 1 + 7) % 7]
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
