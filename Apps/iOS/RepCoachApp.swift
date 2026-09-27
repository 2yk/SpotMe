import SwiftUI
import SwiftData
import RepCoachCore

@main
struct RepCoachApp: App {
    @State private var app = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(app)
                .environment(app.today)
                .environment(app.settings)
                .tint(Theme.volt)
                .preferredColorScheme(.dark)
        }
        .modelContainer(app.container)
    }
}
