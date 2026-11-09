import SwiftUI

/// 01 Home (Paper AB6-0): profile button, daily tagline (or "Chopped") and the glass "+" button, then one C3.2 card per
/// tracker. The running tracker gets the tall card (Pixel timer + Stop); the rest show their
/// period total + Play. Tap a card for the detail sheet (02); "+" opens New tracker (05).
struct HomeView: View {
    @Environment(Store.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pendingDelete: Activity?
    @State private var switching: Switching?
    @State private var bumps: [Int64: Int] = [:]
    @AppStorage(Tagline.disabledKey) private var taglineDisabled = false

    private struct Switching: Equatable {
        let date: Date
        let toID: Int64?
        let fromID: Int64?
    }

    var body: some View {
        // A plain List (styled to look like the stacked cards) so each card gets the native
        // swipe-left-to-delete gesture alongside normal vertical scrolling.
        List {
            Ticker(every: 60) { now in header(now: now) }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            let running = store.activeActivity
            let scheduled = store.scheduledSwitch
            let trackers = switching.map { ordered(next: $0.toID, after: $0.fromID) }
                ?? ordered(next: scheduled?.to?.id, after: running?.id)
            ForEach(Array(trackers.enumerated()), id: \.element.id) { index, a in
                let isRunning = running?.id == a.id
                let schedule = cardSchedule(for: a, scheduled: scheduled, running: running)
                // The card is a Button (press feedback: 0.98 spring, off with Reduce Motion); its
                // Play/Stop are separate Buttons inside the label, so they take their own taps.
                Button { router.openDetail(a.id) } label: {
                    Ticker(every: isRunning || store.isOnBreak(a.id) ? 1 : 60) { now in
                        TrackerCard(activity: a, now: now,
                                    scheduledLine: schedule != nil && !isRunning ? scheduledLine(scheduled, running: running) : nil,
                                    schedule: schedule,
                                    cancelSchedule: { cancelSchedule(bumping: a.id) },
                                    start: { toggle { store.clockIn(a) } },
                                    stop: { toggle { store.stop() } },
                                    takeBreak: { toggle { store.takeBreak(a) } },
                                    openSwitcher: { router.showingSwitcher = true })
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                }
                .buttonStyle(PressScaleStyle(scale: 0.98))
                .modifier(CardBump(trigger: bumps[a.id] ?? 0))
                .accessibilityHint("Opens tracker details")
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button { pendingDelete = a } label: { Label("Delete", systemImage: "trash.fill") }
                        .tint(Color(hex: "#FF453A"))
                }
                // 14pt between cards (7 + 7), 4pt above the first, 24pt below the last.
                .listRowInsets(EdgeInsets(top: index == 0 ? 4 : 7, leading: 12,
                                          bottom: index == trackers.count - 1 ? 24 : 7, trailing: 12))
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
        .task(id: store.scheduledSwitch?.date) { await runSwitch() }
        .task { await scheduleDemo() }
        .onChange(of: store.scheduledSwitch) { old, new in
            guard let id = new?.to?.id ?? (new != nil ? store.activeActivity?.id : nil), new?.date != old?.date else { return }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.3))
                bump(id)
            }
        }
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

    private func cardSchedule(for a: Activity, scheduled: Store.ScheduledSwitch?, running: Activity?) -> CardSchedule? {
        guard let scheduled else { return nil }
        let owner = scheduled.to?.id ?? running?.id
        guard owner == a.id else { return nil }
        return CardSchedule(date: scheduled.date, done: switching?.date == scheduled.date)
    }

    private func runSwitch() async {
        guard let scheduled = store.scheduledSwitch else { return }
        let lead = reduceMotion ? 0 : CardMotion.successLead
        try? await Task.sleep(for: .seconds(max(0, scheduled.date.timeIntervalSince(AppClock.now) - lead)))
        guard !Task.isCancelled, store.scheduledSwitch?.date == scheduled.date else { return }
        let marker = Switching(date: scheduled.date, toID: scheduled.to?.id, fromID: store.activeActivity?.id)
        switching = marker
        try? await Task.sleep(for: .seconds(max(0, scheduled.date.timeIntervalSince(AppClock.now))))
        Task { @MainActor in
            withAnimation(reduceMotion ? nil : CardMotion.resize) { store.refresh() }
            try? await Task.sleep(for: .seconds(0.45))
            if switching == marker {
                withAnimation(reduceMotion ? nil : CardMotion.resize) { switching = nil }
            }
        }
    }

    private func bump(_ id: Int64) {
        guard !reduceMotion else { return }
        bumps[id, default: 0] += 1
    }

    private func cancelSchedule(bumping id: Int64) {
        bump(id)
        toggle { store.cancelScheduledSwitch() }
    }

    private func ordered(next: Int64?, after fromID: Int64?) -> [Activity] {
        var list = store.trackers
        guard let next, let i = list.firstIndex(where: { $0.id == next }) else { return list }
        let moved = list.remove(at: i)
        let at = fromID.flatMap { id in list.firstIndex { $0.id == id }.map { $0 + 1 } } ?? 0
        list.insert(moved, at: at)
        return list
    }

    private func scheduledLine(_ scheduled: Store.ScheduledSwitch?, running: Activity?) -> String? {
        guard let scheduled else { return nil }
        return running == nil ? "Starts at \(Fmt.clock(scheduled.date))" : "Takes over at \(Fmt.clock(scheduled.date))"
    }

    private func scheduleDemo() async {
        guard let mode = QC.scheduleDemo, let meetings = store.trackers.first(where: { $0.name == "Meetings" }) else { return }
        if mode == "switch" {
            if let frozen = AppClock.frozen {
                AppClock.frozen = nil
                AppClock.offset = frozen.timeIntervalSince(Date())
            }
            try? await Task.sleep(for: .seconds(1))
            toggle { store.clockIn(meetings, at: AppClock.now.addingTimeInterval(2.5)) }
            return
        }
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(1.2))
            toggle { store.clockIn(meetings, at: AppClock.now.addingTimeInterval(12 * 60)) }
            try? await Task.sleep(for: .seconds(2.4))
            cancelSchedule(bumping: meetings.id)
            try? await Task.sleep(for: .seconds(1.4))
        }
    }

    private func toggle(_ change: () -> Void) {
        withAnimation(reduceMotion ? nil : CardMotion.resize, change)
    }

    // MARK: Header

    private func header(now: Date) -> some View {
        HStack(spacing: 12) {
            GlassCircleButton(glyph: .person, glyphSize: 18) { router.showingSettings = true }
                .accessibilityLabel("Settings")
            Group {
                if !taglineDisabled {
                    let tagline = Tagline.forDay(now)
                    Text(tagline)
                        .geist(20, .medium, tracking: -0.02, lineHeight: 26)
                        .foregroundStyle(CH.textMuted)
                        .contentTransition(.opacity)
                        .animation(.easeInOut(duration: 0.4), value: tagline)
                } else {
                    Text("Chopped")
                        .geist(20, .semibold, tracking: -0.02, lineHeight: 26)
                        .foregroundStyle(CH.text)
                }
            }
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            if store.activeSession != nil || store.activeBreak != nil {
                Button { toggle { store.stop() } } label: {
                    GlassSurface(shape: Circle())
                        .frame(width: 44, height: 44)
                        .overlay {
                            RoundedRectangle(cornerRadius: 3.5, style: .continuous).fill(Color(hex: "#FF453A"))
                                .frame(width: 14, height: 14)
                        }
                        .contentShape(Circle())
                }
                .buttonStyle(.pressScale)
                .accessibilityLabel("Clock out")
                .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
            GlassCircleButton(glyph: .plus) { router.showingNewTracker = true }
                .accessibilityLabel("New tracker")
        }
        .padding(EdgeInsets(top: 20, leading: 20, bottom: 22, trailing: 20))
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
    var scheduledLine: String? = nil
    var schedule: CardSchedule? = nil
    var cancelSchedule: (() -> Void)? = nil
    var start: () -> Void
    var stop: () -> Void
    var takeBreak: (() -> Void)? = nil
    var openSwitcher: (() -> Void)? = nil
    var showsBreak = true
    @State private var drainStart: Date?

    var body: some View {
        let a = activity
        let over = store.overBy(for: a, now: now)
        Group {
            if showsBreak, let b = store.activeBreak, b.activityID == a.id {
                BreakCard(activity: a, session: b, now: now, openSwitcher: openSwitcher ?? start)
            } else {
                trackerCard(a, over: over)
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
    private func trackerCard(_ a: Activity, over: TimeInterval?) -> some View {
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
        } else if a.hasGoal {
            TrackerBezel(color: a.color) {
                content(a, over: nil, drained: false)
            } footer: {
                SegmentStrip(fraction: store.progress(for: a, now: now), accent: a.color.accent)
            }
        } else {
            TrackerBezel(color: a.color) {
                content(a, over: nil, drained: false)
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
        .transition(.cardContent)
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
        let clockedIn = session?.end.map { "Clocked in · \(Fmt.clock(session?.start ?? now)) · until \(Fmt.clock($0))" }
            .map { $0 + (over == nil ? "" : " · ") } ?? "Clocked in · \(Fmt.time(session?.start ?? now)) · "
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
                Text(Fmt.hms(elapsed)).monospacedDigit()
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
                        Text(session?.end != nil ? clockedIn : clockedIn + (a.hasGoal ? "\(Fmt.hm(total)) of \(Fmt.goal(minutes: a.goalMinutes))"
                                                      : "\(Fmt.hm(total)) \(a.period.current)"))
                    }
                }
                .geist(13, .medium, lineHeight: 17)
                .foregroundStyle(palette.meta)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            ZStack {
                if schedule != nil {
                    CardActionButton(mode: actionMode, size: 52, action: cancelSchedule ?? {})
                        .transition(.blurSwap(dy: 0))
                } else if let takeBreak, let openSwitcher {
                    BreakSwitchControl(accent: a.color.accent, takeBreak: takeBreak, openSwitcher: openSwitcher)
                        .transition(.blurSwap(dy: 0))
                } else {
                    StopButton(accent: a.color.accent, action: stop)
                }
            }
            .animation(CardMotion.swap, value: schedule?.date)
        }
        .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 14))
        .background { stripes }
    }

    private var actionMode: CardActionButton.Mode {
        guard let schedule else { return .play }
        return schedule.done ? .done : .cancel
    }

    private var stripes: some View {
        ScheduleStripes()
            .opacity(schedule == nil ? 0 : 1)
            .animation(.easeInOut(duration: 0.25), value: schedule == nil)
            .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
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
                    } else if let scheduledLine {
                        Text(scheduledLine).transition(.asymmetric(insertion: .blurSwap(dy: 4), removal: .blurSwap(dy: -4)))
                    } else {
                        Text(metaLine(a)).transition(.asymmetric(insertion: .blurSwap(dy: 4), removal: .blurSwap(dy: -4)))
                    }
                }
                .geist(13, .medium, lineHeight: 17)
                .foregroundStyle(palette.meta)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(CardMotion.textSwap, value: scheduledLine)
            }
            .frame(maxWidth: .infinity, minHeight: 40, maxHeight: 40, alignment: .leading)   // 22 + 1 + 17
            ZStack(alignment: .trailing) {
                if let schedule {
                    ScheduleTime(date: schedule.date, color: palette.text)
                        .transition(.asymmetric(insertion: .blurSwap(dy: 4), removal: .blurSwap(dy: -4)))
                } else {
                    Text(Fmt.hm(total))
                        .geistMono(26, .medium, tracking: -0.05, lineHeight: 30)
                        .foregroundStyle(palette.text)
                        .lineLimit(1)
                        .fixedSize()
                        .contentTransition(.numericText())
                        .transition(.asymmetric(insertion: .blurSwap(dy: 4), removal: .blurSwap(dy: -4)))
                }
            }
            .animation(CardMotion.textSwap, value: schedule?.date)
            CardActionButton(mode: actionMode, action: schedule == nil ? start : (cancelSchedule ?? {}))
        }
        .padding(EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 12))
        .background { stripes }
    }

    /// "Weekly · 8h goal", or "Daily · 45m · 6-day streak" once a streak is worth showing.
    private func metaLine(_ a: Activity) -> String {
        guard a.hasGoal else { return a.goalLine }
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

struct BreakCard: View {
    @Environment(Store.self) private var store
    let activity: Activity
    let session: WorkSession
    let now: Date
    var openSwitcher: () -> Void

    var body: some View {
        let green = TrackerColor.breakGreen
        let end = store.breakEnd(session)
        let over = now >= end
        let length = max(1, end.timeIntervalSince(session.start))
        let overBy = now.timeIntervalSince(end)
        let shown = over ? now.timeIntervalSince(session.start) : -overBy
        TrackerBezel(color: green) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 10) {
                        IconTile(glyph: .cup, size: 30, radius: 9, glyphSize: 16)
                        Text("Break")
                            .geist(20, .semibold, tracking: -0.015, lineHeight: 24)
                            .foregroundStyle(CH.onAccent)
                    }
                    Text(Fmt.hms(shown)).monospacedDigit()
                        .geistPixel(62)
                        .foregroundStyle(CH.onAccent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .contentTransition(.numericText(countsDown: !over))
                        .animation(.snappy(duration: 0.25), value: Int(shown))
                        .accessibilityLabel(over ? "On break for \(Fmt.words(shown)), \(Fmt.words(overBy)) over"
                                                 : "\(Fmt.words(shown)) of break left")
                    Group {
                        if over {
                            Text("From \(activity.name) · ")
                                + Text("+\(Fmt.timer(overBy)) over").font(.geist(13, .semibold)).foregroundStyle(CH.onAccent)
                        } else {
                            Text("From \(activity.name) · ends \(Fmt.time(end))")
                        }
                    }
                        .geist(13, .medium, lineHeight: 17)
                        .foregroundStyle(CH.onAccentSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Button(action: openSwitcher) {
                    SurfaceSwapGlyph(size: 52, foreground: green.accent)
                }
                .buttonStyle(.pressScale)
                .accessibilityLabel("Switch tracker")
            }
            .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 14))
        } footer: {
            SegmentStrip(fraction: over ? 1 : now.timeIntervalSince(session.start) / length, accent: green.accent)
        }
    }
}

struct BreakSwitchControl: View {
    let accent: Color
    var takeBreak: () -> Void
    var openSwitcher: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: takeBreak) {
                GlyphView(.cup, size: 22, color: accent, strokeWidth: 2.5)
                    .frame(width: 52, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.pressScale)
            .accessibilityLabel("Take a break")
            Color.white.opacity(0.14).frame(width: 22, height: 1)
            Button(action: openSwitcher) {
                GlyphView(.swap, size: 22, color: accent, strokeWidth: 2.5)
                    .frame(width: 52, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.pressScale)
            .accessibilityLabel("Switch tracker")
        }
        .padding(.vertical, 6)
        .background(.black, in: Capsule())
    }
}
