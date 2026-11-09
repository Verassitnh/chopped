import Foundation

enum BreakSettings {
    static let minutesKey = "breakMinutes"
    static let defaultMinutes = 5
    static let choices = [5, 10, 15, 20, 25, 30, 45, 60]

    static var defaults: UserDefaults { AppGroup.defaults ?? .standard }

    static var minutes: Int {
        let stored = defaults.integer(forKey: minutesKey)
        if stored > 0 { return stored }
        let legacy = UserDefaults.standard.integer(forKey: minutesKey)
        return legacy > 0 ? legacy : defaultMinutes
    }

    static func end(startingAt start: Date) -> Date {
        start.addingTimeInterval(TimeInterval(minutes * 60))
    }
}

extension ChoppedActivityAttributes.ContentState {
    static func onBreak(since start: Date) -> Self {
        Self(name: "Break", colorHex: TrackerColor.breakGreen.accentHex, start: start, icon: Glyph.cup.rawValue,
             goalMinutes: BreakSettings.minutes, showsTitle: AppGroup.liveActivityTitles, countsDown: true)
    }
}
