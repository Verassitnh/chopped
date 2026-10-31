import SwiftUI

struct SwitchSheet: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var contentHeight: CGFloat = 600

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
        VStack(spacing: 18) {
            Capsule().fill(CH.pastMid).frame(width: 40, height: 5)
            header(now: now)
            VStack(spacing: 10) {
                ForEach(choices) { a in
                    Button { switchTo(a) } label: {
                        TrackerCard(activity: a, now: now, start: { switchTo(a) }, stop: {})
                            .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    }
                    .buttonStyle(PressScaleStyle(scale: 0.98))
                    .accessibilityHint("Switches to \(a.name)")
                }
            }
            if store.activeSession != nil {
                Button(action: clockOut) {
                    Text("CLOCK OUT FOR THE DAY")
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

    private func header(now: Date) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Switch to…")
                    .geist(22, .semibold, tracking: -0.015, lineHeight: 28)
                    .foregroundStyle(CH.text)
                Text(subtitle(now: now))
                    .geist(14, .medium, lineHeight: 18)
                    .foregroundStyle(CH.textSecondary)
                    .lineLimit(1)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            CircleIconButton(glyph: .close, size: 36, glyphSize: 12, action: { dismiss() })
                .accessibilityLabel("Close")
        }
        .padding(.horizontal, 8)
    }

    private var choices: [Activity] {
        store.activities.filter { !store.isRunning($0.id) }
    }

    private func subtitle(now: Date) -> String {
        guard let session = store.activeSession, let running = store.activeActivity else { return "Nothing running" }
        return "\(running.name) stops at \(Fmt.hms(now.timeIntervalSince(session.start)))"
    }

    private func switchTo(_ a: Activity) {
        withAnimation(reduceMotion ? nil : Motion.spring) { store.clockIn(a) }
        dismiss()
    }

    private func clockOut() {
        withAnimation(reduceMotion ? nil : Motion.spring) { store.stop() }
        dismiss()
    }
}
