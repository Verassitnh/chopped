import SwiftUI
import UIKit

@main
struct ChoppedApp: App {
    @State private var store: Store
    @State private var router = AppRouter()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        QC.configure()
        let store = QC.makeStore()
        _store = State(initialValue: store)
        // Intents (widgets, Live Activity, controls) write the shared DB. `ChoppedSync` syncs the Live
        // Activity straight from SQLite; the in-memory store is only re-read while the app is on screen
        // (a background launch for an intent stays light; the foreground refresh below catches up).
        if !QC.demo {
            ChoppedSync.appRefresh = {
                if UIApplication.shared.applicationState == .active { store.refresh() }
            }
            // Widget buttons run in the extension and post this when the app is already running.
            ChoppedSync.observeExtensionChanges {
                if UIApplication.shared.applicationState == .active {
                    store.refresh()
                } else {
                    LiveActivityBridge.sync(ChoppedData.snapshot()?.activityState)
                }
            }
        }
        if let screen = QC.screen {
            let router = AppRouter()
            router.open(screen, store: store)
            _router = State(initialValue: router)
        }
    }

    var body: some Scene {
        WindowGroup {
            QCSurfaceRoot { RootView() }
                .environment(store)
                .environment(router)
                .preferredColorScheme(.dark)
                .modifier(QCSnapshotTrigger(delay: snapshotDelay))
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { store.refresh(silent: true) }
                }
                .onAppear { Haptics.prepare() }
        }
    }

    /// 1.5s for plain screens; sheets/pushes get extra time to finish presenting.
    private var snapshotDelay: TimeInterval {
        switch QC.screen {
        case .detail, .newTracker, .trackerStats: 2.2
        default: 1.5
        }
    }
}
