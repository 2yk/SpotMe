import SwiftUI
import SwiftData
import WatchKit
import RepCoachCore

@main
struct RepCoachWatchApp: App {
    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) private var appDelegate
    @State private var app: AppModel
    @State private var workout: WorkoutModel

    init() {
        let app = AppModel()
        _app = State(initialValue: app)
        _workout = State(initialValue: WorkoutModel(today: app.today))
    }

    var body: some Scene {
        WindowGroup {
            TodayView()
                .environment(app.today)
                .environment(app.settings)
                .environment(workout)
                .environment(workout.health)
        }
        .modelContainer(app.container)
    }
}

final class WatchAppDelegate: NSObject, WKApplicationDelegate {
    /// The system relaunched the app while a workout was running: pick it back up.
    func handleActiveWorkoutRecovery() {
        Task { @MainActor in await HealthWorkout.shared.recover() }
    }
}
