import SwiftUI

// Preserved from the original Pocus UI (unstyled). Screen engineers may restyle or replace these;
// the logic (week paging, stop-at, keep-duration-on-start-change) is the reference behaviour.

/// Fix one activity's clock-ins, a week at a time.
struct SessionsEditor: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    let activity: Activity

    @State private var week: DateInterval
    @State private var addingTime = false

    init(activity: Activity, week: DateInterval = Store.week(containing: AppClock.now)) {
        self.activity = activity
        _week = State(initialValue: week)
    }

    var body: some View {
        let sessions = store.sessions(for: activity.id, in: week)

        NavigationStack {
            List {
                Section {
                    if sessions.isEmpty {
                        Text("No clock-ins this week").foregroundStyle(.secondary)
                    }
                    ForEach(sessions) { session in
                        SessionRow(session: session)
                    }
                    .onDelete { offsets in offsets.forEach { store.deleteSession(sessions[$0]) } }

                    Button("Add Time", systemImage: "plus") { addingTime = true }
                } header: {
                    HStack {
                        Button("Previous Week", systemImage: "chevron.left") { shiftWeek(by: -1) }
                        Spacer()
                        Text((week.contains(AppClock.now) ? "This week" : weekRange(week)))
                        Spacer()
                        Button("Next Week", systemImage: "chevron.right") { shiftWeek(by: 1) }
                            .disabled(week.contains(AppClock.now))
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                } footer: {
                    Text("Total \(Fmt.words(store.total(for: activity.id, in: week, now: AppClock.now)))")
                }
            }
            .navigationTitle(activity.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .sheet(isPresented: $addingTime) { NewSessionSheet(activity: activity, week: week) }
        }
    }

    private func shiftWeek(by weeks: Int) {
        week = Store.week(containing: Calendar.chopped.date(byAdding: .weekOfYear, value: weeks, to: week.start)!)
    }
}

private struct SessionRow: View {
    @Environment(Store.self) private var store
    let session: WorkSession

    /// nil until the user picks an earlier stop time, so "Stop Now" stays truly now.
    @State private var stopAt: Date?

    var body: some View {
        VStack(alignment: .leading) {
            DatePicker("Start", selection: binding(\.start, upTo: session.end ?? AppClock.now))
            if let end = session.end {
                DatePicker("End", selection: Binding(
                    get: { end },
                    set: { var s = session; s.end = max($0, session.start); store.updateSession(s) }
                ), in: session.start...)
            } else {
                DatePicker("Stop at", selection: Binding(get: { stopAt ?? AppClock.now }, set: { stopAt = $0 }),
                           in: session.start...AppClock.now)
                HStack {
                    Text("Running").foregroundStyle(.green)
                    Spacer()
                    Button(stopAt == nil ? "Stop Now" : "Stop") { store.stop(at: stopAt ?? AppClock.now) }
                        .buttonStyle(.bordered)
                }
            }
        }
    }

    private func binding(_ keyPath: WritableKeyPath<WorkSession, Date>, upTo limit: Date) -> Binding<Date> {
        Binding(
            get: { session[keyPath: keyPath] },
            set: { var s = session; s[keyPath: keyPath] = min($0, limit); store.updateSession(s) }
        )
    }
}

/// Log time after the fact, e.g. a clock-in that was forgotten or tracked somewhere else.
struct NewSessionSheet: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    let activity: Activity

    @State private var start: Date
    @State private var end: Date

    init(activity: Activity, week: DateInterval) {
        self.activity = activity
        // Default to the hour ending at this time of day, moved into `week`.
        let calendar = Calendar.chopped
        let weeksBack = calendar.dateComponents([.weekOfYear], from: Store.week(containing: AppClock.now).start, to: week.start).weekOfYear ?? 0
        let shifted = calendar.date(byAdding: .weekOfYear, value: weeksBack, to: AppClock.now)!
        let end = calendar.dateInterval(of: .minute, for: min(shifted, AppClock.now))!.start
        _end = State(initialValue: end)
        _start = State(initialValue: end.addingTimeInterval(-3600))
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Start", selection: $start, in: ...AppClock.now)
                DatePicker("End", selection: $end, in: start...AppClock.now)
                LabeledContent("Duration", value: Fmt.words(max(0, end.timeIntervalSince(start))))
            }
            .navigationTitle("Add Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        store.addSession(activityID: activity.id, start: start, end: end)
                        dismiss()
                    }
                    .disabled(end <= start)
                }
            }
            // Moving the start keeps the duration, like Calendar.
            .onChange(of: start) { old, new in
                end = min(end.addingTimeInterval(new.timeIntervalSince(old)), AppClock.now)
            }
        }
        .presentationDetents([.medium])
    }
}

/// "Oct 19 – Oct 25"
func weekRange(_ week: DateInterval) -> String {
    week.start.formatted(.dateTime.month(.abbreviated).day()) + " – "
        + week.end.addingTimeInterval(-1).formatted(.dateTime.month(.abbreviated).day())
}
