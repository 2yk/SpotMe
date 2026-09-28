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
            // Runs are logged in Nike Run Club, so they never show here.
            plan = try Plan.bundled().withoutRuns()
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
                try DemoData.seed(container.mainContext, plan: plan, weeks: LaunchOptions.demoWeeks,
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
    /// `-weeks 0`: how many weeks of demo history; 0 shows first sessions.
    static var demoWeeks: Int { UserDefaults.standard.string(forKey: "weeks").flatMap(Int.init) ?? 8 }
    /// `-day monday`: open on another plan day.
    static var dayKey: String? { UserDefaults.standard.string(forKey: "day") }
    /// `-screen rest`: with `-demo`, drive the UI to a screen for screenshots. Debug builds only.
    static var screen: String? { demo ? UserDefaults.standard.string(forKey: "screen") : nil }
    /// `-tab history`: open the phone app on a tab. Navigation only, so it works without `-demo`.
    static var tab: String? { UserDefaults.standard.string(forKey: "tab") }
    /// HealthKit workouts. Off in demo mode, so screenshots don't stop at the Health permission sheet,
    /// unless `-healthkit YES` is passed too.
    static var healthKit: Bool { !demo || UserDefaults.standard.bool(forKey: "healthkit") }
    /// Watch–phone sync. Off in demo mode so made-up sessions never reach a real device, unless `-sync YES`.
    static var sync: Bool { !demo || UserDefaults.standard.bool(forKey: "sync") }
}
