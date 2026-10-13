import SwiftUI
import SwiftData
import RepCoachCore

@main
struct RepCoachApp: App {
    @State private var app: AppModel
    @State private var sync: PhoneSync
    @State private var launcher = WatchLauncher()

    init() {
        let app = AppModel()
        let sync = PhoneSync(context: app.container.mainContext, settings: app.settings, today: app.today)
        app.today.onSwapsChanged = { [weak sync] _ in sync?.swapsMade() }
        sync.activate()
        Self.styleBars()
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
                .environment(launcher)
                .tint(Theme.volt)
                .preferredColorScheme(.dark)
        }
        .modelContainer(app.container)
    }

    /// Large titles in the app's rounded heavy, on the black screen. The tab bar stays the system's.
    private static func styleBars() {
        func rounded(_ size: CGFloat, _ weight: UIFont.Weight) -> UIFont {
            let font = UIFont.systemFont(ofSize: size, weight: weight)
            return font.fontDescriptor.withDesign(.rounded).map { UIFont(descriptor: $0, size: size) } ?? font
        }
        let bar = UINavigationBarAppearance()
        bar.configureWithTransparentBackground()
        bar.largeTitleTextAttributes = [.font: rounded(34, .heavy), .foregroundColor: UIColor.white]
        bar.titleTextAttributes = [.font: rounded(17, .semibold), .foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = bar
        UINavigationBar.appearance().scrollEdgeAppearance = bar
    }
}
