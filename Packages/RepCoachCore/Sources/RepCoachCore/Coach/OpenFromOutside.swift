import Foundation

/// What opening the watch app from outside does: the complication, the app icon, a Siri or Shortcuts entry.
/// It opens the app where things are, and never starts a second session.
public enum OpenFromOutside: Equatable, Sendable {
    /// A workout is under way (a rest, a break or paused included): back to the screen it was on, with the same
    /// clock and the same set. The day on show doesn't change.
    case continueWorkout
    /// Open Today on today's plan day and start there; only when nothing has been started today.
    case startToday
    /// Open Today on today's plan day and stop there: a finished day shows Finished (never Start again by
    /// itself), a rest day or a plain open just shows the list.
    case showToday

    /// - Parameters:
    ///   - isRunning: a Health workout is under way or a workout screen is on show.
    ///   - isFinished: the day on show (today's, unless a workout is running) was finished.
    ///   - isComplete: every item of that day is done or skipped.
    ///   - wantsStart: the tap was on the start link (a training day's complication), not a plain open.
    public static func decide(isRunning: Bool, isFinished: Bool, isComplete: Bool, wantsStart: Bool) -> OpenFromOutside {
        if isRunning { return .continueWorkout }
        if isFinished || isComplete || !wantsStart { return .showToday }
        return .startToday
    }
}
