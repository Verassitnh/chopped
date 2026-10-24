import SwiftUI

/// 01 Home (Paper AB6-0): date + tagline header with the glass "+" button, then one C3.2 card per
/// tracker. The running tracker gets the tall card (Pixel timer + Stop); the rest show their
/// period total + Play. Tap a card for the detail sheet (02); "+" opens New tracker (05).
struct HomeView: View {
    @Environment(Store.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Ticker { now in
            ScrollView {
                VStack(spacing: 0) {
                    header(now: now)
                    VStack(spacing: 14) {
                        ForEach(store.activities) { a in
                            TrackerCard(activity: a, now: now,
                                        start: { toggle { store.clockIn(a) } },
                                        stop: { toggle { store.stop() } })
                                .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                                .onTapGesture { router.openDetail(a.id) }
                                .accessibilityAddTraits(.isButton)
                                .accessibilityHint("Opens tracker details")
                        }
                        if store.activities.isEmpty { emptyState }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 4)
                    .padding(.bottom, 120)   // clears the floating tab bar
                }
            }
            .scrollIndicators(.hidden)
        }
        .background(CH.bg)
    }

    private func toggle(_ change: () -> Void) {
        withAnimation(reduceMotion ? nil : Motion.spring, change)
    }

    // MARK: Header

    private func header(now: Date) -> some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Self.dateLine(now))
                    .geist(13, .medium, lineHeight: 16)
                    .foregroundStyle(CH.textSecondary)
                Text("lock in twin")
                    .geist(20, .medium, tracking: -0.02, lineHeight: 26)
                    .foregroundStyle(CH.textMuted)
            }
            .frame(height: 46)   // 16 + 4 + 26, pinned so fractional line-height padding can't drift
            Spacer(minLength: 12)
            GlassCircleButton(glyph: .plus) { router.showingNewTracker = true }
                .accessibilityLabel("New tracker")
        }
        .padding(EdgeInsets(top: 20, leading: 20, bottom: 22, trailing: 20))
    }

    /// "Friday, 23 October".
    static func dateLine(_ date: Date) -> String {
        let f = DateFormatter()
        f.calendar = .chopped
        f.locale = Locale(identifier: "en_GB")
        f.dateFormat = "EEEE, d MMMM"
        return f.string(from: date)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Text("No trackers yet")
                .geist(17, .semibold, tracking: -0.01, lineHeight: 22)
                .foregroundStyle(CH.text)
            Text("Tap + to start tracking something.")
                .geist(13, .medium, lineHeight: 17)
                .foregroundStyle(CH.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

/// One home card (C3.2). Switches between the idle row and the tall running layout.
struct TrackerCard: View {
    @Environment(Store.self) private var store
    let activity: Activity
    let now: Date
    var start: () -> Void
    var stop: () -> Void

    var body: some View {
        let a = activity
        let running = store.isRunning(a.id)
        TrackerBezel(color: a.color) {
            Group {
                if running { runningRow(a) } else { idleRow(a) }
            }
            .transition(.opacity)
        } footer: {
            SegmentStrip(fraction: store.progress(for: a, now: now), accent: a.color.accent)
        }
        .animation(nil, value: now)
        .accessibilityElement(children: .contain)
    }

    // MARK: Running (Deep Work in the design)

    private func runningRow(_ a: Activity) -> some View {
        let session = store.activeSession
        let elapsed = session.map { now.timeIntervalSince($0.start) } ?? 0
        let total = store.periodTotal(for: a, now: now)
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    IconTile(glyph: a.glyph, size: 30, radius: 9, glyphSize: 16)
                    Text(a.name)
                        .geist(20, .semibold, tracking: -0.015, lineHeight: 24)
                        .foregroundStyle(CH.onAccent)
                        .lineLimit(1)
                }
                Text(Fmt.hms(elapsed))
                    .geistPixel(62)
                    .foregroundStyle(CH.onAccent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText(countsDown: false))
                    .animation(.snappy(duration: 0.25), value: Int(elapsed))
                    .accessibilityLabel("Running for \(Fmt.words(elapsed))")
                Text("Clocked in · \(Fmt.time(session?.start ?? now)) · \(Fmt.hm(total)) of \(Fmt.goal(minutes: a.goalMinutes))")
                    .geist(13, .medium, lineHeight: 17)
                    .foregroundStyle(CH.onAccentSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            StopButton(accent: a.color.accent, action: stop)
        }
        .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 14))
    }

    // MARK: Idle

    private func idleRow(_ a: Activity) -> some View {
        let total = store.periodTotal(for: a, now: now)
        return HStack(spacing: 12) {
            IconTile(glyph: a.glyph)
            VStack(alignment: .leading, spacing: 1) {
                Text(a.name)
                    .geist(18, .semibold, tracking: -0.015, lineHeight: 22)
                    .foregroundStyle(CH.onAccent)
                    .lineLimit(1)
                Text(metaLine(a))
                    .geist(13, .medium, lineHeight: 17)
                    .foregroundStyle(CH.onAccentSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 40, maxHeight: 40, alignment: .leading)   // 22 + 1 + 17
            Text(Fmt.hm(total))
                .geistMono(26, .medium, tracking: -0.05, lineHeight: 30)
                .foregroundStyle(CH.onAccent)
                .lineLimit(1)
                .fixedSize()
                .contentTransition(.numericText())
            PlayButton(action: start)
        }
        .padding(EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 12))
    }

    /// "Weekly · 8h goal", or "Daily · 45m · 6-day streak" once a streak is worth showing.
    private func metaLine(_ a: Activity) -> String {
        let streak = store.streak(for: a, now: now).current
        guard streak >= Self.streakThreshold(a.period) else { return a.goalLine }
        let unit = a.period == .day ? "day" : a.period.rawValue
        return "\(a.period.adjective) · \(Fmt.goal(minutes: a.goalMinutes)) · \(streak)-\(unit) streak"
    }

    /// Shortest streak shown on the card (a few days in a row; any multi-period run for longer periods).
    static func streakThreshold(_ period: GoalPeriod) -> Int {
        switch period {
        case .day: 5
        case .week: 3
        case .month, .year: 2
        }
    }
}
