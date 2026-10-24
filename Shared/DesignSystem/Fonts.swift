import SwiftUI
import UIKit

/// Bundled fonts (registered via UIAppFonts in Pocus-Info.plist and PocusWidgets-Info.plist).
/// Sizes are fixed points (no Dynamic Type scaling) so layouts match the Paper artboards.
enum GeistWeight {
    case regular, medium, semibold, bold

    /// CSS 650 in the designs maps to `.semibold` (static fonts only).
    var sans: String {
        switch self {
        case .regular: "Geist-Regular"
        case .medium: "Geist-Medium"
        case .semibold: "Geist-SemiBold"
        case .bold: "Geist-Bold"
        }
    }

    var mono: String {
        switch self {
        case .regular: "GeistMono-Regular"
        case .medium: "GeistMono-Medium"
        case .semibold: "GeistMono-SemiBold"
        case .bold: "GeistMono-Bold"
        }
    }
}

enum GeistFont {
    /// Geist Pixel, Square variant (ELSH = 0). Only for the big running timer + hero totals.
    static let pixel = "GeistPixel-Square"

    static let allPostScriptNames: [String] = [
        "Geist-Regular", "Geist-Medium", "Geist-SemiBold", "Geist-Bold",
        "GeistMono-Regular", "GeistMono-Medium", "GeistMono-SemiBold", "GeistMono-Bold",
        pixel,
    ]

    /// PostScript names that failed to load (empty when everything is registered).
    static var missing: [String] { allPostScriptNames.filter { UIFont(name: $0, size: 12) == nil } }
}

extension Font {
    static func geist(_ size: CGFloat, _ weight: GeistWeight = .regular) -> Font {
        .custom(weight.sans, fixedSize: size)
    }

    static func geistMono(_ size: CGFloat, _ weight: GeistWeight = .medium) -> Font {
        .custom(weight.mono, fixedSize: size)
    }

    static func geistPixel(_ size: CGFloat) -> Font {
        .custom(GeistFont.pixel, fixedSize: size)
    }
}

/// Applies a Paper text style: font + letter-spacing (em) + CSS-style line height.
/// The line-height box is emulated by splitting the extra leading above/below
/// (single line) and as `lineSpacing` (multi-line), like CSS.
struct TypeStyle: ViewModifier {
    let postScriptName: String
    let size: CGFloat
    /// Letter-spacing in **em** (Paper/CSS value). Points = em × size.
    let tracking: CGFloat
    /// CSS line-height in points; nil = font's natural line height.
    let lineHeight: CGFloat?

    func body(content: Content) -> some View {
        let natural = UIFont(name: postScriptName, size: size)?.lineHeight ?? size * 1.2
        let diff = (lineHeight ?? natural) - natural
        content
            .font(.custom(postScriptName, fixedSize: size))
            .tracking(tracking * size)
            .lineSpacing(max(0, diff))
            // Negative when the CSS line-height is tighter than the font (e.g. pixel 62/62) — shrinks the box like CSS.
            .padding(.vertical, diff / 2)
    }
}

extension View {
    /// `.geist(17, .semibold, tracking: -0.01, lineHeight: 22)`
    func geist(_ size: CGFloat, _ weight: GeistWeight = .regular, tracking: CGFloat = 0, lineHeight: CGFloat? = nil) -> some View {
        modifier(TypeStyle(postScriptName: weight.sans, size: size, tracking: tracking, lineHeight: lineHeight))
    }

    /// `.geistMono(26, .medium, tracking: -0.05, lineHeight: 30)`. Default weight is medium (most numbers in the designs are 500).
    func geistMono(_ size: CGFloat, _ weight: GeistWeight = .medium, tracking: CGFloat = 0, lineHeight: CGFloat? = nil) -> some View {
        modifier(TypeStyle(postScriptName: weight.mono, size: size, tracking: tracking, lineHeight: lineHeight))
    }

    /// `.geistPixel(62)` — line height defaults to the font size (as in Paper: 62/62, 112/112).
    func geistPixel(_ size: CGFloat, tracking: CGFloat = 0, lineHeight: CGFloat? = nil) -> some View {
        modifier(TypeStyle(postScriptName: GeistFont.pixel, size: size, tracking: tracking, lineHeight: lineHeight ?? size))
    }
}
