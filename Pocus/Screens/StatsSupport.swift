import SwiftUI
import UIKit

// Shared building blocks for 03 Stats and 04 Tracker stats (values from Paper AL7-0 / AYR-0).

// MARK: - Colours only used on the stats pages

enum StatsColor {
    static let dim = Color(hex: "#5E5E62")        // axis labels, LAST column, inactive segments
    static let rowName = Color(hex: "#E5E5EA")    // table tracker names, "Open tracker"
    static let card = Color(hex: "#121214")       // goal cards
    static let track = Color(hex: "#161618")      // streak tracks, empty heat cells, pill button
    static let rule = Color(hex: "#151517")       // table row separators
    static let missCell = Color(hex: "#18181A")   // goal-hit miss
    static let heatLow = Color(hex: "#0E4429")
    static let heatMid = Color(hex: "#006D32")
    static let heatFuture = Color(hex: "#3A3A3C")
    static let gridFaint = Color(hex: "#1C1C1C")
    static let gridStrong = Color(hex: "#3A3A3A")
    static let nowLine = Color(hex: "#2A2A2A")
}

// MARK: - Goal maths shared by both screens

/// A tracker's goal history normalised for charts: day/week trackers use their own period,
/// month/year trackers are pro-rated to weeks (so "4w" streaks and 12 dots read the same way).
struct GoalSeries {
    let results: [GoalResult]
    /// "d" or "w".
    let unit: String

    var completed: [GoalResult] { results.filter { !$0.isCurrent } }

    /// Whether period `i` belongs to a streak: a hit, or, for daily goals, today while it's still in progress
    /// right after a hit day (a day streak isn't broken until the day is over). Weekly and pro-rated goals
    /// only count the current week once it's hit.
    func counts(_ i: Int) -> Bool {
        let r = results[i]
        if r.hit { return true }
        return unit == "d" && r.isCurrent && i > 0 && results[i - 1].hit
    }

    /// Index ranges of consecutive counting periods (see `counts`).
    var runs: [ClosedRange<Int>] {
        var out: [ClosedRange<Int>] = []
        var start: Int?, end = 0
        for i in results.indices {
            if counts(i) {
                if start == nil { start = i }
                end = i
            } else if let s = start {
                out.append(s...end); start = nil
            }
        }
        if let s = start { out.append(s...end) }
        return out
    }

    var best: Int { runs.map(\.count).max() ?? 0 }

    /// Trailing counting periods ("6d" includes today while it's still in progress).
    var current: Int {
        var n = 0
        for i in results.indices.reversed() {
            if results[i].isCurrent && !counts(i) { continue }
            if counts(i) { n += 1 } else { break }
        }
        return n
    }

    /// The run that makes up `current` (nil when the streak is 0).
    var currentRun: ClosedRange<Int>? {
        guard current > 0 else { return nil }
        return runs.last
    }
}

extension Store {
    /// Weekly equivalent of the tracker's goal (day × 7, month/year pro-rated per day × 7).
    func weeklyGoal(for a: Activity, now: Date) -> TimeInterval {
        switch a.period {
        case .day: a.goal * 7
        case .week: a.goal
        case .month, .year: dailyShare(of: a, on: now) * 7
        }
    }

    /// `count` periods of goal outcomes ending with the current one (see `GoalSeries`).
    func goalSeries(for a: Activity, count: Int, now: Date) -> GoalSeries {
        switch a.period {
        case .day, .week:
            return GoalSeries(results: goalHistory(for: a, count: count, now: now), unit: a.period == .day ? "d" : "w")
        case .month, .year:
            let goal = weeklyGoal(for: a, now: now)
            let current = Store.week(containing: now)
            let results = intervals(.week, count: count, endingAt: now).map {
                GoalResult(interval: $0, seconds: total(for: a.id, in: $0, now: now), goal: goal, isCurrent: $0 == current)
            }
            return GoalSeries(results: results, unit: "w")
        }
    }

    /// Fraction of the weekly-equivalent goal logged in `week` up to the same point in the week as `now`
    /// (e.g. Mon 00:00 → Fri 20:56), so past weeks compare like-for-like with the week in progress.
    /// Drives the "Goal % · 8 weeks" lines; the current week gives this week's share so far.
    func weekFractionToDate(for a: Activity, week: DateInterval, now: Date) -> Double {
        let g = weeklyGoal(for: a, now: now)
        guard g > 0 else { return 0 }
        let elapsed = now.timeIntervalSince(Store.week(containing: now).start)
        let span = DateInterval(start: week.start, duration: min(max(0, elapsed), week.duration))
        return total(for: a.id, in: span, now: now) / g
    }

    /// Fraction of the weekly-equivalent goal logged in `week`.
    func weekFraction(for a: Activity, week: DateInterval, now: Date) -> Double {
        let g = weeklyGoal(for: a, now: now)
        return g > 0 ? total(for: a.id, in: week, now: now) / g : 0
    }
}

extension GoalPeriod {
    /// Goal-card caption prefix: "TODAY 0:30 / 0:45", "WEEK 22:49 / 25:00".
    var captionPrefix: String { self == .day ? "TODAY" : segmentLabel }
    /// Hero label: "THIS WEEK".
    var heroLabel: String { self == .day ? "TODAY" : "THIS \(segmentLabel)" }
    var vsLabel: String {
        switch self {
        case .day: "vs yesterday"
        case .week: "vs last week"
        case .month: "vs last month"
        case .year: "vs last year"
        }
    }
}

enum StatsFmt {
    /// Deltas with a true minus sign, as in the designs ("+3:19", "−0:46").
    static func delta(_ t: TimeInterval) -> String { (t < 0 ? "\u{2212}" : "+") + Fmt.hm(abs(t)) }

    /// Week labels use the preceding Sunday, as in the designs ("OCT 11" for the week of Mon Oct 12).
    static func weekLabel(_ weekStart: Date) -> String {
        let sunday = Calendar.chopped.date(byAdding: .day, value: -1, to: weekStart) ?? weekStart
        return sunday.formatted(.dateTime.month(.abbreviated).day()).uppercased()
    }

    static func month(_ d: Date) -> String { d.formatted(.dateTime.month(.abbreviated)).uppercased() }
}

// MARK: - Small shapes

/// 7×12 row chevron (Paper `M1 1l5 5-5 5`, stroke 1.6).
struct SmallChevron: View {
    var color: Color = StatsColor.dim
    var body: some View {
        Path { p in
            p.move(to: CGPoint(x: 1, y: 1)); p.addLine(to: CGPoint(x: 6, y: 6)); p.addLine(to: CGPoint(x: 1, y: 11))
        }
        .stroke(color, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
        .frame(width: 7, height: 12)
    }
}

/// 11×18 back chevron (Paper `M9 2 2 9l7 7`, stroke 2.4).
struct BackChevron: View {
    var body: some View {
        Path { p in
            p.move(to: CGPoint(x: 9, y: 2)); p.addLine(to: CGPoint(x: 2, y: 9)); p.addLine(to: CGPoint(x: 9, y: 16))
        }
        .stroke(Color.white, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
        .frame(width: 11, height: 18)
    }
}

struct DotView: View {
    let color: Color
    var size: CGFloat = 6
    var body: some View { Circle().fill(color).frame(width: size, height: size) }
}

// MARK: - SVG-style text placement

enum TextAnchor { case start, middle, end }

extension View {
    /// Places a label like an SVG `<text x y text-anchor>` inside a `ZStack(alignment: .topLeading)`:
    /// `x` per anchor, `baseline` = y of the first baseline.
    func svgPlaced(x: CGFloat, baseline: CGFloat, anchor: TextAnchor = .start) -> some View {
        fixedSize()
            .alignmentGuide(.leading) { d in
                switch anchor {
                case .start: -x
                case .middle: -(x - d.width / 2)
                case .end: -(x - d.width)
                }
            }
            .alignmentGuide(.top) { d in -(baseline - d[.firstTextBaseline]) }
    }
}

// MARK: - Grow-in animation

/// Holds the "has appeared" flag for a chart so its bars can grow in once, with a stagger.
/// QC snapshots and Reduce Motion render the final state immediately.
struct GrowGroup<Content: View>: View {
    @State private var grown = QC.snapshot
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ViewBuilder var content: (Bool) -> Content

    var body: some View {
        content(grown || reduceMotion)
            .onAppear { if !grown { grown = true } }
    }
}

extension View {
    /// Scales from 0 along `axis` (anchored bottom / leading) until `grown`, delayed by `delay`.
    func growIn(_ grown: Bool, axis: Axis = .vertical, delay: Double = 0) -> some View {
        scaleEffect(x: axis == .horizontal && !grown ? 0.001 : 1,
                    y: axis == .vertical && !grown ? 0.001 : 1,
                    anchor: axis == .vertical ? .bottom : .leading)
            .animation(Motion.grow.delay(delay), value: grown)
    }
}

// MARK: - QC full-page render

extension View {
    /// In `-QCSnapshot -QCFullPage` runs, renders `page` at full content height (status-bar inset 62pt like the
    /// artboards) to Documents/qc-<screen>-full.png in addition to the window snapshot.
    func qcFullPage<Page: View>(_ screen: AppScreen, width: CGFloat, @ViewBuilder page: @escaping () -> Page) -> some View {
        task(id: width) {
            guard QC.fullPage, QC.snapshot, QC.screen == screen, width > 0 else { return }
            try? await Task.sleep(for: .seconds(3.0))  // after the window snapshot (1.5–2.2s)
            QC.writeFullPage(page().padding(.top, 62).frame(width: width).background(CH.bg),
                             name: "qc-\(screen.rawValue)-full.png")
        }
    }
}
