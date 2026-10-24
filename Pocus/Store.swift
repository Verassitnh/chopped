import Foundation
import Observation

struct Activity: Identifiable, Hashable {
    let id: Int64
    var name: String
    var colorHex: String
    var position: Int
}

struct WorkSession: Identifiable, Hashable {
    let id: Int64
    let activityID: Int64
    var start: Date
    var end: Date?

    /// Seconds of this session that fall inside `interval`. Running sessions count up to `now`.
    func duration(in interval: DateInterval, now: Date) -> TimeInterval {
        let lower = max(start, interval.start)
        let upper = min(end ?? now, interval.end)
        return max(0, upper.timeIntervalSince(lower))
    }
}

@Observable
final class Store {
    private let db: Database
    private(set) var activities: [Activity] = []
    private(set) var sessions: [WorkSession] = []

    init(db: Database = Database()) {
        self.db = db
        seedIfNeeded()
        reload()
    }

    var activeSession: WorkSession? { sessions.first { $0.end == nil } }

    func activity(_ id: Int64) -> Activity? { activities.first { $0.id == id } }

    // MARK: Clocking

    /// Clocks into `activity`, clocking out of whatever was running.
    func clockIn(_ activity: Activity) {
        guard activeSession?.activityID != activity.id else { return }
        let now = Date()
        stop(at: now)
        db.execute("INSERT INTO sessions (activity_id, start) VALUES (?, ?)", [activity.id, now])
        reload()
    }

    func stop(at date: Date = Date()) {
        db.execute("UPDATE sessions SET end = ? WHERE end IS NULL", [date])
        reload()
    }

    // MARK: Totals

    static func week(containing date: Date) -> DateInterval {
        Calendar.current.dateInterval(of: .weekOfYear, for: date)!
    }

    static func day(containing date: Date) -> DateInterval {
        Calendar.current.dateInterval(of: .day, for: date)!
    }

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

    // MARK: Activities

    func addActivity(name: String, colorHex: String) {
        let position = (activities.map(\.position).max() ?? -1) + 1
        db.execute("INSERT INTO activities (name, color, position) VALUES (?, ?, ?)", [name, colorHex, position])
        reload()
    }

    func updateActivity(_ activity: Activity) {
        db.execute("UPDATE activities SET name = ?, color = ? WHERE id = ?",
                   [activity.name, activity.colorHex, activity.id])
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

    func addSession(activityID: Int64, start: Date, end: Date) {
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

    // MARK: Loading

    private func reload() {
        activities = db.query("SELECT id, name, color, position FROM activities ORDER BY position, id") {
            Activity(id: $0.int(0), name: $0.text(1), colorHex: $0.text(2), position: Int($0.int(3)))
        }
        sessions = db.query("SELECT id, activity_id, start, end FROM sessions ORDER BY start DESC") {
            WorkSession(id: $0.int(0), activityID: $0.int(1), start: $0.date(2)!, end: $0.date(3))
        }
        syncLiveActivity()
    }

    /// Also called when the app returns to the foreground, to restart a Live Activity the system ended.
    func syncLiveActivity() {
        LiveActivityController.sync(session: activeSession, activity: activeSession.flatMap { activity($0.activityID) })
    }

    private func seedIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: "seeded") else { return }
        let defaults = [("Deep Work", "#3A7BD5"), ("Meetings", "#F7971E"), ("Email", "#8E54E9"), ("Exercise", "#11998E")]
        for (position, (name, color)) in defaults.enumerated() {
            db.execute("INSERT INTO activities (name, color, position) VALUES (?, ?, ?)", [name, color, position])
        }
        UserDefaults.standard.set(true, forKey: "seeded")
    }
}
