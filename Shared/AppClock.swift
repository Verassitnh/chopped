import SwiftUI

/// Single source of "now". QC demo mode freezes it (`AppClock.frozen`) so timers and
/// totals render deterministically. Never call `Date()` / `.now` directly in app code.
enum AppClock {
    /// Set once at launch by the QC harness. nil = real time.
    nonisolated(unsafe) static var frozen: Date?

    nonisolated(unsafe) static var offset: TimeInterval = 0

    static var now: Date { frozen ?? Date().addingTimeInterval(offset) }
    static var isFrozen: Bool { frozen != nil }
}

/// TimelineView that hands its content `AppClock.now` (frozen in QC mode, ticking otherwise).
///
///     Ticker(every: 1) { now in Text(Fmt.hms(now.timeIntervalSince(start))) }
struct Ticker<Content: View>: View {
    var every: TimeInterval = 1
    @ViewBuilder var content: (Date) -> Content

    var body: some View {
        if AppClock.isFrozen {
            content(AppClock.now)
        } else {
            TimelineView(.periodic(from: .now, by: every)) { _ in content(AppClock.now) }
        }
    }
}
