import AppIntents
import SwiftUI

// Building blocks shared by the Live Activity, Dynamic Island, widgets and their in-app QC hosts.

/// Running timer in the system's own count-up format ("0:01", "50:01", "1:00:46"), live in WidgetKit /
/// ActivityKit without timeline reloads. Renders the same string statically when `AppClock` is frozen.
struct LiveTimerText: View {
    let start: Date
    var now: Date = AppClock.now

    var body: some View {
        Group {
            if AppClock.isFrozen {
                Text(Fmt.timer(now.timeIntervalSince(start)))
            } else {
                Text(timerInterval: start...Date.distantFuture, countsDown: false)
            }
        }
        .monospacedDigit()
    }
}

/// Black circle + accent rounded square. Widget sizes use r3 (36 → 11, 34 → 10); 52 uses r4.
struct SurfaceStopGlyph: View {
    var size: CGFloat
    var accent: Color
    var background: Color = .black
    var squareRadius: CGFloat? = nil

    var body: some View {
        let s = (size * 0.3).rounded()
        Circle().fill(background)
            .frame(width: size, height: size)
            .overlay {
                RoundedRectangle(cornerRadius: squareRadius ?? (size >= 44 ? 4 : 3), style: .continuous)
                    .fill(accent).frame(width: s, height: s)
            }
            .contentShape(Circle())
    }
}

struct SurfaceSwapGlyph: View {
    var size: CGFloat
    var foreground: Color
    var background: Color = .black

    var body: some View {
        Circle().fill(background)
            .frame(width: size, height: size)
            .overlay { GlyphView(.swap, size: (size * 0.42).rounded(), color: foreground) }
            .contentShape(Circle())
    }
}

struct SwitchLink<Label: View>: View {
    @ViewBuilder var label: Label

    var body: some View {
        Link(destination: ChoppedLink.switcher) { label }
            .accessibilityLabel("Switch tracker")
    }
}

enum ChoppedLink {
    static let switcher = URL(string: "chopped://switch")!
}

/// Wraps content in an intent button (plain style) — works in widgets, live activities and the app.
struct IntentButton<I: AppIntent, Label: View>: View {
    let intent: I
    var accessibility: String
    @ViewBuilder var label: Label

    var body: some View {
        Button(intent: intent) { label }
            .buttonStyle(.plain)
            .accessibilityLabel(accessibility)
    }
}

extension View {
    /// Subtle numeric morph between timeline entries / updates.
    func numericMorph() -> some View { contentTransition(.numericText()) }
}
