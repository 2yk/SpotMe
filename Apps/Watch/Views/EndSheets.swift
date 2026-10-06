import SwiftUI
import RepCoachCore

/// End workout?: Finish, Discard workout or Keep going on one screen, no scrolling dialog. Discard asks once
/// more.
struct EndWorkoutSheet: View {
    @Environment(WorkoutModel.self) private var workout
    @Environment(\.dismiss) private var dismiss
    @State private var discarding: Bool

    init(startsDiscarding: Bool = false) {
        _discarding = State(initialValue: startsDiscarding)
    }

    var body: some View {
        Group {
            if discarding { discard } else { end }
        }
        .padding(.horizontal, Metrics.side)
        .padding(.top, discarding ? Metrics.top - pt(6) : Metrics.top - pt(2))
        .padding(.bottom, Metrics.bottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea()
        .barTitle(discarding ? "Discard?" : "", .white, close: true)
    }

    private var end: some View {
        VStack(spacing: pt(4)) {
            Text("End workout?")
                .role(.title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, pt(4))
            Button("Finish") {
                dismiss()
                Task { await workout.finishWorkout() }
            }
            .buttonStyle(PrimaryButtonStyle(height: 38))
            Button("Discard workout") { withAnimation(.snappy) { discarding = true } }
                .buttonStyle(NeutralButtonStyle(height: 34, label: Theme.red, font: .row.weight(.bold).size(14)))
            Button("Keep going") { dismiss() }
                .buttonStyle(NeutralButtonStyle(height: 34, font: .row.weight(.bold).size(14)))
            Text(workout.savesToHealth
                 ? "Finish saves it to Health. Discard deletes today's sets, here and on your iPhone."
                 : "Discard deletes today's sets, here and on your iPhone.")
                .role(.small.weight(.medium), Theme.text3)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, pt(2))
        }
    }

    private var discard: some View {
        VStack(spacing: pt(4)) {
            Text("Everything logged today is deleted, here and on your iPhone, and nothing stays in Health.")
                .role(.detail, Theme.text2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, pt(4))
            Spacer(minLength: 0)
            Button("Discard") {
                dismiss()
                withAnimation(.snappy) { workout.discardWorkout() }
            }
            .buttonStyle(PrimaryButtonStyle(tint: Theme.red, height: 38))
            Button("Keep it") { dismiss() }
                .buttonStyle(NeutralButtonStyle(height: 34, font: .row.weight(.bold).size(14)))
        }
    }
}

/// Why Start workout couldn't start the Health workout: the watch isn't allowed to save workouts.
struct HealthAlertSheet: View {
    let message: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Not saving to Health")
                    .role(.title)
                    .fixedSize(horizontal: false, vertical: true)
                Text(message)
                    .role(.detail, Theme.text2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, pt(4))
                Button("OK") { dismiss() }
                    .buttonStyle(NeutralButtonStyle(height: 38))
                    .padding(.top, pt(7))
            }
            .padding(.horizontal, Metrics.side + pt(4))
            .padding(.top, Metrics.top - pt(4))
            .padding(.bottom, Metrics.bottom)
        }
        .ignoresSafeArea()
        .barTitle("", close: true)
    }
}
