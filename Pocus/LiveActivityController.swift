import Foundation

/// Keeps the single Live Activity (and the widgets / controls) in step with the running session.
enum LiveActivityController {
    /// - Parameter periodBase: seconds already logged in the tracker's current goal period, excluding the running session.
    static func sync(session: WorkSession?, activity: Activity?, periodBase: TimeInterval? = nil) {
        let state = session.flatMap { session in
            activity.map { activity in
                PocusActivityAttributes.ContentState(
                    name: activity.name, colorHex: activity.colorHex, start: session.start,
                    icon: activity.icon, periodBase: periodBase, goalMinutes: activity.goalMinutes,
                    period: activity.period.rawValue, trackerID: activity.id)
            }
        }
        LiveActivityBridge.sync(state)
        ChoppedSync.reloadSurfaces()
    }
}
