import Foundation
import UserNotifications

enum BreakSettings {
    static let minutesKey = "breakMinutes"
    static let autoResumeKey = "breakAutoResume"
    static let defaultMinutes = 15
    static let choices = [5, 10, 15, 20, 25, 30, 45, 60]

    static var minutes: Int {
        let stored = UserDefaults.standard.integer(forKey: minutesKey)
        return stored > 0 ? stored : defaultMinutes
    }

    static var autoResume: Bool {
        UserDefaults.standard.object(forKey: autoResumeKey) as? Bool ?? true
    }
}

enum BreakNotice {
    static let identifier = "break-over"

    static func schedule(end: Date?, tracker: Activity?, resumes: Bool) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        guard let end, let tracker else { return }
        let wait = end.timeIntervalSinceNow
        guard wait > 1 else { return }
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Break's over"
            content.body = resumes ? "\(tracker.name) is running again." : "Back to \(tracker.name)?"
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: wait, repeats: false)
            center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
        }
    }
}
