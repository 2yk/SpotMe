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

private struct DimmedRoot: ViewModifier {
    @Environment(\.isLuminanceReduced) private var luminanceReduced

    func body(content: Content) -> some View {
        #if DEBUG
        let forced = LaunchOptions.demo && UserDefaults.standard.bool(forKey: "dim")
        #else
        let forced = false
        #endif
        content.environment(\.dimmed, luminanceReduced || forced)
    }
}

extension View {
    /// Call once at the root: every screen under it reads `\.dimmed`.
    func dimmedRoot() -> some View { modifier(DimmedRoot()) }
}
