import SwiftUI

// Chopped-styled replacements for the legacy SessionsEditor / NewSessionSheet (Pocus/Legacy).
// Same behaviour: fix a clock-in's start/end (or stop a running one at an earlier time),
// delete it, or log time after the fact. Moving the start keeps the duration, like Calendar.

/// Shared sheet chrome: X · title · accent ✓, on #141416.
private struct EditorChrome<Content: View>: View {
    let title: String
    let accent: Color
    var canSave = true
    var save: () -> Void
    @ViewBuilder var content: Content
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text(title)
                    .geist(17, .semibold, tracking: -0.01, lineHeight: 22)
                    .foregroundStyle(CH.text)
                HStack {
                    CircleIconButton(glyph: .close, background: Color.white.opacity(0.08)) { dismiss() }
                        .accessibilityLabel("Cancel")
                    Spacer()
                    CircleIconButton(glyph: .check, glyphSize: 16, background: accent, foreground: .black) {
                        save(); dismiss()
                    }
                    .opacity(canSave ? 1 : 0.35)
                    .disabled(!canSave)
                    .accessibilityLabel("Save")
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            content
                .padding(.horizontal, 20)
                .padding(.top, 24)
            Spacer(minLength: 0)
        }
        .background(CH.sheet)
        .presentationBackground(CH.sheet)
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(30)
        .tint(accent)
    }
}

/// Grouped rows on #1C1C1E (r20), 54pt rows, like the detail settings list.
private struct EditorGroup<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: 0) { content }
            .padding(.horizontal, 16)
            .background(CH.raised, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct EditorRow<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: Trailing
    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .geist(16, .medium, lineHeight: 20)
                .foregroundStyle(Color(hex: "#BDBDBD"))
                .frame(maxWidth: .infinity, alignment: .leading)
            trailing
        }
        .frame(minHeight: 54)
    }
}

/// Big mono duration readout ("DURATION 2:15").
private struct DurationReadout: View {
    let seconds: TimeInterval
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabelText("Duration")
            Text(Fmt.hm(seconds))
                .geistMono(36, .medium, tracking: -0.04, lineHeight: 40)
                .foregroundStyle(CH.text)
                .contentTransition(.numericText())
                .animation(.snappy, value: Int(seconds / 60))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Edit one entry

struct EntryEditSheet: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    let session: WorkSession
    let activity: Activity

    @State private var start: Date
    @State private var end: Date
    /// Running sessions only: keep it running (false = stop it at `end`).
    @State private var keepRunning: Bool
    @State private var confirmingDelete = false

    init(session: WorkSession, activity: Activity) {
        self.session = session
        self.activity = activity
        _start = State(initialValue: session.start)
        _end = State(initialValue: session.end ?? AppClock.now)
        _keepRunning = State(initialValue: session.isRunning)
    }

    private var effectiveEnd: Date { keepRunning ? AppClock.now : end }

    var body: some View {
        EditorChrome(title: session.isRunning ? "Running entry" : "Edit entry", accent: activity.color.accent,
                     canSave: effectiveEnd >= start, save: save) {
            VStack(alignment: .leading, spacing: 24) {
                DurationReadout(seconds: max(0, effectiveEnd.timeIntervalSince(start)))
                EditorGroup {
                    EditorRow(title: "Start") {
                        DatePicker("Start", selection: $start, in: ...(keepRunning ? AppClock.now : end))
                            .labelsHidden()
                    }
                    if session.isRunning {
                        EditorRow(title: "Still running") {
                            Toggle("Still running", isOn: $keepRunning.animation(Motion.spring)).labelsHidden()
                        }
                    }
                    if !keepRunning {
                        EditorRow(title: session.isRunning ? "Stop at" : "End") {
                            DatePicker("End", selection: $end, in: start...AppClock.now)
                                .labelsHidden()
                        }
                    }
                }
                Button { confirmingDelete = true } label: {
                    Text("DELETE ENTRY")
                        .geistMono(13, .medium, tracking: 0.08, lineHeight: 16)
                        .foregroundStyle(Color(hex: "#FF453A"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.pressScale)
            }
        }
        .onChange(of: start) { old, new in
            guard !keepRunning else { return }
            end = min(end.addingTimeInterval(new.timeIntervalSince(old)), AppClock.now)
        }
        .confirmationDialog("Delete this entry?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete Entry", role: .destructive) {
                store.deleteSession(session)
                dismiss()
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func save() {
        var s = session
        s.start = start
        if session.isRunning && keepRunning {
            s.end = nil
        } else {
            s.end = max(end, start)
        }
        store.updateSession(s)
    }
}

// MARK: - Add time

struct AddEntrySheet: View {
    @Environment(Store.self) private var store
    let activity: Activity

    @State private var start: Date
    @State private var end: Date

    init(activity: Activity) {
        self.activity = activity
        // The hour ending now (to the minute).
        let end = Calendar.chopped.dateInterval(of: .minute, for: AppClock.now)!.start
        _end = State(initialValue: end)
        _start = State(initialValue: end.addingTimeInterval(-3600))
    }

    var body: some View {
        EditorChrome(title: "Add time", accent: activity.color.accent, canSave: end > start, save: {
            store.addSession(activityID: activity.id, start: start, end: end)
        }) {
            VStack(alignment: .leading, spacing: 24) {
                DurationReadout(seconds: max(0, end.timeIntervalSince(start)))
                EditorGroup {
                    EditorRow(title: "Start") {
                        DatePicker("Start", selection: $start, in: ...AppClock.now).labelsHidden()
                    }
                    EditorRow(title: "End") {
                        DatePicker("End", selection: $end, in: start...AppClock.now).labelsHidden()
                    }
                }
            }
        }
        .onChange(of: start) { old, new in
            end = min(end.addingTimeInterval(new.timeIntervalSince(old)), AppClock.now)
        }
        .presentationDetents([.medium, .large])
    }
}
