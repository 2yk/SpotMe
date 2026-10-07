import XCTest
import SwiftData
@testable import RepCoachCore

/// The store as build 3 left it on the owner's devices: exercise settings without a name, and no plan edits.
enum StoreBuild3 {
    @Model
    final class WorkoutSession {
        @Attribute(.unique) var id: UUID
        var date: Date
        var dayKey: String
        var isDeload: Bool
        var healthKitWorkoutId: UUID?
        var endedAt: Date?
        @Relationship(deleteRule: .cascade, inverse: \ExerciseLog.session)
        var logs: [ExerciseLog] = []

        init(id: UUID, date: Date, dayKey: String) {
            self.id = id
            self.date = date
            self.dayKey = dayKey
            self.isDeload = false
        }
    }

    @Model
    final class ExerciseLog {
        var session: WorkoutSession?
        var exerciseId: String
        var order: Int
        var completedAt: Date?
        var skipped: Bool = false
        @Relationship(deleteRule: .cascade, inverse: \SetLog.log)
        var sets: [SetLog] = []

        init(exerciseId: String, order: Int) {
            self.exerciseId = exerciseId
            self.order = order
        }
    }

    @Model
    final class SetLog {
        var log: ExerciseLog?
        var index: Int
        var weight: Double
        var reps: Int
        var seconds: Int?
        var timestamp: Date

        init(index: Int, weight: Double, reps: Int) {
            self.index = index
            self.weight = weight
            self.reps = reps
            self.timestamp = .now
        }
    }

    @Model
    final class ExerciseSettings {
        @Attribute(.unique) var exerciseId: String
        var increment: Double?
        var repMin: Int?
        var repMax: Int?
        var sets: Int?
        var restSec: Int?
        var startWeight: Double?

        init(exerciseId: String) {
            self.exerciseId = exerciseId
        }
    }
}

/// The store as it was before ramp-up sets and effort: no `SetLog.isRampUp`, no `WorkoutSession.effort`.
enum StoreBeforeRampUps {
    @Model
    final class WorkoutSession {
        @Attribute(.unique) var id: UUID
        var date: Date
        var dayKey: String
        var isDeload: Bool
        var healthKitWorkoutId: UUID?
        var endedAt: Date?
        @Relationship(deleteRule: .cascade, inverse: \ExerciseLog.session)
        var logs: [ExerciseLog] = []

        init(id: UUID, date: Date, dayKey: String) {
            self.id = id
            self.date = date
            self.dayKey = dayKey
            self.isDeload = false
        }
    }

    @Model
    final class ExerciseLog {
        var session: WorkoutSession?
        var exerciseId: String
        var order: Int
        var completedAt: Date?
        var skipped: Bool = false
        @Relationship(deleteRule: .cascade, inverse: \SetLog.log)
        var sets: [SetLog] = []

        init(exerciseId: String, order: Int) {
            self.exerciseId = exerciseId
            self.order = order
        }
    }

    @Model
    final class SetLog {
        var log: ExerciseLog?
        var index: Int
        var weight: Double
        var reps: Int
        var seconds: Int?
        var timestamp: Date

        init(index: Int, weight: Double, reps: Int) {
            self.index = index
            self.weight = weight
            self.reps = reps
            self.timestamp = .now
        }
    }

    @Model
    final class ExerciseSettings {
        @Attribute(.unique) var exerciseId: String
        var name: String?
        var increment: Double?
        var repMin: Int?
        var repMax: Int?
        var sets: Int?
        var restSec: Int?
        var startWeight: Double?

        init(exerciseId: String) {
            self.exerciseId = exerciseId
        }
    }

    @Model
    final class PlanEditsRecord {
        var data: Data

        init(data: Data) {
            self.data = data
        }
    }

    @Model
    final class BodyMeasurement {
        @Attribute(.unique) var id: UUID
        var date: Date
        var arm: Double
        var waist: Double

        init(id: UUID, date: Date, arm: Double, waist: Double) {
            self.id = id
            self.date = date
            self.arm = arm
            self.waist = waist
        }
    }
}

/// The store as watch and phone build 8 left it on the owner's devices: ramp-ups and effort, but no swaps, no
/// time, energy or average heart rate, and Machine Chest Press still under its old id.
enum StoreBuild8 {
    @Model
    final class WorkoutSession {
        @Attribute(.unique) var id: UUID
        var date: Date
        var dayKey: String
        var isDeload: Bool
        var healthKitWorkoutId: UUID?
        var endedAt: Date?
        var effort: Int?
        @Relationship(deleteRule: .cascade, inverse: \ExerciseLog.session)
        var logs: [ExerciseLog] = []

        init(id: UUID, date: Date, dayKey: String) {
            self.id = id
            self.date = date
            self.dayKey = dayKey
            self.isDeload = false
        }
    }

    @Model
    final class ExerciseLog {
        var session: WorkoutSession?
        var exerciseId: String
        var order: Int
        var completedAt: Date?
        var skipped: Bool = false
        @Relationship(deleteRule: .cascade, inverse: \SetLog.log)
        var sets: [SetLog] = []

        init(exerciseId: String, order: Int) {
            self.exerciseId = exerciseId
            self.order = order
        }
    }

    @Model
    final class SetLog {
        var log: ExerciseLog?
        var index: Int
        var weight: Double
        var reps: Int
        var seconds: Int?
        var timestamp: Date
        var isRampUp: Bool = false

        init(index: Int, weight: Double, reps: Int) {
            self.index = index
            self.weight = weight
            self.reps = reps
            self.timestamp = .now
        }
    }

    @Model
    final class ExerciseSettings {
        @Attribute(.unique) var exerciseId: String
        var name: String?
        var increment: Double?
        var repMin: Int?
        var repMax: Int?
        var sets: Int?
        var restSec: Int?
        var startWeight: Double?

        init(exerciseId: String) {
            self.exerciseId = exerciseId
        }
    }

    @Model
    final class PlanEditsRecord {
        var data: Data

        init(data: Data) {
            self.data = data
        }
    }

    @Model
    final class BodyMeasurement {
        @Attribute(.unique) var id: UUID
        var date: Date
        var arm: Double
        var waist: Double

        init(id: UUID, date: Date, arm: Double, waist: Double) {
            self.id = id
            self.date = date
            self.arm = arm
            self.waist = waist
        }
    }
}

final class StoreMigrationTests: XCTestCase {
    /// Opening a build 3 store with today's models keeps every session, set and setting, and plan edits save.
    func testABuild3StoreOpensWithEverythingKept() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("default.store")
        let sessionId = UUID()

        do {
            let schema = Schema([StoreBuild3.WorkoutSession.self, StoreBuild3.ExerciseLog.self,
                                 StoreBuild3.SetLog.self, StoreBuild3.ExerciseSettings.self])
            let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url)])
            let context = ModelContext(container)
            let session = StoreBuild3.WorkoutSession(id: sessionId, date: .now, dayKey: "monday")
            context.insert(session)
            let log = StoreBuild3.ExerciseLog(exerciseId: "hammer-curl", order: 0)
            context.insert(log)
            log.session = session
            let set = StoreBuild3.SetLog(index: 1, weight: 12.5, reps: 11)
            context.insert(set)
            set.log = log
            let settings = StoreBuild3.ExerciseSettings(exerciseId: "hammer-curl")
            settings.increment = 1
            context.insert(settings)
            try context.save()
        }

        let schema = Schema(RepCoachStore.models)
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url)])
        let context = ModelContext(container)
        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>())
        XCTAssertEqual(sessions.map(\.id), [sessionId])
        XCTAssertEqual(sessions.first?.log(for: "hammer-curl")?.orderedSets.map(\.loggedSet),
                       [LoggedSet(weight: 12.5, reps: 11)])
        let settings = try XCTUnwrap(try context.fetch(FetchDescriptor<ExerciseSettings>()).first)
        XCTAssertEqual(settings.overrides, ExerciseOverrides(increment: 1))

        var edits = PlanEdits()
        edits.days["monday"] = ["hammer-curl"]
        try edits.save(to: context)
        settings.name = "Hammers"
        try context.save()
        XCTAssertEqual(PlanEdits.load(from: context), edits)
        XCTAssertEqual(try context.fetch(FetchDescriptor<ExerciseSettings>()).first?.name, "Hammers")
    }

    /// Opening a store from before ramp-up sets keeps everything: old sets are working sets, old sessions have no
    /// effort, and the new fields can be written and read back.
    func testAStoreFromBeforeRampUpsOpensWithEverythingKept() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("default.store")
        let sessionId = UUID()
        let measurementId = UUID()

        do {
            let schema = Schema([StoreBeforeRampUps.WorkoutSession.self, StoreBeforeRampUps.ExerciseLog.self,
                                 StoreBeforeRampUps.SetLog.self, StoreBeforeRampUps.ExerciseSettings.self,
                                 StoreBeforeRampUps.PlanEditsRecord.self, StoreBeforeRampUps.BodyMeasurement.self])
            let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url)])
            let context = ModelContext(container)
            let session = StoreBeforeRampUps.WorkoutSession(id: sessionId, date: .now, dayKey: "wednesday")
            session.endedAt = .now
            context.insert(session)
            let log = StoreBeforeRampUps.ExerciseLog(exerciseId: "incline-db-press", order: 0)
            context.insert(log)
            log.session = session
            for (index, reps) in [10, 9].enumerated() {
                let set = StoreBeforeRampUps.SetLog(index: index + 1, weight: 20, reps: reps)
                context.insert(set)
                set.log = log
            }
            let named = StoreBeforeRampUps.ExerciseSettings(exerciseId: "incline-db-press")
            named.name = "Incline Press"
            context.insert(named)
            context.insert(StoreBeforeRampUps.BodyMeasurement(id: measurementId, date: .now, arm: 14.5, waist: 33))
            try context.save()
        }

        let schema = Schema(RepCoachStore.models)
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url)])
        let context = ModelContext(container)
        let session = try XCTUnwrap(try context.fetch(FetchDescriptor<WorkoutSession>()).first)
        XCTAssertEqual(session.id, sessionId)
        XCTAssertNil(session.effort)
        XCTAssertNotNil(session.endedAt)
        let log = try XCTUnwrap(session.log(for: "incline-db-press"))
        XCTAssertEqual(log.orderedSets.map(\.loggedSet), [LoggedSet(weight: 20, reps: 10), LoggedSet(weight: 20, reps: 9)])
        XCTAssertEqual(log.orderedSets.map(\.isRampUp), [false, false])
        XCTAssertEqual(log.status, .inProgress(setsDone: 2))
        XCTAssertEqual(try HistoryStore(context: context).history(for: "incline-db-press"),
                       [[LoggedSet(weight: 20, reps: 10), LoggedSet(weight: 20, reps: 9)]])
        XCTAssertEqual(try context.fetch(FetchDescriptor<ExerciseSettings>()).first?.name, "Incline Press")
        XCTAssertEqual(try context.fetch(FetchDescriptor<BodyMeasurement>()).map(\.id), [measurementId])

        // New writes work on the migrated store, and survive a save.
        let recorder = WorkoutRecorder(context: context)
        try recorder.addSet(to: log, weight: 10, reps: 8, isRampUp: true)
        try recorder.setEffort(7, on: session)
        XCTAssertEqual(try context.fetch(FetchDescriptor<WorkoutSession>()).first?.effort, 7)
        XCTAssertEqual(log.orderedCountedSets.count, 2)
        XCTAssertEqual(log.orderedSets.last?.isRampUp, true)
    }

    /// Opening a build 8 store keeps everything, the old chest press id moves to the new one once, and the new
    /// fields (slot, time, energy, heart rate, saved workouts) can be written and read back.
    func testABuild8StoreMigratesTheChestPressAndTakesTheNewFields() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("default.store")
        let sessionIds = [UUID(), UUID()]
        let workoutId = UUID()

        do {
            let schema = Schema([StoreBuild8.WorkoutSession.self, StoreBuild8.ExerciseLog.self,
                                 StoreBuild8.SetLog.self, StoreBuild8.ExerciseSettings.self,
                                 StoreBuild8.PlanEditsRecord.self, StoreBuild8.BodyMeasurement.self])
            let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url)])
            let context = ModelContext(container)
            for (offset, id) in sessionIds.enumerated() {
                let session = StoreBuild8.WorkoutSession(id: id, date: Date(timeIntervalSince1970: 1_700_000_000 + Double(offset) * 604_800),
                                                         dayKey: "wednesday")
                session.endedAt = session.date.addingTimeInterval(3000)
                session.effort = 7
                session.healthKitWorkoutId = workoutId
                context.insert(session)
                let log = StoreBuild8.ExerciseLog(exerciseId: "machine-chest-press-or-flat-bench", order: 0)
                context.insert(log)
                log.session = session
                for (index, reps) in [10, 9, 8].enumerated() {
                    let set = StoreBuild8.SetLog(index: index + 1, weight: 40, reps: reps)
                    context.insert(set)
                    set.log = log
                }
            }
            let settings = StoreBuild8.ExerciseSettings(exerciseId: "machine-chest-press-or-flat-bench")
            settings.increment = 2.5
            context.insert(settings)
            try context.save()
        }

        let schema = Schema(RepCoachStore.models)
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url)])
        let context = ModelContext(container)
        let report = try IdMigration.run(in: context)
        XCTAssertEqual(report.logs, 2)
        XCTAssertEqual(report.sets, 6)
        XCTAssertEqual(report.settings, 1)
        XCTAssertTrue(try IdMigration.run(in: context).isEmpty)

        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>(sortBy: [SortDescriptor(\.date)]))
        XCTAssertEqual(sessions.map(\.id), sessionIds)
        XCTAssertEqual(sessions.map(\.effort), [7, 7])
        XCTAssertNil(sessions[0].activeSeconds)
        XCTAssertNil(sessions[0].logs.first?.slotExerciseId)
        XCTAssertEqual(try HistoryStore(context: context).history(for: "machine-chest-press").count, 2)
        XCTAssertEqual(try context.fetch(FetchDescriptor<ExerciseSettings>()).map(\.exerciseId), ["machine-chest-press"])

        // The new fields work on the migrated store and survive a save.
        sessions[0].addPart(seconds: 2880, energy: 342, averageHeartRate: 124)
        sessions[0].saveWorkout(workoutId)
        sessions[0].logs.first?.slotExerciseId = "machine-chest-press"
        try context.save()
        let reread = try XCTUnwrap(try context.fetch(FetchDescriptor<WorkoutSession>(sortBy: [SortDescriptor(\.date)])).first)
        XCTAssertEqual(reread.activeSeconds, 2880)
        XCTAssertEqual(reread.energyKcal, 342)
        XCTAssertEqual(reread.averageHeartRate, 124)
        XCTAssertEqual(reread.savedWorkoutIds, [workoutId])
        XCTAssertEqual(reread.logs.first?.slotExerciseId, "machine-chest-press")
    }

    func testTwoPartsOfASessionAddUp() throws {
        let session = WorkoutSession(dayKey: "wednesday")
        session.addPart(seconds: 2400, energy: 300, averageHeartRate: 120)
        session.addPart(seconds: 600, energy: 60, averageHeartRate: 140)
        XCTAssertEqual(session.activeSeconds, 3000)
        XCTAssertEqual(session.energyKcal, 360)
        XCTAssertEqual(try XCTUnwrap(session.averageHeartRate), 124, accuracy: 1e-9)
        let first = UUID(), second = UUID()
        session.saveWorkout(first)
        session.saveWorkout(second)
        session.saveWorkout(first)
        XCTAssertEqual(session.savedWorkoutIds, [second, first])
        XCTAssertEqual(session.healthKitWorkoutId, first)
    }
}
