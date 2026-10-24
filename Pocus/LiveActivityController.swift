import ActivityKit
import Foundation

/// Keeps the single Live Activity in step with the running session.
enum LiveActivityController {
    private typealias ClockIn = ActivityKit.Activity<PocusActivityAttributes>

    /// - Parameter periodBase: seconds already logged in the tracker's current goal period, excluding the running session.
    static func sync(session: WorkSession?, activity: Activity?, periodBase: TimeInterval? = nil) {
        let running = ClockIn.activities.filter { $0.activityState == .active || $0.activityState == .stale }

        guard let session, let activity else {
            for liveActivity in running {
                Task { await liveActivity.end(nil, dismissalPolicy: .immediate) }
            }
            return
        }

        let state = PocusActivityAttributes.ContentState(
            name: activity.name, colorHex: activity.colorHex, start: session.start,
            icon: activity.icon, periodBase: periodBase, goalMinutes: activity.goalMinutes, period: activity.period.rawValue)
        let content = ActivityContent(state: state, staleDate: nil)

        if let current = running.first {
            for extra in running.dropFirst() {
                Task { await extra.end(nil, dismissalPolicy: .immediate) }
            }
            if current.content.state != state {
                Task { await current.update(content) }
            }
        } else if ActivityAuthorizationInfo().areActivitiesEnabled {
            _ = try? ClockIn.request(attributes: PocusActivityAttributes(), content: content)
        }
    }
}
