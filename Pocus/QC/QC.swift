import SwiftUI
import UIKit

/// Screens addressable by `-QCScreen <name>` (and the app's top-level routes).
enum AppScreen: String, CaseIterable {
    case home, detail, stats, trackerStats, newTracker
}

/// QC harness. Launch arguments:
///   -QCScreen <home|detail|stats|trackerStats|newTracker>   open that screen directly
///   -QCDemo                                                  in-memory demo data + frozen now (Fri 23 Oct 2026 20:56:01)
///   -QCSnapshot                                              ~1.5s after layout, write Documents/qc-<screen>.png
///   -QCFullPage                                              (stats/trackerStats) also write qc-<screen>-full.png, full scroll height
enum QC {
    private static let args = ProcessInfo.processInfo.arguments

    static let screen: AppScreen? = {
        guard let i = args.firstIndex(of: "-QCScreen"), i + 1 < args.count else { return nil }
        return AppScreen(rawValue: args[i + 1])
    }()

    static let demo = args.contains("-QCDemo")
    static let snapshot = args.contains("-QCSnapshot")
    /// With -QCSnapshot: long scrolling screens also write qc-<screen>-full.png at full content height.
    static let fullPage = args.contains("-QCFullPage")

    /// Snapshot file name: qc-<screen>.png (qc-app.png when no -QCScreen).
    static var snapshotName: String { "qc-\(screen?.rawValue ?? "app").png" }

    /// Call once at launch before building the Store.
    static func configure() {
        if demo { AppClock.frozen = DemoData.now }
        if demo || screen != nil || snapshot {
            let missing = GeistFont.missing
            log("QC demo=\(demo) screen=\(screen?.rawValue ?? "-") snapshot=\(snapshot) now=\(AppClock.now) missingFonts=\(missing)")
        }
    }

    static func makeStore() -> Store {
        guard demo else { return Store() }
        return DemoData.makeStore()
    }

    /// Writes the key window to Documents/<name> at native scale. Returns the file URL.
    @MainActor @discardableResult
    static func writeSnapshot(name: String = QC.snapshotName) -> URL? {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow) ?? UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first?.windows.first
        else { log("QC snapshot: no window"); return nil }

        let format = UIGraphicsImageRendererFormat()
        format.scale = window.screen.scale
        format.opaque = true
        let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(name)
        do {
            try image.pngData()?.write(to: url, options: .atomic)
            log("QC snapshot written: \(url.path) (\(Int(window.bounds.width))x\(Int(window.bounds.height))@\(Int(format.scale))x)")
            return url
        } catch {
            log("QC snapshot failed: \(error)")
            return nil
        }
    }

    /// Renders `view` (already sized) with ImageRenderer at the screen scale and writes Documents/<name>.
    @MainActor @discardableResult
    static func writeFullPage<V: View>(_ view: V, name: String) -> URL? {
        let renderer = ImageRenderer(content: view.environment(\.colorScheme, .dark))
        renderer.scale = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first?.screen.scale ?? 3
        renderer.isOpaque = true
        guard let data = renderer.uiImage?.pngData() else { log("QC full page: render failed"); return nil }
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(name)
        do {
            try data.write(to: url, options: .atomic)
            log("QC full page written: \(url.path)")
            return url
        } catch {
            log("QC full page failed: \(error)")
            return nil
        }
    }

    static func log(_ message: String) {
        NSLog("%@", message)
    }
}

/// Attach once at the root: after layout settles, writes the snapshot when -QCSnapshot is set.
struct QCSnapshotTrigger: ViewModifier {
    /// Extra wait for routes that present a sheet / push.
    var delay: TimeInterval

    func body(content: Content) -> some View {
        content.task {
            guard QC.snapshot else { return }
            try? await Task.sleep(for: .seconds(delay))
            QC.writeSnapshot()
        }
    }
}
