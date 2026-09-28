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
    /// nil when the watch can't use Health at all.
    public var healthAccess: HealthAccess?
    /// Every session stored on the watch.
    public var sessions: [UUID]
    /// Sessions discarded on the watch, most recent last.
    public var deleted: [UUID]

    public init(healthAccess: HealthAccess?, sessions: [UUID] = [], deleted: [UUID] = []) {
        self.healthAccess = healthAccess
        self.sessions = sessions
        self.deleted = deleted
    }

    /// Statuses sent before the session lists existed read as empty lists.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        healthAccess = try container.decodeIfPresent(HealthAccess.self, forKey: .healthAccess)
        sessions = try container.decodeIfPresent([UUID].self, forKey: .sessions) ?? []
        deleted = try container.decodeIfPresent([UUID].self, forKey: .deleted) ?? []
    }

    /// Of the phone's sessions, the ones to send the watch: missing there and not discarded there.
    public func missing(fromPhone phone: some Sequence<UUID>) -> [UUID] {
        let known = Set(sessions).union(deleted)
        return phone.filter { !known.contains($0) }
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
