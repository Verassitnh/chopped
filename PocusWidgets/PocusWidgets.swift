import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

@main
struct PocusWidgets: WidgetBundle {
    var body: some Widget {
        ClockInLiveActivity()
        TrackersWidget()
        TrackerWidget()
        if #available(iOS 18.0, *) {
            RunningControl()
            TrackerControl()
        }
    }
}

// MARK: - Live Activity + Dynamic Island

struct ClockInLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PocusActivityAttributes.self) { context in
            LockActivityView(state: context.state, isStale: context.isStale)
                .activityBackgroundTint(context.state.color.tint)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let state = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading, priority: 1) {
                    IslandExpandedHeader(state: state, isStale: context.isStale)
                        .padding(.leading, 6)
                        .dynamicIsland(verticalPlacement: .belowIfTooWide)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    IslandStopButton(state: state)
                        .padding(.trailing, 6)
                        .frame(maxHeight: .infinity)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    IslandExpandedFooter(state: state)
                        .padding(.horizontal, 6)
                        .padding(.top, 8)
                }
            } compactLeading: {
                IslandIconTile(state: state)
            } compactTrailing: {
                IslandCompactTimer(state: state, isStale: context.isStale)
            } minimal: {
                IslandIconTile(state: state)
            }
            .keylineTint(state.color.accent)
        }
    }
}

// MARK: - Timeline

struct ChoppedEntry: TimelineEntry {
    let date: Date
    let snapshot: ChoppedSnapshot?
    /// Small widget: configured tracker id (nil = follow the running tracker).
    var selectedID: Int64? = nil

    /// The small widget's tracker: configured → running → first.
    var smallTracker: TrackerSnapshot? {
        guard let snapshot else { return nil }
        return snapshot.tracker(selectedID) ?? snapshot.running ?? snapshot.trackers.first
    }
}

enum ChoppedTimeline {
    /// Entries every minute for an hour while something runs (totals/strips move), otherwise one entry
    /// refreshed at the next period boundary (or in an hour).
    static func entries(selectedID: Int64? = nil) -> Timeline<ChoppedEntry> {
        let now = Date()
        let snapshot = ChoppedData.snapshot(now: now)
        guard let snapshot, snapshot.running != nil else {
            let next = snapshot?.trackers.map(\.periodInterval.end).min().map { min($0, now.addingTimeInterval(3600)) }
                ?? now.addingTimeInterval(3600)
            return Timeline(entries: [ChoppedEntry(date: now, snapshot: snapshot, selectedID: selectedID)], policy: .after(next))
        }
        let minute = Calendar.current.dateInterval(of: .minute, for: now)?.start ?? now
        var entries = (0..<60).map { i -> ChoppedEntry in
            let date = i == 0 ? now : minute.addingTimeInterval(TimeInterval(i * 60))
            return ChoppedEntry(date: date, snapshot: snapshot, selectedID: selectedID)
        }
        // An entry exactly at the 1h mark, where the live timer switches "59:59" → "1:00:00" (LiveTimerText).
        if let hourMark = snapshot.running?.runningStart?.addingTimeInterval(3600),
           hourMark > now, let last = entries.last?.date, hourMark < last {
            entries.append(ChoppedEntry(date: hourMark, snapshot: snapshot, selectedID: selectedID))
            entries.sort { $0.date < $1.date }
        }
        return Timeline(entries: entries, policy: .atEnd)
    }

    static var placeholder: ChoppedEntry {
        let now = Date()
        let week = Calendar.chopped.dateInterval(of: .weekOfYear, for: now)!
        let day = Calendar.chopped.dateInterval(of: .day, for: now)!
        func t(_ id: Int64, _ name: String, _ c: TrackerColor, _ icon: String, _ goal: Int, _ p: GoalPeriod,
               _ logged: TimeInterval, running: Bool = false) -> TrackerSnapshot {
            TrackerSnapshot(id: id, name: name, colorHex: c.accentHex, icon: icon, goalMinutes: goal, period: p,
                            position: Int(id), periodInterval: p == .day ? day : week, periodLogged: logged,
                            runningStart: running ? now.addingTimeInterval(-3001) : nil, lastUsed: nil)
        }
        let s = ChoppedSnapshot(date: now, trackers: [
            t(1, "Deep Work", .blue, "target", 1500, .week, 79_140, running: true),
            t(2, "Meetings", .orange, "people", 480, .week, 19_440),
            t(3, "Exercise", .teal, "pulse", 45, .day, 1_800),
            t(4, "Email", .purple, "mail", 30, .day, 1_620),
        ])
        return ChoppedEntry(date: now, snapshot: s)
    }
}

struct TrackersProvider: TimelineProvider {
    func placeholder(in context: Context) -> ChoppedEntry { ChoppedTimeline.placeholder }
    func getSnapshot(in context: Context, completion: @escaping (ChoppedEntry) -> Void) {
        let live = ChoppedEntry(date: Date(), snapshot: ChoppedData.snapshot())
        completion(context.isPreview && (live.snapshot?.trackers.isEmpty ?? true) ? ChoppedTimeline.placeholder : live)
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<ChoppedEntry>) -> Void) {
        completion(ChoppedTimeline.entries())
    }
}

struct TrackerProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ChoppedEntry { ChoppedTimeline.placeholder }
    func snapshot(for configuration: SelectTrackerIntent, in context: Context) async -> ChoppedEntry {
        let live = ChoppedEntry(date: Date(), snapshot: ChoppedData.snapshot(), selectedID: configuration.tracker.map { Int64($0.id) })
        return context.isPreview && live.smallTracker == nil ? ChoppedTimeline.placeholder : live
    }
    func timeline(for configuration: SelectTrackerIntent, in context: Context) async -> Timeline<ChoppedEntry> {
        ChoppedTimeline.entries(selectedID: configuration.tracker.map { Int64($0.id) })
    }
}

// MARK: - Home-screen widgets

struct TrackersWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ChoppedTrackers", provider: TrackersProvider()) { entry in
            Group {
                if let snapshot = entry.snapshot, !snapshot.trackers.isEmpty {
                    MediumWidgetView(snapshot: snapshot, now: entry.date)
                } else {
                    EmptyWidgetView()
                }
            }
            .containerBackground(MediumWidgetView.background, for: .widget)
        }
        .configurationDisplayName("Trackers")
        .description("Your running tracker and quick starts.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

struct TrackerWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "ChoppedTracker", intent: SelectTrackerIntent.self, provider: TrackerProvider()) { entry in
            if let t = entry.smallTracker {
                SmallWidgetView(tracker: t, somethingRunning: entry.snapshot?.running != nil, now: entry.date)
                    .containerBackground(t.color.tint, for: .widget)
            } else {
                EmptyWidgetView()
                    .containerBackground(CH.raised, for: .widget)
            }
        }
        .configurationDisplayName("Tracker")
        .description("Start, stop and follow one tracker.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

// MARK: - Control Center (iOS 18)

/// SF Symbol stand-ins for the tracker glyphs (controls only render symbols).
func controlSymbol(_ icon: String) -> String {
    switch Glyph.tracker(icon) {
    case .people: "person.2"
    case .pulse: "waveform.path.ecg"
    case .mail: "envelope"
    case .book: "book"
    case .music: "music.note"
    default: "target"
    }
}

@available(iOS 18.0, *)
struct RunningControl: ControlWidget {
    struct Value {
        var isRunning: Bool
        var name: String
        var colorHex: String
    }

    struct Provider: ControlValueProvider {
        var previewValue: Value { Value(isRunning: true, name: "Deep Work", colorHex: TrackerColor.blue.accentHex) }
        func currentValue() async throws -> Value {
            let s = ChoppedData.snapshot()
            let t = s?.running ?? s?.lastUsed
            return Value(isRunning: s?.running != nil, name: t?.name ?? "Chopped", colorHex: t?.colorHex ?? TrackerColor.blue.accentHex)
        }
    }

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "ChoppedRunningControl", provider: Provider()) { value in
            ControlWidgetToggle(value.name, isOn: value.isRunning, action: SetAnyRunningIntent()) { on in
                Label(on ? "Running" : "Stopped", systemImage: on ? "stop.fill" : "play.fill")
            }
            .tint(Color(hex: value.colorHex))
        }
        .displayName("Running Tracker")
        .description("Stop the running tracker, or resume the last one.")
    }
}

@available(iOS 18.0, *)
struct SelectTrackerControlIntent: ControlConfigurationIntent {
    static var title: LocalizedStringResource = "Tracker"
    @Parameter(title: "Tracker") var tracker: TrackerEntity?
    init() {}
}

@available(iOS 18.0, *)
struct TrackerControl: ControlWidget {
    struct Value {
        var tracker: TrackerEntity?
        var isRunning: Bool
    }

    struct Provider: AppIntentControlValueProvider {
        func previewValue(configuration: SelectTrackerControlIntent) -> Value {
            Value(tracker: configuration.tracker ?? TrackerEntity(id: 0, name: "Exercise", colorHex: TrackerColor.teal.accentHex, icon: "pulse"),
                  isRunning: false)
        }
        func currentValue(configuration: SelectTrackerControlIntent) async throws -> Value {
            let s = ChoppedData.snapshot()
            let entity = configuration.tracker ?? s?.trackers.first.map(TrackerEntity.init)
            let running = entity.map { e in s?.running?.id == Int64(e.id) } ?? false
            return Value(tracker: entity, isRunning: running)
        }
    }

    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(kind: "ChoppedTrackerControl", provider: Provider()) { value in
            ControlWidgetToggle(value.tracker?.name ?? "Tracker", isOn: value.isRunning,
                                action: SetTrackerRunningIntent(tracker: value.tracker)) { on in
                Label(on ? "Running" : "Start",
                      systemImage: on ? "stop.fill" : controlSymbol(value.tracker?.icon ?? "target"))
            }
            .tint(Color(hex: value.tracker?.colorHex ?? TrackerColor.blue.accentHex))
        }
        .displayName("Start Tracker")
        .description("Start or stop a specific tracker.")
        .promptsForUserConfiguration()
    }
}
