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
}
