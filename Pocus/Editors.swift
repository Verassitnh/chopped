import SwiftUI

/// Fix one activity's clock-ins, a week at a time.
struct SessionsEditor: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    let activity: Activity

    @State private var week: DateInterval
    @State private var addingTime = false

    init(activity: Activity, week: DateInterval = Store.week(containing: .now)) {
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
                        Text(week.title(now: .now))
                        Spacer()
                        Button("Next Week", systemImage: "chevron.right") { shiftWeek(by: 1) }
                            .disabled(week.contains(.now))
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                } footer: {
                    Text("Total \(store.total(for: activity.id, in: week, now: .now).short)")
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
        week = Store.week(containing: Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: week.start)!)
    }
}

private struct SessionRow: View {
    @Environment(Store.self) private var store
    let session: WorkSession

    /// nil until the user picks an earlier stop time, so "Stop Now" stays truly now.
    @State private var stopAt: Date?

    var body: some View {
        VStack(alignment: .leading) {
            DatePicker("Start", selection: binding(\.start, upTo: session.end ?? .now))
            if let end = session.end {
                DatePicker("End", selection: Binding(
                    get: { end },
                    set: { var s = session; s.end = max($0, session.start); store.updateSession(s) }
                ), in: session.start...)
            } else {
                DatePicker("Stop at", selection: Binding(get: { stopAt ?? .now }, set: { stopAt = $0 }),
                           in: session.start...Date.now)
                HStack {
                    Text("Running").foregroundStyle(.green)
                    Spacer()
                    Button(stopAt == nil ? "Stop Now" : "Stop") { store.stop(at: stopAt ?? .now) }
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
private struct NewSessionSheet: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    let activity: Activity

    @State private var start: Date
    @State private var end: Date

    init(activity: Activity, week: DateInterval) {
        self.activity = activity
        // Default to the hour ending at this time of day, moved into `week`.
        let calendar = Calendar.current
        let weeksBack = calendar.dateComponents([.weekOfYear], from: Store.week(containing: .now).start, to: week.start).weekOfYear ?? 0
        let shifted = calendar.date(byAdding: .weekOfYear, value: weeksBack, to: .now)!
        let end = calendar.dateInterval(of: .minute, for: min(shifted, .now))!.start
        _end = State(initialValue: end)
        _start = State(initialValue: end.addingTimeInterval(-3600))
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Start", selection: $start, in: ...Date.now)
                DatePicker("End", selection: $end, in: start...Date.now)
                LabeledContent("Duration", value: max(0, end.timeIntervalSince(start)).short)
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
                end = min(end.addingTimeInterval(new.timeIntervalSince(old)), .now)
            }
        }
        .presentationDetents([.medium])
    }
}

/// Add (activity == nil) or edit an activity.
struct ActivityEditor: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    let activity: Activity?

    @State private var name = ""
    @State private var colorHex = Color.palette[0]
    @State private var confirmingDelete = false

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 14) {
                        ForEach(Color.palette, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 40, height: 40)
                                .overlay { if hex == colorHex { Circle().strokeBorder(.white, lineWidth: 3) } }
                                .onTapGesture { colorHex = hex }
                        }
                    }
                    .padding(.vertical, 6)
                }
                if activity != nil {
                    Button("Delete", role: .destructive) { confirmingDelete = true }
                }
            }
            .navigationTitle(activity == nil ? "New" : "Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog("Delete \(name) and all its time?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let activity { store.deleteActivity(activity) }
                    dismiss()
                }
            }
            .onAppear {
                if let activity {
                    name = activity.name
                    colorHex = activity.colorHex
                } else {
                    colorHex = Color.palette[store.activities.count % Color.palette.count]
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if var activity {
            activity.name = trimmed
            activity.colorHex = colorHex
            store.updateActivity(activity)
        } else {
            store.addActivity(name: trimmed, colorHex: colorHex)
        }
        dismiss()
    }
}
