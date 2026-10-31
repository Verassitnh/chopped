import SwiftUI

/// A tracker colour: bright `accent` (inner block, "now" items) + dark `tint` (outer bezel).
struct TrackerColor: Identifiable, Hashable {
    let key: String
    let accentHex: String
    let tintHex: String

    var id: String { key }
    var accent: Color { Color(hex: accentHex) }
    var tint: Color { Color(hex: tintHex) }
    /// Unfilled segment tick / faint accent wash (accent @ 0.2, i.e. `#RRGGBB33`).
    var faint: Color { accent.opacity(0.2) }

    // Named palette (accent / tint from SPEC). Tints for green/yellow are derived (not in the designs).
    static let blue = TrackerColor(key: "blue", accentHex: "#4A8BE5", tintHex: "#172335")     // Deep Work
    static let orange = TrackerColor(key: "orange", accentHex: "#F7A23A", tintHex: "#362716") // Meetings
    static let teal = TrackerColor(key: "teal", accentHex: "#1DB3A6", tintHex: "#0F2A29")     // Exercise
    static let purple = TrackerColor(key: "purple", accentHex: "#9D68F0", tintHex: "#261D37") // Email
    static let red = TrackerColor(key: "red", accentHex: "#EF6B6B", tintHex: "#351D1F")       // Reading
    static let pink = TrackerColor(key: "pink", accentHex: "#F07EB8", tintHex: "#3A1C2C")     // new-tracker demo
    static let green = TrackerColor(key: "green", accentHex: "#7CCB8E", tintHex: TrackerColor.derivedTint("#7CCB8E"))
    static let yellow = TrackerColor(key: "yellow", accentHex: "#E9C95A", tintHex: TrackerColor.derivedTint("#E9C95A"))

    /// Colour-picker order from the New Tracker sheet (N2).
    static let picker: [TrackerColor] = [.blue, .teal, .green, .yellow, .orange, .red, .pink, .purple]

    /// Palette entry for a stored accent hex. Unknown hexes get a derived tint.
    static func forHex(_ hex: String) -> TrackerColor {
        let norm = normalize(hex)
        if let match = picker.first(where: { $0.accentHex == norm }) { return match }
        return TrackerColor(key: norm, accentHex: norm, tintHex: derivedTint(norm))
    }

    static func normalize(_ hex: String) -> String {
        "#" + hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")).uppercased()
    }

    /// Approximates the design tints: ~19% accent over #0C0C0E.
    static func derivedTint(_ hex: String) -> String {
        let v = UInt64(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0
        func mix(_ c: UInt64) -> Int { Int((Double(c) * 0.19 + 12 * 0.81).rounded()) }
        return String(format: "#%02X%02X%02X", mix((v >> 16) & 0xFF), mix((v >> 8) & 0xFF), mix(v & 0xFF))
    }
}

/// Goal period for a tracker.
enum GoalPeriod: String, CaseIterable, Identifiable, Codable {
    case day, week, month, year

    var id: String { rawValue }

    /// "Daily" / "Weekly" / "Monthly" / "Yearly" (card meta lines).
    var adjective: String {
        switch self {
        case .day: "Daily"
        case .week: "Weekly"
        case .month: "Monthly"
        case .year: "Yearly"
        }
    }

    var current: String { self == .day ? "today" : "this \(rawValue)" }

    func goalLine(minutes: Int) -> String {
        minutes > 0 ? "\(adjective) · \(Fmt.goal(minutes: minutes)) goal" : "\(adjective) · No goal"
    }

    /// "DAY" / "WEEK" … (Track-per segmented control).
    var segmentLabel: String { rawValue.uppercased() }

    /// "Day" / "Week" … (detail settings row value).
    var title: String { rawValue.capitalized }

    var calendarComponent: Calendar.Component {
        switch self {
        case .day: .day
        case .week: .weekOfYear
        case .month: .month
        case .year: .year
        }
    }
}
