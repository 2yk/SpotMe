import Foundation

/// Whether the watch app may save workouts to Health, as HealthKit reports it on the watch.
public enum HealthAccess: String, Codable, Sendable {
    /// The watch asks the first time Start workout is tapped.
    case notAsked
    case allowed
    /// Only the Health app can turn it back on.
    case denied
}

/// What the watch tells the phone about itself (WatchConnectivity application context, latest wins): its Health
/// access for the phone's Settings, and which sessions it has and has discarded, so the phone can send back
/// sessions the watch lost (a reinstalled watch app) and delete the ones it discarded.
public struct WatchStatus: Codable, Equatable, Sendable {
    /// How far back the watch lists its sessions, and so how far back the phone restores them: plenty for
    /// targets and recent history, and it keeps the status small.
    public static let window: TimeInterval = 400 * 24 * 60 * 60

    /// nil when the watch can't use Health at all.
    public var healthAccess: HealthAccess?
    /// The sessions stored on the watch since `since`. nil when unknown (an older watch app, or the watch
    /// couldn't read its store), in which case the phone sends nothing back.
    public var sessions: [UUID]?
    /// The start of the window `sessions` covers.
    public var since: Date?
    /// Sessions discarded on the watch, most recent last.
    public var deleted: [UUID]
    /// Today's swaps as the watch has them; the phone takes the later mark for each exercise.
    public var swaps: SwapMarks

    public init(healthAccess: HealthAccess?, sessions: [UUID]? = nil, since: Date? = nil, deleted: [UUID] = [],
                swaps: SwapMarks = SwapMarks()) {
        self.healthAccess = healthAccess
        self.sessions = sessions
        self.since = since
        self.deleted = deleted
        self.swaps = swaps
    }

    /// Statuses sent before the session lists existed read as "sessions unknown".
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        healthAccess = try container.decodeIfPresent(HealthAccess.self, forKey: .healthAccess)
        sessions = try container.decodeIfPresent([UUID].self, forKey: .sessions)
        since = try container.decodeIfPresent(Date.self, forKey: .since)
        deleted = try container.decodeIfPresent([UUID].self, forKey: .deleted) ?? []
        swaps = try container.decodeIfPresent(SwapMarks.self, forKey: .swaps) ?? SwapMarks()
    }

    /// Of the phone's sessions, the ones to send the watch: in the window, missing there and not discarded
    /// there. Nothing while the watch's list is unknown.
    public func missing(fromPhone phone: [(id: UUID, date: Date)]) -> [UUID] {
        guard let sessions else { return [] }
        let known = Set(sessions).union(deleted)
        return phone
            .filter { !known.contains($0.id) && $0.date >= (since ?? .distantPast) }
            .map(\.id)
    }

    // MARK: WatchConnectivity

    static let key = "watchStatus"

    public var applicationContext: [String: Any] {
        guard let data = try? JSONEncoder().encode(self) else { return [:] }
        return [Self.key: data]
    }

    public init?(applicationContext: [String: Any]) {
        guard let data = applicationContext[Self.key] as? Data,
              let status = try? JSONDecoder().decode(Self.self, from: data) else { return nil }
        self = status
    }
}
