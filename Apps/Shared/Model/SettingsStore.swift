import Foundation
import RepCoachCore

/// `TrainingSettings`, kept in UserDefaults. Edited on the iPhone; the watch gets them through sync (milestone 3).
@MainActor @Observable
final class SettingsStore {
    var settings: TrainingSettings {
        didSet { save() }
    }

    @ObservationIgnored private let defaults: UserDefaults
    private static let key = "trainingSettings"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        settings = defaults.data(forKey: Self.key)
            .flatMap { try? JSONDecoder().decode(TrainingSettings.self, from: $0) } ?? TrainingSettings()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: Self.key)
    }
}
