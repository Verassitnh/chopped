import SwiftUI

/// 02 Tracker detail sheet (Paper AGW-0). Presented by RootView via `router.detailActivityID`.
/// Full-accent header (grabber, icon/name, close X, Pixel timer, progress strip, big Stop/Start pill),
/// then this week's day bars, the entries list (tap to fix times, + Add to log time), then EDIT TRACKER
/// (opens the 05 sheet in edit mode) over DELETE TRACKER.
struct TrackerDetailView: View {
    @Environment(Store.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let activityID: Int64

    @State private var editingSession: WorkSession?
    @State private var addingEntry = false
    @State private var editingTracker = false
    @State private var confirmingDelete = false

    var body: some View {
        Group {
            if let a = store.activity(activityID) {
                Ticker { now in content(a, now: now) }
                    .sheet(item: $editingSession) { s in EntryEditSheet(session: s, activity: a) }
                    .sheet(isPresented: $addingEntry) { AddEntrySheet(activity: a) }
                    // Same edge-to-edge 05 sheet as the home "+", over the detail.
                    .newTrackerOverlay(isPresented: $editingTracker, editing: a)
                    .sensoryFeedback(.impact(weight: .light), trigger: editingTracker) { _, open in open }
                    .confirmationDialog("Delete \(a.name)?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                        Button("Delete Tracker", role: .destructive) { delete(a) }
                    } message: {
                        Text("All of its time entries will be deleted too.")
                    }
            } else {
                CH.bg.onAppear { dismiss() }
            }
        }
        .presentationDragIndicator(.hidden)
        // The sheet draws its own surface 8pt below the system sheet top (Paper: status bar + 8 gap),
        // with 28pt top corners matching the accent header.
        .presentationBackground(CH.bg)
        .presentationCornerRadius(28)
    }

    private func content(_ a: Activity, now: Date) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                DetailHeader(activity: a, now: now, close: { dismiss() }, toggle: { toggle(a) })
                weekBars(a, now: now)
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                entries(a, now: now)
                    .padding(.horizontal, 20)
                    .padding(.top, 52)
                // Paper: 52 below the entries, 20 between the two labels, 64 to the bottom
                // (each label carries 8pt of tap padding above and below).
                VStack(spacing: 4) {
                    textButton("EDIT TRACKER", color: Color(hex: "#F2F2F7")) { editingTracker = true }
                    textButton("DELETE TRACKER", color: Color(hex: "#FF453A")) { confirmingDelete = true }
                }
                .padding(.top, 44)
                .padding(.bottom, 56)
            }
        }
        .scrollIndicators(.hidden)
        // QC aid: `-QCScrollBottom` snapshots the bottom of the sheet (settings + delete).
        .defaultScrollAnchor(ProcessInfo.processInfo.arguments.contains("-QCScrollBottom") ? .bottom : .top)
        .background(CH.bg)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28, style: .continuous))
        .padding(.top, 8)
        .ignoresSafeArea(edges: .bottom)
    }

    /// Geist Mono 13 caps text button (EDIT / DELETE TRACKER).
    private func textButton(_ title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .geistMono(13, .medium, tracking: 0.08, lineHeight: 16)
                .foregroundStyle(color)
                .padding(.vertical, 8).padding(.horizontal, 16)
                .contentShape(Rectangle())
        }
        .buttonStyle(.pressScale)
    }

    private func toggle(_ a: Activity) {
        withAnimation(reduceMotion ? nil : Motion.spring) {
            if store.isRunning(a.id) { store.stop() } else { store.clockIn(a) }
        }
    }

    private func delete(_ a: Activity) {
        dismiss()
        router.detailActivityID = nil
        if store.isRunning(a.id) { store.stop() }
        store.deleteActivity(a)
    }

    // MARK: Week bars

    private func weekBars(_ a: Activity, now: Date) -> some View {
        let days = store.thisWeekDays(for: a.id, now: now)
        let maxSeconds = max(days.map(\.seconds).max() ?? 0, 1)
        let today = Store.day(containing: now)
        let letters = ["M", "T", "W", "T", "F", "S", "S"]
        return HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(days.enumerated()), id: \.element.id) { i, d in
                let isToday = d.interval.start == today.start
                let empty = d.seconds < 60
                VStack(spacing: 8) {
                    Text(empty ? "–" : Fmt.hm(d.seconds))
                        .geistMono(11, isToday && !empty ? .semibold : .medium, tracking: -0.02, lineHeight: 15)
                        .foregroundStyle(isToday && !empty ? Color.white : CH.textTertiary)
                        .contentTransition(.numericText())
                    if empty {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(a.color.accent.opacity(0.18))
                            .frame(height: 4)
                    } else {
                        GrowBar(height: max(4, (48 * d.seconds / maxSeconds).rounded()),
                                color: isToday ? a.color.accent : a.color.accent.opacity(0.45))
                    }
                    Text(letters[i % 7])
                        .geistMono(12, isToday ? .bold : .medium, lineHeight: 16)
                        .foregroundStyle(isToday ? Color.white : CH.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(d.interval.start.formatted(.dateTime.weekday(.wide))): \(Fmt.words(d.seconds))")
            }
        }
    }

    // MARK: Entries

    private func entries(_ a: Activity, now: Date) -> some View {
        let groups = store.entriesByDay(for: a.id, in: Store.week(containing: now), now: now)
        return VStack(spacing: 0) {
            HStack {
                Text("Entries")
                    .geist(17, .semibold, tracking: -0.01, lineHeight: 16)
                    .foregroundStyle(CH.text)
                Spacer()
                GlassPill(glyph: .plus, title: "Add") { addingEntry = true }
            }
            .padding(.bottom, 6)

            if groups.isEmpty {
                Text("No time logged this week")
                    .geist(13, .medium, lineHeight: 16)
                    .foregroundStyle(CH.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 18)
            }
            ForEach(Array(groups.enumerated()), id: \.element.id) { gi, g in
                HStack {
                    Text(Self.dayTitle(g.day.start, now: now))
                    Spacer()
                    Text(Fmt.hm(g.total)).contentTransition(.numericText())
                }
                .geist(13, .medium, lineHeight: 16)
                .foregroundStyle(CH.textSecondary)
                .padding(.top, gi == 0 ? 18 : 22)
                .padding(.bottom, 6)

                ForEach(g.sessions) { s in
                    Button { editingSession = s } label: { entryRow(s, accent: a.color.accent, now: now) }
                        .buttonStyle(.pressScale)
                }
            }
        }
    }

    private func entryRow(_ s: WorkSession, accent: Color, now: Date) -> some View {
        HStack {
            HStack(spacing: 0) {
                Text("\(Fmt.time(s.start)) → ")
                Text(s.end.map { Fmt.time($0) } ?? "now")
            }
            .geistMono(17, .regular, tracking: -0.03, lineHeight: 22)
            .foregroundStyle(Color(hex: "#C8C8C8"))
            Spacer()
            HStack(spacing: 8) {
                if s.isRunning {
                    Circle().fill(accent).frame(width: 7, height: 7)
                }
                Text(Fmt.hm(s.duration(now: now)))
                    .geistMono(17, .medium, tracking: -0.03, lineHeight: 22)
                    .foregroundStyle(Color(hex: s.isRunning ? "#C8C8C8" : "#5E5E5E"))
                    .contentTransition(.numericText())
            }
        }
        .frame(height: 52)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Edit times")
    }

    /// "Today", then weekday names ("Thursday").
    static func dayTitle(_ day: Date, now: Date) -> String {
        let cal = Calendar.chopped
        if cal.isDate(day, inSameDayAs: now) { return "Today" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.calendar = cal
        f.dateFormat = "EEEE"
        return f.string(from: day)
    }
}

// MARK: - Header

/// The accent block at the top of the detail sheet.
private struct DetailHeader: View {
    @Environment(Store.self) private var store
    let activity: Activity
    let now: Date
    var close: () -> Void
    var toggle: () -> Void

    var body: some View {
        let a = activity
        let running = store.isRunning(a.id)
        let session = running ? store.activeSession : nil
        let total = store.periodTotal(for: a, now: now)
        let elapsed = session.map { now.timeIntervalSince($0.start) } ?? 0

        VStack(spacing: 0) {
            Capsule().fill(Color.black.opacity(0.25)).frame(width: 40, height: 5)
                .padding(.top, 8)

            HStack(spacing: 12) {
                IconTile(glyph: a.glyph, size: 40, radius: 12, glyphSize: 20)
                VStack(alignment: .leading, spacing: 1) {
                    Text(a.name)
                        .geist(22, .semibold, tracking: -0.02, lineHeight: 26)
                        .foregroundStyle(CH.onAccent)
                        .lineLimit(1)
                    Text("\(a.goalLine) · resets \(Self.resetLabel(a.period))")
                        .geist(13, .medium, lineHeight: 17)
                        .foregroundStyle(CH.onAccentSecondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44, alignment: .leading)
                CircleIconButton(glyph: .close, size: 36, glyphSize: 14,
                                 background: Color.black.opacity(0.12), foreground: .black, action: close)
                    .accessibilityLabel("Close")
            }
            .padding(EdgeInsets(top: 10, leading: 20, bottom: 18, trailing: 16))

            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    HStack(spacing: 7) {
                        Circle().fill(.black).frame(width: 7, height: 7)
                            .opacity(running ? 1 : 0.35)
                        Text(running ? "Clocked in · \(Fmt.time(session?.start ?? now))"
                                     : a.period == .day ? "Today so far" : "This \(a.period.rawValue) so far")
                            .geist(13, .semibold, lineHeight: 17)
                            .foregroundStyle(Color.black.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(Fmt.hms(running ? elapsed : total))
                        .geistPixel(92, lineHeight: 90)
                        .foregroundStyle(CH.onAccent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: .infinity)
                        .contentTransition(.numericText())
                        .animation(.snappy(duration: 0.25), value: Int(running ? elapsed : total))
                }

                VStack(spacing: 10) {
                    SegmentStrip(fraction: store.progress(for: a, now: now), accent: .black,
                                 unfilled: Color.black.opacity(0.16))
                    HStack(spacing: 12) {
                        HStack(alignment: .firstTextBaseline, spacing: 5) {
                            Text(Fmt.hm(total))
                                .geistMono(15, .medium, tracking: -0.05, lineHeight: 19)
                                .foregroundStyle(CH.onAccent)
                                .contentTransition(.numericText())
                            Text("of \(Fmt.goal(minutes: a.goalMinutes))")
                                .geistMono(12, .medium, tracking: -0.02, lineHeight: 16)
                                .foregroundStyle(Color.black.opacity(0.55))
                        }
                        Spacer()
                        Text(remainingLine(a))
                            .geist(13, .medium, lineHeight: 17)
                            .foregroundStyle(Color.black.opacity(0.55))
                    }
                }

                Button(action: toggle) {
                    HStack(spacing: 10) {
                        if running {
                            RoundedRectangle(cornerRadius: 4, style: .continuous).fill(a.color.accent)
                                .frame(width: 16, height: 16)
                        } else {
                            GlyphView(.play, size: 14, color: a.color.accent)
                        }
                        Text(running ? "Stop" : "Start")
                            .geist(17, .semibold, lineHeight: 21)
                            .foregroundStyle(.white)
                            .contentTransition(.interpolate)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(.black, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
                .buttonStyle(.pressScale)
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 20)
        .background(a.color.accent,
                    in: UnevenRoundedRectangle(topLeadingRadius: 28, bottomLeadingRadius: 30,
                                               bottomTrailingRadius: 30, topTrailingRadius: 28, style: .continuous))
    }

    private func remainingLine(_ a: Activity) -> String {
        // Round up to the minute: 2:10:59 to go reads "2h 11m left".
        let left = (store.remaining(for: a, now: now) / 60).rounded(.up) * 60
        return left > 0 ? "\(Fmt.words(left)) left" : "Goal hit"
    }

    /// "Mon" for weeks, "daily"/"1st"/"Jan 1" for the others.
    static func resetLabel(_ period: GoalPeriod) -> String {
        switch period {
        case .day: "midnight"
        case .week: "Mon"
        case .month: "1st"
        case .year: "Jan 1"
        }
    }
}

// MARK: - Small shared pieces

/// Bar that grows from 0 on first appear (≤0.45s), then follows `height`.
struct GrowBar: View {
    let height: CGFloat
    let color: Color
    var radius: CGFloat = 6
    @State private var shown = AppClock.isFrozen
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(color)
            .frame(height: shown ? height : 0)
            .frame(height: height, alignment: .bottom)
            .onAppear {
                guard !shown else { return }
                if reduceMotion { shown = true } else { withAnimation(Motion.grow) { shown = true } }
            }
            .animation(reduceMotion ? nil : Motion.spring, value: height)
    }
}

/// 32pt glass capsule with a glyph + label ("+ Add").
struct GlassPill: View {
    let glyph: Glyph
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                GlyphView(glyph, size: 12, color: .white, strokeWidth: 8.0 / 3)   // 2pt at 12pt, like Paper
                Text(title)
                    .geist(13, .semibold, lineHeight: 18)
                    .foregroundStyle(Color(hex: "#CFCFCF"))
            }
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background {
                GlassSurface(shape: Capsule())   // #FFFFFF17 fill, #FFFFFF24 border, #FFFFFF2E inset top
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.pressScale)
    }
}
