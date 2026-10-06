import SwiftUI
import RepCoachCore

/// The edge timer of a countdown, drawn from the same clock as `CountdownDigits`. Redrawn 15 times a second on
/// screen and on each whole second with the wrist down (Always On).
struct EdgeCountdown: View {
    let countdown: Countdown
    var tint = Theme.ice
    @Environment(\.dimmed) private var dimmed

    var body: some View {
        TimelineView(CountdownSchedule(countdown: countdown)) { context in
            EdgeTimer(left: countdown.progress(at: context.date), tint: tint,
                      state: dimmed ? .alwaysOn : countdown.isPaused ? .paused : .normal)
        }
        // A new schedule for every change (more time, a pause), so the line never runs on an old one.
        .id(countdown)
    }
}

/// The time left in a countdown, as "1:48". Grey while paused or with the wrist down.
struct CountdownDigits: View {
    let countdown: Countdown
    var role = TextRole.timer
    @Environment(\.dimmed) private var dimmed

    var body: some View {
        TimelineView(CountdownSchedule(countdown: countdown)) { context in
            Text(Format.clock(Int(countdown.left(at: context.date).rounded(.up))))
                .role(role, countdown.isPaused || dimmed ? Theme.text2 : .white, single: true)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .accessibilityIdentifier("countdown")
        }
        .id(countdown)
    }
}

/// Entries for a countdown: 15 a second on screen, every whole second in Always On (the fastest it allows),
/// lined up with the seconds so the number changes on time. None while paused or once it has run out.
struct CountdownSchedule: TimelineSchedule {
    let countdown: Countdown

    func entries(from start: Date, mode: TimelineScheduleMode) -> AnyIterator<Date> {
        guard let end = countdown.endsAt, end > start else {
            return AnyIterator([start].makeIterator())
        }
        let perSecond: Double = mode == .lowFrequency ? 1 : 15
        // After `start` itself, ticks at end - k/perSecond from the first one after it down to the end.
        var k = (end.timeIntervalSince(start) * perSecond).rounded(.up) - 1
        var first = true
        return AnyIterator {
            if first {
                first = false
                return start
            }
            guard k >= 0 else { return nil }
            defer { k -= 1 }
            return end.addingTimeInterval(-k / perSecond)
        }
    }
}

/// Entries for a timer counting up from `start`: 15 a second on screen, every whole second in Always On, lined
/// up with the seconds since `start`. Just one while there's nothing to count.
struct CountUpSchedule: TimelineSchedule {
    let start: Date?

    func entries(from date: Date, mode: TimelineScheduleMode) -> AnyIterator<Date> {
        guard let start else { return AnyIterator([date].makeIterator()) }
        let perSecond: Double = mode == .lowFrequency ? 1 : 15
        var k = (date.timeIntervalSince(start) * perSecond).rounded(.down) + 1
        var first = true
        return AnyIterator {
            if first {
                first = false
                return date
            }
            defer { k += 1 }
            return start.addingTimeInterval(k / perSecond)
        }
    }
}
