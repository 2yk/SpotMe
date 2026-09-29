import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import RepCoachCore

/// Every set logged, as a CSV file to share: Files, Mail, Numbers, Excel or Google Sheets.
struct SetsExport: Transferable {
    let csv: String
    let date: Date
    /// Sessions in the file.
    let sessions: Int

    var fileName: String { "SpotMe sets \(date.formatted(.iso8601.year().month().day())).csv" }

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { export in
            // A byte order mark, so Excel reads the file as UTF-8.
            Data("\u{FEFF}".utf8) + Data(export.csv.utf8)
        }
        .suggestedFileName { $0.fileName }
    }

    /// Everything stored on this phone, with exercise names as the user has them.
    @MainActor
    static func current(context: ModelContext, today: TodayModel) -> SetsExport {
        let sessions = (try? context.fetch(FetchDescriptor<WorkoutSession>())) ?? []
        let names = Dictionary(today.library.map { ($0.exerciseId, $0.name) }, uniquingKeysWith: { first, _ in first })
        let days = Dictionary(today.plan.days.map { ($0.key, $0.title) }, uniquingKeysWith: { first, _ in first })
        return SetsExport(csv: SetsCSV.make(sessions: sessions, names: names, dayTitles: days), date: .now,
                          sessions: sessions.count)
    }
}

/// The share button for `SetsExport`.
struct ExportSetsLink<Label: View>: View {
    let export: SetsExport
    @ViewBuilder var label: Label

    var body: some View {
        ShareLink(item: export, preview: SharePreview(export.fileName, image: Image(systemName: "tablecells"))) {
            label
        }
        .disabled(export.sessions == 0)
    }
}
