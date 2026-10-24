import SwiftUI

/// 04 Tracker stats (Paper AYR-0), pushed on the Stats stack. PLACEHOLDER — replace with the real screen.
struct TrackerStatsView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    let activityID: Int64

    var body: some View {
        Ticker { now in
            VStack(alignment: .leading, spacing: 16) {
                CircleIconButton(glyph: .chevronLeft, glyphSize: 22) { dismiss() }
                if let a = store.activity(activityID) {
                    Text(a.name).geist(22, .semibold).foregroundStyle(CH.text)
                    Text(Fmt.hm(store.weekComparison(for: a.id, now: now).current)).geistPixel(112).foregroundStyle(.white)
                }
                Text("Placeholder — TrackerStatsView").geistMono(12).foregroundStyle(CH.textTertiary)
                Spacer()
            }
            .padding(20)
        }
        .background(CH.bg)
    }
}
