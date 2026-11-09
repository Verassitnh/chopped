import SwiftUI

struct SwitchSheet: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var contentHeight: CGFloat = 600
    @State private var picked: Date? = QC.switchOffset.map { Self.minute(AppClock.now).addingTimeInterval(TimeInterval($0 * 60)) }

    static let reach = 30

    var body: some View {
        Ticker { now in
            ScrollView {
                content(now: now)
                    .onGeometryChange(for: CGFloat.self, of: \.size.height) { contentHeight = $0 }
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
        }
        .presentationDetents([.height(contentHeight)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(CH.sheet)
        .presentationCornerRadius(32)
    }

    private func content(now: Date) -> some View {
        let at = switchDate(now: now)
        return VStack(spacing: 18) {
            Capsule().fill(CH.pastMid).frame(width: 40, height: 5)
            header(now: now, at: at)
            VStack(spacing: 8) {
                readout(now: now, at: at)
                SwitchWheel(base: Self.minute(now), now: now, range: range(now: now), offset: offsetBinding(now: now))
            }
            if let previous {
                section("Back to") { card(previous, now: now, at: at) }
                section("Or switch to") {
                    ForEach(choices.filter { $0.id != previous.id }) { card($0, now: now, at: at) }
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(choices) { card($0, now: now, at: at) }
                }
            }
            if store.activeSession != nil || store.activeBreak != nil {
                Button { clockOut(at: at, now: now) } label: {
                    Text(isNow(now) ? "CLOCK OUT FOR THE DAY" : "CLOCK OUT AT \(Fmt.clock(at))")
                        .geistMono(13, .medium, tracking: 0.08, lineHeight: 18)
                        .foregroundStyle(CH.textSecondary)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(EdgeInsets(top: 8, leading: 12, bottom: 40, trailing: 12))
    }

    private var previous: Activity? { store.activeBreak.flatMap { store.activity($0.activityID) } }

    private func section<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabelText(title).padding(.horizontal, 8)
            content()
        }
    }

    private func card(_ a: Activity, now: Date, at: Date) -> some View {
        Button { switchTo(a, at: at, now: now) } label: {
            TrackerCard(activity: a, now: now,
                        scheduledLine: at > now ? "Starts \(Fmt.clock(at)) · " + (a.hasGoal ? "\(Fmt.goal(minutes: a.goalMinutes)) goal" : a.goalLine) : nil,
                        start: { switchTo(a, at: at, now: now) }, stop: {}, showsBreak: false)
                .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .buttonStyle(PressScaleStyle(scale: 0.98))
        .accessibilityHint(at > now ? "Switches to \(a.name) at \(Fmt.clock(at))" : "Switches to \(a.name)")
    }

    private func header(now: Date, at: Date) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Switch to…")
                    .geist(22, .semibold, tracking: -0.015, lineHeight: 28)
                    .foregroundStyle(CH.text)
                subtitle(now: now, at: at)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            CircleIconButton(glyph: .close, size: 36, glyphSize: 12, action: { dismiss() })
                .accessibilityLabel("Close")
        }
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private func subtitle(now: Date, at: Date) -> some View {
        if let b = store.activeBreak {
            let end = store.breakEnd(b)
            Text(now >= end ? "Break over by \(Fmt.hms(now.timeIntervalSince(end)))" : "Break ends in \(Fmt.hms(end.timeIntervalSince(now)))")
                .geist(14, .medium, lineHeight: 18)
                .monospacedDigit()
                .foregroundStyle(CH.textSecondary)
        } else if let session = store.activeSession, let running = store.activeActivity {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(isNow(now) ? "\(running.name) stops now" : "\(running.name) stops at \(Fmt.clock(at))")
                    .geist(14, .medium, lineHeight: 18)
                    .foregroundStyle(CH.textSecondary)
                Text(Fmt.hms(max(0, at.timeIntervalSince(session.start))))
                    .geistMono(12, .medium, lineHeight: 16)
                    .monospacedDigit()
                    .foregroundStyle(CH.textTertiary)
                    .layoutPriority(1)
            }
        } else {
            Text("Nothing running")
                .geist(14, .medium, lineHeight: 18)
                .foregroundStyle(CH.textSecondary)
        }
    }

    private func readout(now: Date, at: Date) -> some View {
        let parts = Fmt.clockParts(at)
        let minutes = offset(now: now)
        return HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text("SWITCH AT")
                    .geistMono(11, .medium, tracking: 0.08, lineHeight: 14)
                    .foregroundStyle(CH.textTertiary)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(parts.time)
                        .geistMono(34, .medium, tracking: -0.05, lineHeight: 38)
                        .monospacedDigit()
                        .foregroundStyle(CH.text)
                        .contentTransition(.numericText(value: Double(minutes)))
                        .animation(reduceMotion ? nil : .snappy(duration: 0.2), value: minutes)
                    Text(parts.meridiem)
                        .geistMono(16, .medium, lineHeight: 20)
                        .foregroundStyle(CH.textMuted)
                }
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: 12)
            VStack(alignment: .trailing, spacing: 6) {
                Text(minutes == 0 ? "Now" : minutes > 0 ? "in \(minutes) min" : "\(-minutes) min ago")
                    .geist(14, .medium, lineHeight: 18)
                    .monospacedDigit()
                    .foregroundStyle(CH.textMuted)
                if minutes != 0 {
                    Button { picked = nil } label: {
                        Text("↺ Now · \(Fmt.clock(now))")
                            .geistMono(12, .medium, lineHeight: 16)
                            .foregroundStyle(CH.text)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(CH.raised, in: Capsule())
                    }
                    .buttonStyle(.pressScale)
                    .accessibilityLabel("Reset to now")
                    .transition(.opacity)
                }
            }
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: minutes == 0)
        }
        .padding(.horizontal, 8)
    }

    static func minute(_ date: Date) -> Date {
        Calendar.chopped.dateInterval(of: .minute, for: date)?.start ?? date
    }

    private func isNow(_ now: Date) -> Bool { offset(now: now) == 0 }

    private func range(now: Date) -> ClosedRange<Int> {
        let base = Self.minute(now)
        let earliest = store.latestBoundary(now: now).map { Int(ceil($0.timeIntervalSince(base) / 60)) } ?? -Self.reach
        return min(0, max(-Self.reach, earliest))...Self.reach
    }

    private func offset(now: Date) -> Int {
        guard let picked else { return 0 }
        let r = range(now: now)
        return min(max(Int((picked.timeIntervalSince(Self.minute(now)) / 60).rounded()), r.lowerBound), r.upperBound)
    }

    private func offsetBinding(now: Date) -> Binding<Int> {
        Binding(get: { offset(now: now) },
                set: { picked = $0 == 0 ? nil : Self.minute(AppClock.now).addingTimeInterval(TimeInterval($0 * 60)) })
    }

    private func switchDate(now: Date) -> Date {
        let m = offset(now: now)
        return m == 0 ? now : Self.minute(now).addingTimeInterval(TimeInterval(m * 60))
    }

    private var choices: [Activity] {
        store.trackers.filter { !store.isRunning($0.id) }
    }

    private func switchTo(_ a: Activity, at: Date, now: Date) {
        withAnimation(reduceMotion ? nil : Motion.spring) { store.clockIn(a, at: isNow(now) ? nil : at) }
        dismiss()
    }

    private func clockOut(at: Date, now: Date) {
        withAnimation(reduceMotion ? nil : Motion.spring) { store.stop(at: isNow(now) ? AppClock.now : at) }
        dismiss()
    }
}
