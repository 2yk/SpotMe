import SwiftUI
import RepCoachCore

/// The big card at the top of Today: name, prescription and today's target weight.
struct UpNextCard: View {
    @Environment(TodayModel.self) private var today
    let items: [PlanItem]

    var body: some View {
        let lead = items[0]
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Text(items.count > 1 ? "Superset" : "Up next").eyebrow(lead.tint)
                Spacer(minLength: 4)
                if case .inProgress(let done) = today.status(of: lead) {
                    Chip(text: "Set \(done + 1)/\(today.target(for: lead).sets)", tint: lead.tint)
                }
            }
            if items.count > 1 {
                ForEach(items) { item in
                    SupersetLine(item: item, target: today.target(for: item))
                }
                Text(Format.prescription(lead, today.target(for: lead)))
                    .font(.rounded(.footnote, .medium))
                    .foregroundStyle(Theme.secondary)
            } else {
                single(lead, today.target(for: lead))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glowCard(lead.tint)
    }

    @ViewBuilder
    private func single(_ item: PlanItem, _ target: ItemTarget) -> some View {
        Text(item.name)
            .font(.rounded(.title3, .bold))
            .lineLimit(3)
            .minimumScaleFactor(0.75)
        if item.kind == .weighted {
            Text(Format.prescription(item, target))
                .font(.rounded(.footnote, .medium))
                .foregroundStyle(Theme.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                if let weight = target.weight {
                    Text(Format.weight(weight)).font(.number(34)).monospacedDigit()
                    Text("kg").font(.rounded(.footnote, .bold)).foregroundStyle(Theme.secondary)
                } else {
                    Text("Pick a weight").font(.rounded(.headline, .bold)).foregroundStyle(item.tint)
                }
                Spacer(minLength: 4)
                if let session = target.session, target.weight != nil {
                    Chip(text: Coach.tag(session, increment: item.increment ?? 2.5), tint: item.tint)
                }
            }
        } else if item.kind == .checklist {
            Text(item.group)
                .font(.rounded(.footnote, .medium))
                .foregroundStyle(Theme.secondary)
                .lineLimit(1)
            HStack(alignment: .center) {
                if let display = item.display, display != "—" {
                    Text(display).font(.number(26))
                }
                Spacer(minLength: 4)
                // Tapping the card ticks it off; warmups open their steps.
                Image(systemName: item.steps == nil ? "checkmark.circle.fill" : "list.number")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Theme.ice)
            }
            if item.steps == nil, let note = item.note {
                Text(note)
                    .font(.rounded(.caption2, .medium))
                    .foregroundStyle(Theme.secondary)
                    .lineLimit(3)
            }
        } else {
            Text(Format.prescription(item, target))
                .font(.rounded(.footnote, .medium))
                .foregroundStyle(Theme.secondary)
                .lineLimit(1)
            if item.takesWeight, let weight = target.weight, weight > 0 {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(Format.weight(weight)).font(.number(28)).monospacedDigit()
                    Text("kg").font(.rounded(.footnote, .bold)).foregroundStyle(Theme.secondary)
                }
            }
        }
    }
}

private struct SupersetLine: View {
    let item: PlanItem
    let target: ItemTarget

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(item.name)
                .font(.rounded(.headline, .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 2)
            if let weight = target.weight {
                Text(Format.weight(weight)).font(.number(20)).monospacedDigit()
                Text("kg").font(.rounded(.caption2, .bold)).foregroundStyle(Theme.secondary)
            }
        }
    }
}
