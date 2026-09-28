import Foundation
import OSLog
import SwiftData
import WatchConnectivity
import RepCoachCore

/// Watch side of WatchConnectivity. Finished sessions go to the phone as queued transfers that the system
/// delivers whenever the phone is reachable, so a whole session can be logged with the phone out of range.
/// The phone's settings and plan edits arrive as the application context and are applied only between
/// sessions, so targets never move mid-workout.
@MainActor @Observable
final class WatchSync: NSObject {
    @ObservationIgnored private let today: TodayModel
    @ObservationIgnored private let settings: SettingsStore
    @ObservationIgnored private let defaults: UserDefaults
    /// True while a session is under way; supplied by the app.
    @ObservationIgnored var isBusy: () -> Bool = { false }

    private static let unsentKey = "unsentSessionIds"
    private static let pendingKey = "pendingSyncContext"
    private static let appliedKey = "appliedSyncContextSentAt"
    private static let historySentKey = "sentHistoryToPhone"

    init(today: TodayModel, settings: SettingsStore, defaults: UserDefaults = .standard) {
        self.today = today
        self.settings = settings
        self.defaults = defaults
    }

    func activate() {
        guard LaunchOptions.sync, WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Queues a finished session for the phone. Kept in a list until the connection is up, so nothing is lost
    /// if the app is closed first.
    func send(_ session: WorkoutSession) {
        guard LaunchOptions.sync else { return }
        unsent.insert(session.id.uuidString)
        flush()
    }

    /// When the app comes forward: finish and send sessions from earlier days that were never finished, then
    /// apply any settings waiting from the phone.
    func catchUp() {
        guard LaunchOptions.sync else { return }
        for session in (try? today.recorder.unfinishedSessions()) ?? [] {
            try? today.recorder.finishAtLastActivity(session)
            unsent.insert(session.id.uuidString)
        }
        flush()
        applyPendingIfIdle()
    }

    /// Applies the phone's latest settings and overrides, unless a session is under way.
    func applyPendingIfIdle() {
        guard let data = defaults.data(forKey: Self.pendingKey),
              let pending = try? JSONDecoder().decode(SyncContext.self, from: data),
              !isBusy() else { return }
        do {
            try pending.applyOverrides(to: today.context)
            settings.settings = pending.settings
            defaults.set(pending.sentAt, forKey: Self.appliedKey)
            defaults.removeObject(forKey: Self.pendingKey)
            today.refresh()
        } catch {
            Logger.sync.error("Couldn't apply the phone's settings: \(error.localizedDescription)")
        }
    }

    // MARK: Internals

    private var unsent: Set<String> {
        get { Set(defaults.stringArray(forKey: Self.unsentKey) ?? []) }
        set { defaults.set(Array(newValue), forKey: Self.unsentKey) }
    }

    private func flush() {
        let ids = unsent
        guard !ids.isEmpty, WCSession.isSupported(), WCSession.default.activationState == .activated else { return }
        let sessions = ((try? today.context.fetch(FetchDescriptor<WorkoutSession>())) ?? [])
            .filter { ids.contains($0.id.uuidString) }
        for session in sessions {
            WCSession.default.transferUserInfo(SessionPayload(session).userInfo)
        }
        unsent = []
    }

    /// The first time the phone app is there, send every finished session so its history starts complete.
    private func sendHistoryOnce() {
        guard !defaults.bool(forKey: Self.historySentKey) else { return }
        let finished = ((try? today.context.fetch(FetchDescriptor<WorkoutSession>())) ?? []).filter { $0.endedAt != nil }
        unsent.formUnion(finished.map(\.id.uuidString))
        defaults.set(true, forKey: Self.historySentKey)
        flush()
    }

    private func received(_ context: SyncContext) {
        if let applied = defaults.object(forKey: Self.appliedKey) as? Date, context.sentAt <= applied { return }
        guard let data = try? JSONEncoder().encode(context) else { return }
        defaults.set(data, forKey: Self.pendingKey)
        applyPendingIfIdle()
    }

    fileprivate func activated(context: SyncContext?, companionInstalled: Bool) {
        if let context { received(context) }
        if companionInstalled { sendHistoryOnce() }
        flush()
    }

    fileprivate func companionInstalledChanged(_ installed: Bool) {
        if installed { sendHistoryOnce() }
    }

    fileprivate func receivedContext(_ context: SyncContext) {
        received(context)
    }
}

extension WatchSync: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {
        let context = SyncContext(applicationContext: session.receivedApplicationContext)
        let installed = session.isCompanionAppInstalled
        Task { @MainActor in self.activated(context: context, companionInstalled: installed) }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let context = SyncContext(applicationContext: applicationContext) else { return }
        Task { @MainActor in self.receivedContext(context) }
    }

    nonisolated func sessionCompanionAppInstalledDidChange(_ session: WCSession) {
        let installed = session.isCompanionAppInstalled
        Task { @MainActor in self.companionInstalledChanged(installed) }
    }
}
