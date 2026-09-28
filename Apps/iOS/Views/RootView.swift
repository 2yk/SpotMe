import SwiftUI
import RepCoachCore

struct RootView: View {
    @Environment(TodayModel.self) private var today
    @Environment(SettingsStore.self) private var settings
    @Environment(PhoneSync.self) private var sync
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab = RootTab.today

    enum RootTab: Hashable {
        case today, history, plan, settings
    }

    var body: some View {
        TabView(selection: $tab) {
            Tab("Today", systemImage: "bolt.fill", value: .today) {
                TodayScreen()
            }
            Tab("History", systemImage: "chart.xyaxis.line", value: .history) {
                HistoryScreen()
            }
            Tab("Plan", systemImage: "list.bullet.rectangle.portrait", value: .plan) {
                PlanScreen()
            }
            Tab("Settings", systemImage: "gearshape", value: .settings) {
                SettingsScreen()
            }
        }
        .onChange(of: settings.settings) {
            today.refresh()
            sync.sendContext()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { today.wake() }
        }
        #if DEBUG
        .task {
            switch LaunchOptions.screen {
            case "history", "exercise": tab = .history
            case "plan", "editor": tab = .plan
            case "settings": tab = .settings
            default: break
            }
        }
        #endif
    }
}
