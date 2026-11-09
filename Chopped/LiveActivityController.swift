import Foundation

/// Keeps the single Live Activity (and the widgets / controls) in step with the running session.
enum LiveActivityController {
    /// - Parameter periodBase: seconds already logged in the tracker's current goal period, excluding the running session.
    static func sync(session: WorkSession?, activity: Activity?, periodBase: TimeInterval? = nil,
                     next: (session: WorkSession, activity: Activity, periodBase: TimeInterval)? = nil) {
        let state = session.flatMap { session in
            activity.map { activity in
                ChoppedActivityAttributes.ContentState(
                    name: activity.name, colorHex: activity.colorHex, start: session.start,
                    icon: activity.icon, periodBase: periodBase, goalMinutes: activity.goalMinutes,
                    period: activity.period.rawValue, trackerID: activity.id,
                    showsTitle: AppGroup.liveActivityTitles, endsAt: session.end,
                    next: next.map { n in
                        ChoppedActivityAttributes.Upcoming(
                            name: n.activity.name, colorHex: n.activity.colorHex, start: n.session.start,
                            icon: n.activity.icon, periodBase: n.periodBase, goalMinutes: n.activity.goalMinutes,
                            period: n.activity.period.rawValue, trackerID: n.activity.id)
                    })
            }
        }
        LiveActivityBridge.sync(state)
        ChoppedSync.reloadSurfaces()
    }

    static func syncBreak(since start: Date) {
        LiveActivityBridge.sync(.onBreak(since: start))
        ChoppedSync.reloadSurfaces()
    }
}
