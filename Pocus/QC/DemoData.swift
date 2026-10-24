import Foundation

/// Deterministic demo data for `-QCDemo` (in-memory DB). Frozen now = Fri 23 Oct 2026 20:56:01 (local time).
/// Weeks start Monday (this week = Oct 19–25). Deep Work running since 20:06:00 → 00:50:01.
/// See design/FOUNDATION.md "Demo data" for the full table and known deviations from the designs.
enum DemoData {
    static let now: Date = date(2026, 10, 23, 20, 56, 1)

    /// Monday of the current demo week (Oct 19 2026).
    static let weekStart: Date = date(2026, 10, 19, 0, 0, 0)

    static func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int, _ s: Int = 0) -> Date {
        Calendar.chopped.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min, second: s))!
    }

    /// Day `offset` (0 = Mon) of week `k` (0 = current, -1 = last week …) at hh:mm.
    private static func at(week k: Int, day offset: Int, _ h: Int, _ m: Int) -> Date {
        let day = Calendar.chopped.date(byAdding: .day, value: 7 * k + offset, to: weekStart)!
        return Calendar.chopped.date(bySettingHour: h, minute: m, second: 0, of: day)!
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
            let s = store.streak(for: a, now: n)
            out.append("  \(a.name): period \(Fmt.hm(store.periodTotal(for: a, now: n))) (\(Fmt.percent(store.progress(for: a, now: n)))) week \(Fmt.hm(w.current)) last \(Fmt.hm(w.last)) streak \(s.current)/best \(s.best) onPace \(store.isOnPace(a, now: n))")
        }
        let weeks = store.periodTotals(count: 8, now: n).map { Fmt.hm($0.seconds) }
        out.append("  8 weeks: \(weeks.joined(separator: " "))")
        let scores = store.dayScores(days: 84, now: n)
        out.append("  perfect days (84d): \(scores.filter(\.isPerfect).count)")
        if let dw = store.activities.first {
            out.append("  DW days: \(store.thisWeekDays(for: dw.id, now: n).map { Fmt.hm($0.seconds) }.joined(separator: " "))")
            let st = store.sessionStats(for: dw.id, in: Store.week(containing: n), now: n)
            out.append("  DW sessions \(st.count) avg \(Fmt.hm(st.average)) longest \(Fmt.hm(st.longest)) best \(st.bestDay.map { $0.formatted(.dateTime.weekday()) } ?? "-")")
            out.append("  DW goal hits 12w: \(store.goalHistory(for: dw, count: 12, now: n).map { $0.hit ? "x" : "." }.joined())")
        }
        return out.joined(separator: "\n")
    }

    static func populate(_ store: Store) {
        store.insertDefaultTrackers()
        let ids = Dictionary(uniqueKeysWithValues: store.activities.map { ($0.name, $0.id) })
        let dw = ids["Deep Work"]!, mt = ids["Meetings"]!, ex = ids["Exercise"]!, em = ids["Email"]!, rd = ids["Reading"]!

        var rows: [(activityID: Int64, start: Date, end: Date?)] = []
        func add(_ id: Int64, _ k: Int, _ day: Int, _ h: Int, _ m: Int, minutes: Int) {
            guard minutes > 0 else { return }
            let start = at(week: k, day: day, h, m)
            rows.append((id, start, start.addingTimeInterval(TimeInterval(minutes * 60))))
        }

        // ---- Current week (Mon 19 – Fri 23 Oct).
        // Deep Work: M 4:12 · T 5:06 · W 3:48 · T 6:00 · F 3:43 (incl. running 0:50:01) = 22:49, 12 sessions, longest 3:45.
        add(dw, 0, 0, 9, 0, minutes: 150); add(dw, 0, 0, 13, 30, minutes: 102)
        add(dw, 0, 1, 9, 0, minutes: 120); add(dw, 0, 1, 13, 30, minutes: 96); add(dw, 0, 1, 16, 0, minutes: 90)
        add(dw, 0, 2, 9, 0, minutes: 138); add(dw, 0, 2, 13, 30, minutes: 90)
        add(dw, 0, 3, 9, 30, minutes: 135); add(dw, 0, 3, 14, 0, minutes: 225)
        add(dw, 0, 4, 9, 0, minutes: 105); add(dw, 0, 4, 13, 30, minutes: 68)
        rows.append((dw, date(2026, 10, 23, 20, 6, 0), nil))  // running → 00:50:01
        // Meetings 5:24
        for (d, m) in [60, 90, 60, 60].enumerated() { add(mt, 0, d, 12, 0, minutes: m) }
        add(mt, 0, 4, 11, 0, minutes: 54)
        // Exercise 3:45 (today 0:30 of 45m) · Email 2:59 (today 0:27 of 30m)
        for (d, m) in [45, 50, 50, 50, 30].enumerated() { add(ex, 0, d, 7, 0, minutes: m) }
        for (d, m) in [38, 36, 40, 38, 27].enumerated() { add(em, 0, d, 8, 15, minutes: m) }
        // Reading 1:30
        add(rd, 0, 0, 21, 30, minutes: 45); add(rd, 0, 2, 21, 30, minutes: 45)

        // ---- Last week (12 – 18 Oct): DW 19:30 · Meetings 6:10 · Exercise 3:00 · Email 2:50 · Reading 0:42 = 32:12
        for d in 0..<5 {
            add(dw, -1, d, 9, 0, minutes: 120); add(dw, -1, d, 13, 30, minutes: 114)
            add(mt, -1, d, 12, 0, minutes: 74)
        }
        for (d, m) in [30, 30, 30, 0, 0, 45, 45].enumerated() { add(ex, -1, d, 7, 0, minutes: m) }  // 6-day streak from Sat
        for (d, m) in [25, 25, 24, 24, 24, 24, 24].enumerated() { add(em, -1, d, 8, 15, minutes: m) }
        add(rd, -1, 5, 21, 30, minutes: 42)

        // ---- Weeks -11 … -2 (3 Aug – 11 Oct): weekly minutes, spread evenly.
        let older: [(k: Int, dw: Int, mt: Int, ex: Int, em: Int, rd: Int)] = [
            (-11, 1450, 360, 120, 80, 45), (-10, 1560, 420, 150, 90, 60), (-9, 1230, 490, 105, 75, 30),
            (-8, 1520, 390, 130, 100, 50), (-7, 1050, 300, 90, 60, 30), (-6, 1110, 340, 100, 70, 40),
            (-5, 1035, 310, 90, 60, 40), (-4, 1300, 330, 105, 65, 40), (-3, 1190, 320, 100, 67, 40),
            (-2, 1335, 315, 95, 70, 40),
        ]
        for w in older {
            for (d, m) in spread(w.dw, over: 5).enumerated() {
                add(dw, w.k, d, 9, 0, minutes: m / 2); add(dw, w.k, d, 13, 30, minutes: m - m / 2)
            }
            for (d, m) in spread(w.mt, over: 5).enumerated() { add(mt, w.k, d, 12, 0, minutes: m) }
            for (d, m) in spread(w.ex, over: 7).enumerated() { add(ex, w.k, d, 7, 0, minutes: m) }
            for (d, m) in spread(w.em, over: 7).enumerated() { add(em, w.k, d, 8, 15, minutes: m) }
            add(rd, w.k, 1, 21, 30, minutes: w.rd / 2); add(rd, w.k, 5, 21, 30, minutes: w.rd - w.rd / 2)
        }

        // ---- Reading earlier in 2026 so the year total is 96:10 (5770 min): 30 weeks from 5 Jan, Saturdays 15:00.
        let readingSoFar = rows.filter { $0.activityID == rd }
            .reduce(0) { $0 + Int(($1.end!.timeIntervalSince($1.start)) / 60) }
        for (i, m) in spread(5770 - readingSoFar, over: 30).enumerated() { add(rd, -41 + i, 5, 15, 0, minutes: m) }

        store.importSessions(rows)
    }

    /// Splits `total` minutes into `n` near-equal parts (remainder on the first days).
    private static func spread(_ total: Int, over n: Int) -> [Int] {
        (0..<n).map { total / n + ($0 < total % n ? 1 : 0) }
    }
}
