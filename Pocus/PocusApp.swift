import SwiftUI

@main
struct PocusApp: App {
    @State private var store: Store
    @State private var router = AppRouter()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        QC.configure()
        let store = QC.makeStore()
        _store = State(initialValue: store)
        // Intents (widgets, Live Activity, controls) write the shared DB; reload the in-memory store after.
        if !QC.demo { ChoppedSync.appRefresh = { store.refresh() } }
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
                    if phase == .active { store.refresh() }
                }
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
