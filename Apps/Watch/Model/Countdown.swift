import Foundation

/// A rest between sets, or the break before the next item: counts down to `endsAt`, or holds while paused.
struct Countdown: Hashable {
    /// The whole length, for the ring. Adding time makes it longer.
    private(set) var duration: TimeInterval
    /// When it runs out; nil while paused.
    private(set) var endsAt: Date?
    /// What was left when it was paused.
    private var pausedLeft: TimeInterval = 0

    init(seconds: TimeInterval, from start: Date = .now) {
        duration = seconds
        endsAt = start.addingTimeInterval(seconds)
    }

    var isPaused: Bool { endsAt == nil }

    func left(at date: Date) -> TimeInterval {
        guard let endsAt else { return pausedLeft }
        return max(0, endsAt.timeIntervalSince(date))
    }

    /// 1 when it starts, 0 when it runs out.
    func progress(at date: Date) -> Double {
        duration > 0 ? min(1, left(at: date) / duration) : 0
    }

    mutating func add(_ seconds: TimeInterval) {
        duration += seconds
        if let endsAt {
            self.endsAt = endsAt.addingTimeInterval(seconds)
        } else {
            pausedLeft += seconds
        }
    }

    mutating func pause(at date: Date = .now) {
        guard endsAt != nil else { return }
        pausedLeft = left(at: date)
        endsAt = nil
    }

    /// Carries on with what was left, at least `minimum` seconds.
    mutating func resume(at date: Date = .now, minimum: TimeInterval = 0) {
        guard endsAt == nil else { return }
        let left = max(pausedLeft, minimum)
        duration = max(duration, left)
        endsAt = date.addingTimeInterval(left)
    }
}

/// Fires a countdown's haptics and its end. Scheduling again replaces what was scheduled; nothing fires while
/// the countdown is paused.
@MainActor
final class CountdownAlarm {
    private var tasks: [Task<Void, Never>] = []

    func schedule(_ countdown: Countdown, haptics: Bool, onEnd: @escaping @MainActor () -> Void) {
        cancel()
        guard let endsAt = countdown.endsAt else { return }
        let warning = endsAt.addingTimeInterval(-10)
        if haptics, warning > .now {
            tasks.append(Self.after(warning) { Haptics.play(.restWarning) })
        }
        tasks.append(Self.after(endsAt) {
            if haptics { Haptics.play(.restOver) }
            onEnd()
        })
    }

    func cancel() {
        tasks.forEach { $0.cancel() }
        tasks = []
    }

    /// Runs `action` at `date`, on the main actor, unless cancelled first.
    static func after(_ date: Date, _ action: @escaping @MainActor () -> Void) -> Task<Void, Never> {
        Task { @MainActor in
            let delay = date.timeIntervalSinceNow
            if delay > 0 { try? await Task.sleep(for: .seconds(delay)) }
            guard !Task.isCancelled else { return }
            action()
        }
    }
}
