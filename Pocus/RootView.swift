import SwiftUI
import UIKit

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
        .task {
            // -QCScreen detail: present once the scene is active and on screen (device launches are slower).
            guard let id = router.qcPendingDetailID else { return }
            router.qcPendingDetailID = nil
            for _ in 0..<40 where UIApplication.shared.applicationState != .active {
                try? await Task.sleep(for: .seconds(0.1))
            }
            try? await Task.sleep(for: .seconds(0.3))
            router.detailActivityID = id
            // If UIKit dropped the presentation, try once more.
            try? await Task.sleep(for: .seconds(1.5))
            if !QC.sheetPresented {
                QC.log("QC detail sheet not presented, retrying")
                router.detailActivityID = nil
                try? await Task.sleep(for: .seconds(0.2))
                router.detailActivityID = id
            }
        }
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
            // Paper AL8-0: blur 24, #FFFFFF14 fill, #FFFFFF24 border, #FFFFFF33 inset top, #00000080 0 10 30.
            GlassSurface(shape: Capsule(), fill: .white.opacity(0x14 / 255.0), highlight: .white.opacity(0.2))
                .background {
                    // CSS box-shadow is only drawn outside the box, so the translucent glass isn't darkened.
                    Capsule().fill(.black)
                        .shadow(color: .black.opacity(0.5), radius: 15, y: 10)
                        .mask {
                            Rectangle().padding(-60)
                                .overlay(Capsule().blendMode(.destinationOut))
                                .compositingGroup()
                        }
                }
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
