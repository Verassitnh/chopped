import SwiftUI

/// 04 Tracker stats (Paper AYR-0, ref design/refs/04-tracker-stats@3x.png): full page pushed on the Stats stack.
struct TrackerStatsView: View {
    @Environment(Store.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    let activityID: Int64

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                Ticker(every: 30) { now in
                    TrackerStatsPage(activityID: activityID, now: now, width: geo.size.width) { dismiss() }
                }
            }
            .scrollIndicators(.hidden)
            .qcFullPage(.trackerStats, width: geo.size.width) {
                TrackerStatsPage(activityID: activityID, now: AppClock.now, width: geo.size.width) {}
                    .environment(store)
                    .environment(router)
            }
        }
        .background(CH.bg.ignoresSafeArea())
    }
}

struct TrackerStatsPage: View {
    @Environment(Store.self) private var store
    @Environment(AppRouter.self) private var router
    let activityID: Int64
    let now: Date
    let width: CGFloat
    var back: () -> Void

    private var w: CGFloat { max(0, width - 40) }

    var body: some View {
        if let a = store.activity(activityID) {
            VStack(alignment: .leading, spacing: 0) {
                nav(a)
                TrackerHero(activity: a, now: now)
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                section(top: 36) { LastWeeksChart(activity: a, now: now) }
                section(top: 44) { DayBars(activity: a, now: now) }
                section(top: 44) { GoalHitRow(activity: a, now: now) }
                section(top: 44) { StreakBar(activity: a, width: w, now: now) }
                section(top: 44) { SessionNumbers(activity: a, now: now) }
                Button { router.openDetail(a.id) } label: {
                    HStack(spacing: 8) {
                        Text("Open tracker").geist(14, .semibold, lineHeight: 18).frame(height: 18).foregroundStyle(StatsColor.rowName)
                        SmallChevron()
                    }
                    .padding(.horizontal, 18)
                    .frame(height: 44)
                    .background(StatsColor.track, in: Capsule())
                    .contentShape(Capsule())
                }
                .buttonStyle(.pressScale)
                .frame(maxWidth: .infinity)
                .padding(.top, 36)
                .padding(.bottom, 48)
            }
            .frame(width: width, alignment: .leading)
        } else {
            Color.clear.frame(width: width, height: 1)
        }
    }

    /// Back circle · centred icon + name + goal line · 44pt spacer (H1-style).
    private func nav(_ a: Activity) -> some View {
        HStack(spacing: 0) {
            Button(action: back) {
                Circle().fill(Color.white.opacity(0x14 / 255))
                    .frame(width: 44, height: 44)
                    .overlay { BackChevron() }
                    .contentShape(Circle())
            }
            .buttonStyle(.pressScale)
            .accessibilityLabel("Back")
            VStack(spacing: 1) {
                HStack(spacing: 8) {
                    IconTile(glyph: a.glyph, size: 22, radius: 7, glyphSize: 12,
                             foreground: a.color.accent, background: a.color.accent.opacity(0x29 / 255))
                    Text(a.name).geist(17, .semibold, tracking: -0.01, lineHeight: 22).frame(height: 22).foregroundStyle(CH.text).lineLimit(1)
                }
                Text(a.goalLine).geist(12, .medium, lineHeight: 16).frame(height: 16).foregroundStyle(CH.textTertiary)
            }
            .frame(maxWidth: .infinity)
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    private func section<C: View>(top: CGFloat, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 16) { content() }
            .padding(.horizontal, 20)
            .padding(.top, top)
    }
}

// MARK: - Hero

private struct TrackerHero: View {
    @Environment(Store.self) private var store
    let activity: Activity
    let now: Date

    var body: some View {
        let a = activity
        let period = store.currentPeriod(for: a, now: now)
        let previous = store.interval(a.period, containing: period.start.addingTimeInterval(-1))
        let current = store.periodTotal(for: a, now: now)
        let last = store.total(for: a.id, in: previous, now: now)
        let diff = current - last
        let progress = store.progress(for: a, now: now)
        VStack(spacing: 8) {
            SectionLabelText(a.period.heroLabel).frame(height: 14)
            Text(Fmt.hm(current))
                .geistPixel(112).frame(height: 112)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .contentTransition(.numericText(value: current))
                .animation(.snappy, value: current)
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("\(diff < 0 ? "↓" : "↑") \(Fmt.hm(abs(diff)))")
                    .geistMono(14, .medium, tracking: -0.01, lineHeight: 18).frame(height: 18)
                    .foregroundStyle(diff < 0 ? CH.textSecondary : CH.up)
                    .contentTransition(.numericText(value: diff))
                Text([Fmt.signedPercent(current, vs: last), a.period.vsLabel].compactMap { $0 }.joined(separator: " "))
                    .geistMono(12, .medium, tracking: -0.01, lineHeight: 16).frame(height: 16)
                    .foregroundStyle(CH.textTertiary)
            }
            VStack(spacing: 8) {
                GrowGroup { grown in
                    Capsule().fill(CH.raised)
                        .frame(height: 8)
                        .overlay(alignment: .leading) {
                            GeometryReader { g in
                                Capsule().fill(StatsColor.rowName)
                                    .frame(width: (g.size.width * min(1, (progress * 100).rounded() / 100)).rounded())
                                    .growIn(grown, axis: .horizontal)
                            }
                        }
                }
                HStack {
                    caption("\(Fmt.percent(progress)) OF \(Fmt.hm(a.goal))")
                    Spacer(minLength: 8)
                    caption(progress >= 1 ? "GOAL HIT" : "\(Fmt.words((store.remaining(for: a, now: now) / 60).rounded(.up) * 60).uppercased()) LEFT")
                }
            }
            .padding(.top, 12)
        }
        .frame(maxWidth: .infinity)
    }

    private func caption(_ s: String) -> some View {
        Text(s).geistMono(9, .medium, tracking: 0.06, lineHeight: 13).frame(height: 13).foregroundStyle(CH.textTertiary)
            .contentTransition(.numericText())
    }
}

// MARK: - Last 8 weeks

private struct LastWeeksChart: View {
    @Environment(Store.self) private var store
    let activity: Activity
    let now: Date

    var body: some View {
        let a = activity
        let weeks = store.periodTotals(for: a.id, period: .week, count: 8, now: now)
        let goal = store.weeklyGoal(for: a, now: now)
        // Same average as the Stats "8-week trend" (all 8 weeks, this one included).
        let avg = weeks.isEmpty ? 0 : weeks.reduce(0) { $0 + $1.seconds } / Double(weeks.count)
        let vsAvg = Fmt.signedPercent(weeks.last?.seconds ?? 0, vs: avg).map { "\($0) vs avg" }
        // 100pt = the taller of the goal and the best week; the dashed goal line sits at the goal's height.
        let scale = max(goal, weeks.map(\.seconds).max() ?? 0)
        let goalLineY: CGFloat = scale > 0 ? 101 - (goal / scale * 100).rounded() : 1
        SectionLabel("Last 8 weeks", value: vsAvg).frame(height: 16)
        GrowGroup { grown in
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(weeks.enumerated()), id: \.offset) { i, wk in
                    let isNow = i == weeks.count - 1
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(isNow ? a.color.accent : CH.past)
                            .frame(height: scale > 0 ? (wk.seconds / scale * 100).rounded() : 0)
                            .growIn(grown, delay: Double(i) * 0.03)
                        Text(isNow ? "NOW" : StatsFmt.weekLabel(wk.start))
                            .geistMono(8, isNow ? .semibold : .medium, lineHeight: 12).frame(height: 12)
                            .foregroundStyle(isNow ? Color.white : StatsColor.dim)
                            .lineLimit(1)
                            .fixedSize()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 119, alignment: .bottom)
            .overlay(alignment: .top) {
                Line().stroke(Color.white.opacity(0x47 / 255), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .frame(height: 1)
                    .offset(y: goalLineY - 1)
            }
            .overlay(alignment: .topTrailing) {
                Text("GOAL \(Fmt.words(goal).uppercased())")
                    .geistMono(8, .medium, tracking: 0.06, lineHeight: 12).frame(height: 12)
                    .foregroundStyle(CH.textTertiary)
                    .offset(y: goalLineY - 1 - 16)
            }
        }
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            Path { $0.move(to: CGPoint(x: rect.minX, y: rect.midY)); $0.addLine(to: CGPoint(x: rect.maxX, y: rect.midY)) }
        }
    }
}

// MARK: - This week's days

private struct DayBars: View {
    @Environment(Store.self) private var store
    let activity: Activity
    let now: Date

    var body: some View {
        let days = store.thisWeekDays(for: activity.id, now: now)
        let today = Store.day(containing: now)
        let elapsed = days.filter { $0.start <= today.start }.count
        let total = days.reduce(0) { $0 + $1.seconds }
        let maxV = days.map(\.seconds).max() ?? 0
        SectionLabel("This week", value: "avg \(Fmt.hm(elapsed > 0 ? (total / Double(elapsed) / 60).rounded() * 60 : 0)) / day").frame(height: 16)
        GrowGroup { grown in
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(days.enumerated()), id: \.offset) { i, d in
                    let isToday = d.interval == today
                    let empty = d.seconds < 60
                    VStack(spacing: 6) {
                        Text(empty ? "–" : Fmt.hm(d.seconds))
                            .geistMono(9, .medium, lineHeight: 13).frame(height: 13)
                            .foregroundStyle(isToday && !empty ? Color.white : StatsColor.dim)
                            .fixedSize()
                        Group {
                            if empty {
                                RoundedRectangle(cornerRadius: 2, style: .continuous).fill(CH.raised).frame(height: 3)
                            } else {
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(isToday ? activity.color.accent : CH.past)
                                    .frame(height: maxV > 0 ? (d.seconds / maxV * 64).rounded() : 0)
                            }
                        }
                        .growIn(grown, delay: Double(i) * 0.04)
                        Text(d.start.formatted(.dateTime.weekday(.narrow)))
                            .geistMono(10, .medium, lineHeight: 14).frame(height: 14)
                            .foregroundStyle(isToday ? Color.white : CH.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - Goal hit

private struct GoalHitRow: View {
    @Environment(Store.self) private var store
    let activity: Activity
    let now: Date

    var body: some View {
        let series = store.goalSeries(for: activity, count: 12, now: now)
        let done = series.completed
        let hits = done.filter(\.hit).count
        let pct = done.isEmpty ? "" : " · " + Fmt.percent(Double(hits) / Double(done.count))
        SectionLabel("Goal hit · 12 \(series.unit == "d" ? "days" : "weeks")", value: "\(hits)/\(done.count)\(pct)").frame(height: 16)
        GrowGroup { grown in
            HStack(spacing: 4) {
                ForEach(Array(series.results.enumerated()), id: \.offset) { i, r in
                    let shape = RoundedRectangle(cornerRadius: 3, style: .continuous)
                    Group {
                        if r.isCurrent {
                            shape.strokeBorder(StatsColor.dim, style: StrokeStyle(lineWidth: 1.5, dash: [4, 2.5]))
                        } else {
                            shape.fill(r.hit ? CH.pastLight : StatsColor.missCell)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 18)
                    .opacity(grown ? 1 : 0)
                    .animation(Motion.grow.delay(Double(i) * 0.025), value: grown)
                }
            }
        }
    }
}

// MARK: - Streak

private struct StreakBar: View {
    @Environment(Store.self) private var store
    let activity: Activity
    let width: CGFloat
    let now: Date

    var body: some View {
        let series = store.goalSeries(for: activity, count: 12, now: now)
        let unitW = width / CGFloat(max(1, series.results.count))
        let currentRun = series.currentRun
        SectionLabel("Streak", value: "current \(series.current)\(series.unit) · best \(series.best)\(series.unit)").frame(height: 16)
        GrowGroup { grown in
            ZStack(alignment: .topLeading) {
                Capsule().fill(StatsColor.track).frame(width: width, height: 10)
                ForEach(Array(series.runs.enumerated()), id: \.offset) { i, run in
                    Capsule()
                        .fill(run == currentRun ? activity.color.accent : CH.pastMid)
                        .frame(width: max(4, (CGFloat(run.count) * unitW - 4).rounded()), height: 10)
                        .growIn(grown, axis: .horizontal, delay: Double(i) * 0.06)
                        .offset(x: CGFloat(run.lowerBound) * unitW)
                }
            }
            .frame(width: width, height: 10, alignment: .topLeading)
        }
    }
}

// MARK: - Session numbers

private struct SessionNumbers: View {
    @Environment(Store.self) private var store
    let activity: Activity
    let now: Date

    var body: some View {
        let s = store.sessionStats(for: activity.id, in: Store.week(containing: now), now: now)
        SectionLabelText("This week").frame(height: 14)
        HStack(alignment: .top) {
            stat("\(s.count)", "sessions")
            Spacer(minLength: 8)
            stat(Fmt.hm(s.average), "avg session")
            Spacer(minLength: 8)
            stat(Fmt.hm(s.longest), "longest")
            Spacer(minLength: 8)
            stat(s.bestDay.map { $0.formatted(.dateTime.weekday(.abbreviated)).uppercased() } ?? "–", "best day")
        }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).geistMono(18, .medium, tracking: -0.02, lineHeight: 22).frame(height: 22).foregroundStyle(CH.text)
                .contentTransition(.numericText())
            Text(label).geist(11, .medium, lineHeight: 15).frame(height: 15).foregroundStyle(CH.textTertiary)
        }
    }
}
