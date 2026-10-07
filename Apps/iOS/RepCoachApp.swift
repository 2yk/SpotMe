import SwiftUI
import SwiftData
import RepCoachCore

@main
struct RepCoachApp: App {
    @State private var app: AppModel
    @State private var sync: PhoneSync

    init() {
        let app = AppModel()
        let sync = PhoneSync(context: app.container.mainContext, settings: app.settings, today: app.today)
        app.today.onSwapsChanged = { [weak sync] _ in sync?.swapsMade() }
        sync.activate()
        _app = State(initialValue: app)
        _sync = State(initialValue: sync)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(app)
                .environment(app.today)
                .environment(app.settings)
                .environment(sync)
                .tint(Theme.volt)
                .preferredColorScheme(.dark)
        }
        .modelContainer(app.container)
    }
}
