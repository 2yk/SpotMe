import Foundation
import SwiftData

/// The SwiftData schema shared by the watch and iPhone apps.
public enum RepCoachStore {
    public static var models: [any PersistentModel.Type] {
        [WorkoutSession.self, ExerciseLog.self, SetLog.self, ExerciseSettings.self, PlanEditsRecord.self]
    }

    /// The on-disk store, or a throwaway one for tests, previews and demo data.
    public static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(models)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
