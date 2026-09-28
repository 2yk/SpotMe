import SwiftUI
import RepCoachCore

/// Switch Today to another plan day, e.g. to make up a missed session.
struct DayPickerView: View {
    @Environment(TodayModel.self) private var today
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let todayKey = today.plan.day(for: .now)?.key
        NavigationStack {
            List(today.plan.days) { day in
                Button {
                    today.select(day.key)
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(day.title)
                                .font(.rounded(.body, .semibold))
                                .foregroundStyle(day.key == today.dayKey ? Theme.volt : .white)
                            Text(day.focus)
                                .font(.rounded(.footnote))
                                .foregroundStyle(Theme.secondary)
                                .lineLimit(2)
                        }
                        Spacer(minLength: 0)
                        if day.key == todayKey {
                            Text("Today").eyebrow(Theme.volt, size: 9)
                        }
                    }
                }
            }
            .navigationTitle("Days")
        }
    }
}
