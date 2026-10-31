import SwiftUI

/// 01 Home (Paper AB6-0): date + tagline header with the glass "+" button, then one C3.2 card per
/// tracker. The running tracker gets the tall card (Pixel timer + Stop); the rest show their
/// period total + Play. Tap a card for the detail sheet (02); "+" opens New tracker (05).
struct HomeView: View {
    @Environment(Store.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pendingDelete: Activity?

    var body: some View {
        // A plain List (styled to look like the stacked cards) so each card gets the native
        // swipe-left-to-delete gesture alongside normal vertical scrolling.
        List {
            Ticker(every: 60) { now in header(now: now) }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            ForEach(Array(store.trackers.enumerated()), id: \.element.id) { index, a in
                // The card is a Button (press feedback: 0.98 spring, off with Reduce Motion); its
                // Play/Stop are separate Buttons inside the label, so they take their own taps.
                Button { router.openDetail(a.id) } label: {
                    Ticker(every: store.isRunning(a.id) ? 1 : 60) { now in
                        TrackerCard(activity: a, now: now,
                                    start: { toggle { store.clockIn(a) } },
                                    stop: { toggle { store.stop() } })
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                }
                .buttonStyle(PressScaleStyle(scale: 0.98))
                .accessibilityHint("Opens tracker details")
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button { pendingDelete = a } label: { Label("Delete", systemImage: "trash.fill") }
                        .tint(Color(hex: "#FF453A"))
                }
                // 14pt between cards (7 + 7), 4pt above the first, 24pt below the last.
                .listRowInsets(EdgeInsets(top: index == 0 ? 4 : 7, leading: 12,
                                          bottom: index == store.trackers.count - 1 ? 24 : 7, trailing: 12))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            if store.trackers.isEmpty {
                emptyState
                    .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 24, trailing: 12))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.defaultMinListRowHeight, 0)
        .scrollIndicators(.hidden)
        .background(CH.bg)
        .alert("Delete \(pendingDelete?.name ?? "tracker")?",
               isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
               presenting: pendingDelete) { a in
            Button("Delete", role: .destructive) { delete(a) }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("This will delete all historic data entries.")
        }
    }

    private func delete(_ a: Activity) {
        withAnimation(reduceMotion ? nil : Motion.spring) {
            if store.isRunning(a.id) { store.stop() }
            store.deleteActivity(a)
        }
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
                let tagline = Tagline.forDay(now)
                Text(tagline)
                    .geist(20, .medium, tracking: -0.02, lineHeight: 26)
                    .foregroundStyle(CH.textMuted)
                    .lineLimit(1)
                    .contentTransition(.opacity)   // crossfade when the day rolls over while open
                    .animation(.easeInOut(duration: 0.4), value: tagline)
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let activity: Activity
    let now: Date
    var start: () -> Void
    var stop: () -> Void
    @State private var drainStart: Date?

    var body: some View {
        let a = activity
        let over = store.overBy(for: a, now: now)
        Group {
            if let over, let drainStart {
                TimelineView(.animation) { context in
                    let elapsed = context.date.timeIntervalSince(drainStart)
                    card(a, over: over, frame: DrainFrame(elapsed: elapsed, reduceMotion: reduceMotion))
                }
            } else {
                card(a, over: over, frame: over == nil ? nil : .settled)
            }
        }
        .animation(nil, value: now)
        .accessibilityElement(children: .contain)
        .onChange(of: over != nil) { _, isOver in
            drainStart = isOver ? Date() : nil
            if isOver, let over, over < 3 { OverLimitAlerts.shared.playSound() }
        }
        .task(id: drainStart) {
            guard drainStart != nil else { return }
            let overflow = Drained.overflowTicks(progress: store.progress(for: a, now: now))
            try? await Task.sleep(for: .seconds(DrainFrame.duration(overflow: overflow, reduceMotion: reduceMotion)))
            drainStart = nil
        }
    }

    @ViewBuilder
    private func card(_ a: Activity, over: TimeInterval?, frame: DrainFrame?) -> some View {
        if let over, let frame {
            let overflow = Drained.overflowTicks(progress: store.progress(for: a, now: now))
            TrackerBezel(tint: Color.mix(a.color.tintHex, Drained.bezelHex, frame.bezel), accent: .clear) {
                ZStack {
                    content(a, over: over, drained: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Drained.inner)
                    if frame.level < 1 {
                        content(a, over: over, drained: false)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(a.color.accent)
                            .mask {
                                if frame.reduceMotion {
                                    Rectangle().opacity(1 - frame.level)
                                } else {
                                    PourShape(level: frame.level, amplitude: DrainFrame.waveHeight, phase: frame.wavePhase)
                                }
                            }
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
            } footer: {
                DrainStrip(frame: frame, overflow: overflow, accentHex: a.color.accentHex)
            }
            .scaleEffect(x: 1 + frame.squash * 0.5, y: 1 - frame.squash, anchor: .bottom)
        } else {
            TrackerBezel(color: a.color) {
                content(a, over: nil, drained: false)
            } footer: {
                SegmentStrip(fraction: store.progress(for: a, now: now), accent: a.color.accent)
            }
        }
    }

    private func content(_ a: Activity, over: TimeInterval?, drained: Bool) -> some View {
        Group {
            if store.isRunning(a.id) {
                runningRow(a, over: over, drained: drained)
            } else {
                idleRow(a, over: over, drained: drained)
            }
        }
        .transition(.opacity)
    }

    private struct Palette {
        let text: Color, meta: Color, strong: Color, icon: Color, iconTile: Color

        static let accent = Palette(text: CH.onAccent, meta: CH.onAccentSecondary, strong: CH.onAccent,
                                    icon: CH.onAccent, iconTile: CH.iconTileFill)
        static let drained = Palette(text: Drained.text, meta: Drained.meta, strong: Drained.metaStrong,
                                     icon: Drained.icon, iconTile: Drained.iconTile)
    }

    private func overText(_ over: TimeInterval, _ palette: Palette) -> Text {
        Text(Drained.overLabel(over)).font(.geist(13, .semibold)).foregroundStyle(palette.strong)
    }

    // MARK: Running (Deep Work in the design)

    private func runningRow(_ a: Activity, over: TimeInterval?, drained: Bool) -> some View {
        let palette = drained ? Palette.drained : .accent
        let session = store.activeSession
        let elapsed = session.map { now.timeIntervalSince($0.start) } ?? 0
        let total = store.periodTotal(for: a, now: now)
        let clockedIn = "Clocked in · \(Fmt.time(session?.start ?? now)) · "
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    IconTile(glyph: a.glyph, size: 30, radius: 9, glyphSize: 16,
                             foreground: palette.icon, background: palette.iconTile)
                    Text(a.name)
                        .geist(20, .semibold, tracking: -0.015, lineHeight: 24)
                        .foregroundStyle(palette.text)
                        .lineLimit(1)
                }
                Text(Fmt.hms(elapsed))
                    .geistPixel(62)
                    .foregroundStyle(palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText(countsDown: false))
                    .animation(.snappy(duration: 0.25), value: Int(elapsed))
                    .accessibilityLabel("Running for \(Fmt.words(elapsed))")
                Group {
                    if let over {
                        Text(clockedIn) + overText(over, palette)
                    } else {
                        Text(clockedIn + "\(Fmt.hm(total)) of \(Fmt.goal(minutes: a.goalMinutes))")
                    }
                }
                .geist(13, .medium, lineHeight: 17)
                .foregroundStyle(palette.meta)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            StopButton(accent: a.color.accent, action: stop)
        }
        .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 14))
    }

    // MARK: Idle

    private func idleRow(_ a: Activity, over: TimeInterval?, drained: Bool) -> some View {
        let palette = drained ? Palette.drained : .accent
        let total = store.periodTotal(for: a, now: now)
        return HStack(spacing: 12) {
            IconTile(glyph: a.glyph, foreground: palette.icon, background: palette.iconTile)
            VStack(alignment: .leading, spacing: 1) {
                Text(a.name)
                    .geist(18, .semibold, tracking: -0.015, lineHeight: 22)
                    .foregroundStyle(palette.text)
                    .lineLimit(1)
                Group {
                    if let over {
                        Text("\(a.period.adjective) · \(Fmt.goal(minutes: a.goalMinutes)) · ") + overText(over, palette)
                    } else {
                        Text(metaLine(a))
                    }
                }
                .geist(13, .medium, lineHeight: 17)
                .foregroundStyle(palette.meta)
                .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 40, maxHeight: 40, alignment: .leading)   // 22 + 1 + 17
            Text(Fmt.hm(total))
                .geistMono(26, .medium, tracking: -0.05, lineHeight: 30)
                .foregroundStyle(palette.text)
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

    /// Shortest streak shown on the card: five days or weeks in a row; any multi-period run for longer periods.
    static func streakThreshold(_ period: GoalPeriod) -> Int {
        switch period {
        case .day, .week: 5
        case .month, .year: 2
        }
    }
}
