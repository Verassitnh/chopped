import Foundation

/// The Home header line under the date: one per local calendar day, picked from `all`.
enum Tagline {
    /// Exact copy, lowercase. The first is the design's (and the fixed QC/demo) line.
    static let all = [
        "lock in twin",
        "don't be chopped",
        "be better",
        "generational lock in",
        "best in your bloodline",
        "goated chad",
        "stop chud maxxing",
        "get cracked",
        "no more skill issues",
        "be better dog",
        "keep crackin big dog",
        "shut up and lock in",
        "absolute chud",
        "don't be a whale",
        "be better king",
    ]

    /// Today's line: stable through the day and across launches, changes at local midnight.
    /// Fixed to "lock in twin" when the clock is frozen (-QCDemo) so design comparisons stay exact.
    static func forDay(_ date: Date, calendar: Calendar = .current) -> String {
        if AppClock.isFrozen { return all[0] }
        var index = seed(date, calendar) % all.count
        // Don't repeat yesterday's pick (by its unadjusted seed; good enough and stays stateless).
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: date),
           seed(yesterday, calendar) % all.count == index {
            index = (index + 1) % all.count
        }
        return all[index]
    }

    /// FNV-1a over the local "yyyy-MM-dd" (stable across processes, unlike `hashValue`).
    private static func seed(_ date: Date, _ calendar: Calendar) -> Int {
        let d = calendar.dateComponents([.year, .month, .day], from: date)
        let key = String(format: "%04d-%02d-%02d", d.year ?? 0, d.month ?? 0, d.day ?? 0)
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in key.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01b3
        }
        return Int(hash % UInt64(Int32.max))
    }
}
