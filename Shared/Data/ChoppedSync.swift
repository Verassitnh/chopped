import ActivityKit
import Foundation
import WidgetKit

/// Keeps every system surface (Live Activity, widgets, controls) in step with the database.
enum ChoppedSync {
    /// Set by the app at launch: re-reads the in-memory `Store` (UI + haptic) when the app is on screen.
    /// nil inside the widget extension.
    @MainActor static var appRefresh: (() -> Void)?

    /// Call after an intent changed the database (synchronously, before `perform()` returns).
    @MainActor static func didChange() {
        // Widgets / controls first, so every surface flips right away.
        reloadSurfaces()
        if let appRefresh {
            // App process: straight from SQLite (no full Store load), then the Store if it's on screen.
            LiveActivityBridge.sync(ChoppedData.snapshot()?.activityState)
            appRefresh()
        } else {
            // Widget extension: it can't see the app's Live Activity. The widget intents chain
            // `SyncLiveActivityIntent` into the app for that; this wakes an app that's already running.
            CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                                 CFNotificationName(changedNotification as CFString), nil, nil, true)
        }
    }

    /// Darwin notification posted by the widget extension after it changed the database.
    static let changedNotification = "com.jackson.chopped.dataChanged"

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
    private typealias ClockIn = ActivityKit.Activity<ChoppedActivityAttributes>

    /// App process only (the widget extension can't see the app's activities).
    static func sync(_ state: ChoppedActivityAttributes.ContentState?) {
        let enabled = ActivityAuthorizationInfo().areActivitiesEnabled
        if AppGroup.defaults?.object(forKey: AppGroup.liveActivitiesEnabledKey) as? Bool != enabled {
            AppGroup.defaults?.set(enabled, forKey: AppGroup.liveActivitiesEnabledKey)
        }
        let running = ClockIn.activities.filter { $0.activityState == .active || $0.activityState == .stale }
        OverLimitNotice.schedule(for: state)

        guard let state else {
            for live in running {
                Task { await live.end(nil, dismissalPolicy: .immediate) }
            }
            return
        }

        // Stale at the 1h mark so the island re-renders with room for the hour field ("1:00:00"), or earlier
        // when the tracker runs past its goal, so the system re-renders it drained without the app running.
        let content = ActivityContent(state: state, staleDate: state.staleDate(after: Date()))
        if let current = running.first {
            for extra in running.dropFirst() {
                Task { await extra.end(nil, dismissalPolicy: .immediate) }
            }
            if current.content.state != state || current.content.staleDate != content.staleDate {
                Task { await current.update(content) }
            }
        } else if enabled {
            do {
                _ = try ClockIn.request(attributes: ChoppedActivityAttributes(), content: content)
            } catch {
                NSLog("Chopped live activity request failed: \(error)")
            }
        } else {
            NSLog("Chopped live activities disabled")
        }
    }
}
