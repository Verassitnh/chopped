import Observation
import SwiftUI

enum AppTab: Hashable { case track, stats }

/// App navigation state. Injected into the environment by `PocusApp`; screens read it with
/// `@Environment(AppRouter.self) private var router`.
@Observable
final class AppRouter {
    var tab: AppTab = .track
    /// Tracker whose detail sheet (02) is open.
    var detailActivityID: Int64?
    /// New tracker sheet (05).
    var showingNewTracker = false
    /// Stats navigation stack; push a tracker id to show Tracker Stats (04).
    var statsPath: [Int64] = []

    func openDetail(_ id: Int64) { detailActivityID = id }
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
        case .detail: tab = .track; detailActivityID = target
        case .stats: tab = .stats
        case .trackerStats: tab = .stats; statsPath = target.map { [$0] } ?? []
        case .newTracker: tab = .track; showingNewTracker = true
        }
    }
}

extension Int64: @retroactive Identifiable { public var id: Int64 { self } }
