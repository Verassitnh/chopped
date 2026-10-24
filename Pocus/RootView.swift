import SwiftUI
import UIKit

/// Top level: Track / Stats in a standard (Liquid Glass) tab bar, plus the app's sheets.
/// Screens live in Pocus/Screens/*.swift; navigation state lives in `AppRouter`.
struct RootView: View {
    @Environment(Store.self) private var store
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.tab) {
            HomeView()
                .background(CH.bg.ignoresSafeArea())
                .tabItem { Label("Track", systemImage: "clock") }
                .tag(AppTab.track)
            NavigationStack(path: $router.statsPath) {
                StatsView()
                    .toolbar(.hidden, for: .navigationBar)
                    .navigationDestination(for: Int64.self) { id in
                        TrackerStatsView(activityID: id)
                            .toolbar(.hidden, for: .navigationBar)
                    }
            }
            .background(CH.bg.ignoresSafeArea())
            .tabItem { Label("Stats", systemImage: "chart.bar") }
            .tag(AppTab.stats)
        }
        .tint(.white)
        .transaction { $0.animation = nil }  // tab switches are instant
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
