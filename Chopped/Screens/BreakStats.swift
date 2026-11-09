import SwiftUI

struct BreaksSection: View {
    @Environment(Store.self) private var store
    let range: StatsRange
    let width: CGFloat
    let now: Date
    @State private var byTracker = false

    var body: some View {
        let (cur, last) = range.intervals(store, now: now)
        let total = store.breakTotal(in: cur, now: now)
        let lastTotal = store.breakTotal(in: last, now: now)
        let count = store.breakCount(in: cur)
        let work = store.total(in: cur, now: now)
        HStack(spacing: 12) {
            SectionLabelText("Breaks")
            Spacer(minLength: 0)
            modePicker
        }
        .frame(height: 24)
        if count == 0 {
            Text("No breaks \(range.currentLabel.lowercased()). Take one from a running tracker.")
                .geist(13, .medium, lineHeight: 17)
                .foregroundStyle(CH.textTertiary)
        } else if byTracker {
            perTracker(store.breakTotals(in: cur, now: now))
        } else {
            aggregate(total: total, last: lastTotal, count: count, work: work)
        }
    }

    private var modePicker: some View {
        HStack(spacing: 2) {
            option("ALL", selected: !byTracker) { byTracker = false }
            option("BY TRACKER", selected: byTracker) { byTracker = true }
        }
    }

    private func option(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button { withAnimation(Motion.spring, action) } label: {
            Text(title)
                .geistMono(10, selected ? .semibold : .medium, tracking: 0.06, lineHeight: 14)
                .foregroundStyle(selected ? Color.white : StatsColor.dim)
                .padding(.vertical, 5)
                .padding(.horizontal, 9)
                .background {
                    if selected {
                        RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.white.opacity(0.10))
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.pressScale)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func aggregate(total: TimeInterval, last: TimeInterval, count: Int, work: TimeInterval) -> some View {
        let diff = total - last
        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(Fmt.hm(total))
                    .geistMono(34, .medium, tracking: -0.04, lineHeight: 40)
                    .foregroundStyle(CH.text)
                    .contentTransition(.numericText(value: total))
                Text("\(StatsFmt.delta(diff)) \(range.vsLabel)")
                    .geistMono(12, .medium, tracking: -0.01, lineHeight: 16)
                    .foregroundStyle(CH.textTertiary)
            }
            BreakNumbers(count: count, total: total, work: work)
        }
    }

    private func perTracker(_ rows: [BreakTotal]) -> some View {
        let maxSeconds = max(rows.map(\.seconds).max() ?? 0, 1)
        return GrowGroup { grown in
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { i, r in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            DotView(color: r.activity.color.accent)
                            Text(r.activity.name)
                                .geist(14, .medium, lineHeight: 18)
                                .foregroundStyle(StatsColor.rowName)
                                .lineLimit(1)
                            Spacer(minLength: 8)
                            Text("\(r.count)×")
                                .geistMono(12, .medium, tracking: -0.01, lineHeight: 16)
                                .foregroundStyle(StatsColor.dim)
                            Text(Fmt.hm(r.seconds))
                                .geistMono(14, .medium, tracking: -0.01, lineHeight: 18)
                                .foregroundStyle(CH.text)
                                .frame(minWidth: 48, alignment: .trailing)
                                .contentTransition(.numericText())
                        }
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(r.activity.color.accent.opacity(0.7))
                            .frame(width: max(4, width * r.seconds / maxSeconds), height: 4)
                            .growIn(grown, axis: .horizontal, delay: Double(i) * 0.05)
                    }
                    .padding(.vertical, 10)
                    .overlay(alignment: .bottom) { StatsColor.rule.frame(height: 1) }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(r.activity.name): \(r.count) breaks, \(Fmt.words(r.seconds))")
                }
            }
        }
    }
}

struct TrackerBreaks: View {
    @Environment(Store.self) private var store
    let activity: Activity
    let now: Date

    var body: some View {
        let week = Store.week(containing: now)
        let total = store.breakTotal(for: activity.id, in: week, now: now)
        SectionLabelText("Breaks this week").frame(height: 14)
        BreakNumbers(count: store.breakCount(for: activity.id, in: week), total: total,
                     work: store.total(for: activity.id, in: week, now: now))
    }
}

private struct BreakNumbers: View {
    let count: Int
    let total: TimeInterval
    let work: TimeInterval

    var body: some View {
        HStack(alignment: .top) {
            stat("\(count)", count == 1 ? "break" : "breaks")
            Spacer(minLength: 8)
            stat(Fmt.hm(total), "break time")
            Spacer(minLength: 8)
            stat(count == 0 ? "–" : Fmt.words(total / Double(count)), "avg break")
            Spacer(minLength: 8)
            stat(work + total > 0 ? Fmt.percent(total / (work + total)) : "–", "of time")
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
