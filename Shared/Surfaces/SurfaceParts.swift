import AppIntents
import SwiftUI

// Building blocks shared by the Live Activity, Dynamic Island, widgets and their in-app QC hosts.

/// Running timer that counts live in WidgetKit / ActivityKit (system-updated, no timeline reloads)
/// and renders statically when `AppClock` is frozen (QC snapshots). Live output matches `Fmt`:
/// `.hms` "00:00:57" / "00:50:01" / "01:00:46"; `.compact` "00:15" / "50:01" / "1:00:46".
///
/// The system styles never zero-pad a missing hour field (`.timer` gives "0:15", `.stopwatch` gives
/// "00:15" but drops hours under 1h), so under an hour `.hms` prefixes a literal "00:" to the stopwatch,
/// and over an hour `.compact` switches from the stopwatch to the timer. The 1h switch needs one
/// re-render at the hour mark: the Live Activity's staleDate (start + 1h, pass `pastHour: context.isStale`)
/// and a widget timeline entry at the hour mark provide it.
struct LiveTimerText: View {
    enum Style {
        /// "00:50:01" (zero-padded hours) — lock screen, island expanded.
        case hms
        /// "50:01" / "1:50:01" — island compact, widgets.
        case compact
    }

    let start: Date
    var style: Style = .compact
    /// Reference time for the static (frozen) rendering and for picking the under/over-an-hour format.
    var now: Date = AppClock.now
    /// The Live Activity went stale at its 1h staleDate (re-rendered by the system at the hour mark).
    var pastHour = false

    private var overHour: Bool { pastHour || now.timeIntervalSince(start) >= 3600 }

    var body: some View {
        if AppClock.isFrozen {
            Text(style == .hms ? Fmt.hms(now.timeIntervalSince(start)) : Fmt.compact(now.timeIntervalSince(start)))
        } else if #available(iOS 18.0, *) {
            let stopwatch = SystemFormatStyle.Stopwatch(startingAt: start, showsHours: true, maxFieldCount: 3,
                                                        maxPrecision: .seconds(1))
            switch (style, overHour) {
            case (.hms, false):
                // "00:" + "00:57" → "00:00:57"
                Text("00:") + Text(.currentDate, format: stopwatch)
            case (.hms, true):
                // "01:00:46" (stopwatch pads hours)
                Text(.currentDate, format: stopwatch)
            case (.compact, false):
                // "00:15" / "50:01"
                Text(.currentDate, format: stopwatch)
            case (.compact, true):
                // "1:00:46"
                Text(.currentDate, format: .timer(countingUpIn: start..<Date.distantFuture,
                                                  showsHours: true, maxFieldCount: 3))
            }
        } else {
            Text(timerInterval: start...Date.distantFuture, countsDown: false)
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
