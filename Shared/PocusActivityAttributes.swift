import ActivityKit
import SwiftUI

/// Live Activity for the running clock-in. Everything lives in ContentState so switching
/// activities updates the existing Live Activity instead of starting a new one.
struct PocusActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var name: String
        var colorHex: String
        var start: Date
        // Added for the Chopped redesign. Optional so older encoded states still decode.
        var icon: String? = nil
        /// Seconds already logged in the current goal period, *excluding* the running session.
        var periodBase: TimeInterval? = nil
        var goalMinutes: Int? = nil
        var period: String? = nil
    }
}
