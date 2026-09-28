import Foundation
import OSLog
import SwiftData
import WatchConnectivity
import RepCoachCore

/// Phone side of WatchConnectivity. Stores every session the watch sends, one copy per session UUID, and sends
/// the watch the current settings and plan overrides whenever they change.
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

    @ObservationIgnored private let context: ModelContext
    @ObservationIgnored private let settings: SettingsStore
    @ObservationIgnored private let today: TodayModel
    @ObservationIgnored private let defaults: UserDefaults
    private static let receivedKey = "lastSessionReceivedAt"
    private static let receivedIdsKey = "receivedSessionIds"

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
        do {
            try payload.upsert(into: context)
        } catch {
            Logger.sync.error("Couldn't store a session from the watch: \(error.localizedDescription)")
            return
        }
        lastReceived = .now
        defaults.set(lastReceived, forKey: Self.receivedKey)
        let id = payload.id.uuidString
        receivedIds = receivedIds.filter { $0 != id } + [id]
        Logger.sync.notice("Stored session \(id, privacy: .public)")
        today.refresh()
        sendContext()
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
        Task { @MainActor in self.watchChanged(paired: paired, installed: installed) }
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
