import SwiftUI
import SwiftData
import RepCoachCore

/// Every body point with its latest value and how it moved (boards 8.4, 8.5), and the waist rule when it trips.
struct BodyLogScreen: View {
    @Query(sort: \BodyMeasurement.date, order: .reverse) private var measurements: [BodyMeasurement]
    @State private var adding = false

    var body: some View {
        let entries = measurements.map(\.entry)
        let change = BodyLog.change(entries)
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let change, change.waistWarning {
                    WaistWarning(change: change)
                }
                if let latest = measurements.first {
                    Text(caption(latest.date, change))
                        .font(PhoneFont.foot)
                        .foregroundStyle(Theme.text3)
                        .padding(.horizontal, 6)
                    VStack(spacing: 0) {
                        ForEach(BodyPoint.allCases) { point in
                            NavigationLink(value: HistoryRoute.point(point)) {
                                BodyRow(point: point, value: latestValue(point), change: change?.deltas[point])
                            }
                            .buttonStyle(RowPressStyle())
                            if point != BodyPoint.allCases.last { DepthDivider(inset: 16) }
                        }
                    }
                    .depthRows()
                    Text("Every two weeks, same time of day, before breakfast. Arm flexed at its widest; waist at the navel, relaxed.")
                        .font(PhoneFont.foot)
                        .foregroundStyle(Theme.text3)
                        .padding(.horizontal, 6)
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Measure yourself every two weeks: weight, arms, waist and the rest. SpotMe warns you if your waist grows while your arms don't.")
                            .font(PhoneFont.body)
                            .foregroundStyle(Theme.text2)
                        Button("Add your first measurement") { adding = true }
                            .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(18)
                    .depthCard()
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(Theme.canvas)
        .navigationTitle("Body")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { adding = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add measurement")
            }
        }
        .sheet(isPresented: $adding) {
            AddMeasurementSheet(last: measurements.first)
        }
        #if DEBUG
        .task { if LaunchOptions.screen == "body-add" { adding = true } }
        #endif
    }

    /// The newest value measured for a point, which may be an older measurement than the latest.
    private func latestValue(_ point: BodyPoint) -> Double? {
        measurements.lazy.compactMap { $0[point] }.first
    }

    private func caption(_ latest: Date, _ change: BodyLog.Change?) -> String {
        let measured = "Measured \(latest.formatted(.dateTime.day().month(.abbreviated)))"
        guard let change else { return measured }
        return "\(measured) · change since \(change.since.formatted(.dateTime.day().month(.abbreviated)))"
    }
}

private struct BodyRow: View {
    let point: BodyPoint
    let value: Double?
    let change: Double?

    var body: some View {
        HStack {
            Text(point.title).font(PhoneFont.headline).foregroundStyle(.white)
            Spacer()
            VStack(alignment: .trailing, spacing: 0) {
                Text(value.map { point.format($0) } ?? "—")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(value == nil ? Theme.text3 : .white)
                    .monospacedDigit()
                if let change {
                    BodyChangeText(point: point, change: change)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(minHeight: 65)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// The waist rule, when it trips.
private struct WaistWarning: View {
    let change: BodyLog.Change

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 18, weight: .semibold))
            Text("Waist \(Format.inchesChange(change.waist ?? 0)) since \(change.since.formatted(.dateTime.day().month(.abbreviated))) while your arms haven't grown. That's likely more fat than muscle: trim calories a little.")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(Theme.ember)
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Theme.emberWash)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: One point

/// One body point over time (board 8.8): where it is, how far it came, a chart and every measurement.
struct BodyPointScreen: View {
    let point: BodyPoint
    @Query(sort: \BodyMeasurement.date, order: .reverse) private var measurements: [BodyMeasurement]
    @Environment(\.modelContext) private var context
    @State private var deleting: BodyMeasurement?

    var body: some View {
        let rows = measurements.compactMap { measurement in measurement[point].map { (measurement, $0) } }
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                tiles(rows.map { ($0.0.date, $0.1) })
                if rows.count > 1 {
                    SeriesChart(dates: rows.reversed().map { $0.0.date }, main: rows.reversed().map(\.1), height: 200,
                                top: 18, bottom: 32, maxTicks: 3, left: 40)
                        .padding(18)
                        .depthCard()
                        .accessibilityLabel("\(point.title) over time")
                }
                VStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.element.0.id) { index, row in
                        HStack {
                            Text(row.0.date, format: .dateTime.day().month(.abbreviated).year())
                                .font(PhoneFont.body)
                            Spacer()
                            Text(point.format(row.1))
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(index == 0 ? Theme.volt : .white)
                                .monospacedDigit()
                        }
                        .padding(.horizontal, 16)
                        .frame(minHeight: 53)
                        .contentShape(Rectangle())
                        .contextMenu {
                            Button("Delete measurement", systemImage: "trash", role: .destructive) { deleting = row.0 }
                        }
                        if index < rows.count - 1 { DepthDivider(inset: 16) }
                    }
                }
                .depthRows()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(Theme.canvas)
        .navigationTitle(point.title)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete this measurement?", isPresented: Binding(get: { deleting != nil },
                                                                              set: { if !$0 { deleting = nil } }),
                            titleVisibility: .visible) {
            Button("Delete measurement", role: .destructive) {
                if let deleting {
                    context.delete(deleting)
                    try? context.save()
                }
                deleting = nil
            }
        } message: {
            Text("It takes every point of that day with it.")
        }
    }

    /// Newest first.
    private func tiles(_ rows: [(date: Date, value: Double)]) -> some View {
        let now = rows.first?.value
        let first = rows.last
        let moved = (now != nil && first != nil && rows.count > 1) ? now! - first!.value : nil
        return HStack(spacing: 8) {
            DepthTile(label: "Now", value: now.map { Format.weight($0) } ?? "—",
                      unit: now == nil ? nil : (point.isWeight ? "kg" : "″"), tint: Theme.volt, tightUnit: !point.isWeight)
            DepthTile(label: rows.count > 1 ? "Since \(first!.date.formatted(.dateTime.day().month(.abbreviated)))" : "Change",
                      value: moved.map { point.formatChange($0) } ?? "—")
            DepthTile(label: "Measured", value: "\(rows.count)")
        }
    }
}

// MARK: New measurement

/// A new measurement (board 8.6): every point optional, starting from the last values.
struct AddMeasurementSheet: View {
    let last: BodyMeasurement?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date.now
    @State private var values: [BodyPoint: Double] = [:]

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Date").font(PhoneFont.body)
                        Spacer()
                        DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: .date)
                            .labelsHidden()
                    }
                    .padding(.horizontal, 16)
                    .frame(minHeight: 52)
                    .depthRows(radius: 20)

                    ForEach(BodyPoint.Group.allCases, id: \.self) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(group.title).depthEyebrow().padding(.leading, 6)
                            VStack(spacing: 0) {
                                ForEach(group.points) { point in
                                    MeasurementRow(point: point, value: binding(point))
                                    if point != group.points.last { DepthDivider(inset: 16) }
                                }
                            }
                            .depthRows(radius: 20)
                        }
                    }
                    Text("Fill in what you measured; leave the rest blank. Type a number, or step by a quarter inch (weight by 0.1 kg).")
                        .font(PhoneFont.foot)
                        .foregroundStyle(Theme.text3)
                        .padding(.horizontal, 6)
                }
                .padding(.horizontal, 16)
                .padding(.top, 76)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)

            HStack {
                Button("Cancel") { dismiss() }
                    .font(PhoneFont.body)
                    .foregroundStyle(Theme.volt)
                Spacer()
                Button("Save", action: save)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(values.isEmpty ? Theme.text3 : Theme.volt)
                    .disabled(values.isEmpty)
            }
            .overlay { Text("Measurement").font(PhoneFont.headline) }
            .padding(.horizontal, 20)
            .frame(height: 44)
            .padding(.top, 20)
        }
        .background(Theme.sheet)
        .sheetSurface()
        .onAppear {
            guard values.isEmpty, let last else { return }
            for point in BodyPoint.allCases { if let value = last[point] { values[point] = value } }
        }
    }

    private func binding(_ point: BodyPoint) -> Binding<Double?> {
        Binding(get: { values[point] }, set: { values[point] = $0 })
    }

    private func save() {
        let measurement = BodyMeasurement(date: date)
        for (point, value) in values { measurement[point] = value }
        context.insert(measurement)
        try? context.save()
        dismiss()
    }
}

/// One point of the sheet: its value, typed or stepped.
private struct MeasurementRow: View {
    let point: BodyPoint
    @Binding var value: Double?

    var body: some View {
        HStack(spacing: 8) {
            Text(point.title).font(PhoneFont.body)
            Spacer(minLength: 8)
            HStack(spacing: 0) {
                TextField("—", value: $value, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(PhoneFont.body)
                    .monospacedDigit()
                    .frame(width: 64)
                Text(point.isWeight ? " kg" : "″")
                    .font(PhoneFont.body)
                    .foregroundStyle(Theme.text2)
                    .frame(width: point.isWeight ? 26 : 10, alignment: .leading)
                    .offset(x: point.isWeight ? 0 : -1)
            }
            MeasureStepper(minus: { step(-1) }, plus: { step(1) })
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 52)
    }

    /// The first tap on a blank point lands on its starting value; after that it moves by one step.
    private func step(_ direction: Double) {
        guard let current = value else {
            value = point.startValue
            return
        }
        let moved = ((current + direction * point.step) / point.step).rounded() * point.step
        value = min(max(moved, point.range.lowerBound), point.range.upperBound)
    }
}

/// The minus and plus of a measurement: a 94 × 32 capsule split by a line.
struct MeasureStepper: View {
    let minus: () -> Void
    let plus: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: minus) { Image(systemName: "minus").frame(maxWidth: .infinity, maxHeight: .infinity) }
                .accessibilityLabel("Decrease")
            Rectangle().fill(Color.white.opacity(0.16)).frame(width: 1, height: 18)
            Button(action: plus) { Image(systemName: "plus").frame(maxWidth: .infinity, maxHeight: .infinity) }
                .accessibilityLabel("Increase")
        }
        .font(.system(size: 16, weight: .bold))
        .foregroundStyle(.white)
        .buttonStyle(.plain)
        .frame(width: 94, height: 32)
        .background(Capsule().fill(Theme.raised))
    }
}
