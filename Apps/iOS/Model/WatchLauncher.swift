import Foundation
import HealthKit
import OSLog

/// Start workout on the phone: asks the watch to open SpotMe and start the day's workout (HealthKit's
/// `startWatchApp`). When it can't, it says so, and the watch's own Start workout still works.
@MainActor @Observable
final class WatchLauncher {
    /// What went wrong, for an alert; nil while all is well.
    var problem: String?
    private(set) var isStarting = false

    func start() {
        guard !isStarting else { return }
        #if DEBUG
        if LaunchOptions.demo { return }
        #endif
        guard HKHealthStore.isHealthDataAvailable() else {
            problem = "Health isn't available on this iPhone, so it can't start a workout on your watch. Start it on the watch."
            return
        }
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .indoor
        isStarting = true
        Task {
            defer { isStarting = false }
            do {
                try await HKHealthStore().startWatchApp(toHandle: configuration)
                Logger.sync.notice("Asked the watch to start the workout")
            } catch {
                Logger.sync.error("Couldn't start the watch workout: \(error.localizedDescription)")
                problem = "Your watch didn't answer. Open SpotMe on the watch and tap Start workout there."
            }
        }
    }
}
