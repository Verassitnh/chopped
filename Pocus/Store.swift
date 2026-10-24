import Foundation
import Observation

struct Activity: Identifiable, Hashable {
    let id: Int64
    var name: String
    /// Accent hex, e.g. "#4A8BE5". Use `color` for accent + tint.
    var colorHex: String
    var position: Int
    /// Glyph key (`Glyph.trackerIcons`), e.g. "target".
    var icon: String = Glyph.target.rawValue
    /// Goal per `period`, in minutes (25h/week = 1500).
    var goalMinutes: Int = 600
    var period: GoalPeriod = .week

    var color: TrackerColor { TrackerColor.forHex(colorHex) }
    var glyph: Glyph { Glyph.tracker(icon) }
    /// Goal in seconds.
    var goal: TimeInterval { TimeInterval(goalMinutes * 60) }

    /// "Weekly · 25h goal" — default card meta line.
    var goalLine: String { "\(period.adjective) · \(Fmt.goal(minutes: goalMinutes)) goal" }
}

struct WorkSession: Identifiable, Hashable {
    let id: Int64
    let activityID: Int64
    var start: Date
    var end: Date?

    var isRunning: Bool { end == nil }

    /// Seconds of this session that fall inside `interval`. Running sessions count up to `now`.
    func duration(in interval: DateInterval, now: Date) -> TimeInterval {
        let lower = max(start, interval.start)
        let upper = min(end ?? now, interval.end)
        return max(0, upper.timeIntervalSince(lower))
    }

    /// Whole length (running sessions up to `now`).
    func duration(now: Date) -> TimeInterval { max(0, (end ?? now).timeIntervalSince(start)) }
}

/// A total for one calendar bucket (day / week / goal period).
struct PeriodTotal: Hashable, Identifiable {
    let interval: DateInterval
    let seconds: TimeInterval
    var start: Date { interval.start }
    var id: Date { interval.start }
}

/// One goal period's outcome.
struct GoalResult: Hashable, Identifiable {
    let interval: DateInterval
    let seconds: TimeInterval
    let goal: TimeInterval
    /// The period containing `now` (still in progress).
    let isCurrent: Bool
    var fraction: Double { goal > 0 ? seconds / goal : 0 }
    var hit: Bool { goal > 0 && seconds >= goal }
    var id: Date { interval.start }
}

struct Streak: Hashable {
    /// Consecutive hit periods ending with the last completed period, plus the current one if already hit
    /// (or, for daily goals, while today is still in progress after a hit day).
    let current: Int
    /// Longest run of consecutive hit periods in the scanned range.
    let best: Int
    /// Runs of consecutive hit periods (for streak timelines), oldest first.
    let runs: [DateInterval]
}

/// Day bucket for the consistency heatmap.
struct DayScore: Hashable, Identifiable {
    let day: DateInterval
    /// min(1, time logged that day on all trackers ÷ the day's target), where the target is the sum of every
    /// tracker's goal pro-rated to one day (`dailyShare`). 1 = perfect day ("put in a full day's worth").
    let score: Double
    var isPerfect: Bool { score >= 0.999 }
    var id: Date { day.start }

    /// Heatmap level: 0 under 1/8 of the target (~48 min with the default goals), 1 under 1/4,
    /// 2 under the full target, 3 = perfect.
    static func level(_ score: Double) -> Int {
        if score >= 0.999 { return 3 }
        if score >= 0.25 { return 2 }
        if score >= 0.125 { return 1 }
        return 0
    }
    var level: Int { DayScore.level(score) }
}

/// Sessions of one tracker on one day (detail "Entries").
struct DayEntries: Hashable, Identifiable {
    let day: DateInterval
    /// Newest first.
    let sessions: [WorkSession]
    let total: TimeInterval
    var id: Date { day.start }
}

struct SessionStats: Hashable {
    let count: Int
    let average: TimeInterval
    let longest: TimeInterval
    /// Day with the largest total (nil if no time).
    let bestDay: Date?
}

@Observable
final class Store {
    private let db: Database
    /// Live Activity syncing is off in QC demo mode.
    private let liveActivities: Bool
    private(set) var activities: [Activity] = []
    /// All sessions, newest first.
    private(set) var sessions: [WorkSession] = []

    /// Monday-first calendar used for every bucket.
    var calendar: Calendar { .chopped }

    init(db: Database = Database(), seed: Bool = true, liveActivities: Bool = true) {
        self.db = db
        self.liveActivities = liveActivities
        if seed { seedIfNeeded() }
        reload()
    }

    var activeSession: WorkSession? { sessions.first { $0.end == nil } }
    var activeActivity: Activity? { activeSession.flatMap { activity($0.activityID) } }

    func activity(_ id: Int64) -> Activity? { activities.first { $0.id == id } }

    func isRunning(_ activityID: Int64) -> Bool { activeSession?.activityID == activityID }

    // MARK: Clocking

    /// Clocks into `activity`, clocking out of whatever was running.
    func clockIn(_ activity: Activity) {
        guard activeSession?.activityID != activity.id else { return }
        let now = AppClock.now
        stop(at: now)
        db.execute("INSERT INTO sessions (activity_id, start) VALUES (?, ?)", [activity.id, now])
        reload()
    }

    func stop(at date: Date = AppClock.now) {
        db.execute("UPDATE sessions SET end = ? WHERE end IS NULL", [date])
        reload()
    }

    // MARK: Calendar buckets

    static func week(containing date: Date) -> DateInterval { Calendar.chopped.dateInterval(of: .weekOfYear, for: date)! }
    static func day(containing date: Date) -> DateInterval { Calendar.chopped.dateInterval(of: .day, for: date)! }

    func interval(_ period: GoalPeriod, containing date: Date) -> DateInterval {
        calendar.dateInterval(of: period.calendarComponent, for: date)!
    }

    /// `count` consecutive periods ending with the one containing `now`, oldest first.
    func intervals(_ period: GoalPeriod, count: Int, endingAt now: Date) -> [DateInterval] {
        let current = interval(period, containing: now)
        return (0..<count).reversed().map { back in
            interval(period, containing: calendar.date(byAdding: period.calendarComponent, value: -back, to: current.start)!)
        }
    }

    /// Days of `interval` (e.g. the 7 days of a week).
    func days(in interval: DateInterval) -> [DateInterval] {
        var out: [DateInterval] = []
        var d = interval.start
        while d < interval.end {
            let day = Store.day(containing: d)
            out.append(day)
            d = day.end
        }
        return out
    }

    // MARK: Totals

    /// Seconds in `interval` for one tracker (nil = all trackers).
    func total(for activityID: Int64? = nil, in interval: DateInterval, now: Date) -> TimeInterval {
        sessions
            .filter { activityID == nil || $0.activityID == activityID }
            .reduce(0) { $0 + $1.duration(in: interval, now: now) }
    }

    func sessions(for activityID: Int64, in interval: DateInterval) -> [WorkSession] {
        sessions.filter {
            $0.activityID == activityID && $0.start < interval.end && ($0.end ?? .distantFuture) > interval.start
        }
    }

    /// Current goal period for the tracker (this day/week/month/year).
    func currentPeriod(for activity: Activity, now: Date) -> DateInterval { interval(activity.period, containing: now) }

    /// Time logged in the tracker's current goal period (home card value, e.g. Reading 96:10 this year).
    func periodTotal(for activity: Activity, now: Date) -> TimeInterval {
        total(for: activity.id, in: currentPeriod(for: activity, now: now), now: now)
    }

    /// periodTotal / goal (may exceed 1). Drives the 20-tick strip.
    func progress(for activity: Activity, now: Date) -> Double {
        activity.goal > 0 ? periodTotal(for: activity, now: now) / activity.goal : 0
    }

    /// Goal minus logged time in the current period (0 when hit). "2h 11m left".
    func remaining(for activity: Activity, now: Date) -> TimeInterval {
        max(0, activity.goal - periodTotal(for: activity, now: now))
    }

    /// On pace = logged ≥ goal × (whole days already finished ÷ days in the period). ("4/5 on pace")
    /// Today isn't held against you until it's over, so a weekly goal is judged against Mon…yesterday and a
    /// daily goal is on pace until the day ends (it then shows as a hit or a miss in the streak/dots).
    func isOnPace(_ activity: Activity, now: Date) -> Bool {
        let p = currentPeriod(for: activity, now: now)
        let today = Store.day(containing: now).start
        let done = Double(calendar.dateComponents([.day], from: p.start, to: today).day ?? 0)
        let total = max(1, (p.duration / 86_400).rounded())
        return periodTotal(for: activity, now: now) >= activity.goal * done / total
    }

    /// Per-day totals over `interval` (one entry per day, oldest first). Single pass over sessions.
    func dailyTotals(for activityID: Int64? = nil, in interval: DateInterval, now: Date) -> [PeriodTotal] {
        let days = days(in: interval)
        var buckets = [TimeInterval](repeating: 0, count: days.count)
        for s in sessions where activityID == nil || s.activityID == activityID {
            let end = s.end ?? now
            guard s.start < interval.end, end > interval.start else { continue }
            for (i, day) in days.enumerated() where s.start < day.end && end > day.start {
                buckets[i] += s.duration(in: day, now: now)
            }
        }
        return zip(days, buckets).map { PeriodTotal(interval: $0, seconds: $1) }
    }

    /// This week's 7 days Mon→Sun (detail + tracker-stats day bars). Future days have 0.
    func thisWeekDays(for activityID: Int64? = nil, now: Date) -> [PeriodTotal] {
        dailyTotals(for: activityID, in: Store.week(containing: now), now: now)
    }

    /// Totals for `count` periods ending with the current one, oldest first (8-week trend: `.week, 8`).
    func periodTotals(for activityID: Int64? = nil, period: GoalPeriod = .week, count: Int, now: Date) -> [PeriodTotal] {
        intervals(period, count: count, endingAt: now).map {
            PeriodTotal(interval: $0, seconds: total(for: activityID, in: $0, now: now))
        }
    }

    /// (this week so far, all of last week). "↑ 4:15 +13% vs last week".
    func weekComparison(for activityID: Int64? = nil, now: Date) -> (current: TimeInterval, last: TimeInterval) {
        let week = Store.week(containing: now)
        let last = Store.week(containing: week.start.addingTimeInterval(-1))
        return (total(for: activityID, in: week, now: now), total(for: activityID, in: last, now: now))
    }

    // MARK: Goals, streaks, heatmap

    /// Goal outcome for the last `count` periods of the tracker's own period, oldest first (last = current).
    func goalHistory(for activity: Activity, count: Int, now: Date) -> [GoalResult] {
        let current = currentPeriod(for: activity, now: now)
        return intervals(activity.period, count: count, endingAt: now).map {
            GoalResult(interval: $0, seconds: total(for: activity.id, in: $0, now: now),
                       goal: activity.goal, isCurrent: $0 == current)
        }
    }

    /// Streak in units of the tracker's period, scanning back `lookback` periods. Same rule as `GoalSeries`:
    /// a daily streak includes today while it's in progress (yesterday hit); other periods count once hit.
    func streak(for activity: Activity, lookback: Int = 120, now: Date) -> Streak {
        let history = goalHistory(for: activity, count: lookback, now: now)
        func counts(_ i: Int) -> Bool {
            history[i].hit || (activity.period == .day && history[i].isCurrent && i > 0 && history[i - 1].hit)
        }
        var runs: [DateInterval] = []
        var run: DateInterval?
        var best = 0, length = 0
        for i in history.indices {
            if counts(i) {
                length += 1
                run = run.map { DateInterval(start: $0.start, end: history[i].interval.end) } ?? history[i].interval
                best = max(best, length)
            } else {
                if let run { runs.append(run) }
                run = nil
                length = 0
            }
        }
        if let run { runs.append(run) }
        var current = 0
        for i in history.indices.reversed() {
            if history[i].isCurrent && !counts(i) { continue }
            if counts(i) { current += 1 } else { break }
        }
        return Streak(current: current, best: best, runs: runs)
    }

    /// Seconds per day for the tracker's goal, pro-rated (week goal / 7, month / days-in-month, year / days-in-year).
    func dailyShare(of activity: Activity, on day: Date) -> TimeInterval {
        let p = interval(activity.period, containing: day)
        let days = max(1, (p.duration / 86_400).rounded())
        return activity.goal / days
    }

    /// Consistency heatmap: `days` days ending today, oldest first.
    func dayScores(days count: Int, now: Date) -> [DayScore] {
        let today = Store.day(containing: now)
        let range = DateInterval(start: calendar.date(byAdding: .day, value: -(count - 1), to: today.start)!, end: today.end)
        let logged = dailyTotals(in: range, now: now)
        return days(in: range).enumerated().map { i, day in
            let target = activities.reduce(0.0) { $0 + dailyShare(of: $1, on: day.start) }
            return DayScore(day: day, score: target > 0 ? min(1, logged[i].seconds / target) : 0)
        }
    }

    // MARK: Entries

    /// Sessions grouped per day (newest day first, newest session first) within `interval`.
    func entriesByDay(for activityID: Int64, in interval: DateInterval, now: Date) -> [DayEntries] {
        let list = sessions(for: activityID, in: interval)  // already newest first
        var groups: [Date: [WorkSession]] = [:]
        for s in list { groups[Store.day(containing: s.start).start, default: []].append(s) }
        return groups.keys.sorted(by: >).map { start in
            let day = Store.day(containing: start)
            return DayEntries(day: day, sessions: groups[start]!, total: total(for: activityID, in: day, now: now))
        }
    }

    /// Count / average / longest / best day for a tracker within `interval` ("12 sessions · 1:54 avg").
    func sessionStats(for activityID: Int64, in interval: DateInterval, now: Date) -> SessionStats {
        let list = sessions(for: activityID, in: interval)
        let durations = list.map { $0.duration(in: interval, now: now) }
        let total = durations.reduce(0, +)
        let best = dailyTotals(for: activityID, in: interval, now: now).max { $0.seconds < $1.seconds }
        return SessionStats(count: list.count,
                            average: list.isEmpty ? 0 : total / Double(list.count),
                            longest: durations.max() ?? 0,
                            bestDay: (best?.seconds ?? 0) > 0 ? best?.start : nil)
    }

    // MARK: Activities

    @discardableResult
    func addActivity(name: String, colorHex: String, icon: Glyph = .target,
                     goalMinutes: Int = 600, period: GoalPeriod = .week) -> Int64 {
        let position = (activities.map(\.position).max() ?? -1) + 1
        let id = db.execute(
            "INSERT INTO activities (name, color, position, icon, goal_minutes, period) VALUES (?, ?, ?, ?, ?, ?)",
            [name, colorHex, position, icon.rawValue, goalMinutes, period.rawValue])
        reload()
        return id
    }

    func updateActivity(_ activity: Activity) {
        db.execute("UPDATE activities SET name = ?, color = ?, icon = ?, goal_minutes = ?, period = ? WHERE id = ?",
                   [activity.name, activity.colorHex, activity.icon, activity.goalMinutes, activity.period.rawValue, activity.id])
        reload()
    }

    func deleteActivity(_ activity: Activity) {
        db.execute("DELETE FROM activities WHERE id = ?", [activity.id])
        reload()
    }

    func moveActivities(from source: IndexSet, to destination: Int) {
        var reordered = activities
        reordered.move(fromOffsets: source, toOffset: destination)
        for (position, activity) in reordered.enumerated() {
            db.execute("UPDATE activities SET position = ? WHERE id = ?", [position, activity.id])
        }
        reload()
    }

    // MARK: Session fixes

    func addSession(activityID: Int64, start: Date, end: Date?) {
        db.execute("INSERT INTO sessions (activity_id, start, end) VALUES (?, ?, ?)", [activityID, start, end])
        reload()
    }

    func updateSession(_ session: WorkSession) {
        db.execute("UPDATE sessions SET start = ?, end = ? WHERE id = ?", [session.start, session.end, session.id])
        reload()
    }

    func deleteSession(_ session: WorkSession) {
        db.execute("DELETE FROM sessions WHERE id = ?", [session.id])
        reload()
    }

    /// Bulk insert without reloading per row (demo seeding).
    func importSessions(_ rows: [(activityID: Int64, start: Date, end: Date?)]) {
        db.transaction {
            for r in rows {
                db.execute("INSERT INTO sessions (activity_id, start, end) VALUES (?, ?, ?)", [r.activityID, r.start, r.end])
            }
        }
        reload()
    }

    // MARK: Loading

    private func reload() {
        activities = db.query("SELECT id, name, color, position, icon, goal_minutes, period FROM activities ORDER BY position, id") {
            Activity(id: $0.int(0), name: $0.text(1), colorHex: $0.text(2), position: Int($0.int(3)),
                     icon: $0.text(4), goalMinutes: Int($0.int(5)), period: GoalPeriod(rawValue: $0.text(6)) ?? .week)
        }
        sessions = db.query("SELECT id, activity_id, start, end FROM sessions ORDER BY start DESC") {
            WorkSession(id: $0.int(0), activityID: $0.int(1), start: $0.date(2)!, end: $0.date(3))
        }
        syncLiveActivity()
    }

    /// Re-reads the database (changes made by widgets / Control Center / Live Activity intents).
    func refresh() { reload() }

    /// Also called when the app returns to the foreground, to restart a Live Activity the system ended.
    func syncLiveActivity() {
        guard liveActivities else { return }
        let session = activeSession
        let activity = session.flatMap { activity($0.activityID) }
        let base = activity.map { a in
            sessions.filter { $0.activityID == a.id && $0.end != nil }
                .reduce(0) { $0 + $1.duration(in: currentPeriod(for: a, now: AppClock.now), now: AppClock.now) }
        }
        LiveActivityController.sync(session: session, activity: activity, periodBase: base)
    }

    // MARK: Seeding

    struct DefaultTracker {
        let name: String
        let color: TrackerColor
        let icon: Glyph
        let goalMinutes: Int
        let period: GoalPeriod
    }

    /// Default trackers (match the designs).
    static let defaultTrackers: [DefaultTracker] = [
        DefaultTracker(name: "Deep Work", color: .blue, icon: .target, goalMinutes: 25 * 60, period: .week),
        DefaultTracker(name: "Meetings", color: .orange, icon: .people, goalMinutes: 8 * 60, period: .week),
        DefaultTracker(name: "Exercise", color: .teal, icon: .pulse, goalMinutes: 45, period: .day),
        DefaultTracker(name: "Email", color: .purple, icon: .mail, goalMinutes: 30, period: .day),
        DefaultTracker(name: "Reading", color: .red, icon: .book, goalMinutes: 150 * 60, period: .year),
    ]

    /// Inserts the default trackers into an empty store (no UserDefaults flag — used by QC demo).
    func insertDefaultTrackers() {
        for d in Store.defaultTrackers {
            addActivity(name: d.name, colorHex: d.color.accentHex, icon: d.icon, goalMinutes: d.goalMinutes, period: d.period)
        }
    }

    private func seedIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: "seeded") else { return }
        for (position, d) in Store.defaultTrackers.enumerated() {
            db.execute("INSERT INTO activities (name, color, position, icon, goal_minutes, period) VALUES (?, ?, ?, ?, ?, ?)",
                       [d.name, d.color.accentHex, position, d.icon.rawValue, d.goalMinutes, d.period.rawValue])
        }
        UserDefaults.standard.set(true, forKey: "seeded")
    }
}
