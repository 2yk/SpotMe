import SwiftUI
import SwiftData
import WatchKit
import RepCoachCore

@main
struct RepCoachWatchApp: App {
    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @State private var app: AppModel
    @State private var workout: WorkoutModel
    @State private var sync: WatchSync

    init() {
        let app = AppModel()
        let workout = WorkoutModel(today: app.today)
        let sync = WatchSync(today: app.today, settings: app.settings)
        sync.isBusy = { [weak workout] in workout?.canFinish ?? false }
        workout.onSessionFinished = { [weak sync] session in
            sync?.send(session)
            sync?.applyPendingIfIdle()
        }
        sync.activate()
        _app = State(initialValue: app)
        _workout = State(initialValue: workout)
        _sync = State(initialValue: sync)
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
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            app.today.wake()
            sync.catchUp()
        }
    }
}

final class WatchAppDelegate: NSObject, WKApplicationDelegate {
    /// The system relaunched the app while a workout was running: pick it back up.
    func handleActiveWorkoutRecovery() {
        Task { @MainActor in await HealthWorkout.shared.recover() }
    }
}
