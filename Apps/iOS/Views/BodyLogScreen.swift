import SwiftUI
import SwiftData
import Charts
import RepCoachCore

/// History's body card: the latest flexed arm and waist, how they moved, and whether a measurement is due.
struct BodyLogCard: View {
    @Query(sort: \BodyMeasurement.date, order: .reverse) private var measurements: [BodyMeasurement]

    var body: some View {
        let entries = measurements.map(\.entry)
        let change = BodyLog.change(entries)
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Body").eyebrow(Theme.volt, size: 12)
                Spacer()
                if BodyLog.isDue(entries) {
                    Chip(text: entries.isEmpty ? "Start" : "Due", tint: Theme.volt)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.tertiary)
            }
            if let latest = measurements.first {
                HStack(spacing: 10) {
                    MeasureTile(label: "Arm", value: latest.arm, change: change?.arm, better: .up)
                    MeasureTile(label: "Waist", value: latest.waist, change: change?.waist, better: .down)
                }
                if let change, change.waistWarning {
                    WaistWarning(change: change)
                } else if let change {
                    Text("Since \(change.since, format: .dateTime.day().month(.abbreviated))")
                        .font(.rounded(.footnote, .medium))
                        .foregroundStyle(Theme.tertiary)
                }
            } else {
                Text("Measure your flexed arm and your waist every two weeks. SpotMe warns you if your waist grows while your arms don't.")
                    .font(.rounded(.subheadline))
                    .foregroundStyle(Theme.secondary)
            }
        }
        .padding(18)
        .card(Theme.card, radius: 24)
    }
}

/// Every measurement, the arm and waist over time, and the waist rule.
struct BodyLogScreen: View {
    @Query(sort: \BodyMeasurement.date, order: .reverse) private var measurements: [BodyMeasurement]
    @Environment(\.modelContext) private var context
    @State private var adding = false

    var body: some View {
        let change = BodyLog.change(measurements.map(\.entry))
        List {
            if let change, change.waistWarning {
                Section {
                    WaistWarning(change: change)
                }
                .listRowBackground(Theme.ember.opacity(0.14))
            }
            if measurements.count > 1 {
                Section {
                    TrendChart(title: "Flexed arm", tint: Theme.volt, points: measurements.map { ($0.date, $0.arm) })
                    TrendChart(title: "Waist", tint: Theme.ember, points: measurements.map { ($0.date, $0.waist) })
                }
                .listRowBackground(Theme.card)
            }
            Section {
                if measurements.isEmpty {
                    Button { adding = true } label: {
                        Label("Add your first measurement", systemImage: "plus.circle.fill")
                            .foregroundStyle(Theme.volt)
                    }
                }
                ForEach(measurements) { measurement in
                    HStack {
                        Text(measurement.date, format: .dateTime.day().month(.abbreviated).year())
                        Spacer()
                        Text("Arm \(Format.inches(measurement.arm))").foregroundStyle(Theme.volt)
                        Text("Waist \(Format.inches(measurement.waist))").foregroundStyle(Theme.ember)
                    }
                    .font(.rounded(.subheadline, .semibold))
                    .monospacedDigit()
                }
                .onDelete { offsets in
                    offsets.map { measurements[$0] }.forEach(context.delete)
                    try? context.save()
                }
            } header: {
                Text("Every two weeks")
            } footer: {
                Text("Arm: flexed, at its widest. Waist: at the navel, relaxed. Same time of day each time, ideally before breakfast.")
            }
            .listRowBackground(Theme.card)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.canvas)
        .navigationTitle("Body")
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
}

/// A new arm and waist measurement, starting from the last one.
struct AddMeasurementSheet: View {
    let last: BodyMeasurement?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date.now
    @State private var arm = 14.0
    @State private var waist = 32.0

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: .date)
                    InchesField(title: "Flexed arm", value: $arm, range: 8...30)
                    InchesField(title: "Waist", value: $waist, range: 20...70)
                } footer: {
                    Text("Arm: flexed, at its widest. Waist: at the navel, relaxed. Type a number, or step by a quarter inch.")
                }
                .listRowBackground(Theme.card)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.canvas)
            .navigationTitle("Measurement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        context.insert(BodyMeasurement(date: date, arm: arm, waist: waist))
                        try? context.save()
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                if let last {
                    arm = last.arm
                    waist = last.waist
                }
            }
        }
        .presentationDetents([.medium])
    }
}

/// A measurement in inches: type it, or step by a quarter inch.
private struct InchesField: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField(title, value: $value, format: .number.precision(.fractionLength(0...2)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .frame(width: 64)
            Text("″").foregroundStyle(Theme.secondary)
            Stepper(title, value: $value, in: range, step: 0.25)
                .labelsHidden()
        }
    }
}

/// The latest value and its change since the comparison, green when it moved the right way.
private struct MeasureTile: View {
    enum Better { case up, down }

    let label: String
    let value: Double
    let change: Double?
    let better: Better

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).eyebrow(Theme.tertiary, size: 10)
            Text(Format.inches(value))
                .font(.number(24))
                .monospacedDigit()
            if let change {
                let good = better == .up ? change > 0 : change < 0
                Text(Format.inchesChange(change))
                    .font(.rounded(.footnote, .bold))
                    .foregroundStyle(change == 0 ? Theme.secondary : good ? Theme.mint : Theme.ember)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .card(Theme.cardRaised, radius: 18)
    }
}

/// The waist rule, when it trips.
private struct WaistWarning: View {
    let change: BodyLog.Change

    var body: some View {
        Label {
            Text("Waist \(Format.inchesChange(change.waist)) since \(change.since, format: .dateTime.day().month(.abbreviated)) while your arms haven't grown. That's likely more fat than muscle: trim calories a little.")
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
        }
        .font(.rounded(.footnote, .semibold))
        .foregroundStyle(Theme.ember)
    }
}

/// One measurement over time.
private struct TrendChart: View {
    let title: String
    let tint: Color
    let points: [(date: Date, value: Double)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).eyebrow(Theme.tertiary, size: 11)
            Chart(points, id: \.date) { point in
                LineMark(x: .value("Date", point.date), y: .value(title, point.value))
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                PointMark(x: .value("Date", point.date), y: .value(title, point.value))
                    .symbolSize(30)
            }
            .foregroundStyle(tint)
            .chartYScale(domain: .automatic(includesZero: false))
            .frame(height: 120)
        }
        .padding(.vertical, 6)
    }
}
