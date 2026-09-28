import Foundation
import OSLog
import SwiftData
import WatchConnectivity
import RepCoachCore

/// Phone side of WatchConnectivity. Stores every session the watch sends, one copy per session UUID, and sends
/// the watch the current settings and plan overrides whenever they change. From the watch's status it deletes
/// the sessions discarded there and sends back any the watch lost, so a reinstalled watch app gets its history.
@MainActor @Observable
final class PhoneSync: NSObject {
    enum WatchState: Equatable {
        case unsupported, notPaired, appNotInstalled, ready
    }

    private(set) var watchState = WatchState.unsupported
    /// When the last session arrived from the watch.
    private(set) var lastReceived: Date?
    /// When settings and overrides last went to the watch.
    private(set) var lastSent: Date?
    /// Whether the watch may save workouts to Health, as it last reported; nil until it has.
    private(set) var watchHealthAccess: HealthAccess?
    /// Bumped whenever stored sessions change, for screens that list them.
    private(set) var sessionsChanged = 0

    @ObservationIgnored private let context: ModelContext
    @ObservationIgnored private let settings: SettingsStore
    @ObservationIgnored private let today: TodayModel
    @ObservationIgnored private let defaults: UserDefaults
    private static let receivedKey = "lastSessionReceivedAt"
    private static let receivedIdsKey = "receivedSessionIds"
    private static let healthAccessKey = "watchHealthAccess"
    private static let discardedKey = "discardedSessionIds"

    /// Sessions discarded on the watch, most recent last: deleted here and never stored or sent back again.
    private var discardedIds: [String] {
        get { defaults.stringArray(forKey: Self.discardedKey) ?? [] }
        set { defaults.set(Array(newValue.suffix(500)), forKey: Self.discardedKey) }
    }

    /// The sessions stored most recently, sent back so the watch stops re-sending them.
    private var receivedIds: [String] {
        get { defaults.stringArray(forKey: Self.receivedIdsKey) ?? [] }
        set { defaults.set(Array(newValue.suffix(300)), forKey: Self.receivedIdsKey) }
    }

    init(context: ModelContext, settings: SettingsStore, today: TodayModel, defaults: UserDefaults = .standard) {
        self.context = context
        self.settings = settings
        self.today = today
        self.defaults = defaults
        lastReceived = defaults.object(forKey: Self.receivedKey) as? Date
        watchHealthAccess = defaults.string(forKey: Self.healthAccessKey).flatMap(HealthAccess.init(rawValue:))
    }

    func activate() {
        guard LaunchOptions.sync, WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Sends the current settings and overrides. The watch keeps only the latest and applies it between sessions.
    func sendContext() {
        guard LaunchOptions.sync, WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated, session.isPaired, session.isWatchAppInstalled else { return }
        do {
            let payload = SyncContext(settings: settings.settings, overrides: try SyncContext.overrides(in: context),
                                      received: receivedIds.compactMap(UUID.init))
            try session.updateApplicationContext(payload.applicationContext)
            lastSent = .now
        } catch {
            Logger.sync.error("Couldn't send settings to the watch: \(error.localizedDescription)")
        }
    }

    fileprivate func received(_ payload: SessionPayload) {
        let id = payload.id.uuidString
        // A transfer can land after the watch discarded its session; keep it deleted.
        guard !discardedIds.contains(id) else { return }
        do {
            try payload.upsert(into: context)
        } catch {
            Logger.sync.error("Couldn't store a session from the watch: \(error.localizedDescription)")
            return
        }
        lastReceived = .now
        defaults.set(lastReceived, forKey: Self.receivedKey)
        receivedIds = receivedIds.filter { $0 != id } + [id]
        sessionsChanged += 1
        Logger.sync.notice("Stored session \(id, privacy: .public)")
        today.refresh()
        sendContext()
    }

    fileprivate func receivedStatus(_ status: WatchStatus) {
        if let access = status.healthAccess {
            watchHealthAccess = access
            defaults.set(access.rawValue, forKey: Self.healthAccessKey)
        }
        deleteDiscarded(status.deleted)
        sendMissing(to: status)
    }

    /// Deletes the phone's copies of sessions discarded on the watch.
    private func deleteDiscarded(_ ids: [UUID]) {
        let new = ids.map(\.uuidString).filter { !discardedIds.contains($0) }
        guard !new.isEmpty else { return }
        discardedIds += new
        do {
            let deleted = try WorkoutRecorder(context: context).deleteSessions(ids)
            guard deleted > 0 else { return }
            Logger.sync.notice("Deleted \(deleted) session(s) discarded on the watch")
            sessionsChanged += 1
            today.refresh()
        } catch {
            Logger.sync.error("Couldn't delete discarded sessions: \(error.localizedDescription)")
        }
    }

    /// Sends the watch every session it doesn't have, e.g. after its app was deleted and installed again.
    /// Transfers still waiting in the system's queue aren't sent twice.
    private func sendMissing(to status: WatchStatus) {
        let session = WCSession.default
        guard LaunchOptions.sync, WCSession.isSupported(), session.activationState == .activated,
              session.isPaired, session.isWatchAppInstalled else { return }
        do {
            let discarded = Set(discardedIds)
            let queued = Set(session.outstandingUserInfoTransfers.compactMap { SessionPayload(userInfo: $0.userInfo)?.id })
            let wanted = Set(status.missing(fromPhone: try WorkoutRecorder(context: context).sessionIds()))
                .subtracting(queued)
                .filter { !discarded.contains($0.uuidString) }
            guard !wanted.isEmpty else { return }
            let sessions = try context.fetch(FetchDescriptor<WorkoutSession>()).filter { wanted.contains($0.id) }
            for stored in sessions {
                session.transferUserInfo(SessionPayload(stored).userInfo)
            }
            Logger.sync.notice("Sent the watch \(sessions.count) session(s) it was missing")
        } catch {
            Logger.sync.error("Couldn't send the watch its missing sessions: \(error.localizedDescription)")
        }
    }

    fileprivate func watchChanged(paired: Bool, installed: Bool) {
        watchState = !paired ? .notPaired : !installed ? .appNotInstalled : .ready
        sendContext()
    }
}

extension PhoneSync: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {
        let paired = session.isPaired
        let installed = session.isWatchAppInstalled
        let status = WatchStatus(applicationContext: session.receivedApplicationContext)
        Task { @MainActor in
            if let status { self.receivedStatus(status) }
            self.watchChanged(paired: paired, installed: installed)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let status = WatchStatus(applicationContext: applicationContext) else { return }
        Task { @MainActor in self.receivedStatus(status) }
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        let paired = session.isPaired
        let installed = session.isWatchAppInstalled
        Task { @MainActor in self.watchChanged(paired: paired, installed: installed) }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    /// The user switched watches; start talking to the new one.
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let payload = SessionPayload(userInfo: userInfo) else {
            Logger.sync.error("Ignored a transfer that isn't a session (keys: \(userInfo.keys.sorted(), privacy: .public))")
            return
        }
        Logger.sync.notice("Received session \(payload.id.uuidString, privacy: .public) from the watch")
        Task { @MainActor in self.received(payload) }
    }
}
