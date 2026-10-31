import ActivityKit
import SwiftUI

/// Live Activity for the running clock-in. Everything lives in ContentState so switching
/// activities updates the existing Live Activity instead of starting a new one.
struct ChoppedActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var name: String
        var colorHex: String
        var start: Date
        // Added for the Chopped redesign. Optional so older encoded states still decode.
        var icon: String? = nil
        /// Seconds already logged in the current goal period, *excluding* the running session.
        var periodBase: TimeInterval? = nil
        var goalMinutes: Int? = nil
        var period: String? = nil
        /// Running tracker's id (deep links / intents).
        var trackerID: Int64? = nil
    }
}

extension ChoppedActivityAttributes.ContentState {
    var color: TrackerColor { TrackerColor.forHex(colorHex) }
    var glyph: Glyph { Glyph.tracker(icon) }
    var goalPeriod: GoalPeriod { period.flatMap(GoalPeriod.init(rawValue:)) ?? .week }
    var hasGoal: Bool { (goalMinutes ?? 0) > 0 }

    /// Logged in the current goal period at `now` ("22:49" of "22:49 / 25:00").
    func periodTotal(at now: Date) -> TimeInterval { (periodBase ?? 0) + max(0, now.timeIntervalSince(start)) }

    /// periodTotal / goal (strip fraction).
    func progress(at now: Date) -> Double {
        guard let g = goalMinutes, g > 0 else { return 0 }
        return periodTotal(at: now) / TimeInterval(g * 60)
    }

    var overDate: Date? {
        guard let g = goalMinutes, g > 0 else { return nil }
        return start.addingTimeInterval(TimeInterval(g * 60) - (periodBase ?? 0))
    }

    func isOver(at now: Date) -> Bool { overDate.map { now > $0 } ?? false }

    var hourMark: Date { start.addingTimeInterval(3600) }

    func staleDate(after now: Date) -> Date? {
        [overDate, hourMark].compactMap { $0 }.filter { $0 > now }.min()
    }
}
