import Foundation

/// Whether the watch app may save workouts to Health, as HealthKit reports it on the watch.
public enum HealthAccess: String, Codable, Sendable {
    /// The watch asks the first time Start workout is tapped.
    case notAsked
    case allowed
    /// Only the Health app can turn it back on.
    case denied
}

/// What the watch tells the phone about itself (WatchConnectivity application context, latest wins),
/// for the phone's Settings screen.
public struct WatchStatus: Codable, Equatable, Sendable {
    public var healthAccess: HealthAccess

    public init(healthAccess: HealthAccess) {
        self.healthAccess = healthAccess
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
