import ActivityKit
import SwiftUI
import WidgetKit

@main
struct PocusWidgets: WidgetBundle {
    var body: some Widget {
        ClockInLiveActivity()
    }
}

struct ClockInLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PocusActivityAttributes.self) { context in
            LockScreenView(state: context.state)
                .activityBackgroundTint(Color(hex: context.state.colorHex))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let state = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    ClockedInLabel(state: state)
                        .padding(.leading, 6)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Elapsed(start: state.start)
                        .font(.title2.weight(.light))
                        .padding(.trailing, 6)
                }
            } compactLeading: {
                Circle().fill(Color(hex: state.colorHex)).frame(width: 10, height: 10)
            } compactTrailing: {
                Elapsed(start: state.start)
                    .font(.caption.weight(.semibold))
                    .frame(width: 56)
            } minimal: {
                Circle().fill(Color(hex: state.colorHex)).frame(width: 10, height: 10)
            }
        }
    }
}

/// Mirrors the active card: name, white dot + "Clocked in", running time on the right.
private struct LockScreenView: View {
    let state: PocusActivityAttributes.ContentState

    var body: some View {
        HStack {
            ClockedInLabel(state: state)
            Spacer()
            Elapsed(start: state.start)
                .font(.system(size: 40, weight: .light))
        }
        .padding(16)
        .foregroundStyle(.white)
    }
}

private struct ClockedInLabel: View {
    let state: PocusActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(state.name)
                .font(.title3.bold())
                .lineLimit(1)
            HStack(spacing: 6) {
                Circle().fill(.white).frame(width: 7, height: 7)
                Text("Clocked in")
            }
            .font(.subheadline.weight(.semibold))
        }
    }
}

/// Counts up from `start`; the system renders it live without app updates.
private struct Elapsed: View {
    let start: Date

    var body: some View {
        Text(timerInterval: start...start.addingTimeInterval(24 * 3600), countsDown: false)
            .monospacedDigit()
            .multilineTextAlignment(.trailing)
    }
}
