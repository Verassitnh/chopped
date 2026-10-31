import AVFoundation
import UserNotifications

@MainActor
final class OverLimitAlerts: NSObject, UNUserNotificationCenterDelegate {
    static let shared = OverLimitAlerts()

    private var player: AVAudioPlayer?
    private var lastPlayed: Date?

    func install() {
        UNUserNotificationCenter.current().delegate = self
    }

    func playSound() {
        if let lastPlayed, Date().timeIntervalSince(lastPlayed) < 5 { return }
        lastPlayed = Date()
        guard let url = Bundle.main.url(forResource: "over-limit", withExtension: "wav") else { return }
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        player = try? AVAudioPlayer(contentsOf: url)
        player?.play()
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        guard notification.request.identifier == OverLimitNotice.identifier else { return [.banner, .sound] }
        await MainActor.run { playSound() }
        return []
    }
}
