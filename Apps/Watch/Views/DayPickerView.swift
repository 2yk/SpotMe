import SwiftUI
import RepCoachCore

/// Switch Today to another plan day, e.g. to make up a missed session.
struct DayPickerView: View {
    @Environment(TodayModel.self) private var today
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let todayKey = today.plan.day(for: .now)?.key
        NavigationStack {
            ScrollView {
                VStack(spacing: pt(4)) {
                    ForEach(today.plan.days) { day in
                        Button {
                            today.select(day.key)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: pt(1)) {
                                HStack(spacing: pt(6)) {
                                    Text(day.title).role(.row, day.key == today.dayKey ? Theme.volt : .white)
                                    Spacer(minLength: 0)
                                    if day.key == todayKey {
                                        Text("Today")
                                            .role(.eyebrow, .black)
                                            .padding(.horizontal, pt(5))
                                            .padding(.vertical, pt(1))
                                            .background(Capsule().fill(Theme.volt))
                                    }
                                }
                                Text(day.focus)
                                    .role(.small.weight(.medium), Theme.text2)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                            }
                            .padding(EdgeInsets(top: pt(7), leading: pt(10), bottom: pt(8), trailing: pt(10)))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .surface()
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Metrics.side)
                .padding(.top, Metrics.top)
                .padding(.bottom, Metrics.bottom)
            }
            .ignoresSafeArea()
            .barTitle("Days", close: true)
        }
    }
}
