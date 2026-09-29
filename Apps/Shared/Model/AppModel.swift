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
                                  inProgress: LaunchOptions.demoFresh ? nil
                                      : LaunchOptions.dayKey ?? plan.day(for: .now)?.key)
                if LaunchOptions.sampleEdits { try seedSampleEdits(container.mainContext, plan: plan) }
                if LaunchOptions.demoWeeks > 0 {
                    try DemoData.seedBody(container.mainContext, lastDaysAgo: LaunchOptions.screen == "body-due" ? 16 : 3,
                                          waistWarning: LaunchOptions.screen == "body-warning")
                }
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

    #if DEBUG
    /// `-sampleEdits YES`: Monday with Barbell Row added, Face Pulls removed and Hammer Curl renamed.
    private static func seedSampleEdits(_ context: ModelContext, plan: Plan) throws {
        guard let monday = plan.days.first(where: { $0.key == "monday" }) else { return }
        var edits = PlanEdits()
        let row = PlanItem(name: "Barbell Row", exerciseId: "custom-barbell-row", group: "Back · Thickness",
                           kind: .weighted, sets: 3, repMin: 8, repMax: 10, increment: 2.5,
                           sessionsAtTopToProgress: 1, restSec: 120)
        edits.add(row, to: monday, plan: plan)
        edits.remove("face-pulls", from: monday)
        try edits.save(to: context)
        let hammer = ExerciseSettings(exerciseId: "hammer-curl")
        hammer.name = "Hammer Curl (rope)"
        context.insert(hammer)
        try context.save()
    }
    #endif
}

/// Launch arguments, read through UserDefaults' argument domain.
enum LaunchOptions {
    /// `-demo YES`: an in-memory store with eight weeks of made-up history. Debug builds only.
    static var demo: Bool { UserDefaults.standard.bool(forKey: "demo") }
    /// `-weeks 0`: how many weeks of demo history; 0 shows first sessions.
    static var demoWeeks: Int { UserDefaults.standard.string(forKey: "weeks").flatMap(Int.init) ?? 8 }
    /// `-fresh YES`: demo history without a session under way today.
    static var demoFresh: Bool { UserDefaults.standard.bool(forKey: "fresh") }
    /// `-sampleEdits YES`: with `-demo`, some plan edits on Monday.
    static var sampleEdits: Bool { demo && UserDefaults.standard.bool(forKey: "sampleEdits") }
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
