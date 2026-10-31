import Foundation
import UserNotifications

enum OverLimitNotice {
    static let identifier = "over-limit"
    static let soundName = "over-limit.wav"

    static func schedule(for state: ChoppedActivityAttributes.ContentState?) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        guard let state, let overDate = state.overDate, let goal = state.goalMinutes else { return }
        let wait = overDate.timeIntervalSinceNow
        guard wait > 1 else { return }
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "\(state.name) is over"
            content.body = "It's used the \(Fmt.goal(minutes: goal)) you gave it."
            content.sound = UNNotificationSound(named: UNNotificationSoundName(soundName))
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: wait, repeats: false)
            center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
        }
    }
}
