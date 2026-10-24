import SwiftUI

/// Top level: Track / Stats tabs with the floating glass tab bar, plus the app's sheets.
/// Screens live in Pocus/Screens/*.swift; navigation state lives in `AppRouter`.
struct RootView: View {
    @Environment(Store.self) private var store
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        ZStack(alignment: .bottom) {
            CH.bg.ignoresSafeArea()

            switch router.tab {
            case .track:
                HomeView()
            case .stats:
                NavigationStack(path: $router.statsPath) {
                    StatsView()
                        .toolbar(.hidden, for: .navigationBar)
                        .navigationDestination(for: Int64.self) { id in
                            TrackerStatsView(activityID: id)
                                .toolbar(.hidden, for: .navigationBar)
                        }
                }
            }

            if router.statsPath.isEmpty || router.tab == .track {
                GlassTabBar(selection: $router.tab)
                    .padding(.bottom, 22)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
        .sheet(item: $router.detailActivityID) { id in
            TrackerDetailView(activityID: id)
        }
        .newTrackerOverlay(isPresented: $router.showingNewTracker)
    }
}

/// 188×62 glass capsule, two 89×54 tabs (Paper node AL8-0 / home tab bar).
struct GlassTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 0) {
            item(.track, glyph: .clock, title: "Track")
            item(.stats, glyph: .bars, title: "Stats")
        }
        .padding(4)
        .frame(width: 188, height: 62)
        .background {
            Capsule().fill(.ultraThinMaterial)
                .overlay(Capsule().fill(Color.white.opacity(0.08)))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.14), lineWidth: 1))
                .shadow(color: .black.opacity(0.5), radius: 15, y: 10)
        }
    }

    private func item(_ tab: AppTab, glyph: Glyph, title: String) -> some View {
        let selected = selection == tab
        let color = selected ? Color.white : Color(hex: "#8A8A8A")
        return Button { selection = tab } label: {
            VStack(spacing: 3) {
                GlyphView(glyph, size: 22, color: color)
                Text(title)
                    .geist(10, selected ? .bold : .semibold, lineHeight: 12)
                    .foregroundStyle(color)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                if selected { Capsule().fill(Color.white.opacity(0.14)) }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.pressScale)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
