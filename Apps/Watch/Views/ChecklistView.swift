import SwiftUI
import RepCoachCore

/// Runs, warmups, mobility and cooldowns: read the steps, tap Done.
struct ChecklistView: View {
    @Environment(TodayModel.self) private var today
    let item: PlanItem
    let onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: item.symbol)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.ice)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Theme.ice.opacity(0.17)))
                    if let display = item.display, display != "—" {
                        Text(display).font(.number(24))
                    }
                }
                Text(item.name).font(.rounded(.title3, .bold))
                if let note = item.note {
                    Text(note)
                        .font(.rounded(.footnote))
                        .foregroundStyle(Theme.secondary)
                }
                if let steps = item.steps {
                    VStack(spacing: 5) {
                        ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(index + 1)")
                                    .font(.number(11, weight: .heavy))
                                    .foregroundStyle(.black)
                                    .frame(width: 18, height: 18)
                                    .background(Circle().fill(Theme.ice))
                                Text(step).font(.rounded(.footnote, .medium))
                                Spacer(minLength: 0)
                            }
                            .padding(8)
                            .card(radius: 12)
                        }
                    }
                }
                Button("Done") {
                    today.complete(item)
                    Haptics.play(.logged)
                    onDone()
                }
                .buttonStyle(PrimaryButtonStyle(tint: Theme.mint))
                .padding(.top, 2)
            }
        }
        .navigationTitle(item.group)
        .containerBackground(Theme.ice.gradient.opacity(0.28), for: .navigation)
    }
}
