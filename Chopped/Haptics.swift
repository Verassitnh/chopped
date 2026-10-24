import UIKit

/// Quick taptic pulses for clocking in and out.
@MainActor
enum Haptics {
    private static let start = UIImpactFeedbackGenerator(style: .rigid)
    private static let stop = UIImpactFeedbackGenerator(style: .heavy)

    static func prepare() {
        start.prepare()
        stop.prepare()
    }

    static func clockedIn() {
        start.impactOccurred(intensity: 1)
        start.prepare()
    }

    static func clockedOut() {
        stop.impactOccurred(intensity: 1)
        stop.prepare()
    }
}
