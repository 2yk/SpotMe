#if DEBUG
import SwiftUI
import RepCoachCore

/// Screenshots only: the Start workout complication's slots for a training day, Sunday and a rest day, or
/// (`-screen complications-states`) where the session stands: Start workout, the next item, Done.
/// The watch face draws the real ones; this is as close as the app gets.
struct ComplicationGallery: View {
    @Environment(TodayModel.self) private var today

    var body: some View {
        let monday = TodayEntry(date: .now, day: today.plan.day(forWeekday: 2))
        let sunday = TodayEntry(date: .now, day: today.plan.day(forWeekday: 1))
        let saturday = TodayEntry(date: .now, day: today.plan.day(forWeekday: 7))
        let wednesday = today.plan.day(forWeekday: 4)
        let stamp = SwapMarks.stamp(.now)
        let start = TodayEntry(date: .now, day: wednesday, state: ComplicationState(date: stamp, phase: .notStarted))
        let running = TodayEntry(date: .now, day: wednesday, state: ComplicationState(
            date: stamp, phase: .running, next: "Cable Lateral Raise", done: 4, total: 15))
        let finished = TodayEntry(date: .now, day: wednesday, state: ComplicationState(
            date: stamp, phase: .finished, done: 12, total: 15))
        ScrollView {
            if LaunchOptions.screen == "complications-states" {
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        ForEach([start, running, finished], id: \.phase) { entry in
                            StartCircular(entry: entry).frame(width: 50, height: 50)
                        }
                    }
                    StartRectangular(entry: start).frame(height: 56)
                    StartRectangular(entry: running).frame(height: 56)
                    StartRectangular(entry: finished).frame(height: 56)
                    StartInline(entry: running).font(.system(size: 13, weight: .semibold))
                    StartInline(entry: finished).font(.system(size: 13, weight: .semibold))
                }
                .padding(.horizontal, 4)
            } else {
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        ForEach([monday, sunday, saturday], id: \.badge) { entry in
                            StartCircular(entry: entry).frame(width: 50, height: 50)
                        }
                    }
                    StartRectangular(entry: monday).frame(height: 56)
                    StartRectangular(entry: saturday).frame(height: 56)
                    StartInline(entry: monday).font(.system(size: 13, weight: .semibold))
                }
                .padding(.horizontal, 4)
            }
        }
        .containerBackground(.black, for: .navigation)
    }
}
#endif
