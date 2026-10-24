import Foundation

/// Deterministic demo data for `-QCDemo` (in-memory DB). Frozen now = Fri 23 Oct 2026 20:56:01 (local time).
/// Weeks start Monday (this week = Oct 19–25). Deep Work running since 20:06:00 → 00:50:01.
/// The per-day table was solved against the designs (03/04 refs) by design/gen/demo/gen.py; see design/FOUNDATION.md
/// "Demo data" for what matches and the contradictions in the designs that can't all hold at once.
enum DemoData {
    static let now: Date = date(2026, 10, 23, 20, 56, 1)

    /// Monday of the current demo week (Oct 19 2026).
    static let weekStart: Date = date(2026, 10, 19, 0, 0, 0)

    static func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int, _ s: Int = 0) -> Date {
        Calendar.chopped.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min, second: s))!
    }

    /// Fresh in-memory store filled with the demo data.
    static func makeStore() -> Store {
        let store = Store(db: .inMemory(), seed: false, liveActivities: false)
        populate(store)
        QC.log(summary(store))
        return store
    }

    /// One-line-per-metric dump of the computed demo numbers (logged at launch in -QCDemo).
    static func summary(_ store: Store) -> String {
        let n = now
        var out = ["QC demo summary:"]
        for a in store.activities {
            let w = store.weekComparison(for: a.id, now: n)
            let series = store.goalSeries(for: a, count: 12, now: n)
            let dots = series.results.map { $0.isCurrent ? "o" : ($0.hit ? "x" : ".") }.joined()
            out.append("  \(a.name): period \(Fmt.hm(store.periodTotal(for: a, now: n))) (\(Fmt.percent(store.progress(for: a, now: n)))) week \(Fmt.hm(w.current)) last \(Fmt.hm(w.last)) streak \(series.current)\(series.unit) best \(series.best)\(series.unit) dots \(dots) onPace \(store.isOnPace(a, now: n))")
        }
        let weeks = store.periodTotals(count: 8, now: n).map { Fmt.hm($0.seconds) }
        out.append("  8 weeks: \(weeks.joined(separator: " "))")
        let scores = store.dayScores(days: 83, now: n)
        out.append("  heat (from Sun Aug 2): \(scores.map { String(DayScore.level($0.score)) }.joined()) perfect \(scores.filter(\.isPerfect).count)")
        if let dw = store.activities.first {
            out.append("  DW days: \(store.thisWeekDays(for: dw.id, now: n).map { Fmt.hm($0.seconds) }.joined(separator: " "))")
            out.append("  DW 8 weeks: \(store.periodTotals(for: dw.id, count: 8, now: n).map { Fmt.hm($0.seconds) }.joined(separator: " "))")
            let st = store.sessionStats(for: dw.id, in: Store.week(containing: n), now: n)
            out.append("  DW sessions \(st.count) avg \(Fmt.hm(st.average)) longest \(Fmt.hm(st.longest)) best \(st.bestDay.map { $0.formatted(.dateTime.weekday()) } ?? "-")")
        }
        return out.joined(separator: "\n")
    }

    /// Minutes per day and tracker, 2026: (month, day, Deep Work, Meetings, Exercise, Email, Reading).
    /// This week's Deep Work is added separately as real sessions (detail entries / session stats).
    private static let days: [(m: Int, d: Int, dw: Int, mt: Int, ex: Int, em: Int, rd: Int)] = [
        (1, 3, 0, 0, 0, 0, 161), (1, 10, 0, 0, 0, 0, 161), (1, 17, 0, 0, 0, 0, 160), (1, 24, 0, 0, 0, 0, 160),
        (1, 31, 0, 0, 0, 0, 160), (2, 7, 0, 0, 0, 0, 160), (2, 14, 0, 0, 0, 0, 160), (2, 21, 0, 0, 0, 0, 160),
        (2, 28, 0, 0, 0, 0, 160), (3, 7, 0, 0, 0, 0, 160), (3, 14, 0, 0, 0, 0, 160), (3, 21, 0, 0, 0, 0, 160),
        (3, 28, 0, 0, 0, 0, 160), (4, 4, 0, 0, 0, 0, 160), (4, 11, 0, 0, 0, 0, 160), (4, 18, 0, 0, 0, 0, 160),
        (4, 25, 0, 0, 0, 0, 160), (5, 2, 0, 0, 0, 0, 160), (5, 9, 0, 0, 0, 0, 160), (5, 16, 0, 0, 0, 0, 160),
        (5, 23, 0, 0, 0, 0, 160), (5, 30, 0, 0, 0, 0, 160), (6, 6, 0, 0, 0, 0, 160), (6, 13, 0, 0, 0, 0, 160),
        (6, 20, 0, 0, 0, 0, 160), (6, 27, 0, 0, 0, 0, 160), (7, 4, 0, 0, 0, 0, 160), (7, 11, 0, 0, 0, 0, 160),
        (7, 18, 0, 0, 0, 0, 160), (7, 25, 0, 0, 0, 0, 160), (8, 2, 0, 0, 0, 0, 60), (8, 3, 0, 20, 45, 30, 0),
        (8, 4, 18, 47, 0, 30, 0), (8, 5, 3, 47, 45, 0, 0), (8, 6, 48, 47, 0, 0, 0), (8, 7, 18, 47, 0, 30, 0),
        (8, 8, 0, 47, 45, 0, 3), (8, 9, 12, 225, 45, 30, 27), (8, 10, 23, 0, 0, 30, 42), (8, 11, 0, 0, 45, 0, 0),
        (8, 12, 0, 0, 45, 30, 20), (8, 13, 51, 0, 0, 0, 30), (8, 14, 0, 0, 45, 30, 20), (8, 15, 0, 0, 0, 30, 48),
        (8, 16, 0, 0, 45, 30, 20), (8, 17, 274, 0, 0, 30, 18), (8, 18, 20, 0, 45, 30, 0), (8, 19, 0, 0, 0, 30, 0),
        (8, 20, 65, 0, 0, 30, 0), (8, 21, 201, 0, 45, 30, 0), (8, 22, 180, 0, 0, 0, 96), (8, 23, 180, 0, 0, 30, 66),
        (8, 24, 141, 144, 45, 30, 0), (8, 25, 0, 0, 0, 30, 0), (8, 26, 0, 20, 45, 30, 0), (8, 27, 141, 120, 45, 30, 0),
        (8, 28, 0, 0, 0, 30, 0), (8, 29, 103, 146, 0, 30, 40), (8, 30, 0, 50, 45, 0, 0), (8, 31, 65, 0, 0, 30, 0),
        (9, 1, 246, 30, 0, 30, 30), (9, 3, 276, 30, 0, 0, 26), (9, 4, 183, 13, 45, 30, 0), (9, 5, 120, 0, 0, 0, 96),
        (9, 6, 120, 0, 45, 30, 21), (9, 7, 292, 30, 0, 30, 30), (9, 8, 65, 0, 0, 30, 0), (9, 9, 0, 0, 45, 0, 0),
        (9, 10, 247, 30, 45, 30, 30), (9, 11, 290, 30, 45, 0, 17), (9, 12, 186, 8, 0, 0, 96), (9, 13, 20, 0, 45, 30, 0),
        (9, 14, 428, 10, 45, 30, 0), (9, 15, 141, 0, 45, 30, 0), (9, 16, 141, 0, 45, 30, 0), (9, 17, 141, 0, 45, 30, 0),
        (9, 18, 20, 0, 45, 30, 0), (9, 19, 94, 21, 45, 30, 0), (9, 20, 60, 21, 45, 30, 0), (9, 21, 81, 0, 45, 30, 0),
        (9, 22, 368, 5, 45, 30, 0), (9, 23, 50, 0, 45, 30, 0), (9, 24, 368, 0, 45, 30, 0), (9, 25, 368, 0, 45, 30, 0),
        (9, 26, 0, 21, 45, 30, 0), (9, 27, 0, 21, 45, 30, 0), (9, 28, 81, 0, 45, 30, 0), (9, 29, 81, 0, 45, 30, 0),
        (9, 30, 448, 0, 45, 0, 0), (10, 1, 81, 0, 45, 30, 0), (10, 2, 81, 0, 45, 30, 0), (10, 3, 60, 21, 45, 30, 0),
        (10, 4, 313, 100, 0, 30, 0), (10, 5, 364, 0, 45, 30, 0), (10, 6, 21, 0, 45, 30, 0), (10, 7, 21, 0, 45, 30, 0),
        (10, 8, 308, 0, 45, 30, 0), (10, 9, 353, 0, 0, 30, 0), (10, 10, 0, 21, 45, 30, 0), (10, 11, 213, 125, 45, 0, 0),
        (10, 12, 350, 0, 15, 20, 0), (10, 13, 360, 0, 0, 30, 0), (10, 14, 60, 120, 15, 30, 0), (10, 15, 60, 120, 45, 30, 0),
        (10, 16, 50, 95, 15, 20, 0), (10, 17, 290, 0, 45, 20, 42), (10, 18, 0, 35, 45, 20, 0), (10, 19, 0, 90, 50, 40, 45),
        (10, 20, 0, 0, 45, 30, 0), (10, 21, 0, 50, 50, 42, 0), (10, 22, 0, 130, 50, 40, 45), (10, 23, 0, 54, 30, 27, 0),    ]

    static func populate(_ store: Store) {
        store.insertDefaultTrackers()
        let ids = Dictionary(uniqueKeysWithValues: store.activities.map { ($0.name, $0.id) })
        let dw = ids["Deep Work"]!, mt = ids["Meetings"]!, ex = ids["Exercise"]!, em = ids["Email"]!, rd = ids["Reading"]!

        var rows: [(activityID: Int64, start: Date, end: Date?)] = []
        func add(_ id: Int64, _ m: Int, _ d: Int, _ h: Int, _ min: Int, minutes: Int) {
            guard minutes > 0 else { return }
            let start = date(2026, m, d, h, min)
            rows.append((id, start, start.addingTimeInterval(TimeInterval(minutes * 60))))
        }

        // Day layout: Exercise 07:00 · Email 08:15 · Deep Work 09:00 (+ 13:30 when over 2:30) · Meetings 18:00 · Reading 21:15.
        for r in days {
            add(ex, r.m, r.d, 7, 0, minutes: r.ex)
            add(em, r.m, r.d, 8, 15, minutes: r.em)
            if r.dw > 150 {
                add(dw, r.m, r.d, 9, 0, minutes: r.dw / 2); add(dw, r.m, r.d, 13, 30, minutes: r.dw - r.dw / 2)
            } else {
                add(dw, r.m, r.d, 9, 0, minutes: r.dw)
            }
            add(mt, r.m, r.d, 18, 0, minutes: r.mt)
            add(rd, r.m, r.d, 21, 15, minutes: r.rd)
        }

        // This week's Deep Work: M 4:12 · T 5:06 · W 3:48 · T 6:00 · F 3:43 (incl. running 0:50:01) = 22:49,
        // 12 sessions, avg 1:54, longest 3:45 (Thu 14:00→17:45), best day Thu.
        add(dw, 10, 19, 9, 0, minutes: 150); add(dw, 10, 19, 13, 30, minutes: 102)
        add(dw, 10, 20, 9, 0, minutes: 120); add(dw, 10, 20, 13, 30, minutes: 96); add(dw, 10, 20, 16, 0, minutes: 90)
        add(dw, 10, 21, 9, 0, minutes: 138); add(dw, 10, 21, 13, 30, minutes: 90)
        add(dw, 10, 22, 9, 30, minutes: 135); add(dw, 10, 22, 14, 0, minutes: 225)
        add(dw, 10, 23, 9, 0, minutes: 105); add(dw, 10, 23, 13, 30, minutes: 68)
        rows.append((dw, date(2026, 10, 23, 20, 6, 0), nil))  // running → 00:50:01

        store.importSessions(rows)
    }
}
