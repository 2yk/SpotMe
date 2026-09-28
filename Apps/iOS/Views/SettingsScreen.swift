import SwiftUI
import RepCoachCore

struct SettingsScreen: View {
    @Environment(SettingsStore.self) private var store
    @Environment(AppModel.self) private var app
    @Environment(PhoneSync.self) private var sync

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            Form {
                Section {
                    Toggle(isOn: scheduled) {
                        Label("Deload every \(app.plan.deloadEveryNthWeek)th week", systemImage: "calendar")
                    }
                    if store.settings.programStart != nil {
                        DatePicker(selection: startDate, displayedComponents: .date) {
                            Label("Program start", systemImage: "flag.checkered")
                        }
                    }
                    Toggle(isOn: manualDeload) {
                        Label("This week is a deload", systemImage: "leaf")
                    }
                } header: {
                    Text("Program")
                } footer: {
                    Text(programFooter)
                }
                .listRowBackground(Theme.card)

                Section {
                    LabeledContent {
                        Text(watchStatus.text).foregroundStyle(watchStatus.color)
                    } label: {
                        Label("Apple Watch", systemImage: "applewatch")
                    }
                    LabeledContent {
                        Text(sync.lastReceived.map { $0.formatted(.relative(presentation: .named)) } ?? "None yet")
                    } label: {
                        Label("Last session in", systemImage: "arrow.down.circle")
                    }
                    Toggle(isOn: $store.settings.restHaptics) {
                        Label("Rest timer haptics", systemImage: "applewatch.radiowaves.left.and.right")
                    }
                    Button {
                        sync.sendContext()
                    } label: {
                        Label("Send plan to watch", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .disabled(sync.watchState != .ready)
                } header: {
                    Text("Watch")
                } footer: {
                    Text("Sessions arrive after Finish workout on the watch, even if the phone was out of range. Rest haptics: a tap at 10 seconds left and another when rest is over.")
                }
                .listRowBackground(Theme.card)

                Section {
                    LabeledContent("Plan", value: "v\(app.plan.planVersion) · \(app.plan.days.map(\.items.count).reduce(0, +)) items")
                    LabeledContent("App", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")
                } header: {
                    Text("About")
                } footer: {
                    Image("Wordmark")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 36)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 32)
                        .accessibilityLabel("SpotMe")
                }
                .listRowBackground(Theme.card)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.canvas)
            .navigationTitle("Settings")
        }
    }

    private var settings: TrainingSettings { store.settings }

    private var watchStatus: (text: String, color: Color) {
        switch sync.watchState {
        case .ready: ("Connected", Theme.mint)
        case .appNotInstalled: ("App not installed", Theme.ember)
        case .notPaired: ("Not paired", Theme.ember)
        case .unsupported: ("Unavailable", Theme.tertiary)
        }
    }

    private var scheduled: Binding<Bool> {
        Binding(
            get: { settings.programStart != nil },
            set: { on in
                // Plan weeks run Monday to Sunday, so start on this week's Monday.
                store.settings.programStart = on
                    ? Calendar(identifier: .iso8601).dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
                    : nil
            }
        )
    }

    private var startDate: Binding<Date> {
        Binding(get: { settings.programStart ?? .now }, set: { store.settings.programStart = $0 })
    }

    private var manualDeload: Binding<Bool> {
        Binding(
            get: { settings.manualDeloadActive(on: .now) },
            set: { store.settings.manualDeloadSetOn = $0 ? .now : nil }
        )
    }

    private var programFooter: String {
        if settings.isDeload(on: .now, plan: app.plan) {
            return "This week is a deload: half the sets at about 85% of the weight. Deload sessions don't count toward progression."
        }
        guard let week = settings.programWeek(on: .now),
              let weeks = settings.weeksUntilDeload(on: .now, plan: app.plan) else {
            return "Set a start date and every \(app.plan.deloadEveryNthWeek)th week becomes a lighter deload week."
        }
        return "Week \(week) of the program. Next deload in \(weeks) week\(weeks == 1 ? "" : "s")."
    }
}
