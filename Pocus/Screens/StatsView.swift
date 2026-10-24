import SwiftUI

/// 03 Stats (Paper AL7-0). PLACEHOLDER — replace with the real screen.
/// Root of the Stats tab's NavigationStack; push a tracker with `router.statsPath.append(id)`.
struct StatsView: View {
    @Environment(Store.self) private var store
    @Environment(AppRouter.self) private var router

    var body: some View {
        Ticker { now in
            let week = store.weekComparison(now: now)
            VStack(alignment: .leading, spacing: 16) {
                Text("Stats").geist(28, .semibold).foregroundStyle(CH.text)
                Text(Fmt.hm(week.current)).geistPixel(112).foregroundStyle(.white)
                SectionValueText("last week \(Fmt.hm(week.last))")
                ForEach(store.activities) { a in
                    Button { router.statsPath.append(a.id) } label: {
                        HStack {
                            Text(a.name).geist(15, .medium).foregroundStyle(CH.text)
                            Spacer()
                            Text(Fmt.hm(store.weekComparison(for: a.id, now: now).current)).geistMono(15).foregroundStyle(CH.text)
                        }
                    }
                }
                Text("Placeholder — StatsView").geistMono(12).foregroundStyle(CH.textTertiary)
                Spacer()
            }
            .padding(20)
        }
        .background(CH.bg)
    }
}
