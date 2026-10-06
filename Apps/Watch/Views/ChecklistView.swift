import SwiftUI
import RepCoachCore

/// Warmups, mobility, neck work and cooldowns: read the steps, tap Done, and the workout moves on.
struct ChecklistView: View {
    @Environment(WorkoutModel.self) private var workout
    let item: PlanItem

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(item.name)
                            .role(.title)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                        if let steps = item.steps {
                            VStack(alignment: .leading, spacing: pt(7)) {
                                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                                    HStack(alignment: .firstTextBaseline, spacing: pt(6)) {
                                        Text("\(index + 1)")
                                            .role(.small.weight(.heavy).size(11), Theme.volt)
                                            .frame(width: pt(12), alignment: .leading)
                                        Text(step)
                                            .role(TextRole(size: 13, line: 16, weight: .medium))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            .padding(.top, pt(6))
                        } else {
                            if let display = item.display, !["", "—"].contains(display) {
                                Text(display).role(.eyebrow, Theme.text3).padding(.top, pt(3))
                            }
                            if let note = item.note {
                                Text(note)
                                    .role(TextRole(size: 13, line: 16, weight: .medium), Theme.text2)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.top, pt(4))
                            }
                        }
                    }
                    .padding(.horizontal, pt(4))
                    Spacer(minLength: pt(8))
                    Button("Done") { workout.finishChecklist(item) }
                        .buttonStyle(PrimaryButtonStyle())
                    Button("Skip") { workout.finishChecklist(item, skipped: true) }
                        .buttonStyle(TextButtonStyle())
                        .padding(.top, pt(2))
                        .padding(.bottom, Metrics.bottom - pt(2))
                        .id("skip")
                }
                .padding(.horizontal, Metrics.side)
                .padding(.top, Metrics.top)
                .frame(minHeight: geometry.size.height)
            }
            #if DEBUG
            .task {
                guard LaunchOptions.screen == "checklist-end" else { return }
                try? await Task.sleep(for: .seconds(0.8))
                proxy.scrollTo("skip", anchor: .bottom)
            }
            #endif
            }
        }
        .ignoresSafeArea()
        .topFade()
        .barTitle(item.group.components(separatedBy: " · ")[0])
    }
}
