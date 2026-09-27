import SwiftUI
import RepCoachCore

// Placeholder so the project builds on day one. Milestone 2 in CLAUDE.md replaces this
// with the real Today → Set → Rest flow described in docs/SPEC.md.
@main
struct RepCoachWatchApp: App {
    var body: some Scene {
        WindowGroup {
            TodayPlaceholderView()
        }
    }
}

struct TodayPlaceholderView: View {
    private let day: PlanDay? = try? Plan.bundled().day(for: .now)

    var body: some View {
        NavigationStack {
            List(day?.items ?? []) { item in
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name).font(.headline)
                    if let display = item.display {
                        Text(display).font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(day?.title ?? "RepCoach")
        }
    }
}
