import ActivityKit
import Foundation
import WidgetKit

/// Keeps every system surface (Live Activity, widgets, controls) in step with the database.
enum ChoppedSync {
    /// Set by the app at launch: reloads the in-memory `Store` from disk (which then syncs the
    /// Live Activity and reloads widgets). nil inside the widget extension.
    @MainActor static var appRefresh: (() -> Void)?

    /// Call after an intent changed the database (synchronously, before `perform()` returns).
    @MainActor static func didChange() {
        if let appRefresh {
            appRefresh()
        } else {
            // Widget extension: widgets / controls first, so every surface flips right away.
            reloadSurfaces()
            // Update / end the Live Activity if this process can see it (it can't start one).
            LiveActivityBridge.sync(ChoppedData.snapshot()?.activityState, canRequest: false)
            // Tell a running app to re-read the database (which also syncs the Live Activity).
            CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                                 CFNotificationName(changedNotification as CFString), nil, nil, true)
        }
    }

    /// Darwin notification posted by the widget extension after it changed the database.
    static let changedNotification = "com.jackson.Pocus.dataChanged"

    /// App: calls `handler` on the main queue whenever the widget extension changes the database.
    @MainActor static func observeExtensionChanges(_ handler: @escaping @MainActor () -> Void) {
        extensionChangeHandler = handler
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), nil, { _, _, _, _, _ in
            DispatchQueue.main.async { MainActor.assumeIsolated { ChoppedSync.extensionChangeHandler?() } }
        }, changedNotification as CFString, nil, .deliverImmediately)
    }

    @MainActor private static var extensionChangeHandler: (@MainActor () -> Void)?

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

    /// - Parameter canRequest: false in the widget extension, which may update / end but never start one.
    static func sync(_ state: PocusActivityAttributes.ContentState?, canRequest: Bool = true) {
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
        } else if canRequest, ActivityAuthorizationInfo().areActivitiesEnabled {
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
