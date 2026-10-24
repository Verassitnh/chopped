import SwiftUI

struct ClockView: View {
    @Environment(Store.self) private var store
    @State private var editingSessions: Activity?
    @State private var editingActivity: Activity?
    @State private var addingActivity = false
    @State private var deletingActivity: Activity?

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let now = context.date
                let week = Store.week(containing: now)
                let today = Store.day(containing: now)

                List {
                    WeekHeader(total: store.total(in: week, now: now), week: week)
                        .cardRow()

                    ForEach(store.activities) { activity in
                        let active = store.activeSession?.activityID == activity.id ? store.activeSession : nil
                        ActivityCard(
                            activity: activity,
                            now: now,
                            session: active,
                            weekTotal: store.total(for: activity.id, in: week, now: now),
                            todayTotal: store.total(for: activity.id, in: today, now: now)
                        )
                        .onTapGesture { store.clockIn(activity) }
                        .contextMenu {
                            Button("Fix Times", systemImage: "clock.arrow.circlepath") { editingSessions = activity }
                            Button("Edit", systemImage: "pencil") { editingActivity = activity }
                            if active != nil {
                                Button("Stop", systemImage: "stop.fill") { store.stop() }
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            // Not role: .destructive — that hides the row before the confirmation answers.
                            Button("Delete", systemImage: "trash") { deletingActivity = activity }
                                .tint(.red)
                        }
                        .cardRow()
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .background(Color.black.ignoresSafeArea())
            .confirmationDialog(
                "Delete \(deletingActivity?.name ?? "") and all its time?",
                isPresented: Binding(get: { deletingActivity != nil }, set: { if !$0 { deletingActivity = nil } }),
                titleVisibility: .visible,
                presenting: deletingActivity
            ) { activity in
                Button("Delete", role: .destructive) {
                    withAnimation { store.deleteActivity(activity) }
                }
            }
            .navigationTitle("Pocus")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add", systemImage: "plus") { addingActivity = true }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let session = store.activeSession, let activity = store.activity(session.activityID) {
                    StopBar(activity: activity, session: session) { store.stop() }
                        .contextMenu {
                            Button("Fix Times", systemImage: "clock.arrow.circlepath") { editingSessions = activity }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.snappy, value: store.activeSession?.id)
            .sensoryFeedback(.impact, trigger: store.activeSession?.id)
            .sheet(item: $editingSessions) { SessionsEditor(activity: $0) }
            .sheet(item: $editingActivity) { ActivityEditor(activity: $0) }
            .sheet(isPresented: $addingActivity) { ActivityEditor(activity: nil) }
        }
    }
}

private extension View {
    /// Strips List row chrome so cards float on the black background.
    func cardRow() -> some View {
        listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}

private struct WeekHeader: View {
    let total: TimeInterval
    let week: DateInterval

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("This week").font(.headline)
            Text(week.range)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(total.hoursMinutes).font(.headline).monospacedDigit()
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 4)
    }
}

/// Compressed card, laid out like a Weather app location row.
struct ActivityCard: View {
    let activity: Activity
    let now: Date
    let session: WorkSession?
    let weekTotal: TimeInterval
    let todayTotal: TimeInterval

    private var isActive: Bool { session != nil }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.name)
                    .font(.title2.bold())
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if isActive {
                        Circle().fill(.white).frame(width: 7, height: 7)
                            .phaseAnimator([1.0, 0.3]) { $0.opacity($1) } animation: { _ in .easeInOut(duration: 0.8) }
                    }
                    Text(isActive ? "Clocked in" : now.formatted(date: .omitted, time: .shortened))
                }
                .font(.subheadline.weight(.semibold))
                Spacer(minLength: 0)
                Text(session.map { now.timeIntervalSince($0.start).clock } ?? "Today \(todayTotal.hoursMinutes)")
                    .font(.footnote.weight(.medium))
                    .monospacedDigit()
                    .opacity(0.85)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(weekTotal.hoursMinutes)
                    .font(.system(size: 50, weight: .light))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Spacer(minLength: 0)
                Text("this week").font(.footnote.weight(.medium)).opacity(0.85)
            }
        }
        .foregroundStyle(.white)
        .padding(16)
        .frame(height: 116)
        .background {
            let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
            ZStack {
                shape.fill(Color(hex: activity.colorHex))
                shape.fill(LinearGradient(colors: [.black.opacity(0), .black.opacity(0.35)],
                                          startPoint: .top, endPoint: .bottom))
                if !isActive { shape.fill(.black.opacity(0.35)) }
                if isActive { shape.strokeBorder(.white.opacity(0.9), lineWidth: 2) }
            }
        }
        .scaleEffect(isActive ? 1 : 0.98)
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .animation(.snappy, value: isActive)
    }
}

private struct StopBar: View {
    let activity: Activity
    let session: WorkSession
    let stop: () -> Void

    var body: some View {
        HStack {
            Circle().fill(Color(hex: activity.colorHex)).frame(width: 12, height: 12)
            VStack(alignment: .leading, spacing: 0) {
                Text(activity.name).font(.headline)
                Text("since \(session.start.formatted(date: .omitted, time: .shortened))")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: stop) {
                Label("Stop", systemImage: "stop.fill")
                    .font(.headline)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(.white, in: Capsule())
                    .foregroundStyle(.black)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .padding(.horizontal)
        .padding(.bottom, 6)
    }
}
