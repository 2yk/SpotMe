import SwiftUI
import RepCoachCore

/// One item: today's target and why, how to do it, and what happened last time.
struct ItemDetailSheet: View {
    @Environment(TodayModel.self) private var today
    @Environment(\.dismiss) private var dismiss
    let item: PlanItem

    var body: some View {
        let target = today.target(for: item)
        let last = (try? today.history.entries(for: item.exerciseId, excluding: today.session?.id))?.first
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 14) {
                        ItemBadge(item: item, status: today.status(of: item), size: 52)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.group).eyebrow(item.tint, size: 11)
                            Text(item.name).font(.rounded(.title2, .bold))
                        }
                    }

                    if item.kind != .checklist {
                        targetTiles(target)
                        if let session = target.session {
                            Text(Coach.explain(session, increment: item.increment ?? 2.5))
                                .font(.rounded(.subheadline, .medium))
                                .foregroundStyle(Theme.secondary)
                        }
                    }

                    if let note = item.note {
                        Text(note)
                            .font(.rounded(.body))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .card(Theme.card, radius: 18)
                    }

                    if let steps = item.steps {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.number(12, weight: .heavy))
                                        .foregroundStyle(.black)
                                        .frame(width: 22, height: 22)
                                        .background(Circle().fill(Theme.ice))
                                    Text(step).font(.rounded(.body))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .card(Theme.card, radius: 18)
                    }

                    if let last {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Last time").eyebrow(Theme.tertiary, size: 11)
                                Spacer()
                                Text(last.date, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated))
                                    .font(.rounded(.footnote, .medium))
                                    .foregroundStyle(Theme.tertiary)
                            }
                            Text(Format.sets(last.sets, timed: item.kind == .timed))
                                .font(.rounded(.headline, .semibold))
                        }
                        .padding(16)
                        .card(Theme.card, radius: 18)
                    }
                }
                .padding(20)
            }
            .background(Theme.canvas)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("Close")
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func targetTiles(_ target: ItemTarget) -> some View {
        HStack(spacing: 10) {
            StatTile(label: "Sets", value: "\(target.sets)")
            StatTile(label: item.kind == .timed ? "Seconds" : "Reps", value: Format.perSet(item, target) ?? "max")
            if item.takesWeight {
                StatTile(label: "Weight", value: target.weight.map(Format.weight) ?? "—", unit: "kg", tint: item.tint)
            } else if let rest = item.restSec {
                StatTile(label: "Rest", value: Format.clock(rest))
            }
        }
    }
}
