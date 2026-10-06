import SwiftUI
import RepCoachCore

/// The top of a set screen, ready to log or hold: the exercise's name, the hints under it and, for an exercise
/// with a figure, a small still of it on the right that opens How. The name and its hints line up inside the
/// tiles' corners.
struct ExerciseHeader: View {
    @Environment(TodayModel.self) private var today
    let flow: ExerciseFlow
    @State private var showingHow = false

    var body: some View {
        let item = flow.currentItem
        let figure = ExerciseFigure.of(item)
        HStack(alignment: .center, spacing: pt(6)) {
            VStack(alignment: .leading, spacing: 0) {
                // One line when the name fits beside the figure's button, else two.
                ViewThatFits(in: .horizontal) {
                    Text(item.name).role(.title).lineLimit(1).fixedSize(horizontal: true, vertical: false)
                    Text(item.name).role(.title).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                }
                if today.isDeload {
                    Text("Deload")
                        .role(.eyebrow, .black)
                        .padding(.horizontal, pt(5))
                        .padding(.vertical, pt(1))
                        .background(Capsule().fill(Theme.ember))
                        .padding(.top, pt(2))
                }
                SetHintRow(flow: flow, stacked: figure != nil)
                    .padding(.top, pt(1))
                if let partner = partnerName {
                    Text("Superset · then \(partner)")
                        .role(.small, Theme.ice)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, pt(1))
                }
            }
            if let figure {
                Spacer(minLength: 0)
                Button { showingHow = true } label: {
                    FigureView(exercise: figure, yaw: figure.figure.openingYaw, size: pt(38), moving: false)
                        .frame(width: pt(42), height: pt(42))
                        .background(RoundedRectangle(cornerRadius: pt(11), style: .continuous).fill(Theme.card))
                }
                .buttonStyle(RowButtonStyle())
                .accessibilityLabel("How to do it")
                .sheet(isPresented: $showingHow) { HowView(item: item, exercise: figure) }
            }
        }
        .padding(.horizontal, pt(4))
        #if DEBUG
        .onAppear {
            // `-screen how`: the How sheet over the set screen; `-turned YES` once the Crown has been turned.
            if LaunchOptions.screen == "how", figure != nil {
                UserDefaults.standard.set(UserDefaults.standard.bool(forKey: "turned"), forKey: "figuresTurned")
                showingHow = true
            }
        }
        #endif
    }

    /// The other exercise of a superset pair.
    private var partnerName: String? {
        guard flow.isSuperset, let step = flow.current else { return nil }
        return flow.items[(step.item + 1) % flow.items.count].name
    }
}
