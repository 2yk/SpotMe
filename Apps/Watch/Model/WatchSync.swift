import Foundation
import OSLog
import SwiftData
import WatchConnectivity
import RepCoachCore

/// Watch side of WatchConnectivity. Finished sessions go to the phone as queued transfers that the system
/// delivers whenever the phone is reachable, so a whole session can be logged with the phone out of range.
/// The phone confirms what it stored; anything unconfirmed is sent again when the app next comes forward.
/// The phone's settings and plan edits arrive as the application context and are applied only between
/// sessions, so targets never move mid-workout. The Health switch moves no targets and applies at once.
/// The watch's own application context tells the phone which sessions it has and which it discarded: the
/// phone sends back any the watch lost (a reinstalled app) and deletes the discarded ones.
@MainActor @Observable
final class WatchSync: NSObject {
    @ObservationIgnored private let today: TodayModel
    @ObservationIgnored private let settings: SettingsStore
    @ObservationIgnored private let defaults: UserDefaults
    /// True while a session is under way; supplied by the app.
    @ObservationIgnored var isBusy: () -> Bool = { false }
    /// Whether SpotMe may save workouts to Health; supplied by the app, nil when Health isn't in use.
    @ObservationIgnored var healthAccess: () -> HealthAccess? = { nil }

    private static let unsentKey = "unsentSessionIds"
    private static let awaitingKey = "sessionsAwaitingPhone"
    private static let pendingKey = "pendingSyncContext"
    private static let appliedKey = "appliedSyncContextSentAt"
    private static let historySentKey = "sentHistoryToPhone"
    private static let discardedKey = "discardedSessionIds"

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

    /// Queues a finished session for the phone and keeps offering it until the phone confirms it.
    func send(_ session: WorkoutSession) {
        guard LaunchOptions.sync else { return }
        let id = session.id.uuidString
        unsent.insert(id)
        awaiting.insert(id)
        flush()
    }

    /// When the app comes forward: finish sessions from earlier days that were never finished, re-send anything
    /// the phone hasn't confirmed, then apply settings waiting from the phone.
    func catchUp() {
        guard LaunchOptions.sync else { return }
        for session in (try? today.recorder.unfinishedSessions()) ?? [] {
            try? today.recorder.finishAtLastActivity(session)
            let id = session.id.uuidString
            unsent.insert(id)
            awaiting.insert(id)
        }
        resendUnconfirmed()
        flush()
        applyPendingIfIdle()
        sendStatus()
    }

    /// Tells the phone the watch's Health access and which sessions it has (in the restore window) and
    /// discarded. Latest wins. A store that can't be read sends no list, so the phone sends nothing back.
    func sendStatus() {
        guard LaunchOptions.sync, canSend else { return }
        let since = Date.now.addingTimeInterval(-WatchStatus.window)
        let status = WatchStatus(healthAccess: healthAccess(),
                                 sessions: try? today.recorder.sessionIds(since: since),
                                 since: since,
                                 deleted: discardedIds.compactMap(UUID.init(uuidString:)))
        do {
            try WCSession.default.updateApplicationContext(status.applicationContext)
        } catch {
            Logger.sync.error("Couldn't send the watch status: \(error.localizedDescription)")
        }
    }

    /// A workout was discarded: stop offering it, and have the phone delete its copy and never send it back.
    func sessionDiscarded(_ id: UUID) {
        let key = id.uuidString
        unsent.remove(key)
        awaiting.remove(key)
        discardedIds = Array((discardedIds.filter { $0 != key } + [key]).suffix(200))
        sendStatus()
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

    /// Waiting for the connection before they can be queued.
    private var unsent: Set<String> {
        get { Set(defaults.stringArray(forKey: Self.unsentKey) ?? []) }
        set { defaults.set(Array(newValue), forKey: Self.unsentKey) }
    }

    /// Queued at least once but not yet confirmed by the phone.
    private var awaiting: Set<String> {
        get { Set(defaults.stringArray(forKey: Self.awaitingKey) ?? []) }
        set { defaults.set(Array(newValue), forKey: Self.awaitingKey) }
    }

    /// Sessions discarded here, most recent last, so neither side brings them back.
    private var discardedIds: [String] {
        get { defaults.stringArray(forKey: Self.discardedKey) ?? [] }
        set { defaults.set(newValue, forKey: Self.discardedKey) }
    }

    /// Connected and the phone app is there; until then sessions just wait in their lists.
    private var canSend: Bool {
        WCSession.isSupported() && WCSession.default.activationState == .activated
            && WCSession.default.isCompanionAppInstalled
    }

    private func flush() {
        let ids = unsent
        guard !ids.isEmpty, canSend else { return }
        let sessions = ((try? today.context.fetch(FetchDescriptor<WorkoutSession>())) ?? [])
            .filter { ids.contains($0.id.uuidString) }
        for session in sessions {
            WCSession.default.transferUserInfo(SessionPayload(session).userInfo)
        }
        Logger.sync.notice("Queued \(sessions.count) session(s) for the phone")
        unsent = []
    }

    /// Offers unconfirmed sessions again, skipping any whose transfer is still waiting in the system's queue so
    /// a phone left out of range doesn't collect duplicates.
    private func resendUnconfirmed() {
        guard canSend else { return }
        let queued = Set(WCSession.default.outstandingUserInfoTransfers.compactMap {
            SessionPayload(userInfo: $0.userInfo)?.id.uuidString
        })
        unsent.formUnion(awaiting.subtracting(queued))
    }

    /// The first time the phone app is there, send every finished session so its history starts complete.
    /// Best effort: these aren't tracked for confirmation.
    private func sendHistoryOnce() {
        guard !defaults.bool(forKey: Self.historySentKey) else { return }
        let finished = ((try? today.context.fetch(FetchDescriptor<WorkoutSession>())) ?? []).filter { $0.endedAt != nil }
        unsent.formUnion(finished.map(\.id.uuidString))
        defaults.set(true, forKey: Self.historySentKey)
        flush()
    }

    private func received(_ context: SyncContext) {
        // Confirmations count straight away; settings wait for a gap between sessions.
        let confirmed = awaiting.intersection(context.received.map(\.uuidString))
        awaiting.subtract(confirmed)
        if !confirmed.isEmpty { Logger.sync.notice("The phone confirmed \(confirmed.count) session(s)") }
        if let applied = defaults.object(forKey: Self.appliedKey) as? Date, context.sentAt <= applied { return }
        settings.settings.healthWorkouts = context.settings.healthWorkouts
        guard let data = try? JSONEncoder().encode(context) else { return }
        defaults.set(data, forKey: Self.pendingKey)
        applyPendingIfIdle()
    }

    fileprivate func activated(context: SyncContext?, companionInstalled: Bool) {
        if let context { received(context) }
        if companionInstalled { sendHistoryOnce() }
        resendUnconfirmed()
        flush()
        sendStatus()
    }

    fileprivate func companionInstalledChanged(_ installed: Bool) {
        guard installed else { return }
        sendHistoryOnce()
        resendUnconfirmed()
        flush()
        sendStatus()
    }

    fileprivate func receivedContext(_ context: SyncContext) {
        received(context)
    }

    /// A session the phone sent back because this watch didn't have it. What's already here always wins.
    fileprivate func restored(_ payload: SessionPayload) {
        guard !discardedIds.contains(payload.id.uuidString) else { return }
        do {
            if let local = try today.recorder.session(for: payload.dayKey, on: payload.date), local.id != payload.id {
                // The day was started again here before the copy arrived: keep one session for it. The copy's
                // items join the watch's session, and the phone drops the copy, which that session replaces.
                try payload.merge(into: local, context: today.context)
                sessionDiscarded(payload.id)
            } else {
                guard try payload.insertIfMissing(into: today.context) else { return }
            }
        } catch {
            Logger.sync.error("Couldn't restore a session from the phone: \(error.localizedDescription)")
            return
        }
        Logger.sync.notice("Restored session \(payload.id.uuidString, privacy: .public) from the phone")
        today.refresh()
        sendStatus()
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

    /// Sessions the phone sends back after the watch lost them.
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let payload = SessionPayload(userInfo: userInfo) else { return }
        Task { @MainActor in self.restored(payload) }
    }

    nonisolated func sessionCompanionAppInstalledDidChange(_ session: WCSession) {
        let installed = session.isCompanionAppInstalled
        Task { @MainActor in self.companionInstalledChanged(installed) }
    }

    /// Unconfirmed sessions are re-sent anyway; this only records why a transfer failed.
    nonisolated func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        guard let error else { return }
        Logger.sync.error("A session transfer failed: \(error.localizedDescription)")
    }
}
