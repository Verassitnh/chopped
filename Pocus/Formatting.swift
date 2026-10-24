import SwiftUI

extension TimeInterval {
    /// "4:07" — hours and minutes, for big totals.
    var hoursMinutes: String {
        let minutes = Int(self) / 60
        return String(format: "%d:%02d", minutes / 60, minutes % 60)
    }

    /// "1:04:09" — for a running session.
    var clock: String {
        let seconds = Int(self)
        return String(format: "%d:%02d:%02d", seconds / 3600, seconds / 60 % 60, seconds % 60)
    }

    /// "4h 7m" — for stats rows.
    var short: String {
        let minutes = Int(self) / 60
        if minutes < 60 { return "\(minutes)m" }
        return minutes % 60 == 0 ? "\(minutes / 60)h" : "\(minutes / 60)h \(minutes % 60)m"
    }
}

extension Color {
    static let palette = [
        "#3A7BD5", "#56CCF2", "#11998E", "#6FCF97", "#F2C94C",
        "#F7971E", "#EB5757", "#FF6FB5", "#8E54E9", "#828282",
    ]
}

extension DateInterval {
    /// "Oct 19 – Oct 25"
    var range: String {
        start.formatted(.dateTime.month(.abbreviated).day()) + " – "
            + end.addingTimeInterval(-1).formatted(.dateTime.month(.abbreviated).day())
    }

    /// "This week" for the current week, otherwise the range.
    func title(now: Date) -> String { contains(now) ? "This week" : range }
}
