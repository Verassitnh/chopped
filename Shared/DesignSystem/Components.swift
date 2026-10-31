import SwiftUI

// MARK: - Motion

enum Motion {
    /// Start/stop card transitions.
    static let spring = Animation.spring(response: 0.35, dampingFraction: 0.85)
    /// Bars growing in on first appear.
    static let grow = Animation.easeOut(duration: 0.45)
}

/// Press feedback used by every tappable control: scale 0.96 (0.98 for large cards) on press-down,
/// released on lift with a quick spring. No scale under Reduce Motion.
struct PressScaleStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? scale : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressScaleStyle {
    static var pressScale: PressScaleStyle { PressScaleStyle() }
}

/// Wraps `label` in a Button with `.pressScale` when `action` is non-nil (widgets pass nil and wrap in an intent Button).
private struct OptionalButton<Label: View>: View {
    let action: (() -> Void)?
    @ViewBuilder let label: Label

    var body: some View {
        if let action {
            Button(action: action) { label }.buttonStyle(.pressScale)
        } else {
            label
        }
    }
}

// MARK: - IconTile

/// Rounded square holding a tracker glyph. Defaults = idle card (36pt, r11, glyph 18, black on black@13%).
/// Sizes seen in the designs: card 36/11/18 · running card 30/9/16 · live activity 24/7/13 ·
/// widgets 26/8/14 · DI compact 22/7/12 (accent glyph on accent@0.2) · DI expanded 40/12/20.
struct IconTile: View {
    let glyph: Glyph
    var size: CGFloat = 36
    var radius: CGFloat = 11
    var glyphSize: CGFloat = 18
    var foreground: Color = CH.onAccent
    var background: Color = CH.iconTileFill

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(background)
            .frame(width: size, height: size)
            .overlay { GlyphView(glyph, size: glyphSize, color: foreground) }
    }
}

// MARK: - Play / Stop

/// Black circle with a white play triangle. Default 40pt (cards). Widgets: 34 / 26.
struct PlayButton: View {
    var size: CGFloat = 40
    var background: Color = .black
    var foreground: Color = .white
    var action: (() -> Void)? = nil

    var body: some View {
        OptionalButton(action: action) {
            Circle()
                .fill(background)
                .frame(width: size, height: size)
                .overlay {
                    // Triangle box is round(s*.32) wide, nudged right 1.2pt @40 so its centroid sits on the circle's centre.
                    GlyphView(.play, size: (size * 0.32).rounded(), color: foreground)
                        .offset(x: size * 0.03)
                }
                .contentShape(Circle())
                .accessibilityLabel("Start")
        }
    }
}

/// Black circle with an accent rounded square (size × 0.3, r4). Default 52pt (running card / live activity).
/// DI expanded uses inverted colours: `StopButton(size: 52, accent: .black, background: accent)`.
struct StopButton: View {
    var size: CGFloat = 52
    var accent: Color
    var background: Color = .black
    var action: (() -> Void)? = nil

    var body: some View {
        OptionalButton(action: action) {
            Circle()
                .fill(background)
                .frame(width: size, height: size)
                .overlay {
                    let s = (size * 0.3).rounded()
                    RoundedRectangle(cornerRadius: 4, style: .continuous).fill(accent).frame(width: s, height: s)
                }
                .contentShape(Circle())
                .accessibilityLabel("Stop")
        }
    }
}

// MARK: - SegmentStrip

/// Row of `count` equal ticks; the first round(fraction × count) are filled with `accent`.
/// Home card: 20 ticks, h6, gap 3, r2, unfilled accent@0.2. Widgets: 12 ticks, h5. DI expanded: unfilled #1C1C1E.
struct SegmentStrip: View {
    var count: Int = 20
    var fraction: Double
    var accent: Color
    var height: CGFloat = 6
    var gap: CGFloat = 3
    var radius: CGFloat = 2
    /// nil = accent @ 0.2.
    var unfilled: Color? = nil
    /// Stagger ticks when `fraction` changes (off under Reduce Motion).
    var animated: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var filled: Int { max(0, min(count, Int((fraction * Double(count)).rounded()))) }

    var body: some View {
        HStack(spacing: gap) {
            ForEach(0..<count, id: \.self) { i in
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(i < filled ? accent : (unfilled ?? accent.opacity(0.2)))
                    .frame(height: height)
                    .frame(maxWidth: .infinity)
                    .animation(animated && !reduceMotion ? .easeOut(duration: 0.18).delay(Double(i) * 0.012) : nil,
                               value: filled)
            }
        }
        .accessibilityElement()
        .accessibilityValue("\(Int((fraction * 100).rounded())) percent")
    }
}

// MARK: - TrackerBezel

/// C3.2 tracker card shell: tinted outer bezel (r26, padding 5/5/12, gap 10) around a bright
/// accent inner block (r21) with an optional footer (the segment strip, inset 19 leading / 17 trailing).
/// The caller supplies the inner block's own padding (idle 12/12/12/14, running 14/14/14/16).
///
///     TrackerBezel(color: .blue) { innerContent.padding(...) } footer: { SegmentStrip(...) }
///     TrackerBezel(color: .blue, padding: EdgeInsets(5)) { ... }   // lock screen: uniform 5pt, no footer
struct TrackerBezel<Inner: View, Footer: View>: View {
    var tint: Color
    var accent: Color
    var padding = EdgeInsets(top: 5, leading: 5, bottom: 12, trailing: 5)
    var spacing: CGFloat = 10
    var outerRadius: CGFloat = 26
    var innerRadius: CGFloat = 21
    var footerInsets = EdgeInsets(top: 0, leading: 19, bottom: 0, trailing: 17)
    @ViewBuilder var inner: Inner
    @ViewBuilder var footer: Footer

    var body: some View {
        VStack(spacing: spacing) {
            inner
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(accent, in: RoundedRectangle(cornerRadius: innerRadius, style: .continuous))
            footer.padding(footerInsets)
        }
        .padding(padding)
        .background(tint, in: RoundedRectangle(cornerRadius: outerRadius, style: .continuous))
    }
}

extension TrackerBezel {
    init(color: TrackerColor,
         padding: EdgeInsets = EdgeInsets(top: 5, leading: 5, bottom: 12, trailing: 5),
         spacing: CGFloat = 10,
         @ViewBuilder inner: () -> Inner,
         @ViewBuilder footer: () -> Footer) {
        self.init(tint: color.tint, accent: color.accent, padding: padding, spacing: spacing, inner: inner, footer: footer)
    }
}

extension TrackerBezel where Footer == EmptyView {
    /// No footer (lock-screen live activity, new-tracker preview without strip). Default padding is a uniform 5pt.
    init(color: TrackerColor, padding: EdgeInsets = EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5),
         @ViewBuilder inner: () -> Inner) {
        self.init(tint: color.tint, accent: color.accent, padding: padding, spacing: 0, inner: inner, footer: { EmptyView() })
    }
}

extension EdgeInsets {
    init(_ all: CGFloat) { self.init(top: all, leading: all, bottom: all, trailing: all) }
}

// MARK: - SectionLabel

/// Section header row: Geist Mono 11/14 500, uppercase, tracking 0.08em, #6C6C70; optional right
/// value Geist Mono 12/16 500, tracking -0.01em, #AEAEB2. Row is space-between with gap 12.
struct SectionLabel<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            SectionLabelText(title)
            Spacer(minLength: 0)
            trailing
        }
    }
}

extension SectionLabel where Trailing == SectionValueText? {
    init(_ title: String, value: String? = nil) {
        self.title = title
        self.trailing = value.map { SectionValueText($0) }
    }
}

/// Just the label text style (mono 11 caps 0.08em #6C6C70).
struct SectionLabelText: View {
    let text: String
    var color: Color = CH.textTertiary
    init(_ text: String, color: Color = CH.textTertiary) { self.text = text; self.color = color }

    var body: some View {
        Text(text.uppercased())
            .geistMono(11, .medium, tracking: 0.08, lineHeight: 14)
            .foregroundStyle(color)
            .lineLimit(1)
    }
}

/// Section right-hand value style (mono 12/16 500 -0.01em #AEAEB2).
struct SectionValueText: View {
    let text: String
    var color: Color = CH.textMuted
    init(_ text: String, color: Color = CH.textMuted) { self.text = text; self.color = color }

    var body: some View {
        Text(text)
            .geistMono(12, .medium, tracking: -0.01, lineHeight: 16)
            .foregroundStyle(color)
            .lineLimit(1)
    }
}

// MARK: - Circle buttons

/// 44pt glass circle (home "+" header button): white@9% fill, 1pt white@14% border, inset top highlight.
struct GlassCircleButton: View {
    var glyph: Glyph = .plus
    var size: CGFloat = 44
    var glyphSize: CGFloat = 16
    var action: (() -> Void)? = nil

    var body: some View {
        OptionalButton(action: action) {
            GlassSurface(shape: Circle())
                .frame(width: size, height: size)
                .overlay { GlyphView(glyph, size: glyphSize, color: .white) }
                .contentShape(Circle())
        }
    }
}

/// Solid circle with a glyph (sheet X / ✓, stepper −/+, back chevron). Default 44pt on #1C1C1E.
struct CircleIconButton: View {
    let glyph: Glyph
    var size: CGFloat = 44
    var glyphSize: CGFloat = 13
    var background: Color = CH.raised
    var foreground: Color = .white
    var action: (() -> Void)? = nil

    var body: some View {
        OptionalButton(action: action) {
            Circle().fill(background)
                .frame(width: size, height: size)
                .overlay { GlyphView(glyph, size: glyphSize, color: foreground) }
                .contentShape(Circle())
        }
    }
}
