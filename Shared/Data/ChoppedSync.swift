import ActivityKit
import Foundation
import WidgetKit

/// Keeps every system surface (Live Activity, widgets, controls) in step with the database.
enum ChoppedSync {
    /// Set by the app at launch: reloads the in-memory `Store` from disk (which then syncs the
    /// Live Activity and reloads widgets). nil inside the widget extension.
    @MainActor static var appRefresh: (() -> Void)?

    /// Call after an intent changed the database.
    @MainActor static func didChange() {
        if let appRefresh {
            appRefresh()
        } else {
            LiveActivityBridge.sync(ChoppedData.snapshot()?.activityState)
            reloadSurfaces()
        }
    }

    /// Reloads widget timelines and Control Center controls.
    static func reloadSurfaces() {
        WidgetCenter.shared.reloadAllTimelines()
        if #available(iOS 18.0, *) {
            ControlCenter.shared.reloadAllControls()
        }
    }
}

/// Starts / updates / ends the single clock-in Live Activity.
enum LiveActivityBridge {
    private typealias ClockIn = ActivityKit.Activity<PocusActivityAttributes>

    static func sync(_ state: PocusActivityAttributes.ContentState?) {
        let running = ClockIn.activities.filter { $0.activityState == .active || $0.activityState == .stale }

        guard let state else {
            for live in running {
                Task { await live.end(nil, dismissalPolicy: .immediate) }
            }
            return
        }

        // Stale at the 1h mark so the island re-renders with room for the hour field ("1:00:00").
        let hourMark = state.start.addingTimeInterval(3600)
        let content = ActivityContent(state: state, staleDate: hourMark > Date() ? hourMark : nil)
        if let current = running.first {
            for extra in running.dropFirst() {
                Task { await extra.end(nil, dismissalPolicy: .immediate) }
            }
            if current.content.state != state || current.content.staleDate != content.staleDate {
                Task { await current.update(content) }
            }
        } else if ActivityAuthorizationInfo().areActivitiesEnabled {
            do {
                _ = try ClockIn.request(attributes: PocusActivityAttributes(), content: content)
            } catch {
                NSLog("Chopped live activity request failed: \(error)")
            }
        } else {
            NSLog("Chopped live activities disabled")
        }
    }
}
