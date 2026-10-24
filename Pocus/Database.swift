import Foundation
import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// Thin wrapper over the SQLite C API. Everything runs on the main thread.
final class Database {
    private var db: OpaquePointer?

    init(url: URL = Database.defaultURL) {
        guard sqlite3_open(url.path, &db) == SQLITE_OK else {
            fatalError("Could not open database at \(url.path)")
        }
        execute("PRAGMA foreign_keys = ON")
        execute("""
            CREATE TABLE IF NOT EXISTS activities (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                color TEXT NOT NULL,
                position INTEGER NOT NULL DEFAULT 0
            )
            """)
        execute("""
            CREATE TABLE IF NOT EXISTS sessions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                activity_id INTEGER NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
                start REAL NOT NULL,
                end REAL
            )
            """)
        execute("CREATE INDEX IF NOT EXISTS sessions_start ON sessions(start)")
    }

    deinit { sqlite3_close(db) }

    static var defaultURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("pocus.sqlite")
    }

    /// Runs a statement and returns the last inserted row id.
    @discardableResult
    func execute(_ sql: String, _ params: [Any?] = []) -> Int64 {
        let stmt = prepare(sql, params)
        defer { sqlite3_finalize(stmt) }
        let rc = sqlite3_step(stmt)
        if rc != SQLITE_DONE && rc != SQLITE_ROW {
            assertionFailure("SQLite error: \(String(cString: sqlite3_errmsg(db)))\n\(sql)")
        }
        return sqlite3_last_insert_rowid(db)
    }

    func query<T>(_ sql: String, _ params: [Any?] = [], _ map: (Row) -> T) -> [T] {
        let stmt = prepare(sql, params)
        defer { sqlite3_finalize(stmt) }
        var rows: [T] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            rows.append(map(Row(stmt: stmt)))
        }
        return rows
    }

    private func prepare(_ sql: String, _ params: [Any?]) -> OpaquePointer? {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            fatalError("SQLite prepare failed: \(String(cString: sqlite3_errmsg(db)))\n\(sql)")
        }
        for (offset, param) in params.enumerated() {
            let index = Int32(offset + 1)
            switch param {
            case let value as Int64: sqlite3_bind_int64(stmt, index, value)
            case let value as Int: sqlite3_bind_int64(stmt, index, Int64(value))
            case let value as Double: sqlite3_bind_double(stmt, index, value)
            case let value as Date: sqlite3_bind_double(stmt, index, value.timeIntervalSince1970)
            case let value as String: sqlite3_bind_text(stmt, index, value, -1, SQLITE_TRANSIENT)
            default: sqlite3_bind_null(stmt, index)
            }
        }
        return stmt
    }

    struct Row {
        let stmt: OpaquePointer?

        func int(_ column: Int32) -> Int64 { sqlite3_column_int64(stmt, column) }
        func text(_ column: Int32) -> String { String(cString: sqlite3_column_text(stmt, column)) }
        func date(_ column: Int32) -> Date? {
            sqlite3_column_type(stmt, column) == SQLITE_NULL
                ? nil
                : Date(timeIntervalSince1970: sqlite3_column_double(stmt, column))
        }
    }
}
