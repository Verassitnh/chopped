import SwiftUI

/// QC hosts for the system surfaces. `-QCScreen <widgets|liveActivity|island>` (with `-QCDemo`) shows the
/// widget / Live Activity / Dynamic Island views laid out like Paper artboards 07 / 06 / 08, and with
/// `-QCSnapshot` writes `Documents/qc-<name>.png`. Add `-QCRealSize` to render widgets at the system
/// sizes of the iPhone 18 Pro Max (small 176.67, medium 378×176.67, as logged by chronod) instead of the artboard sizes (182, 388×170).
enum QCSurface: String {
    case widgets, liveActivity, island

    static let current: QCSurface? = {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-QCScreen"), i + 1 < args.count else { return nil }
        return QCSurface(rawValue: args[i + 1])
    }()

    static let realSize = ProcessInfo.processInfo.arguments.contains("-QCRealSize")
}

/// `-QCIntent start:<trackerID>|stop` runs the widget intent once at launch (exercises the shared-DB
/// write + Live Activity / widget sync path without tapping a widget).
enum QCIntent {
    @MainActor static func runIfRequested() async {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-QCIntent"), i + 1 < args.count else { return }
        let cmd = args[i + 1]
        if cmd == "stop" {
            _ = try? await StopTrackerIntent().perform()
        } else if cmd.hasPrefix("start:"), let id = Int64(cmd.dropFirst(6)) {
            _ = try? await StartTrackerIntent(trackerID: id).perform()
        }
        QC.log("QC intent \(cmd) done; running=\(ChoppedData.snapshot()?.running?.name ?? "none")")
    }
}

/// Swaps the app root for a surface QC page when requested.
struct QCSurfaceRoot<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        if let surface = QCSurface.current {
            QCSurfacesView(surface: surface)
                .task {
                    guard QC.snapshot else { return }
                    try? await Task.sleep(for: .seconds(1.5))
                    QC.writeSnapshot(name: "qc-\(surface.rawValue)\(QCSurface.realSize ? "-real" : "").png")
                }
        } else {
            content.task { await QCIntent.runIfRequested() }
        }
    }
}

extension Store {
    /// Same model the widget extension reads from the shared DB.
    func surfaceSnapshot(now: Date) -> ChoppedSnapshot {
        ChoppedSnapshot(date: now, trackers: activities.map { a in
            let period = currentPeriod(for: a, now: now)
            let running = activeSession?.activityID == a.id ? activeSession : nil
            let logged = sessions.filter { $0.activityID == a.id && $0.end != nil }
                .reduce(0) { $0 + $1.duration(in: period, now: now) }
            return TrackerSnapshot(id: a.id, name: a.name, colorHex: a.colorHex, icon: a.icon, goalMinutes: a.goalMinutes,
                                   period: a.period, position: a.position, periodInterval: period, periodLogged: logged,
                                   runningStart: running?.start,
                                   lastUsed: sessions.first { $0.activityID == a.id }?.start)
        })
    }
}

struct QCSurfacesView: View {
    let surface: QCSurface
    @Environment(Store.self) private var store

    var body: some View {
        let now = AppClock.now
        let snapshot = store.surfaceSnapshot(now: now)
        switch surface {
        case .widgets: widgets(snapshot, now: now)
        case .liveActivity: lock(snapshot, now: now)
        case .island: island(snapshot, now: now)
        }
    }

    // 07 — bg #121214, status 62, medium at y 86 (26pt sides), smalls 20 below the caption, gap 24.
    private func widgets(_ s: ChoppedSnapshot, now: Date) -> some View {
        let real = QCSurface.realSize
        let small: CGFloat = real ? 176.67 : 182
        let medium = CGSize(width: real ? 378 : 388, height: real ? 176.67 : 170)
        let exercise = s.trackers.first { $0.name == "Exercise" } ?? s.trackers.last!
        return VStack(spacing: 0) {
            Color.clear.frame(height: 62)
            VStack(spacing: 8) {
                widgetFrame(MediumWidgetView.background, size: medium) { MediumWidgetView(snapshot: s, now: now) }
                caption
            }
            .padding(.top, 24)
            HStack(alignment: .top, spacing: 24) {
                VStack(spacing: 8) {
                    widgetFrame(s.running!.color.tint, size: CGSize(width: small, height: small)) {
                        SmallWidgetView(tracker: s.running!, now: now)
                    }
                    caption
                }
                VStack(spacing: 8) {
                    widgetFrame(exercise.color.tint, size: CGSize(width: small, height: small)) {
                        SmallWidgetView(tracker: exercise, somethingRunning: s.running != nil, now: now)
                    }
                    caption
                }
            }
            .padding(.top, 20)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#121214").ignoresSafeArea())
        .ignoresSafeArea()
    }

    private var caption: some View {
        Text("Chopped").geist(12, .medium, lineHeight: 16).foregroundStyle(CH.textSecondary)
    }

    private func widgetFrame<V: View>(_ bg: Color, size: CGSize, @ViewBuilder _ v: () -> V) -> some View {
        v().frame(width: size.width, height: size.height)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    // 06 — bg #0A0A0C, card 14pt from the sides, 120 from the bottom.
    private func lock(_ s: ChoppedSnapshot, now: Date) -> some View {
        VStack(spacing: 0) {
            Spacer()
            if let state = s.activityState {
                LockActivityView(state: state, now: now)
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 120)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#0A0A0C"))
        .ignoresSafeArea()
    }

    // 08 — bg #1A1A1C. Compact pill 200×38 (10/14 padding) + minimal 38; expanded r44 at 12pt sides.
    private func island(_ s: ChoppedSnapshot, now: Date) -> some View {
        let state = s.activityState!
        return VStack(spacing: 0) {
            VStack(spacing: 14) {
                SectionLabelText("Island · compact / minimal")
                HStack(spacing: 10) {
                    HStack {
                        IslandIconTile(state: state)
                        Spacer()
                        IslandCompactTimer(state: state, now: now)
                    }
                    .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 14))
                    .frame(width: 200, height: 38)
                    .background(.black, in: Capsule())
                    IslandIconTile(state: state)
                        .frame(width: 38, height: 38)
                        .background(.black, in: Circle())
                }
            }
            .padding(.top, 32)
            VStack(spacing: 14) {
                SectionLabelText("Island · expanded")
                IslandExpandedView(state: state, now: now)
                    .background(.black, in: RoundedRectangle(cornerRadius: 44, style: .continuous))
            }
            .padding(EdgeInsets(top: 32, leading: 12, bottom: 0, trailing: 12))
            VStack(spacing: 16) {
                SectionLabelText("Control Center")
                HStack(spacing: 20) {
                    ForEach(controlTrackers(s)) { t in controlMock(t) }
                }
            }
            .padding(.vertical, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#1A1A1C"))
        .ignoresSafeArea()
    }

    private func controlTrackers(_ s: ChoppedSnapshot) -> [TrackerSnapshot] {
        let names = ["Deep Work", "Exercise", "Email"]
        return names.compactMap { n in s.trackers.first { $0.name == n } }
    }

    /// Mock of the Control Center buttons (the real ones are system-rendered with SF Symbols).
    private func controlMock(_ t: TrackerSnapshot) -> some View {
        VStack(spacing: 8) {
            Circle().fill(t.isRunning ? t.color.accent : Color.white.opacity(0.1))
                .frame(width: 68, height: 68)
                .overlay {
                    if t.isRunning {
                        RoundedRectangle(cornerRadius: 5, style: .continuous).fill(.black).frame(width: 20, height: 20)
                    } else {
                        GlyphView(t.glyph, size: 24, color: t.color.accent)
                    }
                }
            Text(t.name).geist(11, .semibold, lineHeight: 15)
                .foregroundStyle(t.isRunning ? CH.text : CH.textSecondary)
        }
    }
}
