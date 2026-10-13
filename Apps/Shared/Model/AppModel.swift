import Foundation
import OSLog
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
        let defaults = Self.makeDefaults()
        settings = SettingsStore(defaults: defaults)
        #if DEBUG
        if LaunchOptions.demo, UserDefaults.standard.bool(forKey: "deload") {
            settings.settings.manualDeloadSetOn = .now
        }
        #endif
        container = Self.makeContainer(plan: plan)
        Self.renameExercises(in: container.mainContext, defaults: defaults)
        Self.moveWorkoutKeys(in: container.mainContext, plan: plan, defaults: defaults)
        #if os(iOS)
        Self.reportBodyPoints(in: container.mainContext, defaults: defaults)
        #endif
        today = TodayModel(plan: plan, context: container.mainContext, settings: settings,
                           dayKey: LaunchOptions.dayKey)
        today.defaults = defaults
        today.refresh()
    }

    /// Moves anything stored under an exercise id plan.json has renamed to its current id (once, at the first
    /// launch of the build that renames it; later launches find nothing to move). The count is logged.
    private static func renameExercises(in context: ModelContext, defaults: UserDefaults) {
        do {
            let report = try IdMigration.run(in: context, defaults: defaults)
            guard !report.isEmpty else { return }
            Logger.store.notice("Renamed exercise ids: \(report.summary, privacy: .public)")
            defaults.set(report.summary, forKey: "exerciseRenameReport")
        } catch {
            Logger.store.error("Couldn't rename exercise ids: \(error.localizedDescription)")
        }
    }

    /// Plan 12 moved Push B from key "friday" to "saturday" (and Full Rest from "saturday" to "sunday"): sessions
    /// and plan edits made under the old keys move to the workout's new key. Looks at what was logged, so later
    /// launches find nothing to move. What moved is logged and kept in `planKeyMigrationReport`.
    private static func moveWorkoutKeys(in context: ModelContext, plan: Plan, defaults: UserDefaults) {
        do {
            let report = try PlanKeyMigration.run(in: context, plan: plan)
            guard !report.isEmpty else { return }
            Logger.store.notice("Moved workout keys: \(report.summary, privacy: .public)")
            defaults.set(report.summary, forKey: "planKeyMigrationReport")
        } catch {
            Logger.store.error("Couldn't move workout keys: \(error.localizedDescription)")
        }
    }

    #if os(iOS)
    /// The body log grew from arm and waist to ten optional points (phone build 11). SwiftData moves the stored rows
    /// by itself, arm and waist keeping their values and the other points empty; this notes once how many rows
    /// that was, in the log and in `bodyMigrationReport`.
    private static func reportBodyPoints(in context: ModelContext, defaults: UserDefaults) {
        guard !defaults.bool(forKey: "bodyPointsReported") else { return }
        let rows = (try? context.fetch(FetchDescriptor<BodyMeasurement>())) ?? []
        let summary = "\(rows.count) body measurement(s) kept: arm and waist as they were, the eight new points empty"
        Logger.store.notice("\(summary, privacy: .public)")
        defaults.set(summary, forKey: "bodyMigrationReport")
        defaults.set(true, forKey: "bodyPointsReported")
    }
    #endif

    /// Where settings and the day's small state live. The demo uses a throwaway suite, so a screenshot's deload
    /// week or skipped exercise never reaches the real ones.
    private static func makeDefaults() -> UserDefaults {
        #if DEBUG
        if LaunchOptions.demo {
            let suite = "com.yeshu.RepCoach.demo"
            UserDefaults().removePersistentDomain(forName: suite)
            return UserDefaults(suiteName: suite) ?? .standard
        }
        #endif
        return .standard
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
                if let weekdays = UserDefaults.standard.string(forKey: "swapDays") {
                    try swapDays(weekdays, in: container.mainContext, plan: plan)
                }
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
    /// `-swapDays 3,4`: the workouts on two weekdays (calendar numbers, 2 = Monday … 1 = Sunday) trade places, as
    /// Rearrange days would have done it.
    private static func swapDays(_ weekdays: String, in context: ModelContext, plan: Plan) throws {
        let pair = weekdays.split(separator: ",").compactMap { Int($0) }
        guard pair.count == 2 else { return }
        var edits = PlanEdits.load(from: context)
        edits.swapWorkouts(on: pair[0], and: pair[1], plan: plan)
        try edits.save(to: context)
    }

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
    /// `-item incline-db-press`: with `-demo`, the exercise a screen is about.
    static var item: String? { demo ? UserDefaults.standard.string(forKey: "item") : nil }
    /// `-tab history`: open the phone app on a tab. Navigation only, so it works without `-demo`.
    static var tab: String? { UserDefaults.standard.string(forKey: "tab") }
    /// HealthKit workouts. Off in demo mode, so screenshots don't stop at the Health permission sheet,
    /// unless `-healthkit YES` is passed too.
    static var healthKit: Bool { !demo || UserDefaults.standard.bool(forKey: "healthkit") }
    /// Watch–phone sync. Off in demo mode so made-up sessions never reach a real device, unless `-sync YES`.
    static var sync: Bool { !demo || UserDefaults.standard.bool(forKey: "sync") }
}
