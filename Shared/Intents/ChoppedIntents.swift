import AppIntents
import Foundation

// Compiled into both the app and the widget extension. `LiveActivityIntent`s run in the app's
// process (launched in the background if needed), so they can start/end the Live Activity. Home-screen
// widget buttons use the plain `Widget…Intent`s instead, which run in the extension and flip instantly.

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

/// Start a tracker (widget play buttons). Clocks out of whatever was running.
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

/// Home-screen widget Play. A plain `AppIntent` (not a `LiveActivityIntent`), so the system runs it in the
/// widget extension and re-renders the tapped widget as soon as `perform()` returns, without waiting for a
/// background launch of the app. The Live Activity / app catch up through `ChoppedSync.didChange()`.
struct WidgetStartTrackerIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Tracker"
    static var openAppWhenRun = false
    static var isDiscoverable = false

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

/// Home-screen widget Stop (see `WidgetStartTrackerIntent`).
struct WidgetStopTrackerIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Tracker"
    static var openAppWhenRun = false
    static var isDiscoverable = false

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        ChoppedData.stop()
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
