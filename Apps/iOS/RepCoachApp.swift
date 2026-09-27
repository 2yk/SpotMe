import SwiftUI
import RepCoachCore

// Placeholder so the project builds on day one. Milestone 3 in CLAUDE.md replaces this
// with History, Plan and Settings as described in docs/SPEC.md.
@main
struct RepCoachApp: App {
    var body: some Scene {
        WindowGroup {
            PlanPlaceholderView()
        }
    }
}

struct PlanPlaceholderView: View {
    private let plan: Plan? = try? Plan.bundled()

    var body: some View {
        NavigationStack {
            List(plan?.days ?? []) { day in
                Section(day.title) {
                    ForEach(day.items) { item in
                        HStack {
                            Text(item.name)
                            Spacer()
                            Text(item.display ?? "").foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("RepCoach")
        }
    }
}
