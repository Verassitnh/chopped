import SwiftUI

typealias ClockInState = ChoppedActivityAttributes.ContentState

// MARK: - 06 Lock screen Live Activity (Paper B7A-0)

/// Tinted bezel (uniform 5pt, r26) around the bright accent block: Pixel 68 timer + 52pt swap button
/// that opens the app's Switch sheet.
/// No name, no strip. The bezel tint is also set as `activityBackgroundTint` by the widget.
struct LockActivityView: View {
    let state: ClockInState
    var now: Date = AppClock.now
    /// The activity's staleDate (start + 1h) passed → the timer has gained an hour field.
    var isStale = false

    var body: some View {
        let color = state.color
        let over = state.isOver(at: now)
        TrackerBezel(tint: over ? Drained.bezel : color.tint, accent: .clear,
                     padding: EdgeInsets(5), spacing: 0) {
            ZStack {
                if over {
                    row(drained: true, over: over)
                        .background(Drained.inner)
                        .transition(.opacity)
                } else {
                    row(drained: false, over: over)
                        .background(color.accent)
                        .transition(.opacity)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
            .animation(.easeInOut(duration: 0.8), value: over)
        } footer: {
            EmptyView()
        }
    }

    private func row(drained: Bool, over: Bool) -> some View {
        HStack(spacing: 12) {
            LiveTimerText(start: state.start, style: over ? .selfUpdating : .hms, now: now,
                          pastHour: isStale && !over)
                .geistPixel(68)
                .foregroundStyle(drained ? Drained.text : CH.onAccent)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, alignment: .leading)
            SwitchLink {
                SurfaceSwapGlyph(size: 52, foreground: state.color.accent)
            }
        }
        .padding(EdgeInsets(top: 18, leading: 22, bottom: 18, trailing: 14))
        .frame(maxWidth: .infinity)
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
        (isStale || state.isOver(at: now) || now.timeIntervalSince(state.start) >= 3600) ? 68 : 50
    }

    var body: some View {
        let over = state.isOver(at: now)
        LiveTimerText(start: state.start, style: over ? .selfUpdating : .compact, now: now, pastHour: isStale && !over)
            .geistMono(15, .semibold, tracking: -0.02, lineHeight: 19)
            .foregroundStyle(over ? Drained.text : state.color.accent)
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
                let over = state.isOver(at: now)
                LiveTimerText(start: state.start, style: over ? .selfUpdating : .hms, now: now, pastHour: isStale && !over)
                    .geistPixel(44)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// Expanded swap: 52pt accent circle with a black ⇄; opens the app's Switch sheet.
struct IslandSwapButton: View {
    let state: ClockInState

    var body: some View {
        SwitchLink {
            SurfaceSwapGlyph(size: 52, foreground: .black, background: state.color.accent)
        }
    }
}

/// Expanded footer: 20 ticks (h5, unfilled #1C1C1E) + "SINCE 20:06" / "22:49 / 25:00" (mono 9/13 #6C6C70).
struct IslandExpandedFooter: View {
    let state: ClockInState
    var now: Date = AppClock.now

    var body: some View {
        VStack(spacing: 6) {
            if state.isOver(at: now) {
                DrainStrip(frame: .settled, overflow: Drained.overflowTicks(progress: state.progress(at: now)),
                           accentHex: state.color.accentHex, height: 5)
            } else if state.hasGoal {
                SegmentStrip(count: 20, fraction: state.progress(at: now), accent: state.color.accent,
                             height: 5, unfilled: CH.raised, animated: false)
            }
            HStack {
                Text("SINCE \(Fmt.time(state.start))")
                    .geistMono(9, .medium, tracking: 0.06, lineHeight: 13)
                Spacer(minLength: 8)
                if let goal = state.goalMinutes, goal > 0 {
                    Text("\(Fmt.hm(state.periodTotal(at: now))) / \(Fmt.hm(TimeInterval(goal * 60)))")
                        .geistMono(9, .medium, tracking: 0.02, lineHeight: 13)
                        .numericMorph()
                } else if state.goalMinutes != nil {
                    Text("\(Fmt.hm(state.periodTotal(at: now))) \(state.goalPeriod.current.uppercased())")
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
                IslandSwapButton(state: state)
            }
            IslandExpandedFooter(state: state, now: now)
        }
        .padding(EdgeInsets(top: 18, leading: 18, bottom: 16, trailing: 18))
    }
}
