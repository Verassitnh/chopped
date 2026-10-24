import ActivityKit
import SwiftUI

/// Live Activity for the running clock-in. Everything lives in ContentState so switching
/// activities updates the existing Live Activity instead of starting a new one.
struct PocusActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var name: String
        var colorHex: String
        var start: Date
    }
}

extension Color {
    init(hex: String) {
        let value = UInt64(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0
        self.init(red: Double((value >> 16) & 0xFF) / 255,
                  green: Double((value >> 8) & 0xFF) / 255,
                  blue: Double(value & 0xFF) / 255)
    }
}
