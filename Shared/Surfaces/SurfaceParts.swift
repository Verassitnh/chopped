import AppIntents
import SwiftUI

// Building blocks shared by the Live Activity, Dynamic Island, widgets and their in-app QC hosts.

/// Running timer that counts live in WidgetKit / ActivityKit (`Text(timerInterval:)` / timer format style)
/// and renders statically when `AppClock` is frozen (QC snapshots).
struct LiveTimerText: View {
    enum Style {
        /// "00:50:01" (zero-padded hours) — lock screen, island expanded.
        case hms
        /// "50:01" / "1:50:01" — island compact, widgets.
        case compact
    }

    let start: Date
    var style: Style = .compact
    /// Reference time for the static (frozen) rendering.
    var now: Date = AppClock.now

    var body: some View {
        if AppClock.isFrozen {
            Text(style == .hms ? Fmt.hms(now.timeIntervalSince(start)) : Fmt.compact(now.timeIntervalSince(start)))
        } else {
            switch style {
            case .compact:
                Text(timerInterval: start...Date.distantFuture, countsDown: false)
            case .hms:
                if #available(iOS 18.0, *) {
                    // The system style has no zero-padded hours ("0:50:01"), so prefix the leading "0" while < 10h.
                    let elapsed = now.timeIntervalSince(start)
                    Text(elapsed < 36_000 ? "0" : "")
                        + Text(.currentDate, format: .timer(countingUpIn: start..<Date.distantFuture,
                                                            showsHours: true, maxFieldCount: 3))
                } else {
                    Text(timerInterval: start...Date.distantFuture, countsDown: false)
                }
            }
        }
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
