import SwiftUI

private struct DimmedKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// The wrist is down (Always On). `isLuminanceReduced`, except in a demo run with `-dim YES`, which can't be
    /// told to the system, so screenshots can show the dimmed screens.
    var dimmed: Bool {
        get { self[DimmedKey.self] }
        set { self[DimmedKey.self] = newValue }
    }
}
