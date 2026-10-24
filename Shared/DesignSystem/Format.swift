import Foundation

/// Number formats used across the designs. All take seconds (TimeInterval) and floor to the unit shown.
enum Fmt {
    /// "5:24", "96:10", "0:30", "22:49" — hours:minutes (card totals, table values, goals "25:00").
    static func hm(_ t: TimeInterval) -> String {
        let m = Int(max(0, t)) / 60
        return String(format: "%d:%02d", m / 60, m % 60)
    }

    /// "00:50:01" — zero-padded running timer (Pixel).
    static func hms(_ t: TimeInterval) -> String {
        let s = Int(max(0, t))
        return String(format: "%02d:%02d:%02d", s / 3600, s / 60 % 60, s % 60)
    }

    /// "50:01" under an hour, "1:50:01" over — Dynamic Island compact / widgets.
    static func compact(_ t: TimeInterval) -> String {
        let s = Int(max(0, t))
        return s < 3600 ? String(format: "%02d:%02d", s / 60, s % 60)
                        : String(format: "%d:%02d:%02d", s / 3600, s / 60 % 60, s % 60)
    }

    /// "+3:19" / "-0:46" / "+0:00" — deltas.
    static func signedHM(_ t: TimeInterval) -> String {
        (t < 0 ? "-" : "+") + hm(abs(t))
    }

    /// "2h 11m", "45m", "3h" — prose durations ("2h 11m left").
    static func words(_ t: TimeInterval) -> String {
        let m = Int(max(0, t)) / 60
        if m < 60 { return "\(m)m" }
        return m % 60 == 0 ? "\(m / 60)h" : "\(m / 60)h \(m % 60)m"
    }

    /// Goal in minutes → "25h", "45m", "1h 30m".
    static func goal(minutes: Int) -> String { words(TimeInterval(minutes * 60)) }

    /// 0.913 → "91%".
    static func percent(_ f: Double) -> String { "\(Int((f * 100).rounded()))%" }

    /// "+13%" / "−20%" relative change (true minus sign, like the time deltas); nil when `base` is 0.
    static func signedPercent(_ value: Double, vs base: Double) -> String? {
        guard base > 0 else { return nil }
        let p = Int(((value - base) / base * 100).rounded())
        return (p < 0 ? "\u{2212}" : "+") + "\(abs(p))%"
    }

    /// "20:06" — 24h clock time.
    static func time(_ d: Date, calendar: Calendar = .chopped) -> String {
        let c = calendar.dateComponents([.hour, .minute], from: d)
        return String(format: "%02d:%02d", c.hour ?? 0, c.minute ?? 0)
    }
}

extension Calendar {
    /// The app's calendar: user's calendar/time zone, weeks start Monday ("resets Mon").
    static var chopped: Calendar {
        var c = Calendar.current
        c.firstWeekday = 2
        c.minimumDaysInFirstWeek = 4
        return c
    }
}
