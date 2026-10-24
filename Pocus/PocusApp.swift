import SwiftUI

@main
struct PocusApp: App {
    @State private var store = Store()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            TabView {
                ClockView()
                    .tabItem { Label("Clock", systemImage: "clock") }
                StatsView()
                    .tabItem { Label("Stats", systemImage: "chart.bar") }
            }
            .environment(store)
            .preferredColorScheme(.dark)
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { store.syncLiveActivity() }
            }
        }
    }
}
