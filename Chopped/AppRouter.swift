import Observation
import SwiftUI

enum AppTab: Hashable { case track, stats }

/// App navigation state. Injected into the environment by `ChoppedApp`; screens read it with
/// `@Environment(AppRouter.self) private var router`.
@Observable
final class AppRouter {
    var tab: AppTab = .track
    /// Tracker whose detail sheet (02) is open.
    var detailActivityID: Int64?
    /// New tracker sheet (05).
    var showingNewTracker = false
    var showingSwitcher = false
    /// Stats navigation stack; push a tracker id to show Tracker Stats (04).
    var statsPath: [Int64] = []
    /// `-QCScreen detail`: presented by RootView once its window is on screen. Setting `detailActivityID`
    /// before the window exists can drop the sheet on device (the presenter isn't in the hierarchy yet).
    var qcPendingDetailID: Int64?
    var qcPendingSwitcher = false

    func openDetail(_ id: Int64) { detailActivityID = id }

    func open(_ url: URL) {
        guard url == ChoppedLink.switcher else { return }
        tab = .track
        showingNewTracker = false
        guard detailActivityID != nil else {
            showingSwitcher = true
            return
        }
        detailActivityID = nil
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.45))
            showingSwitcher = true
        }
    }
    func openTrackerStats(_ id: Int64) {
        detailActivityID = nil
        tab = .stats
        statsPath = [id]
    }

    /// Applies a `-QCScreen` route. detail/trackerStats target the running tracker (Deep Work in demo), else the first.
    func open(_ screen: AppScreen, store: Store) {
        let target = store.activeActivity?.id ?? store.activities.first?.id
        switch screen {
        case .home: tab = .track
        case .detail: tab = .track; qcPendingDetailID = target
        case .stats: tab = .stats
        case .trackerStats: tab = .stats; statsPath = target.map { [$0] } ?? []
        case .newTracker: tab = .track; showingNewTracker = true
        case .switcher: tab = .track; qcPendingSwitcher = true
        }
    }
}

extension Int64: @retroactive Identifiable { public var id: Int64 { self } }
