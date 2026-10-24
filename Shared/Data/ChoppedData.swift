import Foundation
import SQLite3

/// App Group shared by the app and the widget extension (entitlements: Pocus.entitlements / PocusWidgets.entitlements).
enum AppGroup {
    static let id = "group.com.jackson.Pocus"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id)
    }
}

/// Location of the SQLite database, shared through the App Group.
///
/// The database used to live in the app's own Application Support directory. `appURL` moves it into the
/// group container once (copy, then the old file is renamed to `pocus-pre-appgroup.sqlite` as a backup), so
/// the widget extension and App Intents can read and write the same data. The widget extension only ever
/// opens an *existing* database (`existingURL`): it must never create an empty file before the app has
/// migrated, or the migration would be skipped.
enum ChoppedDB {
    static let fileName = "pocus.sqlite"

    static var groupURL: URL? { AppGroup.containerURL?.appendingPathComponent(fileName) }

    /// The app's pre-App-Group location (only meaningful inside the app process).
    static var legacyURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(fileName)
    }

    /// App process: shared DB URL, migrating the legacy file on first use. Falls back to the legacy
    /// location if the App Group container is unavailable (e.g. missing entitlement).
    static var appURL: URL {
        guard let group = groupURL else { return legacyURL }
        migrateIfNeeded(to: group)
        return group
    }

    /// Extensions / intents: the shared DB if it exists (never creates it).
    /// Without the App Group (entitlement not provisioned yet) this falls back to the legacy file, which only
    /// exists inside the app's own sandbox — so Live Activity stop/start intents still work in the app process.
    static var existingURL: URL? {
        let fm = FileManager.default
        if let url = groupURL { return fm.fileExists(atPath: url.path) ? url : nil }
        return fm.fileExists(atPath: legacyURL.path) ? legacyURL : nil
    }

    private static func migrateIfNeeded(to group: URL) {
        let fm = FileManager.default
        let legacy = legacyURL
        guard !fm.fileExists(atPath: group.path), fm.fileExists(atPath: legacy.path) else { return }
        do {
            // Copy side files first so the main file only appears once everything is in place.
            for suffix in ["-wal", "-shm", "-journal"] {
                let src = URL(fileURLWithPath: legacy.path + suffix)
                if fm.fileExists(atPath: src.path) {
                    try? fm.copyItem(at: src, to: URL(fileURLWithPath: group.path + suffix))
                }
            }
            let tmp = group.deletingLastPathComponent().appendingPathComponent("pocus-migrating.sqlite")
            try? fm.removeItem(at: tmp)
            try fm.copyItem(at: legacy, to: tmp)
            try fm.moveItem(at: tmp, to: group)
            // Keep the original as a backup instead of deleting it.
            let backup = legacy.deletingLastPathComponent().appendingPathComponent("pocus-pre-appgroup.sqlite")
            try? fm.removeItem(at: backup)
            try? fm.moveItem(at: legacy, to: backup)
            NSLog("ChoppedDB: migrated database to App Group container")
        } catch {
            NSLog("ChoppedDB: migration failed: \(error)")
        }
    }
}

// MARK: - Snapshot model (widgets, controls, live activity)

/// One tracker as seen by the system surfaces.
struct TrackerSnapshot: Identifiable, Hashable {
    let id: Int64
    var name: String
    var colorHex: String
    var icon: String
    var goalMinutes: Int
    var period: GoalPeriod
    var position: Int
    /// Current goal period (day/week/month/year containing the snapshot date).
    var periodInterval: DateInterval
    /// Seconds logged in the current period by finished sessions.
    var periodLogged: TimeInterval
    /// Start of the running session, if this tracker is running.
    var runningStart: Date?
    /// Most recent session start (any state) — "last used".
    var lastUsed: Date?

    var color: TrackerColor { TrackerColor.forHex(colorHex) }
    var glyph: Glyph { Glyph.tracker(icon) }
    var goal: TimeInterval { TimeInterval(goalMinutes * 60) }
    var isRunning: Bool { runningStart != nil }

    /// Logged in the current period at `now`, including the running session.
    func periodTotal(at now: Date) -> TimeInterval {
        guard let start = runningStart else { return periodLogged }
        return periodLogged + max(0, min(now, periodInterval.end).timeIntervalSince(max(start, periodInterval.start)))
    }

    func progress(at now: Date) -> Double { goal > 0 ? periodTotal(at: now) / goal : 0 }

    /// Seconds in the current period excluding the running session (Live Activity `periodBase`).
    var periodBase: TimeInterval { periodLogged }
}

struct ChoppedSnapshot: Hashable {
    var date: Date
    /// Ordered by position.
    var trackers: [TrackerSnapshot]

    var running: TrackerSnapshot? { trackers.first(where: \.isRunning) }
    func tracker(_ id: Int64?) -> TrackerSnapshot? { id.flatMap { id in trackers.first { $0.id == id } } }
    /// Most recently used tracker (for "resume").
    var lastUsed: TrackerSnapshot? {
        trackers.filter { $0.lastUsed != nil }.max { $0.lastUsed! < $1.lastUsed! } ?? trackers.first
    }

    /// Live Activity state for the running tracker (nil when idle).
    var activityState: PocusActivityAttributes.ContentState? {
        guard let r = running, let start = r.runningStart else { return nil }
        return PocusActivityAttributes.ContentState(
            name: r.name, colorHex: r.colorHex, start: start, icon: r.icon,
            periodBase: r.periodBase, goalMinutes: r.goalMinutes, period: r.period.rawValue, trackerID: r.id)
    }
}

// MARK: - Lightweight SQLite access (extension + intents)

/// Minimal reader/writer over the shared database for the widget extension and App Intents.
/// The app itself keeps using `Database`/`Store`; both talk to the same file.
enum ChoppedData {
    /// Reads every tracker with its current-period totals. nil if the database doesn't exist yet.
    static func snapshot(now: Date = Date()) -> ChoppedSnapshot? {
        guard let url = ChoppedDB.existingURL, let db = Connection(url: url, readOnly: true) else { return nil }
        return db.snapshot(now: now)
    }

    /// Clocks into `trackerID` (clocking out of whatever was running). Returns false if the DB is unavailable.
    @discardableResult
    static func start(_ trackerID: Int64, at date: Date = Date()) -> Bool {
        guard let url = ChoppedDB.existingURL, let db = Connection(url: url, readOnly: false) else { return false }
        let running = db.query("SELECT activity_id FROM sessions WHERE end IS NULL") { sqlite3_column_int64($0, 0) }
        if running == [trackerID] { return true }
        db.exec("BEGIN IMMEDIATE")
        db.exec("UPDATE sessions SET end = ? WHERE end IS NULL", [date.timeIntervalSince1970])
        db.exec("INSERT INTO sessions (activity_id, start) VALUES (?, ?)", [trackerID, date.timeIntervalSince1970])
        db.exec("COMMIT")
        return true
    }

    /// Clocks out of whatever is running.
    @discardableResult
    static func stop(at date: Date = Date()) -> Bool {
        guard let url = ChoppedDB.existingURL, let db = Connection(url: url, readOnly: false) else { return false }
        db.exec("UPDATE sessions SET end = ? WHERE end IS NULL", [date.timeIntervalSince1970])
        return true
    }

    final class Connection {
        private var db: OpaquePointer?

        init?(url: URL, readOnly: Bool) {
            let flags = readOnly ? SQLITE_OPEN_READONLY : SQLITE_OPEN_READWRITE  // never SQLITE_OPEN_CREATE
            guard sqlite3_open_v2(url.path, &db, flags, nil) == SQLITE_OK else {
                sqlite3_close(db)
                return nil
            }
            sqlite3_busy_timeout(db, 3000)
        }

        deinit { sqlite3_close(db) }

        func exec(_ sql: String, _ params: [Any] = []) {
            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
            defer { sqlite3_finalize(stmt) }
            bind(stmt, params)
            _ = sqlite3_step(stmt)
        }

        func query<T>(_ sql: String, _ params: [Any] = [], _ map: (OpaquePointer?) -> T) -> [T] {
            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
            defer { sqlite3_finalize(stmt) }
            bind(stmt, params)
            var rows: [T] = []
            while sqlite3_step(stmt) == SQLITE_ROW { rows.append(map(stmt)) }
            return rows
        }

        private func bind(_ stmt: OpaquePointer?, _ params: [Any]) {
            for (i, p) in params.enumerated() {
                let idx = Int32(i + 1)
                switch p {
                case let v as Int64: sqlite3_bind_int64(stmt, idx, v)
                case let v as Int: sqlite3_bind_int64(stmt, idx, Int64(v))
                case let v as Double: sqlite3_bind_double(stmt, idx, v)
                default: sqlite3_bind_null(stmt, idx)
                }
            }
        }

        private static func text(_ stmt: OpaquePointer?, _ col: Int32, _ fallback: String) -> String {
            guard let c = sqlite3_column_text(stmt, col) else { return fallback }
            return String(cString: c)
        }

        func snapshot(now: Date) -> ChoppedSnapshot {
            struct Row { let id: Int64; let name, color, icon, period: String; let goal: Int; let position: Int }
            let hasChoppedColumns = !query("SELECT 1 FROM pragma_table_info('activities') WHERE name = 'goal_minutes'") { _ in 1 }.isEmpty
            let sql = hasChoppedColumns
                ? "SELECT id, name, color, icon, period, goal_minutes, position FROM activities ORDER BY position, id"
                : "SELECT id, name, color, 'target', 'week', 600, position FROM activities ORDER BY position, id"
            let rows = query(sql) {
                Row(id: sqlite3_column_int64($0, 0), name: Self.text($0, 1, ""), color: Self.text($0, 2, "#4A8BE5"),
                    icon: Self.text($0, 3, "target"), period: Self.text($0, 4, "week"),
                    goal: Int(sqlite3_column_int64($0, 5)), position: Int(sqlite3_column_int64($0, 6)))
            }
            let calendar = Calendar.chopped
            // Earliest period start we need (year covers everything).
            let earliest = calendar.dateInterval(of: .year, for: now)?.start ?? now
            struct S { let activity: Int64; let start: Date; let end: Date? }
            let sessions = query("SELECT activity_id, start, end FROM sessions WHERE end IS NULL OR end > ? ",
                                 [earliest.timeIntervalSince1970]) {
                S(activity: sqlite3_column_int64($0, 0),
                  start: Date(timeIntervalSince1970: sqlite3_column_double($0, 1)),
                  end: sqlite3_column_type($0, 2) == SQLITE_NULL ? nil : Date(timeIntervalSince1970: sqlite3_column_double($0, 2)))
            }
            let lastUsed = Dictionary(query("SELECT activity_id, MAX(start) FROM sessions GROUP BY activity_id") {
                (sqlite3_column_int64($0, 0), Date(timeIntervalSince1970: sqlite3_column_double($0, 1)))
            }, uniquingKeysWith: { a, _ in a })

            let trackers = rows.map { r -> TrackerSnapshot in
                let period = GoalPeriod(rawValue: r.period) ?? .week
                let interval = calendar.dateInterval(of: period.calendarComponent, for: now) ?? DateInterval(start: now, duration: 1)
                var logged: TimeInterval = 0
                var running: Date?
                for s in sessions where s.activity == r.id {
                    guard let end = s.end else { running = s.start; continue }
                    let lo = max(s.start, interval.start), hi = min(end, interval.end)
                    if hi > lo { logged += hi.timeIntervalSince(lo) }
                }
                return TrackerSnapshot(id: r.id, name: r.name, colorHex: r.color, icon: r.icon, goalMinutes: r.goal,
                                       period: period, position: r.position, periodInterval: interval,
                                       periodLogged: logged, runningStart: running, lastUsed: lastUsed[r.id])
            }
            return ChoppedSnapshot(date: now, trackers: trackers)
        }
    }
}
