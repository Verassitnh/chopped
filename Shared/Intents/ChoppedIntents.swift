import AppIntents
import Foundation

// Compiled into both the app and the widget extension.
//
// Where each intent runs (measured on the iOS 27 simulator, app closed):
// - Plain `AppIntent`s tapped in a widget / Live Activity run in the widget extension: perform() starts
//   ~0.2s after the tap and the widget shows the new state ~0.5s later.
// - A `LiveActivityIntent` tapped in a widget / control goes through the system's Shortcuts runner, which
//   launches (~1.4s), grants the app a short "fake foreground" assertion and then runs perform() in the
//   app (~1.9s after the tap). That assertion is the only way a backgrounded app may *start* a Live
//   Activity; updating or ending one is allowed from the background.
// - A `LiveActivityIntent` returned through `.result(opensIntent:)` runs in the app straight away (cold
//   launch included, ~0.25s after the first intent), but without that assertion.
//
// So home-screen widget buttons that stop or switch trackers run in the extension (instant flip) and chain
// `SyncLiveActivityIntent`, which ends / updates the Live Activity from the app ~0.3s later. A Play tap
// that has to start a brand-new Live Activity uses `StartTrackerIntent` (see `WidgetPlayButton`).

// MARK: - Entity

struct TrackerEntity: AppEntity, Identifiable, Hashable {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Tracker"
    static var defaultQuery = TrackerQuery()

    let id: Int
    let name: String
    let colorHex: String
    let icon: String

    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }

    init(id: Int, name: String, colorHex: String, icon: String) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
    }

    init(_ t: TrackerSnapshot) {
        self.init(id: Int(t.id), name: t.name, colorHex: t.colorHex, icon: t.icon)
    }
}

struct TrackerQuery: EntityQuery {
    func entities(for identifiers: [Int]) async throws -> [TrackerEntity] {
        let all = ChoppedData.snapshot()?.trackers ?? []
        return all.filter { identifiers.contains(Int($0.id)) }.map(TrackerEntity.init)
    }

    func suggestedEntities() async throws -> [TrackerEntity] {
        (ChoppedData.snapshot()?.trackers ?? []).map(TrackerEntity.init)
    }
}

// MARK: - Actions

/// Start a tracker (widget Play when nothing is running, Shortcuts). Clocks out of whatever was running.
/// Runs in the app with the system's permission to start the Live Activity from the background.
struct StartTrackerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Start Tracker"
    static var description = IntentDescription("Clock in to a tracker.")
    static var openAppWhenRun = false

    @Parameter(title: "Tracker ID") var trackerID: Int

    init() {}
    init(trackerID: Int64) { self.trackerID = Int(trackerID) }

    @MainActor
    func perform() async throws -> some IntentResult {
        ChoppedData.start(Int64(trackerID))
        ChoppedSync.didChange()
        return .result()
    }
}

/// Stop whatever is running (Live Activity / island / widget stop buttons).
struct StopTrackerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop Tracker"
    static var description = IntentDescription("Clock out of the running tracker.")
    static var openAppWhenRun = false

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        ChoppedData.stop()
        ChoppedSync.didChange()
        return .result()
    }
}

/// Home-screen widget Play while another tracker is running (a switch). A plain `AppIntent`, so it runs in
/// the widget extension and the widget flips as soon as `perform()` returns; the chained
/// `SyncLiveActivityIntent` then moves the existing Live Activity over to the new tracker from the app.
struct WidgetStartTrackerIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Tracker"
    static var openAppWhenRun = false
    static var isDiscoverable = false

    @Parameter(title: "Tracker ID") var trackerID: Int

    init() {}
    init(trackerID: Int64) { self.trackerID = Int(trackerID) }

    @MainActor
    func perform() async throws -> some IntentResult & OpensIntent {
        ChoppedData.start(Int64(trackerID))
        ChoppedSync.didChange()
        return .result(opensIntent: SyncLiveActivityIntent())
    }
}

/// Stop from a home-screen widget or the Live Activity / Dynamic Island (see `WidgetStartTrackerIntent`).
struct WidgetStopTrackerIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Tracker"
    static var openAppWhenRun = false
    static var isDiscoverable = false

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & OpensIntent {
        ChoppedData.stop()
        ChoppedSync.didChange()
        return .result(opensIntent: SyncLiveActivityIntent())
    }
}

/// Chained after the extension-run widget intents. A `LiveActivityIntent`, so the system runs it in the app
/// process (launching it in the background if needed), where the Live Activity can be updated or ended.
struct SyncLiveActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Sync Live Activity"
    static var openAppWhenRun = false
    static var isDiscoverable = false

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        ChoppedSync.didChange()
        return .result()
    }
}

/// Control Center: tracker toggle (on = running).
struct SetTrackerRunningIntent: SetValueIntent, LiveActivityIntent {
    static var title: LocalizedStringResource = "Set Tracker Running"
    static var openAppWhenRun = false

    @Parameter(title: "Tracker") var tracker: TrackerEntity?
    @Parameter(title: "Running") var value: Bool

    init() {}
    init(tracker: TrackerEntity?) { self.tracker = tracker }

    @MainActor
    func perform() async throws -> some IntentResult {
        let snapshot = ChoppedData.snapshot()
        let id = tracker.map { Int64($0.id) } ?? snapshot?.lastUsed?.id
        if value, let id {
            ChoppedData.start(id)
        } else if snapshot?.running?.id == id || tracker == nil {
            ChoppedData.stop()
        }
        ChoppedSync.didChange()
        return .result()
    }
}

/// Control Center: "running tracker" toggle. Off stops; on resumes the last-used tracker.
struct SetAnyRunningIntent: SetValueIntent, LiveActivityIntent {
    static var title: LocalizedStringResource = "Clock In / Out"
    static var openAppWhenRun = false

    @Parameter(title: "Running") var value: Bool

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        if value {
            if let id = ChoppedData.snapshot()?.lastUsed?.id { ChoppedData.start(id) }
        } else {
            ChoppedData.stop()
        }
        ChoppedSync.didChange()
        return .result()
    }
}

/// Small widget configuration: which tracker to show (empty = the running tracker, else the first).
struct SelectTrackerIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Tracker"
    static var description = IntentDescription("Choose a tracker. Leave empty to follow the running tracker.")

    @Parameter(title: "Tracker") var tracker: TrackerEntity?

    init() {}
    init(tracker: TrackerEntity?) { self.tracker = tracker }
}
