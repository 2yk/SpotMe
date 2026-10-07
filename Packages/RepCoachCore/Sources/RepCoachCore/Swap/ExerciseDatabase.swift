import Foundation

/// One exercise of the database (`exercises.json`, from `design/exercise-db/`): what a swap can bring in.
public struct DatabaseExercise: Decodable, Hashable, Identifiable, Sendable {
    public struct Alternative: Decodable, Hashable, Sendable {
        public let id: String
        public let why: String
    }

    public let id: String
    public let name: String
    /// The plan.json exerciseIds this exercise is.
    public let planIds: [String]
    public let bodyPart: String
    /// `weighted`, `reps` or `timed`.
    public let logAs: String
    public let perSide: Bool?
    public let loadable: Bool?
    public let incrementKg: Double?
    public let cue: String?
    /// Strain on each injury area, 0 none, 1 low, 2 take care, 3 avoid.
    public let injury: [String: Int]
    /// Best first.
    public let alternatives: [Alternative]
}

/// The exercise database that ships with the app. Swap offers an exercise's `alternatives` from it.
public struct ExerciseDatabase: Sendable {
    private struct File: Decodable {
        let exercises: [DatabaseExercise]
    }

    public let exercises: [DatabaseExercise]
    private let byId: [String: DatabaseExercise]
    private let byPlanId: [String: DatabaseExercise]

    public init(exercises: [DatabaseExercise]) {
        self.exercises = exercises
        byId = Dictionary(exercises.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var planned: [String: DatabaseExercise] = [:]
        for exercise in exercises {
            for id in exercise.planIds where planned[id] == nil { planned[id] = exercise }
        }
        byPlanId = planned
    }

    public init(data: Data) throws {
        self.init(exercises: try JSONDecoder().decode(File.self, from: data).exercises)
    }

    /// `exercises.json` from the package's resources.
    public static let shared: ExerciseDatabase? = {
        guard let url = Bundle.module.url(forResource: "exercises", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? ExerciseDatabase(data: data)
    }()

    public func exercise(id: String) -> DatabaseExercise? { byId[id] }

    /// The entry that stands for a plan exercise: the one with that id, else the one that lists it in `planIds`.
    public func entry(forExerciseId id: String) -> DatabaseExercise? {
        byId[ExerciseIdRenames.current(id)] ?? byPlanId[id]
    }

    /// An exercise's name for screens that only have its id (History, the CSV): the database's name.
    public func name(forExerciseId id: String) -> String? { entry(forExerciseId: id)?.name }
}

/// One row of the Swap sheet.
public struct SwapChoice: Identifiable, Hashable, Sendable {
    /// The exerciseId the item becomes.
    public var id: String
    public var name: String
    /// "Free weights, deeper stretch, same flat press".
    public var why: String
    /// Rated 2 ("take care") for one of the user's injury areas.
    public var takeCare: Bool
    /// The plan's own exercise, offered while the item is swapped so the swap can be taken back.
    public var isOriginal: Bool
    public var exercise: DatabaseExercise?
}

extension ExerciseDatabase {
    /// What can stand in for `slot`: its own kinds of exercise only (a hold for a hold, sets of reps for sets of
    /// reps), and never a checklist item, a max-rep set or volume sets, which other items hang on.
    public func canSwap(_ slot: PlanItem) -> Bool {
        switch slot.kind {
        case .weighted, .reps, .timed: entry(forExerciseId: slot.exerciseId)?.alternatives.isEmpty == false
        case .checklist, .amrap, .percentOfMax: false
        }
    }

    /// The Swap sheet's rows for `current`, in the database's order: its alternatives (the ones of the exercise
    /// on screen, which is the swapped-in one after a swap), leaving out any rated 3 for an injury area of the
    /// user's and marking those rated 2. A swapped item also gets the plan's own exercise first.
    /// - Parameters:
    ///   - current: the item as shown today.
    ///   - slot: the plan's item it stands in for (`current` itself when it is not swapped).
    ///   - excluding: exerciseIds already in today's list, which can't appear twice.
    public func choices(for current: PlanItem, slot: PlanItem, injuryAreas: [String],
                        excluding taken: Set<String> = []) -> [SwapChoice] {
        guard let basis = entry(forExerciseId: current.exerciseId) else { return [] }
        var rows: [SwapChoice] = []
        if current.exerciseId != slot.exerciseId {
            rows.append(SwapChoice(id: slot.exerciseId, name: slot.name, why: "Back to the plan's exercise",
                                   takeCare: false, isOriginal: true, exercise: entry(forExerciseId: slot.exerciseId)))
        }
        for alternative in basis.alternatives {
            guard let exercise = byId[alternative.id], exercise.id != slot.exerciseId,
                  exercise.id != current.exerciseId, !taken.contains(exercise.id),
                  Self.fits(slot.kind, logAs: exercise.logAs) else { continue }
            let strain = injuryAreas.map { exercise.injury[$0] ?? 0 }.max() ?? 0
            guard strain < 3 else { continue }
            rows.append(SwapChoice(id: exercise.id, name: exercise.name, why: alternative.why, takeCare: strain == 2,
                                   isOriginal: false, exercise: exercise))
        }
        return rows
    }

    private static func fits(_ kind: ItemKind, logAs: String) -> Bool {
        switch kind {
        case .weighted, .reps: logAs == "weighted" || logAs == "reps"
        case .timed: logAs == "timed"
        default: false
        }
    }
}

/// A plan day with today's swaps in it.
public struct SwappedDay: Equatable, Sendable {
    public var day: PlanDay
    /// The plan's exercise each swapped-in exercise stands in for: swapped-in id → slot id.
    public var slotOf: [String: String]

    public init(day: PlanDay, slotOf: [String: String] = [:]) {
        self.day = day
        self.slotOf = slotOf
    }
}

extension ExerciseDatabase {
    /// `day` with each slot in `swaps` (slot → exerciseId) replaced by the exercise standing in for it. A swap
    /// whose exercise isn't in the database, is already in the day, or no longer fits the slot is ignored.
    public func applying(_ swaps: [String: String], to day: PlanDay) -> SwappedDay {
        guard !swaps.isEmpty else { return SwappedDay(day: day, slotOf: [:]) }
        var result = day
        var slotOf: [String: String] = [:]
        let taken = Set(day.items.map(\.exerciseId))
        for index in result.items.indices {
            let slot = result.items[index]
            guard let id = swaps[slot.exerciseId], !taken.contains(id), let exercise = byId[id],
                  Self.fits(slot.kind, logAs: exercise.logAs) else { continue }
            result.items[index] = slot.swapped(to: exercise)
            slotOf[exercise.id] = slot.exerciseId
        }
        return SwappedDay(day: result, slotOf: slotOf)
    }
}

extension PlanItem {
    /// A database exercise as a plain item, for screens that show an exercise logged by a swap but not in the
    /// plan: its name, kind and increment, and no prescription.
    public init(database exercise: DatabaseExercise) {
        let kind: ItemKind = switch exercise.logAs {
        case "weighted": .weighted
        case "timed": .timed
        default: .reps
        }
        self.init(name: exercise.name, exerciseId: exercise.id, group: exercise.bodyPart.capitalized, kind: kind,
                  perSide: exercise.perSide, loadable: exercise.logAs == "weighted" ? nil : exercise.loadable,
                  increment: exercise.incrementKg)
    }

    /// This slot with `exercise` in it: the slot's sets, reps, rest, section and superset group, the exercise's
    /// own id, name, kind, side and increment. Its history, targets and "Last" come from its own sessions.
    public func swapped(to exercise: DatabaseExercise) -> PlanItem {
        var item = self
        item.name = exercise.name
        item.exerciseId = exercise.id
        item.note = nil
        item.steps = nil
        switch exercise.logAs {
        case "weighted": item.kind = .weighted
        case "timed": item.kind = .timed
        default: item.kind = .reps
        }
        item.perSide = exercise.perSide
        item.loadable = exercise.logAs == "weighted" ? nil : exercise.loadable
        item.increment = exercise.incrementKg
        item.bodyweightBase = nil
        return item
    }
}
