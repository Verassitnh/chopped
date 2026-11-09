import Foundation
import UserNotifications

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
             showsTitle: AppGroup.liveActivityTitles)
    }
}

enum BreakNotice {
    static let identifier = "break-over"

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    static func schedule(end: Date?, returningTo trackerName: String?) {
        cancel()
        guard let end else { return }
        let wait = end.timeIntervalSinceNow
        guard wait > 1 else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Break's over"
            content.body = trackerName.map { "Switch back to \($0) when you're ready." } ?? "Switch back when you're ready."
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: wait, repeats: false)
            UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
        }
    }
}
