import SwiftUI
import RepCoachCore

/// How to do the exercise: the figure moving at 125 pt, the Digital Crown turning it a full circle, with light
/// haptic detents. Until the Crown has been turned here once, the line says so; after that it is the cue.
struct HowView: View {
    let item: PlanItem
    let exercise: ExerciseFigure
    @State private var crown = 0.0
    @State private var lastDetent = 0
    @FocusState private var focused: Bool
    @AppStorage("figuresTurned") private var hasTurned = false

    /// Degrees per turn of the Crown: one turn is a full circle.
    private static let degreesPerTurn = 360.0

    var body: some View {
        let yaw = exercise.figure.openingYaw + crown * Self.degreesPerTurn
        VStack(spacing: 0) {
            FigureView(exercise: exercise, yaw: yaw, size: pt(125))
            Text(item.name)
                .role(.row, .white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .padding(.top, pt(2))
            Group {
                if hasTurned {
                    Text(exercise.cue).role(.small.weight(.medium), Theme.text2)
                } else {
                    Text("Turn the Crown to look around").role(.small, Theme.ice)
                }
            }
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .padding(.horizontal, pt(8))
            .padding(.top, pt(1))
            dots(yaw: yaw)
                .padding(.top, pt(6))
        }
        .padding(.top, Metrics.sheetTop - pt(4))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea()
        .focusable()
        .focused($focused)
        .digitalCrownRotation($crown, from: -1000, through: 1000, by: nil, sensitivity: .medium, isContinuous: false,
                              isHapticFeedbackEnabled: false)
        .onAppear { focused = true }
        .onChange(of: crown) {
            if abs(crown) > 0.02 { hasTurned = true }
            // A light detent every 30 degrees.
            let detent = Int((crown * Self.degreesPerTurn / 30).rounded(.down))
            if detent != lastDetent {
                lastDetent = detent
                Haptics.play(.step)
            }
        }
        .barTitle("How", close: true)
    }

    /// Seven dots round the circle: where the figure is turned to.
    private func dots(yaw: Double) -> some View {
        let turned = yaw.truncatingRemainder(dividingBy: 360)
        let angle = turned < 0 ? turned + 360 : turned
        let current = Int(angle / (360 / 7)) % 7
        return HStack(spacing: pt(3)) {
            ForEach(0..<7, id: \.self) { index in
                Circle()
                    .fill(index == current ? Theme.volt : Color(white: 0.23))
                    .frame(width: pt(4), height: pt(4))
            }
        }
        .accessibilityHidden(true)
    }
}
