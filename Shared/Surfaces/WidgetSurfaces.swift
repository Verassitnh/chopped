import SwiftUI

// MARK: - 07 Home-screen widgets (Paper B7U-0)
//
// These views draw the whole widget including its bezel (5pt inset). The widget extension sets the
// bezel colour as `containerBackground` and disables content margins; the QC host clips them to r26.

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
                Text("\(Fmt.hm(t.periodTotal(at: now))) of \(Fmt.goal(minutes: t.goalMinutes))")
                    .geist(11, .medium, lineHeight: 14)
                    .foregroundStyle(Color.black.opacity(0.6))
                    .numericMorph()
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            if let start = t.runningStart {
                LiveTimerText(start: start, style: .compact, now: now)
                    .geistPixel(34)
                    .foregroundStyle(CH.onAccent)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(1)
                    .frame(maxWidth: 130, alignment: .trailing)
                    .fixedSize(horizontal: AppClock.isFrozen, vertical: false)
                IntentButton(intent: StopTrackerIntent(), accessibility: "Stop \(t.name)") {
                    SurfaceStopGlyph(size: 36, accent: t.color.accent)
                }
            } else {
                Text(Fmt.hm(t.periodTotal(at: now)))
                    .geistMono(26, .medium, tracking: -0.05, lineHeight: 30)
                    .foregroundStyle(CH.onAccent)
                    .numericMorph()
                IntentButton(intent: StartTrackerIntent(trackerID: t.id), accessibility: "Start \(t.name)") {
                    PlayButton(size: 36)
                }
            }
        }
        .padding(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 10))
        .background(t.color.accent, in: RoundedRectangle(cornerRadius: 21, style: .continuous))
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
            IntentButton(intent: StartTrackerIntent(trackerID: t.id), accessibility: "Start \(t.name)") {
                PlayButton(size: 26, background: Color.white.opacity(0.1))
            }
        }
        // 30pt rows in the design; may give up a fraction so the widget fits 170pt.
        .frame(minHeight: 26, maxHeight: 30)
    }
}

/// Small: one tracker. Running → stop + Pixel timer; idle → play + mono total "/goal".
struct SmallWidgetView: View {
    let tracker: TrackerSnapshot
    var now: Date

    var body: some View {
        let t = tracker
        let accent = t.color.accent
        VStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    IconTile(glyph: t.glyph, size: 26, radius: 8, glyphSize: 14)
                    Spacer(minLength: 0)
                    if t.isRunning {
                        IntentButton(intent: StopTrackerIntent(), accessibility: "Stop \(t.name)") {
                            SurfaceStopGlyph(size: 34, accent: accent)
                        }
                    } else {
                        IntentButton(intent: StartTrackerIntent(trackerID: t.id), accessibility: "Start \(t.name)") {
                            PlayButton(size: 34)
                        }
                    }
                }
                Spacer(minLength: 0)
                VStack(alignment: .leading, spacing: 2) {
                    Text(t.name)
                        .geist(13, .semibold, lineHeight: 16)
                        .foregroundStyle(Color.black.opacity(0.7))
                        .lineLimit(1)
                    if let start = t.runningStart {
                        LiveTimerText(start: start, style: .compact, now: now)
                            .geistPixel(40)
                            .foregroundStyle(CH.onAccent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    } else {
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text(Fmt.hm(t.periodTotal(at: now)))
                                .geistMono(30, .medium, tracking: -0.05, lineHeight: 34)
                                .foregroundStyle(CH.onAccent)
                                .numericMorph()
                            Text("/\(Fmt.hm(t.goal))")
                                .geistMono(12, .medium, tracking: -0.02, lineHeight: 16)
                                .foregroundStyle(Color.black.opacity(0.55))
                        }
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(accent, in: RoundedRectangle(cornerRadius: 21, style: .continuous))

            SegmentStrip(count: 12, fraction: t.progress(at: now), accent: accent, height: 5, animated: false)
                .padding(EdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 12))
        }
        .padding(EdgeInsets(top: 5, leading: 5, bottom: 12, trailing: 5))
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
