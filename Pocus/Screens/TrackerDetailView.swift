import SwiftUI

/// 02 Tracker detail sheet (Paper AGW-0). PLACEHOLDER — replace with the real screen.
/// Presented by RootView via `router.detailActivityID`.
struct TrackerDetailView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    let activityID: Int64

    var body: some View {
        Ticker { now in
            VStack(alignment: .leading, spacing: 12) {
                if let a = store.activity(activityID) {
                    Text(a.name).geist(26, .semibold).foregroundStyle(.black)
                    Text(a.goalLine).geist(15, .medium).foregroundStyle(CH.onAccentSecondary)
                    Text(Fmt.hm(store.periodTotal(for: a, now: now))).geistPixel(62).foregroundStyle(.black)
                    Text("Placeholder — TrackerDetailView").geistMono(12).foregroundStyle(.black)
                }
                Spacer()
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(store.activity(activityID)?.color.accent ?? CH.sheet)
        }
        .presentationDragIndicator(.visible)
    }
}
