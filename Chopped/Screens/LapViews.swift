import SwiftUI
import UIKit

enum LapRange: String, CaseIterable, Identifiable {
    case week, month
    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    func interval(containing date: Date) -> DateInterval {
        Calendar.chopped.dateInterval(of: self == .week ? .weekOfYear : .month, for: date)!
    }

    func label(_ interval: DateInterval) -> String {
        let last = interval.end.addingTimeInterval(-1)
        switch self {
        case .week:
            let start = interval.start.formatted(.dateTime.day().month(.abbreviated))
            return "\(start) – \(last.formatted(.dateTime.day().month(.abbreviated).year()))"
        case .month:
            return interval.start.formatted(.dateTime.month(.wide).year())
        }
    }
}

struct LapsSection: View {
    @Environment(Store.self) private var store
    let activity: Activity
    let now: Date

    @State private var range: LapRange = .week
    @State private var startingLap = false
    @State private var editingLap: Lap?
    @State private var copied = false

    var body: some View {
        let a = activity
        let interval = range.interval(containing: now)
        let active = store.activeLap.flatMap { $0.activityID == a.id ? $0 : nil }
        let totals = store.lapTotals(for: a.id, in: interval, now: now)
        let laps = store.laps(for: a.id, in: interval)
        let lapped = totals.reduce(0) { $0 + $1.seconds }
        let outside = max(0, store.total(for: a.id, in: interval, now: now) - lapped)

        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text("Laps")
                    .geist(17, .semibold, tracking: -0.01, lineHeight: 16)
                    .foregroundStyle(CH.text)
                Spacer()
                if !laps.isEmpty { rangePicker }
                if !a.isCompleted {
                    GlassPill(glyph: .plus, title: active == nil ? "Lap" : "Next") { startingLap = true }
                }
            }
            .padding(.bottom, 6)

            if let active {
                activeCard(active, accent: a.color.accent)
                    .padding(.top, 12)
            }

            if laps.isEmpty && active == nil {
                Text("Optional. Split your time into labelled laps, by client, project or task, to get billable totals.")
                    .geist(13, .medium, lineHeight: 18)
                    .foregroundStyle(CH.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 12)
            } else if !totals.isEmpty {
                HStack {
                    Text(range.label(interval))
                    Spacer()
                    Text(Fmt.decimalHours(lapped)).contentTransition(.numericText())
                }
                .geist(13, .medium, lineHeight: 16)
                .foregroundStyle(CH.textSecondary)
                .padding(.top, 18)
                .padding(.bottom, 6)

                ForEach(totals) { t in totalRow(t) }
                if outside >= 60 {
                    totalRow(title: "Not in a lap", seconds: outside, dim: true)
                }

                copyButton(totals: totals, interval: interval, total: lapped)
                    .padding(.top, 10)

                SectionLabel("Log")
                    .padding(.top, 22)
                    .padding(.bottom, 2)
                ForEach(laps) { lap in
                    Button { editingLap = lap } label: { lapRow(lap, accent: a.color.accent) }
                        .buttonStyle(.pressScale)
                }
            }
        }
        .sheet(isPresented: $startingLap) {
            LapStartSheet(activity: a, isNext: active != nil)
        }
        .sheet(item: $editingLap) { lap in LapEditSheet(lap: lap, activity: a) }
    }

    private var rangePicker: some View {
        HStack(spacing: 2) {
            ForEach(LapRange.allCases) { r in
                Button { withAnimation(Motion.spring) { range = r } } label: {
                    Text(r.title)
                        .geist(13, .semibold, lineHeight: 18)
                        .foregroundStyle(range == r ? Color.black : Color(hex: "#CFCFCF"))
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(range == r ? Color.white : .clear, in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background { GlassSurface(shape: Capsule()) }
    }

    private func activeCard(_ lap: Lap, accent: Color) -> some View {
        HStack(spacing: 12) {
            Button { editingLap = lap } label: {
                HStack(spacing: 10) {
                    Circle().fill(accent).frame(width: 8, height: 8)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(lap.title)
                            .geist(16, .semibold, lineHeight: 20)
                            .foregroundStyle(lap.label.isEmpty ? CH.textSecondary : CH.text)
                            .lineLimit(1)
                        Text("Since \(Fmt.time(lap.start))")
                            .geist(12, .medium, lineHeight: 16)
                            .foregroundStyle(CH.textTertiary)
                    }
                    Spacer(minLength: 8)
                    Text(Fmt.hms(store.lapSeconds(lap, now: now)))
                        .geistMono(17, .medium, tracking: -0.03, lineHeight: 22)
                        .monospacedDigit()
                        .foregroundStyle(CH.text)
                        .contentTransition(.numericText())
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.pressScale)
            .accessibilityHint("Edit lap")

            Button { withAnimation(Motion.spring) { store.endLap() } } label: {
                Text("End")
                    .geist(14, .semibold, lineHeight: 18)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 14)
                    .frame(height: 34)
                    .background(accent, in: Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(.pressScale)
            .accessibilityLabel("End lap")
        }
        .padding(.leading, 16).padding(.trailing, 12)
        .frame(minHeight: 64)
        .background(CH.raised, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func totalRow(_ t: LapTotal) -> some View {
        totalRow(title: t.title, seconds: t.seconds, dim: t.label.isEmpty)
    }

    private func totalRow(title: String, seconds: TimeInterval, dim: Bool) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .geist(16, .medium, lineHeight: 20)
                .foregroundStyle(dim ? CH.textSecondary : Color(hex: "#E5E5EA"))
                .lineLimit(1)
            Spacer(minLength: 8)
            Text(Fmt.hm(seconds))
                .geistMono(15, .medium, tracking: -0.03, lineHeight: 20)
                .foregroundStyle(Color(hex: "#5E5E5E"))
            Text(Fmt.decimalHours(seconds))
                .geistMono(17, .medium, tracking: -0.03, lineHeight: 22)
                .foregroundStyle(dim ? CH.textSecondary : Color(hex: "#C8C8C8"))
                .frame(minWidth: 72, alignment: .trailing)
        }
        .monospacedDigit()
        .frame(height: 44)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(Fmt.words(seconds))")
    }

    private func copyButton(totals: [LapTotal], interval: DateInterval, total: TimeInterval) -> some View {
        Button {
            UIPasteboard.general.string = invoiceText(totals: totals, interval: interval, total: total)
            withAnimation(Motion.spring) { copied = true }
            Task {
                try? await Task.sleep(for: .seconds(1.6))
                withAnimation(Motion.spring) { copied = false }
            }
        } label: {
            Text(copied ? "COPIED" : "COPY TOTALS")
                .geistMono(13, .medium, tracking: 0.08, lineHeight: 16)
                .foregroundStyle(copied ? CH.up : Color(hex: "#F2F2F7"))
                .contentTransition(.interpolate)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.pressScale)
        .sensoryFeedback(.success, trigger: copied) { _, new in new }
    }

    private func invoiceText(totals: [LapTotal], interval: DateInterval, total: TimeInterval) -> String {
        var lines = ["\(activity.name) · \(range.label(interval))"]
        lines += totals.map { "\($0.title)\t\(Fmt.decimalHours($0.seconds))" }
        lines.append("Total\t\(Fmt.decimalHours(total))")
        return lines.joined(separator: "\n")
    }

    private func lapRow(_ lap: Lap, accent: Color) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(lap.title)
                    .geist(15, .medium, lineHeight: 20)
                    .foregroundStyle(lap.label.isEmpty ? CH.textSecondary : Color(hex: "#E5E5EA"))
                    .lineLimit(1)
                HStack(spacing: 0) {
                    Text(TrackerDetailView.dayTitle(lap.start, now: now) + " · ")
                    Text("\(Fmt.time(lap.start)) → ")
                    Text(lap.end.map { Fmt.time($0) } ?? "now")
                }
                .geistMono(12, .medium, tracking: -0.02, lineHeight: 16)
                .foregroundStyle(CH.textTertiary)
            }
            Spacer(minLength: 8)
            if lap.isRunning {
                Circle().fill(accent).frame(width: 7, height: 7)
            }
            Text(Fmt.hm(store.lapSeconds(lap, now: now)))
                .geistMono(17, .medium, tracking: -0.03, lineHeight: 22)
                .monospacedDigit()
                .foregroundStyle(Color(hex: lap.isRunning ? "#C8C8C8" : "#5E5E5E"))
                .contentTransition(.numericText())
        }
        .frame(height: 56)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Edit lap")
    }
}

private struct LapLabelField: View {
    @Binding var label: String
    let suggestions: [String]
    var onSubmit: () -> Void = {}
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("", text: $label, prompt: Text("Client, project or task").foregroundStyle(CH.textTertiary))
                .geist(17, .medium, lineHeight: 22)
                .foregroundStyle(CH.text)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($focused)
                .onSubmit(onSubmit)
                .padding(.horizontal, 16)
                .frame(height: 54)
                .background(CH.raised, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .onAppear { focused = true }

            if !suggestions.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(suggestions, id: \.self) { s in
                            let picked = Store.cleanLabel(label).caseInsensitiveCompare(s) == .orderedSame
                            Button { label = s } label: {
                                Text(s)
                                    .geist(14, .semibold, lineHeight: 18)
                                    .foregroundStyle(picked ? Color.black : Color(hex: "#CFCFCF"))
                                    .padding(.horizontal, 12)
                                    .frame(height: 32)
                                    .background {
                                        if picked { Capsule().fill(Color.white) } else { GlassSurface(shape: Capsule()) }
                                    }
                                    .contentShape(Capsule())
                            }
                            .buttonStyle(.pressScale)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }
}

struct LapStartSheet: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    let activity: Activity
    let isNext: Bool

    @State private var label = ""

    var body: some View {
        EditorChrome(title: isNext ? "Next lap" : "New lap", accent: activity.color.accent, save: start) {
            VStack(alignment: .leading, spacing: 16) {
                LapLabelField(label: $label, suggestions: store.recentLapLabels(for: activity.id)) {
                    start()
                    dismiss()
                }
                Text(footnote)
                    .geist(13, .medium, lineHeight: 18)
                    .foregroundStyle(CH.textTertiary)
            }
        }
        .presentationDetents([.medium])
    }

    private var footnote: String {
        if isNext { return "Ends the current lap and starts this one. Leave the label empty to name it later." }
        if store.isRunning(activity.id) { return "Leave the label empty to name it later." }
        return "Starts \(activity.name) too. Leave the label empty to name it later."
    }

    private func start() {
        withAnimation(Motion.spring) { store.startLap(activity, label: label) }
    }
}

struct LapEditSheet: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    let lap: Lap
    let activity: Activity

    @State private var label: String
    @State private var start: Date
    @State private var end: Date
    @State private var confirmingDelete = false

    init(lap: Lap, activity: Activity) {
        self.lap = lap
        self.activity = activity
        _label = State(initialValue: lap.label)
        _start = State(initialValue: lap.start)
        _end = State(initialValue: lap.end ?? AppClock.now)
    }

    var body: some View {
        EditorChrome(title: lap.isRunning ? "Running lap" : "Edit lap", accent: activity.color.accent,
                     canSave: lap.isRunning || end >= start, save: save) {
            VStack(alignment: .leading, spacing: 24) {
                LapLabelField(label: $label, suggestions: store.recentLapLabels(for: activity.id))
                EditorGroup {
                    EditorRow(title: "Start") {
                        DatePicker("Start", selection: $start, in: ...(lap.isRunning ? AppClock.now : end)).labelsHidden()
                    }
                    if !lap.isRunning {
                        EditorRow(title: "End") {
                            DatePicker("End", selection: $end, in: start...AppClock.now).labelsHidden()
                        }
                    }
                }
                Button { confirmingDelete = true } label: {
                    Text("DELETE LAP")
                        .geistMono(13, .medium, tracking: 0.08, lineHeight: 16)
                        .foregroundStyle(Color(hex: "#FF453A"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.pressScale)
            }
        }
        .confirmationDialog("Delete this lap?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete Lap", role: .destructive) {
                store.deleteLap(lap)
                dismiss()
            }
        } message: {
            Text("The tracked time stays. Only the lap and its label go.")
        }
        .presentationDetents([.medium, .large])
    }

    private func save() {
        var l = lap
        l.label = label
        l.start = start
        l.end = lap.isRunning ? nil : max(end, start)
        store.updateLap(l)
    }
}
