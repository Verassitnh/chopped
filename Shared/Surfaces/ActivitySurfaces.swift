import SwiftUI

typealias ClockInState = PocusActivityAttributes.ContentState

// MARK: - 06 Lock screen Live Activity (Paper B7A-0)

/// Tinted bezel (uniform 5pt, r26) around the bright accent block: Pixel 68 timer + 52pt stop.
/// No name, no strip. The bezel tint is also set as `activityBackgroundTint` by the widget.
struct LockActivityView: View {
    let state: ClockInState
    var now: Date = AppClock.now
    /// The activity's staleDate (start + 1h) passed → the timer has gained an hour field.
    var isStale = false

    var body: some View {
        let color = state.color
        TrackerBezel(color: color) {
            HStack(spacing: 12) {
                LiveTimerText(start: state.start, style: .hms, now: now, pastHour: isStale)
                    .geistPixel(68)
                    .foregroundStyle(CH.onAccent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                IntentButton(intent: StopTrackerIntent(), accessibility: "Stop \(state.name)") {
                    SurfaceStopGlyph(size: 52, accent: color.accent)
                }
            }
            .padding(EdgeInsets(top: 18, leading: 22, bottom: 18, trailing: 14))
        }
    }
}

// MARK: - 08 Dynamic Island (Paper BBE-0)

/// Compact leading + minimal: 22pt tile r7, 12pt accent glyph on accent@0.2.
struct IslandIconTile: View {
    let state: ClockInState

    var body: some View {
        IconTile(glyph: state.glyph, size: 22, radius: 7, glyphSize: 12,
                 foreground: state.color.accent, background: state.color.accent.opacity(0.2))
    }
}

/// Compact trailing: Geist Mono 15/19 600, -0.02em, accent ("50:01").
struct IslandCompactTimer: View {
    let state: ClockInState
    var now: Date = AppClock.now
    /// The activity's staleDate (start + 1h) passed → the timer has gained an hour field.
    var isStale = false

    /// Live timer text reserves a fixed width, so size it to "50:01" (5 cells) or "1:50:01" (7 cells):
    /// Geist Mono advance 0.6em − 0.02em tracking at 15pt = 8.7pt per cell.
    var width: CGFloat {
        (isStale || now.timeIntervalSince(state.start) >= 3600) ? 68 : 50
    }

    var body: some View {
        LiveTimerText(start: state.start, style: .compact, now: now, pastHour: isStale)
            .geistMono(15, .semibold, tracking: -0.02, lineHeight: 19)
            .foregroundStyle(state.color.accent)
            .multilineTextAlignment(.trailing)
            .lineLimit(1)
            .frame(width: AppClock.isFrozen ? nil : width, alignment: .trailing)
    }
}

/// Expanded, top row: 40pt bright tile (black glyph 20) · name 14/18 600 #AEAEB2 over white Pixel 44 timer.
struct IslandExpandedHeader: View {
    let state: ClockInState
    var now: Date = AppClock.now
    /// The activity's staleDate (start + 1h) passed → the timer has gained an hour field.
    var isStale = false

    var body: some View {
        HStack(spacing: 12) {
            IconTile(glyph: state.glyph, size: 40, radius: 12, glyphSize: 20,
                     foreground: CH.onAccent, background: state.color.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(state.name)
                    .geist(14, .semibold, lineHeight: 18)
                    .foregroundStyle(CH.textMuted)
                    .lineLimit(1)
                LiveTimerText(start: state.start, style: .hms, now: now, pastHour: isStale)
                    .geistPixel(44)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// Expanded stop: 52pt accent circle with a 16pt black square.
struct IslandStopButton: View {
    let state: ClockInState

    var body: some View {
        IntentButton(intent: StopTrackerIntent(), accessibility: "Stop \(state.name)") {
            SurfaceStopGlyph(size: 52, accent: .black, background: state.color.accent)
        }
    }
}

/// Expanded footer: 20 ticks (h5, unfilled #1C1C1E) + "SINCE 20:06" / "22:49 / 25:00" (mono 9/13 #6C6C70).
struct IslandExpandedFooter: View {
    let state: ClockInState
    var now: Date = AppClock.now

    var body: some View {
        VStack(spacing: 6) {
            SegmentStrip(count: 20, fraction: state.progress(at: now), accent: state.color.accent,
                         height: 5, unfilled: CH.raised, animated: false)
            HStack {
                Text("SINCE \(Fmt.time(state.start))")
                    .geistMono(9, .medium, tracking: 0.06, lineHeight: 13)
                Spacer(minLength: 8)
                if let goal = state.goalMinutes {
                    Text("\(Fmt.hm(state.periodTotal(at: now))) / \(Fmt.hm(TimeInterval(goal * 60)))")
                        .geistMono(9, .medium, tracking: 0.02, lineHeight: 13)
                        .numericMorph()
                }
            }
            .foregroundStyle(CH.textTertiary)
            .lineLimit(1)
        }
        .padding(.horizontal, 4)
    }
}

/// Whole expanded island as one view (QC host; the widget splits it into regions).
struct IslandExpandedView: View {
    let state: ClockInState
    var now: Date = AppClock.now

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                IslandExpandedHeader(state: state, now: now)
                IslandStopButton(state: state)
            }
            IslandExpandedFooter(state: state, now: now)
        }
        .padding(EdgeInsets(top: 18, leading: 18, bottom: 16, trailing: 18))
    }
}
