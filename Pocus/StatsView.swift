import Charts
import SwiftUI

struct StatsView: View {
    @Environment(Store.self) private var store
    @State private var fixing: FixTarget?
    private let weekCount = 8

    private struct FixTarget: Identifiable {
        let activity: Activity
        let week: DateInterval
        var id: String { "\(activity.id)-\(week.start.timeIntervalSince1970)" }
    }

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 30)) { context in
                let weeks = pastWeeks(from: context.date)

                List {
                    Section {
                        chart(weeks: weeks, now: context.date)
                            .frame(height: 220)
                            .padding(.vertical, 8)
                    }

                    ForEach(weeks, id: \.start) { week in
                        WeekSection(week: week, now: context.date) { fixing = FixTarget(activity: $0, week: week) }
                    }
                }
            }
            .navigationTitle("Stats")
            .sheet(item: $fixing) { SessionsEditor(activity: $0.activity, week: $0.week) }
        }
    }

    /// Most recent first.
    private func pastWeeks(from now: Date) -> [DateInterval] {
        let current = Store.week(containing: now)
        return (0..<weekCount).map { offset in
            Store.week(containing: Calendar.current.date(byAdding: .weekOfYear, value: -offset, to: current.start)!)
        }
    }

    private func chart(weeks: [DateInterval], now: Date) -> some View {
        Chart {
            ForEach(weeks.reversed(), id: \.start) { week in
                ForEach(store.activities) { activity in
                    BarMark(
                        x: .value("Week", week.start, unit: .weekOfYear),
                        y: .value("Hours", store.total(for: activity.id, in: week, now: now) / 3600)
                    )
                    .foregroundStyle(by: .value("Activity", activity.name))
                }
            }
        }
        .chartForegroundStyleScale(
            domain: store.activities.map(\.name),
            range: store.activities.map { Color(hex: $0.colorHex) }
        )
        .chartXAxis {
            AxisMarks(values: .stride(by: .weekOfYear)) {
                AxisValueLabel(format: .dateTime.month(.defaultDigits).day(), centered: true)
            }
        }
        .chartYAxisLabel("hours")
    }
}

private struct WeekSection: View {
    @Environment(Store.self) private var store
    let week: DateInterval
    let now: Date
    let fix: (Activity) -> Void

    var body: some View {
        let total = store.total(in: week, now: now)
        let rows = store.activities
            .map { ($0, store.total(for: $0.id, in: week, now: now)) }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }

        Section {
            if rows.isEmpty {
                Text("Nothing clocked").foregroundStyle(.secondary)
            }
            ForEach(rows, id: \.0.id) { activity, seconds in
                Button { fix(activity) } label: {
                    HStack {
                        Circle().fill(Color(hex: activity.colorHex)).frame(width: 10, height: 10)
                        Text(activity.name)
                        Spacer()
                        Text(seconds.short).monospacedDigit().foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        } header: {
            HStack {
                Text(week.title(now: now))
                Spacer()
                Text(total.short).monospacedDigit()
            }
        }
    }
}
