import SwiftUI

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
