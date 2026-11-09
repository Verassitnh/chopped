import AppIntents
import SwiftUI

// MARK: - 07 Home-screen widgets (Paper B7U-0)
//
// These views draw the whole widget including its bezel (5pt inset). The widget extension sets the
// bezel colour as `containerBackground` and disables content margins. Inner blocks use
// `ContainerRelativeShape` so they stay concentric with the system's widget corners.

/// Medium: running (or first) tracker block + up to 3 tracker rows with play buttons.
struct MediumWidgetView: View {
    let snapshot: ChoppedSnapshot
    var now: Date

    /// Bezel colour (#1C1C1E).
    static let background = CH.raised

    private var top: TrackerSnapshot? { snapshot.running ?? snapshot.trackers.first }
    private var rows: [TrackerSnapshot] { Array(snapshot.trackers.filter { $0.id != top?.id }.prefix(3)) }

    var body: some View {
        VStack(spacing: 8) {
            if let top { block(top) }
            VStack(spacing: 0) {
                ForEach(rows) { row($0) }
            }
            .padding(EdgeInsets(top: 2, leading: 12, bottom: 0, trailing: 12))
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(EdgeInsets(top: 5, leading: 5, bottom: 10, trailing: 5))
    }

    private func block(_ t: TrackerSnapshot) -> some View {
        HStack(spacing: 10) {
            IconTile(glyph: t.glyph, size: 26, radius: 8, glyphSize: 14)
            VStack(alignment: .leading, spacing: 0) {
                Text(t.name)
                    .geist(14, .semibold, lineHeight: 18)
                    .foregroundStyle(CH.onAccent)
                Text(t.hasGoal ? "\(Fmt.hm(t.periodTotal(at: now))) of \(Fmt.goal(minutes: t.goalMinutes))"
                               : "\(Fmt.hm(t.periodTotal(at: now))) \(t.period.current)")
                    .geist(11, .medium, lineHeight: 14)
                    .foregroundStyle(Color.black.opacity(0.6))
                    .numericMorph()
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            if let start = t.runningStart {
                LiveTimerText(start: start, now: now)
                    .geistPixel(34)
                    .foregroundStyle(CH.onAccent)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .frame(maxWidth: 130, alignment: .trailing)
                    .fixedSize(horizontal: AppClock.isFrozen, vertical: false)
                WidgetSwitchButton {
                    SurfaceSwapGlyph(size: 36, foreground: t.color.accent)
                }
            } else {
                Text(Fmt.hm(t.periodTotal(at: now)))
                    .geistMono(26, .medium, tracking: -0.05, lineHeight: 30)
                    .foregroundStyle(CH.onAccent)
                    .numericMorph()
                WidgetPlayButton(tracker: t, somethingRunning: snapshot.running != nil) {
                    PlayButton(size: 36)
                }
            }
        }
        .padding(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 10))
        .background(t.color.accent, in: ContainerRelativeShape())
    }

    private func row(_ t: TrackerSnapshot) -> some View {
        HStack(spacing: 10) {
            IconTile(glyph: t.glyph, size: 22, radius: 7, glyphSize: 12,
                     foreground: t.color.accent, background: Color.white.opacity(0.06))
            Text(t.name)
                .geist(14, .semibold, lineHeight: 18)
                .foregroundStyle(CH.textMuted)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(Fmt.hm(t.periodTotal(at: now)))
                .geistMono(14, .medium, tracking: -0.02, lineHeight: 18)
                .foregroundStyle(CH.textMuted)
                .numericMorph()
            WidgetPlayButton(tracker: t, somethingRunning: snapshot.running != nil) {
                PlayButton(size: 26, background: Color.white.opacity(0.1))
            }
        }
        // 30pt rows in the design; may give up a fraction so the widget fits 170pt.
        .frame(minHeight: 26, maxHeight: 30)
    }
}

enum SquareWidgetStyle {
    case home, standby, night
}

/// Small: one tracker. Running → ⇄ + Pixel timer; idle → play + mono total "/goal".
struct SmallWidgetView: View {
    let tracker: TrackerSnapshot
    /// Another tracker is running (Play switches instead of starting fresh).
    var somethingRunning = false
    var now: Date
    var style: SquareWidgetStyle = .home
    var bezel = true

    private var night: Bool { style == .night }
    private var ink: Color { night ? .white : CH.onAccent }

    var body: some View {
        let t = tracker
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                IconTile(glyph: t.glyph, size: 26, radius: 8, glyphSize: 14,
                         foreground: ink, background: night ? Color.white.opacity(0.12) : CH.iconTileFill)
                    .padding(.top, 2)
                Spacer(minLength: 0)
                if t.isRunning {
                    WidgetSwitchButton {
                        SurfaceSwapGlyph(size: 42, foreground: night ? .white : t.color.accent,
                                         background: night ? .clear : .black)
                            .overlay { if night { Circle().strokeBorder(.white, lineWidth: 2) } }
                    }
                } else {
                    WidgetPlayButton(tracker: t, somethingRunning: somethingRunning) {
                        PlayButton(size: 42, background: night ? .clear : .black)
                            .overlay { if night { Circle().strokeBorder(.white, lineWidth: 2) } }
                    }
                }
            }
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: 2) {
                Text(t.name)
                    .geist(13, .semibold, lineHeight: 16)
                    .foregroundStyle(ink.opacity(0.7))
                    .lineLimit(1)
                if let start = t.runningStart {
                    LiveTimerText(start: start, now: now)
                        .geistPixel(50)
                        .foregroundStyle(ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(Fmt.hm(t.periodTotal(at: now)))
                            .geistMono(34, .medium, tracking: -0.05, lineHeight: 50)
                            .foregroundStyle(ink)
                            .numericMorph()
                        if t.hasGoal {
                            Text("/\(Fmt.hm(t.goal))")
                                .geistMono(13, .medium, tracking: -0.02, lineHeight: 16)
                                .foregroundStyle(ink.opacity(0.55))
                        }
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                }
            }
        }
        .padding(EdgeInsets(top: 14, leading: 14, bottom: 12, trailing: 12))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background {
            let block = ContainerRelativeShape()
            if night {
                block.strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
            } else {
                block.fill(t.color.accent)
            }
        }
        .padding(bezel ? 5 : 0)
    }
}

struct WidgetSwitchButton<Label: View>: View {
    @ViewBuilder var label: Label

    var body: some View {
        if #available(iOS 18.0, *) {
            Button(intent: OpenURLIntent(ChoppedLink.switcher)) { label }
                .buttonStyle(.plain)
                .accessibilityLabel("Switch tracker")
        } else {
            SwitchLink { label }
        }
    }
}

/// Widget Play. Switching while something runs, or starting while Live Activities are off, runs in the widget
/// extension and flips at once. Starting fresh has to create a Live Activity, which iOS only lets a
/// background app do from a `LiveActivityIntent` (run in the app via the system's Shortcuts runner, ~2s
/// before the widget updates), so that case uses `StartTrackerIntent`. See `ChoppedIntents.swift`.
struct WidgetPlayButton<Label: View>: View {
    let tracker: TrackerSnapshot
    let somethingRunning: Bool
    @ViewBuilder var label: Label

    var body: some View {
        if somethingRunning || !AppGroup.liveActivitiesEnabled {
            IntentButton(intent: WidgetStartTrackerIntent(trackerID: tracker.id), accessibility: "Start \(tracker.name)") { label }
        } else {
            IntentButton(intent: StartTrackerIntent(trackerID: tracker.id), accessibility: "Start \(tracker.name)") { label }
        }
    }
}

/// Shown when there's no data yet (app never opened / no trackers).
struct EmptyWidgetView: View {
    var body: some View {
        VStack(spacing: 6) {
            GlyphView(.clock, size: 22, color: CH.textSecondary)
            Text("Open Chopped to\nadd trackers")
                .geist(12, .medium, lineHeight: 16)
                .multilineTextAlignment(.center)
                .foregroundStyle(CH.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
