import SwiftUI

/// 03 Stats (Paper AL7-0, ref design/refs/03-stats@3x.png).
/// Root of the Stats tab's NavigationStack; goal cards push Tracker Stats (04) via `router.statsPath`.
struct StatsView: View {
    @Environment(Store.self) private var store
    @Environment(AppRouter.self) private var router
    @State private var range: StatsRange = .week

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                Ticker(every: 30) { now in
                    StatsPage(now: now, width: geo.size.width, range: $range)
                }
                .padding(.bottom, 120)
            }
            .scrollIndicators(.hidden)
            .qcFullPage(.stats, width: geo.size.width) {
                StatsPage(now: AppClock.now, width: geo.size.width, range: .constant(.week))
                    .padding(.bottom, 120)
                    .environment(store)
                    .environment(router)
            }
        }
        .background(CH.bg.ignoresSafeArea())
    }
}

// MARK: - Range (W / M / 6M / Y)

enum StatsRange: String, CaseIterable, Identifiable {
    case week = "W", month = "M", sixMonths = "6M", year = "Y"
    var id: String { rawValue }

    /// (current, previous) intervals.
    func intervals(_ store: Store, now: Date) -> (current: DateInterval, last: DateInterval) {
        let cal = Calendar.chopped
        switch self {
        case .week:
            let cur = Store.week(containing: now)
            return (cur, Store.week(containing: cur.start.addingTimeInterval(-1)))
        case .month:
            let cur = store.interval(.month, containing: now)
            return (cur, store.interval(.month, containing: cur.start.addingTimeInterval(-1)))
        case .sixMonths:
            let month = store.interval(.month, containing: now)
            let start = cal.date(byAdding: .month, value: -5, to: month.start)!
            let prev = cal.date(byAdding: .month, value: -6, to: start)!
            return (DateInterval(start: start, end: month.end), DateInterval(start: prev, end: start))
        case .year:
            let cur = store.interval(.year, containing: now)
            return (cur, store.interval(.year, containing: cur.start.addingTimeInterval(-1)))
        }
    }

    var currentLabel: String {
        switch self {
        case .week: "THIS WEEK"
        case .month: "THIS MONTH"
        case .sixMonths: "LAST 6 MONTHS"
        case .year: "THIS YEAR"
        }
    }

    var lastLabel: String {
        switch self {
        case .week: "LAST WEEK"
        case .month: "LAST MONTH"
        case .sixMonths: "PREV 6 MONTHS"
        case .year: "LAST YEAR"
        }
    }

    var vsLabel: String {
        switch self {
        case .week: "vs last week"
        case .month: "vs last month"
        case .sixMonths: "vs prev 6 months"
        case .year: "vs last year"
        }
    }

    /// Header overline: "OCT 19 – 25", "OCTOBER 2026", "MAY – OCT 2026", "2026".
    func title(_ interval: DateInterval) -> String {
        let cal = Calendar.chopped
        let start = interval.start
        let end = interval.end.addingTimeInterval(-1)
        switch self {
        case .week:
            let sameMonth = cal.component(.month, from: start) == cal.component(.month, from: end)
            let s = start.formatted(.dateTime.month(.abbreviated).day())
            let e = sameMonth ? end.formatted(.dateTime.day()) : end.formatted(.dateTime.month(.abbreviated).day())
            return "\(s) – \(e)".uppercased()
        case .month:
            return start.formatted(.dateTime.month(.wide).year()).uppercased()
        case .sixMonths:
            return "\(StatsFmt.month(start)) – \(StatsFmt.month(end)) \(end.formatted(.dateTime.year()))"
        case .year:
            return start.formatted(.dateTime.year())
        }
    }
}

// MARK: - Page

struct StatsPage: View {
    @Environment(Store.self) private var store
    let now: Date
    let width: CGFloat
    @Binding var range: StatsRange

    /// Content width inside the 20pt page margins.
    private var w: CGFloat { max(0, width - 40) }

    var body: some View {
        let (cur, last) = range.intervals(store, now: now)
        let rows = store.activities.map { a in
            TrackerRow(activity: a,
                       current: store.total(for: a.id, in: cur, now: now),
                       last: store.total(for: a.id, in: last, now: now))
        }
        VStack(alignment: .leading, spacing: 0) {
            StatsHeader(title: range.title(cur), range: $range)
                .padding(.top, 12)
            StatsHero(range: range, rows: rows)
                .padding(.top, 36)
            section(top: 36) { HoursByTracker(range: range, rows: rows, width: w, now: now) }
            section(top: 44) { WeekTrend(now: now) }
            section(top: 44) { GoalCards(now: now) }
            section(top: 48) { GoalPercentChart(width: w, now: now) }
            section(top: 48) { ConsistencyHeatmap(width: w, now: now) }
            section(top: 48) { StreakLanes(width: w, now: now) }
        }
        .frame(width: width, alignment: .leading)
    }

    private func section<C: View>(top: CGFloat, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 16) { content() }
            .padding(.horizontal, 20)
            .padding(.top, top)
    }
}

struct TrackerRow: Identifiable {
    let activity: Activity
    let current: TimeInterval
    let last: TimeInterval
    var id: Int64 { activity.id }
}

// MARK: - Header

private struct StatsHeader: View {
    let title: String
    @Binding var range: StatsRange
    @Namespace private var ns

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                SectionLabelText(title).frame(height: 14)
                Text("Stats")
                    .geist(28, .bold, tracking: -0.02, lineHeight: 34).frame(height: 34)
                    .foregroundStyle(CH.text)
            }
            Spacer(minLength: 12)
            HStack(spacing: 2) {
                ForEach(StatsRange.allCases) { r in
                    let selected = r == range
                    Button {
                        withAnimation(Motion.spring) { range = r }
                    } label: {
                        Text(r.rawValue)
                            .geistMono(12, selected ? .semibold : .medium, tracking: 0.04, lineHeight: 16).frame(height: 16)
                            .foregroundStyle(selected ? Color.white : StatsColor.dim)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background {
                                if selected {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.white.opacity(0.10))
                                        .matchedGeometryEffect(id: "range", in: ns)
                                }
                            }
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            .padding(.bottom, 2)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Hero

private struct StatsHero: View {
    let range: StatsRange
    let rows: [TrackerRow]

    var body: some View {
        let current = rows.reduce(0) { $0 + $1.current }
        let last = rows.reduce(0) { $0 + $1.last }
        let diff = current - last
        VStack(spacing: 8) {
            SectionLabelText(range.currentLabel).frame(height: 14)
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
                Text([Fmt.signedPercent(current, vs: last), range.vsLabel].compactMap { $0 }.joined(separator: " "))
                    .geistMono(12, .medium, tracking: -0.01, lineHeight: 16).frame(height: 16)
                    .foregroundStyle(CH.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
    }
}

// MARK: - Hours by tracker

private struct HoursByTracker: View {
    @Environment(Store.self) private var store
    let range: StatsRange
    let rows: [TrackerRow]
    let width: CGFloat
    let now: Date

    var body: some View {
        let current = rows.reduce(0) { $0 + $1.current }
        let last = rows.reduce(0) { $0 + $1.last }
        let onPace = store.activities.filter { store.isOnPace($0, now: now) }.count
        SectionLabel("Hours by tracker", value: "\(onPace)/\(store.activities.count) on pace").frame(height: 16)
        GrowGroup { grown in
            VStack(alignment: .leading, spacing: 6) {
                splitBar(rows.map { ($0.activity.color.accent, $0.current) }, scale: max(current, last), height: 10, grown: grown)
                labelRow(range.currentLabel, Fmt.hm(current), labelColor: CH.textTertiary, valueColor: CH.textMuted)
                Color.clear.frame(height: 4)
                splitBar(rows.map { ($0.activity.color.accent.opacity(0x52 / 255), $0.last) }, scale: max(current, last), height: 6, grown: grown)
                labelRow(range.lastLabel, Fmt.hm(last), labelColor: StatsColor.dim, valueColor: CH.textTertiary)
            }
        }
        table(current: current, last: last)
    }

    /// Flex row of segments: widths are shares of `scale`; shrinks to fit when the 2pt gaps overflow (CSS flex).
    private func splitBar(_ parts: [(Color, TimeInterval)], scale: TimeInterval, height: CGFloat, grown: Bool) -> some View {
        let visible = parts.filter { $0.1 > 0 }
        let gaps = CGFloat(max(0, visible.count - 1)) * 2
        let raw = visible.map { scale > 0 ? CGFloat($0.1 / scale) * width : 0 }
        let sum = raw.reduce(0, +)
        let k = sum + gaps > width && sum > 0 ? (width - gaps) / sum : 1
        return HStack(spacing: 2) {
            ForEach(Array(visible.enumerated()), id: \.offset) { i, part in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(part.0)
                    .frame(width: raw[i] * k, height: height)
                    .growIn(grown, axis: .horizontal, delay: Double(i) * 0.05)
            }
        }
        .frame(height: height)
    }

    private func labelRow(_ label: String, _ value: String, labelColor: Color, valueColor: Color) -> some View {
        HStack(spacing: 12) {
            Text(label).geistMono(9, .medium, tracking: 0.08, lineHeight: 13).frame(height: 13).foregroundStyle(labelColor)
            Spacer(minLength: 0)
            Text(value).geistMono(11, .medium, tracking: -0.01, lineHeight: 15).frame(height: 15).foregroundStyle(valueColor)
                .contentTransition(.numericText())
        }
    }

    private func table(current: TimeInterval, last: TimeInterval) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                head("TRACKER").frame(maxWidth: .infinity, alignment: .leading)
                head("NOW").frame(width: 60, alignment: .trailing)
                head("LAST").frame(width: 56, alignment: .trailing)
                // Geist Mono has no Δ; Paper falls back to the system font (SF), so render it in SF explicitly,
                // with the CSS letter-spacing (0.08em) trailing it like the other header labels.
                Text("Δ").font(.system(size: 9, weight: .medium)).tracking(0.72).padding(.trailing, 0.67).foregroundStyle(StatsColor.dim)
                    .frame(height: 13).frame(width: 58, alignment: .trailing)
            }
            .padding(.bottom, 8)
            .overlay(alignment: .bottom) { CH.raised.frame(height: 1).offset(y: 1) }
            .padding(.bottom, 1)

            ForEach(rows) { r in
                HStack(spacing: 0) {
                    HStack(spacing: 10) {
                        DotView(color: r.activity.color.accent)
                        Text(r.activity.name)
                            .geist(14, .medium, lineHeight: 18).frame(height: 18)
                            .foregroundStyle(StatsColor.rowName)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    cell(Fmt.hm(r.current), width: 60, color: CH.text)
                    cell(Fmt.hm(r.last), width: 56, color: StatsColor.dim)
                    delta(r.current - r.last)
                }
                .frame(height: 43)
                .overlay(alignment: .bottom) { StatsColor.rule.frame(height: 1).offset(y: 1) }
                .padding(.bottom, 1)
            }

            HStack(spacing: 0) {
                Text("TOTAL").geistMono(10, .medium, tracking: 0.08, lineHeight: 14).frame(height: 14).foregroundStyle(CH.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                cell(Fmt.hm(current), width: 60, color: .white)
                cell(Fmt.hm(last), width: 56, color: StatsColor.dim)
                delta(current - last)
            }
            .frame(height: 44)
        }
    }

    private func head(_ s: String) -> some View {
        Text(s).geistMono(9, .medium, tracking: 0.08, lineHeight: 13).frame(height: 13).foregroundStyle(StatsColor.dim)
    }

    private func cell(_ s: String, width: CGFloat, color: Color) -> some View {
        Text(s).geistMono(14, .medium, tracking: -0.01, lineHeight: 18).frame(height: 18).foregroundStyle(color)
            .contentTransition(.numericText())
            .frame(width: width, alignment: .trailing)
    }

    private func delta(_ d: TimeInterval) -> some View {
        Text(StatsFmt.delta(d)).geistMono(12, .medium, tracking: -0.01, lineHeight: 16).frame(height: 16)
            .foregroundStyle(d > 0 ? CH.up : CH.textSecondary)
            .contentTransition(.numericText())
            .frame(width: 58, alignment: .trailing)
    }
}

// MARK: - 8-week trend

private struct WeekTrend: View {
    @Environment(Store.self) private var store
    let now: Date

    var body: some View {
        let weeks = store.periodTotals(period: .week, count: 8, now: now)
        let avg = weeks.isEmpty ? 0 : weeks.reduce(0) { $0 + $1.seconds } / Double(weeks.count)
        let maxV = weeks.map(\.seconds).max() ?? 0
        SectionLabel("8-week trend", value: "avg \(Fmt.hm(avg))").frame(height: 16)
        GrowGroup { grown in
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(weeks.enumerated()), id: \.offset) { i, wk in
                    let isNow = i == weeks.count - 1
                    VStack(spacing: 6) {
                        if isNow {
                            Text(Fmt.hm(wk.seconds))
                                .geistMono(10, .medium, tracking: -0.01, lineHeight: 14).frame(height: 14)
                                .foregroundStyle(.white)
                                .contentTransition(.numericText())
                                .opacity(grown ? 1 : 0)
                                .animation(Motion.grow.delay(0.3), value: grown)
                        }
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(isNow ? CH.text : CH.past)
                            .frame(height: maxV > 0 ? (wk.seconds / maxV * 96).rounded() : 0)
                            .growIn(grown, delay: Double(i) * 0.03)
                        Text(isNow ? "NOW" : StatsFmt.weekLabel(wk.start))
                            .geistMono(9, isNow ? .semibold : .medium, tracking: 0.02, lineHeight: 13).frame(height: 13)
                            .foregroundStyle(isNow ? Color.white : StatsColor.dim)
                            .lineLimit(1)
                            .fixedSize()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - Goals

private struct GoalCards: View {
    @Environment(Store.self) private var store
    @Environment(AppRouter.self) private var router
    let now: Date

    var body: some View {
        let list = store.activities
        SectionLabel(title: "Goals") { SectionValueText("tap for detail", color: StatsColor.dim) }.frame(height: 16)
        VStack(spacing: 12) {
            ForEach(Array(stride(from: 0, to: list.count, by: 2)), id: \.self) { i in
                HStack(spacing: 12) {
                    card(list[i])
                    if i + 1 < list.count { card(list[i + 1]) }
                }
            }
        }
    }

    private func card(_ a: Activity) -> some View {
        Button { router.statsPath.append(a.id) } label: {
            GoalCard(activity: a, now: now)
        }
        .buttonStyle(.pressScale)
        .accessibilityHint("Shows \(a.name) stats")
    }
}

private struct GoalCard: View {
    @Environment(Store.self) private var store
    let activity: Activity
    let now: Date

    var body: some View {
        let a = activity
        let accent = a.color.accent
        let progress = store.progress(for: a, now: now)
        let series = store.goalSeries(for: a, count: 12, now: now)
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    DotView(color: accent, size: 7)
                    Text(a.name).geist(13, .semibold, lineHeight: 17).frame(height: 17).foregroundStyle(CH.textMuted).lineLimit(1)
                }
                Spacer(minLength: 0)
                SmallChevron()
            }
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(Fmt.percent(progress))
                    .geistMono(24, .medium, tracking: -0.04, lineHeight: 28).frame(height: 28)
                    .foregroundStyle(CH.text)
                    .contentTransition(.numericText())
                Spacer(minLength: 0)
                Text("\(series.current)\(series.unit)")
                    .geistMono(11, .medium, lineHeight: 15).frame(height: 15)
                    .foregroundStyle(accent)
            }
            GrowGroup { grown in
                Capsule().fill(accent.opacity(0x2E / 255))
                    .frame(height: 4)
                    .overlay(alignment: .leading) {
                        GeometryReader { g in
                            Capsule().fill(accent)
                                .frame(width: (g.size.width * min(1, (progress * 100).rounded() / 100)).rounded())
                                .growIn(grown, axis: .horizontal)
                        }
                    }
            }
            Text("\(a.period.captionPrefix) \(Fmt.hm(store.periodTotal(for: a, now: now))) / \(Fmt.hm(a.goal))")
                .geistMono(9, .medium, tracking: 0.04, lineHeight: 13).frame(height: 13)
                .foregroundStyle(CH.textTertiary)
                .lineLimit(1)
            HStack(spacing: 4) {
                ForEach(series.results) { r in
                    if r.isCurrent {
                        Circle()
                            .strokeBorder(accent, style: StrokeStyle(lineWidth: 1.5, dash: [2.0, 1.53]))
                            .frame(width: 6, height: 6)
                    } else {
                        DotView(color: r.hit ? accent : accent.opacity(0x2E / 255))
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(StatsColor.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

// MARK: - Goal % line chart

private struct GoalPercentChart: View {
    @Environment(Store.self) private var store
    let width: CGFloat
    let now: Date

    private struct Line: Identifiable {
        let activity: Activity
        let values: [Double]
        var id: Int64 { activity.id }
        var current: Double { values.last ?? 0 }
    }

    private let height: CGFloat = 184

    var body: some View {
        let weeks = store.intervals(.week, count: 8, endingAt: now)
        let thisWeek = Store.week(containing: now)
        let lines: [Line] = store.activities
            .filter { store.weeklyGoal(for: $0, now: now) > 0 }
            .map { ($0, store.total(for: $0.id, in: thisWeek, now: now)) }
            .sorted { $0.1 > $1.1 }
            .prefix(3)
            .sorted { store.weekFraction(for: $0.0, week: thisWeek, now: now) > store.weekFraction(for: $1.0, week: thisWeek, now: now) }
            .map { a, _ in
                Line(activity: a, values: weeks.enumerated().map { i, wk in
                    if i == weeks.count - 1, a.period == .day || a.period == .week { return store.progress(for: a, now: now) }
                    return store.weekFraction(for: a, week: wk, now: now)
                })
            }
        let best = lines.max { $0.current < $1.current }
        let plotRight = width - 38
        let step = (width - 50) / 7
        let xs = (0..<8).map { 6 + CGFloat($0) * step }

        SectionLabel("Goal % · 8 weeks", value: best.map { "\($0.activity.name) \(Fmt.percent($0.current)) · best" }).frame(height: 16)
        GrowGroup { grown in
            ZStack(alignment: .topLeading) {
                ForEach([(0.5, false), (0.75, false), (1.0, true)], id: \.0) { p, strong in
                    let y = Self.y(p)
                    Path { $0.move(to: CGPoint(x: 0, y: y)); $0.addLine(to: CGPoint(x: plotRight, y: y)) }
                        .stroke(strong ? StatsColor.gridStrong : StatsColor.gridFaint,
                                style: StrokeStyle(lineWidth: 1, dash: strong ? [4, 4] : [2, 4]))
                    axisText("\(Int(p * 100))%").svgPlaced(x: width - 32, baseline: y + 4)
                }
                ForEach(lines.filter { $0.id != best?.id }.reversed()) { l in
                    curve(l.values, xs: xs).trim(from: 0, to: grown ? 1 : 0)
                        .stroke(l.activity.color.accent.opacity(0.7), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                        .animation(.easeOut(duration: 0.5).delay(0.05), value: grown)
                }
                if let best {
                    curve(best.values, xs: xs).trim(from: 0, to: grown ? 1 : 0)
                        .stroke(best.activity.color.accent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .animation(.easeOut(duration: 0.5), value: grown)
                }
                Path { $0.move(to: CGPoint(x: xs[7], y: 10)); $0.addLine(to: CGPoint(x: xs[7], y: 150)) }
                    .stroke(StatsColor.nowLine, lineWidth: 1)
                ForEach(([best].compactMap { $0 } + lines.filter { $0.id != best?.id })) { l in
                    let r: CGFloat = l.id == best?.id ? 5 : 3.5
                    ZStack {
                        Circle().fill(Color.black).frame(width: 2 * r + 2, height: 2 * r + 2)
                        Circle().fill(l.activity.color.accent).frame(width: 2 * r - 2, height: 2 * r - 2)
                    }
                    .position(x: xs[7], y: Self.y(l.current))
                    .opacity(grown ? 1 : 0)
                    .animation(Motion.grow.delay(0.4), value: grown)
                }
                ForEach([0, 2, 4, 6], id: \.self) { i in
                    axisText(StatsFmt.weekLabel(weeks[i].start))
                        .svgPlaced(x: i == 0 ? 0 : (i == 6 ? xs[i] - 6 : xs[i]), baseline: 170, anchor: i == 0 ? .start : .middle)
                }
                Text("NOW").font(.geistMono(9, .semibold)).foregroundStyle(CH.textMuted)
                    .svgPlaced(x: xs[7], baseline: 170, anchor: .middle)
            }
            .frame(width: width, height: height, alignment: .topLeading)
        }
        HStack(spacing: 16) {
            ForEach(lines) { l in
                HStack(spacing: 6) {
                    DotView(color: l.activity.color.accent)
                    Text(l.activity.name).geist(11, .medium, lineHeight: 15).frame(height: 15).foregroundStyle(CH.textSecondary)
                }
            }
        }
    }

    /// 100% at y 30, 50% at y 130 (Paper), clamped inside the plot.
    static func y(_ p: Double) -> CGFloat { min(154, max(6, 130 - CGFloat(p - 0.5) * 200)) }

    private func axisText(_ s: String) -> some View {
        Text(s).font(.geistMono(9, .regular)).foregroundStyle(StatsColor.dim)
    }

    /// Smooth curve with horizontal tangents at each point (as in the design).
    private func curve(_ values: [Double], xs: [CGFloat]) -> Path {
        Path { p in
            for (i, v) in values.enumerated() {
                let pt = CGPoint(x: xs[i], y: Self.y(v))
                if i == 0 { p.move(to: pt); continue }
                let prev = CGPoint(x: xs[i - 1], y: Self.y(values[i - 1]))
                let mid = (prev.x + pt.x) / 2
                p.addCurve(to: pt, control1: CGPoint(x: mid, y: prev.y), control2: CGPoint(x: mid, y: pt.y))
            }
        }
    }
}

// MARK: - Consistency heatmap

private struct ConsistencyHeatmap: View {
    @Environment(Store.self) private var store
    let width: CGFloat
    let now: Date

    private let left: CGFloat = 22, top: CGFloat = 14, gap: CGFloat = 4

    var body: some View {
        let cal = Calendar.chopped
        let today = Store.day(containing: now).start
        let weekday = cal.component(.weekday, from: today)            // 1 = Sunday
        let lastSunday = cal.date(byAdding: .day, value: -(weekday - 1), to: today)!
        let firstSunday = cal.date(byAdding: .day, value: -77, to: lastSunday)!
        let dayCount = (cal.dateComponents([.day], from: firstSunday, to: today).day ?? 0) + 1
        let scores = store.dayScores(days: dayCount, now: now)
        let cell = (width - left - 11 * gap) / 12
        let pitch = cell + gap
        let sundays = (0..<12).map { cal.date(byAdding: .day, value: 7 * $0, to: firstSunday)! }
        let monthCols = (0..<12).filter { c in
            c == 0 || cal.component(.month, from: sundays[c]) != cal.component(.month, from: sundays[c - 1])
        }.filter { c in c == 0 || c >= 2 }

        SectionLabel("Consistency", value: "\(scores.filter(\.isPerfect).count) perfect days").frame(height: 16)
        GrowGroup { grown in
            ZStack(alignment: .topLeading) {
                ForEach(monthCols, id: \.self) { c in
                    Text(StatsFmt.month(sundays[c])).font(.geistMono(9, .regular)).tracking(0.6)
                        .foregroundStyle(StatsColor.dim)
                        .svgPlaced(x: left + CGFloat(c) * pitch, baseline: 9)
                }
                ForEach([(1, "M"), (3, "W"), (5, "F")], id: \.0) { r, s in
                    Text(s).font(.geistMono(9, .regular)).foregroundStyle(StatsColor.dim)
                        .svgPlaced(x: 0, baseline: top + CGFloat(r) * pitch + cell / 2 + 3)
                }
                ForEach(0..<84, id: \.self) { i in
                    let c = i / 7, r = i % 7
                    let shape = RoundedRectangle(cornerRadius: 5, style: .continuous)
                    Group {
                        if i < scores.count {
                            shape.fill(color(scores[i].score))
                        } else {
                            shape.strokeBorder(StatsColor.heatFuture, style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                        }
                    }
                    .frame(width: cell, height: cell)
                    .opacity(grown ? 1 : 0)
                    .scaleEffect(grown ? 1 : 0.6)
                    .animation(Motion.grow.delay(Double(c) * 0.025), value: grown)
                    .offset(x: left + CGFloat(c) * pitch, y: top + CGFloat(r) * pitch)
                }
            }
            .frame(width: width, height: (top + 7 * cell + 6 * gap + 3.2).rounded(), alignment: .topLeading)
        }
    }

    private func color(_ score: Double) -> Color {
        switch DayScore.level(score) {
        case 3: CH.up
        case 2: StatsColor.heatMid
        case 1: StatsColor.heatLow
        default: StatsColor.track
        }
    }
}

// MARK: - Streak lanes

private struct StreakLanes: View {
    @Environment(Store.self) private var store
    let width: CGFloat
    let now: Date

    private struct Lane: Identifiable {
        let activity: Activity
        let series: GoalSeries
        var id: Int64 { activity.id }
    }

    var body: some View {
        // Every lane shares one axis: the 12 calendar weeks ending with this one (Mon → Sun, 84 day slots).
        // Daily lanes run from that Monday through today; weekly lanes have one slot per week.
        let start = store.intervals(.week, count: 12, endingAt: now)[0].start
        let elapsedDays = (Calendar.chopped.dateComponents([.day], from: start, to: Store.day(containing: now).start).day ?? 0) + 1
        let lanes = store.activities
            .map { a in Lane(activity: a, series: store.goalSeries(for: a, count: a.period == .day ? elapsedDays : 12, now: now)) }
            .enumerated()
            .sorted { l, r in
                let ld = l.element.activity.period == .day, rd = r.element.activity.period == .day
                if ld != rd { return ld }
                return l.offset < r.offset
            }
            .map(\.element)
        let trackX: CGFloat = 78
        let trackW = max(0, width - 112)

        // Paper renders the → ~1.67pt wider on each side than Geist Mono's cell; match it.
        HStack(spacing: 0) {
            SectionLabelText("Streaks · \(StatsFmt.month(start))").padding(.trailing, 7.48)
            SectionLabelText("→").padding(.horizontal, 1.67)
            SectionLabelText("now").padding(.leading, 7.48)
            Spacer(minLength: 12)
            SectionValueText("longest")
        }
        .frame(height: 16)
        .accessibilityElement(children: .combine)
        GrowGroup { grown in
            VStack(spacing: 0) {
                ForEach(Array(lanes.enumerated()), id: \.element.id) { li, lane in
                    let accent = lane.activity.color.accent
                    let unit = trackW / (lane.series.unit == "d" ? 84 : 12)
                    let runs = lane.series.runs
                    let bestRun = runs.enumerated().max { a, b in
                        a.element.count != b.element.count ? a.element.count < b.element.count : a.offset < b.offset
                    }?.offset
                    ZStack(alignment: .topLeading) {
                        Text(lane.activity.name.uppercased())
                            .font(.geistMono(9, .regular)).tracking(0.5)
                            .foregroundStyle(CH.textTertiary)
                            .lineLimit(1)
                            .frame(width: trackX - 4, alignment: .leading)
                            .svgPlaced(x: 0, baseline: 17.5)
                        Capsule().fill(StatsColor.track)
                            .frame(width: trackW, height: 8)
                            .offset(x: trackX, y: 10)
                        ForEach(Array(runs.enumerated()), id: \.offset) { ri, run in
                            let w = max(3, CGFloat(run.count) * unit - 1.2)
                            RoundedRectangle(cornerRadius: min(4, w / 2), style: .continuous)
                                .fill(ri == bestRun ? accent : accent.opacity(0.45))
                                .frame(width: w, height: 8)
                                .growIn(grown, axis: .horizontal, delay: Double(li) * 0.05)
                                .offset(x: trackX + CGFloat(run.lowerBound) * unit, y: 10)
                        }
                        Text("\(lane.series.best)\(lane.series.unit)")
                            .font(.geistMono(11, .regular))
                            .foregroundStyle(CH.textMuted)
                            .svgPlaced(x: width, baseline: 17.5, anchor: .end)
                    }
                    .frame(width: width, height: 28, alignment: .topLeading)
                }
            }
        }
    }
}
