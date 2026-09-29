import Foundation
import HealthKit
import OSLog
import RepCoachCore

/// The HealthKit side of a gym session: a traditional strength training workout that keeps the app running
/// with the wrist down, collects heart rate and energy, and is saved to Health at the end.
/// Only the Start workout button starts one.
@MainActor @Observable
final class HealthWorkout: NSObject {
    /// One per app: the system hands a crashed workout back through the app delegate.
    static let shared = HealthWorkout()

    enum State: Equatable {
        case idle, starting, running, ending
    }

    private(set) var state: State = .idle
    private(set) var startedAt: Date?
    /// Beats per minute, latest sample.
    private(set) var heartRate: Double?
    private(set) var averageHeartRate: Double?
    /// Active kilocalories so far.
    private(set) var energy: Double?

    @ObservationIgnored private let store = HKHealthStore()
    @ObservationIgnored private var session: HKWorkoutSession?
    @ObservationIgnored private var builder: HKLiveWorkoutBuilder?

    private static let shareTypes: Set<HKSampleType> = [HKObjectType.workoutType()]
    private static let readTypes: Set<HKObjectType> = [
        HKQuantityType(.heartRate), HKQuantityType(.activeEnergyBurned), HKObjectType.workoutType(),
    ]

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }
    var isRunning: Bool { state == .running }
    /// Whether SpotMe may save workouts. Asked the first time Start workout is tapped; after that only the
    /// Health app on the iPhone changes it.
    var access: HealthAccess {
        switch store.authorizationStatus(for: HKObjectType.workoutType()) {
        case .sharingAuthorized: .allowed
        case .sharingDenied: .denied
        default: .notAsked
        }
    }

    /// Starts the workout, asking for Health access the first time. Returns false if it couldn't start,
    /// including when saving workouts isn't allowed.
    @discardableResult
    func start() async -> Bool {
        guard isAvailable, state == .idle else { return state == .running }
        state = .starting
        do {
            try await store.requestAuthorization(toShare: Self.shareTypes, read: Self.readTypes)
            guard store.authorizationStatus(for: HKObjectType.workoutType()) == .sharingAuthorized else {
                reset()
                return false
            }
            let configuration = HKWorkoutConfiguration()
            configuration.activityType = .traditionalStrengthTraining
            configuration.locationType = .indoor
            let session = try HKWorkoutSession(healthStore: store, configuration: configuration)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: configuration)
            attach(session, builder)
            let start = Date.now
            session.startActivity(with: start)
            try await builder.beginCollection(at: start)
            startedAt = start
            state = .running
            return true
        } catch {
            Logger.health.error("Couldn't start the workout: \(error.localizedDescription)")
            session?.end()
            reset()
            return false
        }
    }

    /// Ends the workout and saves it to Health. Returns the saved workout's id, or nil if nothing was saved.
    func finish() async -> UUID? {
        guard let session, let builder, state == .running else { return nil }
        state = .ending
        session.end()
        do {
            try await builder.endCollection(at: .now)
            let workout = try await builder.finishWorkout()
            reset()
            return workout?.uuid
        } catch {
            Logger.health.error("Couldn't save the workout: \(error.localizedDescription)")
            reset()
            return nil
        }
    }

    /// Ends the workout without saving anything to Health.
    func discard() {
        guard let session, let builder, state == .running else { return }
        session.end()
        builder.discardWorkout()
        reset()
    }

    /// Removes a workout SpotMe already saved, with the energy saved alongside it: a discarded session leaves
    /// nothing in Health.
    func deleteWorkout(id: UUID) async {
        guard isAvailable else { return }
        do {
            let query = HKSampleQueryDescriptor(predicates: [.workout(HKQuery.predicateForObject(with: id))],
                                                sortDescriptors: [])
            for workout in try await query.result(for: store) {
                _ = try? await store.deleteObjects(of: HKQuantityType(.activeEnergyBurned),
                                                   predicate: HKQuery.predicateForObjects(from: workout))
                try await store.delete(workout)
            }
        } catch {
            Logger.health.error("Couldn't delete the workout from Health: \(error.localizedDescription)")
        }
    }

    /// Picks the workout back up after the system relaunched the app mid-session.
    func recover() async {
        do {
            guard let session = try await store.recoverActiveWorkoutSession() else { return }
            attach(session, session.associatedWorkoutBuilder())
            startedAt = session.startDate
            state = .running
        } catch {
            Logger.health.error("Couldn't recover the workout: \(error.localizedDescription)")
        }
    }

    private func attach(_ session: HKWorkoutSession, _ builder: HKLiveWorkoutBuilder) {
        session.delegate = self
        builder.delegate = self
        self.session = session
        self.builder = builder
    }

    private func reset() {
        session = nil
        builder = nil
        state = .idle
        startedAt = nil
        heartRate = nil
        averageHeartRate = nil
        energy = nil
    }

    fileprivate func update(heartRate: Double?, average: Double?, energy: Double?) {
        if let heartRate { self.heartRate = heartRate }
        if let average { averageHeartRate = average }
        if let energy { self.energy = energy }
    }

    fileprivate func sessionFailed(_ error: Error) {
        Logger.health.error("Workout session failed: \(error.localizedDescription)")
        reset()
    }

    #if DEBUG
    /// Screenshots only: look like a workout that's been running for a while.
    func pretendRunning(heartRate: Double, minutes: Double) {
        state = .running
        startedAt = .now.addingTimeInterval(-minutes * 60)
        self.heartRate = heartRate
        averageHeartRate = heartRate - 9
        energy = minutes * 5.5
    }
    #endif
}

extension HealthWorkout: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                                    from fromState: HKWorkoutSessionState, date: Date) {}

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        Task { @MainActor in self.sessionFailed(error) }
    }
}

extension HealthWorkout: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                                    didCollectDataOf collectedTypes: Set<HKSampleType>) {
        let perMinute = HKUnit.count().unitDivided(by: .minute())
        let heart = workoutBuilder.statistics(for: HKQuantityType(.heartRate))
        let latest = heart?.mostRecentQuantity()?.doubleValue(for: perMinute)
        let average = heart?.averageQuantity()?.doubleValue(for: perMinute)
        let energy = workoutBuilder.statistics(for: HKQuantityType(.activeEnergyBurned))?
            .sumQuantity()?.doubleValue(for: .kilocalorie())
        Task { @MainActor in self.update(heartRate: latest, average: average, energy: energy) }
    }
}

extension Logger {
    static let health = Logger(subsystem: "com.yeshu.RepCoach", category: "health")
}
