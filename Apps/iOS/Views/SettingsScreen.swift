import SwiftUI
import SwiftData
import RepCoachCore

/// Settings (board 10.1), in look B: PROGRAM, APPLE HEALTH, WATCH, YOUR DATA and ABOUT as cards of rows 52 pt high,
/// switches and values at the right edge, volt for what you can tap, footers under each.
struct SettingsScreen: View {
    @Environment(SettingsStore.self) private var store
    @Environment(AppModel.self) private var app
    @Environment(TodayModel.self) private var today
    @Environment(PhoneSync.self) private var sync
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) private var openURL
    @State private var export = SetsExport(csv: "", date: .now, sessions: 0)
    @State private var scroll = ScrollPosition()

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    programGroup($store.settings.rampUps)
                    healthGroup($store.settings.healthWorkouts)
                    watchGroup($store.settings.restHaptics)
                    dataGroup
                    aboutGroup
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .scrollPosition($scroll)
            .background(Theme.canvas.ignoresSafeArea())
            .voltWash()
            .navigationTitle("Settings")
            .onAppear { export = SetsExport.current(context: context, today: today) }
            .onChange(of: sync.sessionsChanged) { export = SetsExport.current(context: context, today: today) }
            #if DEBUG
            .task { script() }
            #endif
        }
    }

    // MARK: Groups

    private func programGroup(_ rampUps: Binding<RampUpSetting>) -> some View {
        SpotFormGroup(
            title: "Program",
            footnotes: [programFooter, "Lighter sets before your first working set. They aren't counted."]
        ) {
            SpotSwitchRow(title: "Deload every \(app.plan.deloadEveryNthWeek)th week", isOn: scheduled)
            if store.settings.programStart != nil {
                SpotRow(title: "Program start") {
                    DatePicker("Program start", selection: startDate, displayedComponents: .date)
                        .labelsHidden()
                        .fixedSize()
                }
            }
            SpotSwitchRow(title: "This week is a deload", isOn: manualDeload)
            SpotMenuRow(title: "Ramp-up sets", selection: rampUps,
                        options: RampUpSetting.allCases.map { (value: $0, title: $0.title) })
        }
    }

    private func healthGroup(_ saves: Binding<Bool>) -> some View {
        SpotFormGroup(title: "Apple Health", footnotes: [healthFooter]) {
            SpotSwitchRow(title: "Save workouts to Health", isOn: saves)
            SpotRow(title: "Watch access") { SpotValue(text: healthAccess.text, color: healthAccess.color) }
            SpotActionRow(title: "Open the Health app") {
                if let url = URL(string: "x-apple-health://") { openURL(url) }
            }
        }
    }

    private func watchGroup(_ haptics: Binding<Bool>) -> some View {
        SpotFormGroup(
            title: "Watch",
            footnotes: ["Sessions arrive after Finish workout on the watch, even if the phone was out of range. Rest haptics: a tap at 10 seconds left and another when rest is over."]
        ) {
            SpotRow(title: "Apple Watch") { SpotValue(text: watchStatus.text, color: watchStatus.color) }
            SpotRow(title: "Last session in") { SpotValue(text: lastSession, color: Theme.text2) }
            SpotSwitchRow(title: "Rest timer haptics", isOn: haptics)
            SpotActionRow(title: "Send plan to watch") { sync.sendContext() }
                .disabled(!watchReady)
                .opacity(watchReady ? 1 : 0.4)
        }
    }

    private var dataGroup: some View {
        SpotFormGroup(title: "Your data", footnotes: [exportFooter]) {
            ExportSetsLink(export: export) {
                SpotActionLabel(title: "Export all sets", icon: "square.and.arrow.up")
            }
            .buttonStyle(RowPressStyle())
            .opacity(export.sessions == 0 ? 0.4 : 1)
        }
    }

    private var aboutGroup: some View {
        VStack(spacing: 28) {
            SpotFormGroup(title: "About") {
                SpotRow(title: "Plan") {
                    SpotValue(text: "v\(app.plan.planVersion) · \(app.plan.days.map(\.items.count).reduce(0, +)) items",
                              color: Theme.text2)
                }
                SpotRow(title: "App") {
                    SpotValue(text: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
                              color: Theme.text2)
                }
            }
            HStack(spacing: 10) {
                CradleMark()
                    .frame(width: 24, height: 18)
                Text("SpotMe").font(.system(size: 24, weight: .heavy, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("SpotMe")
        }
    }

    // MARK: Values

    private var settings: TrainingSettings { store.settings }

    private var watchReady: Bool {
        #if DEBUG
        if sampleWatch { return true }
        #endif
        return sync.watchState == .ready
    }

    private var lastSession: String {
        #if DEBUG
        // `-sampleWatch YES`: what the board shows, for a demo that has no watch.
        if sampleWatch { return "yesterday" }
        #endif
        return sync.lastReceived.map { $0.formatted(.relative(presentation: .named)) } ?? "None yet"
    }

    private var watchStatus: (text: String, color: Color) {
        #if DEBUG
        if sampleWatch { return ("Connected", Theme.mint) }
        #endif
        return switch sync.watchState {
        case .ready: ("Connected", Theme.mint)
        case .appNotInstalled: ("App not installed", Theme.ember)
        case .notPaired: ("Not paired", Theme.ember)
        case .unsupported: ("Unavailable", Theme.text3)
        }
    }

    /// The watch's own Health access: watchOS asks on the watch, the Health app on the iPhone changes it.
    private var healthAccess: (text: String, color: Color) {
        #if DEBUG
        if sampleWatch { return ("Allowed", Theme.mint) }
        #endif
        return switch sync.watchHealthAccess {
        case .allowed: ("Allowed", Theme.mint)
        case .denied: ("Not allowed", Theme.ember)
        case .notAsked: ("Not asked yet", Theme.text2)
        case nil: ("Unknown", Theme.text3)
        }
    }

    private var exportFooter: String {
        export.sessions == 0
            ? "Nothing logged on this iPhone yet."
            : "A CSV file with every set from \(export.sessions) session\(export.sessions == 1 ? "" : "s"), for Numbers, Excel or Google Sheets."
    }

    private var healthFooter: String {
        guard settings.healthWorkouts else {
            let awake = sync.watchHealthAccess == .allowed
                ? "While you train, the watch still runs a workout so rests end on time with your wrist down, and "
                    + "throws it away when you finish."
                : "With Health access, the watch would also keep rests on time with your wrist down."
            return "Nothing goes to Health; your sets stay in SpotMe. " + awake
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

    #if DEBUG
    private var sampleWatch: Bool { LaunchOptions.demo && UserDefaults.standard.bool(forKey: "sampleWatch") }

    /// `-programStart 2026-09-14`: a program start for the demo, so the Program group shows its date and week.
    /// `-scroll 600`: scrolled down.
    private func script() {
        if store.settings.programStart == nil,
           let text = UserDefaults.standard.string(forKey: "programStart"),
           let date = try? Date(text, strategy: .iso8601.year().month().day()) {
            store.settings.programStart = date
        }
        let offset = UserDefaults.standard.double(forKey: "scroll")
        if offset > 0 { scroll.scrollTo(y: offset) }
    }
    #endif
}

private extension RampUpSetting {
    var title: String {
        switch self {
        case .off: "Off"
        case .mainLifts: "Main lifts"
        case .everyWeightedLift: "Every weighted lift"
        }
    }
}
