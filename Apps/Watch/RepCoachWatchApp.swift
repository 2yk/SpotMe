import SwiftUI
import SwiftData
import RepCoachCore

@main
struct RepCoachWatchApp: App {
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
        }
        .modelContainer(app.container)
    }
}
