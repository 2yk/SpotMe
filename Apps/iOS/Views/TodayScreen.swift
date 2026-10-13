import SwiftUI
import SwiftData
import RepCoachCore

/// The day's plan in look B (boards 7.1–7.6): the hero with what changes today, the button to start or continue the
/// workout, and the sections of the day with a figure on every lift. A tap on a row opens the exercise.
struct TodayScreen: View {
    @Environment(TodayModel.self) private var today
    @Query(sort: \BodyMeasurement.date, order: .reverse) private var measurements: [BodyMeasurement]
    @State private var detail: SlotRef?
    @State private var measuring = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    DayStrip(days: today.plan.days, selected: today.dayKey, todayWeekday: today.todayWeekday) { key in
                        withAnimation(.snappy) { today.select(key) }
                    }
                    TodayHero()
                    if today.showsAsToday { StartButton() }
                    // Only once the body log is in use: a nudge when the two weeks are up.
                    if !measurements.isEmpty, BodyLog.isDue(measurements.map(\.entry)) {
                        Button { measuring = true } label: { BodyLogDue() }
                            .buttonStyle(.plain)
                    }
                    if today.queue.isComplete { AllDoneCard() }
                    ForEach(today.day.sections) { section in
                        DepthSection(title: section.title) {
                            ForEach(section.items) { item in
                                Button { detail = SlotRef(id: today.slot(of: item).exerciseId) } label: {
                                    TodayRow(item: item)
                                }
                                .buttonStyle(RowPressStyle())
                                if item.id != section.items.last?.id { DepthDivider() }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .background(Theme.canvas.ignoresSafeArea())
            .voltWash()
            .navigationTitle(today.showsAsToday ? "Today" : today.day.title)
            .sheet(item: $detail) { slot in
                ExerciseSheet(slotId: slot.id)
            }
            .sheet(isPresented: $measuring) {
                AddMeasurementSheet(last: measurements.first)
            }
            #if DEBUG
            .task { await PhoneScript.today(today: today, detail: $detail) }
            #endif
        }
    }
}

// MARK: Hero

/// The day's card: its name, what is different today, how far along it is, and the day's first lift moving.
private struct TodayHero: View {
    @Environment(TodayModel.self) private var today

    var body: some View {
        let day = today.day
        let done = today.queue.doneCount
        let total = today.queue.totalCount
        let running = today.session != nil && done > 0
        let counts = today.changeCounts
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text(day.title).depthEyebrow(Theme.volt)
                if today.isDeload { Chip(text: "DELOAD WEEK", tint: Theme.ember, size: 12) }
            }
            Text(day.headline)
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .padding(.top, 2)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            Text(day.subtitle)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.text2)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                meta("clock", Theme.text2, day.time)
                if today.isDeload {
                    meta("arrow.down", Theme.ember, "Half the sets at 85%")
                } else {
                    if counts.up > 0 { meta("arrow.up", Theme.volt, counts.up == 1 ? "1 goes up" : "\(counts.up) go up") }
                    if counts.lighter > 0 { meta("arrow.down", Theme.ember, "\(counts.lighter) lighter") }
                }
            }
            .padding(.top, 14)
            if running, total > 0 {
                HStack(spacing: 12) {
                    Capsule()
                        .fill(Theme.raised)
                        .frame(width: 134, height: 6)
                        .overlay(alignment: .leading) {
                            Capsule().fill(Theme.volt).frame(width: 134 * CGFloat(done) / CGFloat(total), height: 6)
                        }
                    Text("\(done) of \(total) done")
                        .font(PhoneFont.foot)
                        .foregroundStyle(Theme.text2)
                        .fixedSize()
                }
                .padding(.top, 14)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(done) of \(total) done")
            }
        }
        .frame(width: 200, alignment: .leading)
        .padding(22)
        .frame(maxWidth: .infinity, minHeight: 186, alignment: .topLeading)
        .background(alignment: .bottomTrailing) { HeroFigure() }
        .background { DepthSurface(radius: 28) }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func meta(_ symbol: String, _ tint: Color, _ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: symbol == "clock" ? 14 : 13, weight: symbol == "clock" ? .medium : .bold))
                .foregroundStyle(tint)
                .frame(width: 16)
            Text(text).font(PhoneFont.sub).foregroundStyle(Theme.text2).lineLimit(1)
        }
    }
}

/// The day's first lift, moving at 170 pt in the card's corner with a volt glow behind it.
private struct HeroFigure: View {
    @Environment(TodayModel.self) private var today

    var body: some View {
        if let item = today.day.items.first(where: { $0.kind != .checklist && ExerciseFigure.of($0) != nil }),
           let figure = ExerciseFigure.of(item) {
            ZStack {
                RadialGradient(colors: [Theme.volt.opacity(0.10), Theme.volt.opacity(0)], center: .center,
                               startRadius: 0, endRadius: 120)
                    .frame(width: 240, height: 240)
                FigureView(exercise: figure, yaw: figure.figure.openingYaw, size: 170)
            }
            .offset(x: 22, y: 10)
            .padding(.trailing, 6)
            .accessibilityHidden(true)
        }
    }
}

extension TodayModel {
    /// The day on show is today's. A demo run with `-day` stands in for it, so screenshots show the day as it looks
    /// on its own weekday.
    var showsAsToday: Bool {
        #if DEBUG
        if LaunchOptions.demo, LaunchOptions.dayKey == dayKey { return true }
        #endif
        return isToday
    }

    /// The weekday number the day strip dots as today.
    var todayWeekday: Int {
        #if DEBUG
        if LaunchOptions.demo, let key = LaunchOptions.dayKey, let day = plan.days.first(where: { $0.key == key }) {
            return day.weekday
        }
        #endif
        return calendar.component(.weekday, from: .now)
    }

    /// How many of today's exercises go up in weight and how many are lighter: the engine's own reasons.
    var changeCounts: (up: Int, lighter: Int) {
        var up = 0, lighter = 0
        for item in day.items where item.kind == .weighted {
            switch target(for: item).session?.reason {
            case .increase: up += 1
            case .decrease: lighter += 1
            default: break
            }
        }
        return (up, lighter)
    }
}

// MARK: Start

/// Start workout, then Continue with the item and set while the workout runs; gone once everything is done.
private struct StartButton: View {
    @Environment(TodayModel.self) private var today
    @Environment(WatchLauncher.self) private var launcher

    var body: some View {
        if !today.queue.isComplete, !today.isFinished {
            let next = today.queue.upNext.first
            let running = today.session != nil && today.queue.doneCount > 0
            Button { launcher.start() } label: {
                if running, let next {
                    VStack(spacing: 0) {
                        Text("Continue")
                        Text(continueLine(next))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.black.opacity(0.66))
                            .lineLimit(1)
                    }
                } else {
                    Text("Start workout")
                }
            }
            .buttonStyle(PrimaryButtonStyle(height: running ? 64 : 56))
            .padding(.bottom, 4)
        }
    }

    private func continueLine(_ item: PlanItem) -> String {
        guard item.kind != .checklist else { return item.name }
        var set = 1
        if case .inProgress(let done) = today.status(of: item) { set = done + 1 }
        return "\(item.name) · Set \(set) of \(today.target(for: item).sets)"
    }
}

// MARK: Cards

/// Two weeks since the last measurement.
private struct BodyLogDue: View {
    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Body log due").font(PhoneFont.headline).foregroundStyle(.white)
                Text("Measure yourself: weight, arms, waist and the rest")
                    .font(PhoneFont.sub)
                    .foregroundStyle(Theme.text2)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 8)
            Image(systemName: "plus")
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(.black)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Theme.volt))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .depthCard()
        .padding(.vertical, 4)
    }
}

/// Everything done: how long, how much and how hard.
private struct AllDoneCard: View {
    @Environment(TodayModel.self) private var today

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark")
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(Theme.mint)
                .frame(width: 52, height: 52)
                .background(Circle().fill(Theme.mint.opacity(0.18)))
            VStack(alignment: .leading, spacing: 0) {
                Text("All \(today.queue.totalCount) done").font(PhoneFont.title2)
                if let line = summary {
                    Text(line).font(PhoneFont.sub).foregroundStyle(Theme.text2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { DepthSurface(radius: 28, tint: Theme.mint) }
        .padding(.vertical, 4)
    }

    /// "62 min · 395 kcal · Hard 7", whatever of it the watch has sent.
    private var summary: String? {
        guard let session = today.session else { return nil }
        var parts: [String] = []
        if let seconds = session.activeSeconds, seconds > 0 { parts.append("\(Int((seconds / 60).rounded())) min") }
        if let kcal = session.energyKcal, kcal > 0 { parts.append("\(Int(kcal.rounded())) kcal") }
        if let effort = session.effort { parts.append("\(EffortBand(effort).word) \(effort)") }
        return parts.isEmpty ? "Great session. Recovery starts now." : parts.joined(separator: " · ")
    }
}

// MARK: Rows

/// One exercise of the day: its figure, name and prescription, and on the right today's weight with its arrow and a
/// word on why. Done rows are dimmed with a check.
private struct TodayRow: View {
    @Environment(TodayModel.self) private var today
    let item: PlanItem

    var body: some View {
        let info = today.rowInfo(for: item)
        let done = info.isFinished && !info.isSkipped
        HStack(spacing: 12) {
            RowFigure(item: item)
                .opacity(info.isFinished ? 0.6 : 1)
            VStack(alignment: .leading, spacing: 0) {
                Text(item.name)
                    .font(PhoneFont.headline)
                    .foregroundStyle(info.isFinished ? Theme.text2 : .white)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    if info.isSwapped { SwapIcon(size: 15, color: Theme.text3) }
                    Text(info.isSkipped ? "Skipped" : info.detail)
                        .font(PhoneFont.sub)
                        .foregroundStyle(info.isFinished ? Theme.text2 : info.detailColor)
                        .lineLimit(info.detailLines)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if done {
                Image(systemName: "checkmark")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.mint)
                    .frame(width: 20)
            } else if !info.isFinished {
                trailing(info)
            }
        }
        .padding(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 16))
        .frame(minHeight: 64)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func trailing(_ info: RowInfo) -> some View {
        if info.isFirstTime {
            Text("First time").font(PhoneFont.headline).foregroundStyle(.white)
        } else if let weight = info.weight {
            VStack(alignment: .trailing, spacing: 0) {
                HStack(spacing: 4) {
                    if let arrow = info.arrow {
                        Image(systemName: arrow == .up ? "arrow.up" : "arrow.down")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(arrow == .up ? Theme.volt : Theme.ember)
                    }
                    Text(weight).font(.system(size: 17, weight: .bold, design: .rounded))
                }
                if let tag = today.rowTag(for: item) {
                    Text(tag.text)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(tag.color)
                }
            }
            .fixedSize()
        }
    }
}

/// The 44 pt slot on the left of a row: the exercise's figure still, the clock for a tick-off item, or nothing.
struct RowFigure: View {
    let item: PlanItem

    var body: some View {
        Group {
            if let figure = ExerciseFigure.of(item) {
                FigureView(exercise: figure, yaw: figure.figure.openingYaw, size: 44, moving: false)
            } else if item.kind == .checklist || item.kind == .percentOfMax {
                Image(systemName: "clock")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(Theme.text2)
            } else {
                Color.clear
            }
        }
        .frame(width: 44, height: 44)
        .accessibilityHidden(true)
    }
}

extension TodayModel {
    /// The word under a weight on Today: "+5 kg", "+reps", "lighter", "deload", "set weight".
    func rowTag(for item: PlanItem) -> (text: String, color: Color)? {
        guard item.kind == .weighted, let session = target(for: item).session else { return nil }
        let text = Coach.tag(session, increment: item.increment ?? 2.5)
        switch session.reason {
        case .increase, .firstTime: return (text, Theme.volt)
        case .decrease, .deload: return (text, Theme.ember)
        case .repeatWeight: return (text, Theme.text3)
        }
    }
}
