import SwiftUI
import RepCoachCore

struct SettingsScreen: View {
    @Environment(SettingsStore.self) private var store
    @Environment(AppModel.self) private var app
    @Environment(PhoneSync.self) private var sync
    @Environment(\.openURL) private var openURL

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
                    Toggle(isOn: $store.settings.healthWorkouts) {
                        Label("Save workouts to Health", systemImage: "heart.fill")
                    }
                    if settings.healthWorkouts {
                        LabeledContent {
                            Text(healthAccess.text).foregroundStyle(healthAccess.color)
                        } label: {
                            Label("Watch access", systemImage: "lock.shield")
                        }
                        Button {
                            if let url = URL(string: "x-apple-health://") { openURL(url) }
                        } label: {
                            Label("Open the Health app", systemImage: "arrow.up.forward.app")
                        }
                    }
                } header: {
                    Text("Apple Health")
                } footer: {
                    Text(healthFooter)
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

    /// The watch's own Health access: watchOS asks on the watch, the Health app on the iPhone changes it.
    private var healthAccess: (text: String, color: Color) {
        switch sync.watchHealthAccess {
        case .allowed: ("Allowed", Theme.mint)
        case .denied: ("Not allowed", Theme.ember)
        case .notAsked: ("Not asked yet", Theme.secondary)
        case nil: ("Unknown", Theme.tertiary)
        }
    }

    private var healthFooter: String {
        guard settings.healthWorkouts else {
            return "The watch hides Start workout. Sets you log stay in SpotMe and nothing goes to Health."
        }
        let manage = "To change it: Health app → your profile picture → Apps → SpotMe."
        switch sync.watchHealthAccess {
        case .denied:
            return "Your watch isn't allowed to save workouts, so Start workout can't record one. In the Health app, "
                + "tap your profile picture, then Apps → SpotMe, and turn everything on."
        case .notAsked:
            return "Your watch asks for Health access the first time you tap Start workout. " + manage
        default:
            return "Start workout on the watch records a strength training workout with your heart rate and saves "
                + "it to Health when you finish. " + manage
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
