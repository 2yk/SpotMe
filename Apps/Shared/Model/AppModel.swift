import Foundation
import SwiftData
import RepCoachCore

/// Everything the app needs, built once at launch.
@MainActor @Observable
final class AppModel {
    let plan: Plan
    let container: ModelContainer
    let settings: SettingsStore
    let today: TodayModel

    init() {
        do {
            plan = try Plan.bundled()
        } catch {
            fatalError("plan.json is missing from the app bundle: \(error)")
        }
        settings = SettingsStore()
        container = Self.makeContainer(plan: plan)
        today = TodayModel(plan: plan, context: container.mainContext, settings: settings,
                           dayKey: LaunchOptions.dayKey)
    }

    private static func makeContainer(plan: Plan) -> ModelContainer {
        #if DEBUG
        if LaunchOptions.demo {
            do {
                let container = try RepCoachStore.makeContainer(inMemory: true)
                try DemoData.seed(container.mainContext, plan: plan,
                                  inProgress: LaunchOptions.dayKey ?? plan.day(for: .now)?.key)
                return container
            } catch {
                fatalError("Couldn't build the demo store: \(error)")
            }
        }
        #endif
        do {
            return try RepCoachStore.makeContainer()
        } catch {
            fatalError("Couldn't open the RepCoach store: \(error)")
        }
    }
}

/// Launch arguments, read through UserDefaults' argument domain.
enum LaunchOptions {
    /// `-demo YES`: an in-memory store with eight weeks of made-up history. Debug builds only.
    static var demo: Bool { UserDefaults.standard.bool(forKey: "demo") }
    /// `-day monday`: open on another plan day.
    static var dayKey: String? { UserDefaults.standard.string(forKey: "day") }
    /// `-screen rest`: with `-demo`, drive the UI to a screen for screenshots. Debug builds only.
    static var screen: String? { demo ? UserDefaults.standard.string(forKey: "screen") : nil }
}
