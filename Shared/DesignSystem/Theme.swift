import SwiftUI

extension Color {
    /// `Color(hex: "#4A8BE5")` or `"4A8BE5"`. 8-digit hex is RRGGBBAA (CSS order).
    init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let value = UInt64(s, radix: 16) ?? 0
        if s.count == 8 {
            self.init(.sRGB,
                      red: Double((value >> 24) & 0xFF) / 255,
                      green: Double((value >> 16) & 0xFF) / 255,
                      blue: Double((value >> 8) & 0xFF) / 255,
                      opacity: Double(value & 0xFF) / 255)
        } else {
            self.init(.sRGB,
                      red: Double((value >> 16) & 0xFF) / 255,
                      green: Double((value >> 8) & 0xFF) / 255,
                      blue: Double(value & 0xFF) / 255)
        }
    }
}

/// Chopped design tokens (values from design/SPEC.md + Paper file).
enum CH {
    // Surfaces
    static let bg = Color(hex: "#0C0C0E")        // app background
    static let sheet = Color(hex: "#141416")     // sheets
    static let raised = Color(hex: "#1C1C1E")    // raised rows / chips / circle buttons

    // Text
    static let text = Color(hex: "#F2F2F7")      // primary
    static let textSecondary = Color(hex: "#8E8E93")
    static let textTertiary = Color(hex: "#6C6C70") // section labels
    static let textMuted = Color(hex: "#AEAEB2")    // section-label values, subtitles

    // "Past" grays (accent restraint: only "now" gets accent)
    static let past = Color(hex: "#26262A")      // past bars/cells
    static let pastLight = Color(hex: "#48484C")
    static let pastMid = Color(hex: "#3A3A3E")

    // Semantic
    static let up = Color(hex: "#39D353")        // up / positive delta / heatmap green
    static let destructive = Color(hex: "#EF6B6B")

    // On-accent (black content inside bright blocks)
    static let onAccent = Color.black
    static let onAccentSecondary = Color.black.opacity(0.62)   // #0000009E meta text
    static let iconTileFill = Color.black.opacity(0.13)        // #00000021

    // Glass (header + button, tab bar)
    static let glassFill = Color.white.opacity(0.09)           // #FFFFFF17
    static let glassStroke = Color.white.opacity(0.14)         // #FFFFFF24
    static let glassHighlight = Color.white.opacity(0.18)      // inset top highlight #FFFFFF2E
}
