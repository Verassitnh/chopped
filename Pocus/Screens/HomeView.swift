import SwiftUI

/// 01 Home (Paper AB6-0). PLACEHOLDER — replace with the real screen.
/// Currently shows a font specimen + one component sample so the foundation can be QC'd.
struct HomeView: View {
    @Environment(Store.self) private var store
    @Environment(AppRouter.self) private var router

    var body: some View {
        Ticker { now in
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Geist 20/26 medium — lock in twin").geist(20, .medium, tracking: -0.02, lineHeight: 26).foregroundStyle(CH.textMuted)
                    Text("Geist Regular 17").geist(17).foregroundStyle(CH.text)
                    Text("Geist SemiBold 17").geist(17, .semibold).foregroundStyle(CH.text)
                    Text("Geist Bold 17").geist(17, .bold).foregroundStyle(CH.text)
                    Text("Mono 0123456789 5:24").geistMono(20, .regular).foregroundStyle(CH.text)
                    Text("Mono Medium 22:49 / 25:00").geistMono(20).foregroundStyle(CH.text)
                    Text("Mono SemiBold 36:27").geistMono(20, .semibold).foregroundStyle(CH.text)
                    Text("Mono Bold 96:10").geistMono(20, .bold).foregroundStyle(CH.text)
                    Text("00:50:01").geistPixel(62).foregroundStyle(CH.text)
                    SectionLabel("Hours by tracker", value: "4/5 on pace")
                    HStack(spacing: 6) {
                        ForEach(Glyph.allCases) { GlyphView($0, size: 16, color: CH.text) }
                    }

                    if let a = store.activeActivity ?? store.activities.first {
                        sample(a, now: now)
                    }
                    ForEach(store.activities.filter { !store.isRunning($0.id) }) { a in
                        idleSample(a, now: now)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 120)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(CH.bg)
    }

    private func sample(_ a: Activity, now: Date) -> some View {
        let elapsed = store.activeSession.map { now.timeIntervalSince($0.start) } ?? 0
        return TrackerBezel(color: a.color) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 10) {
                        IconTile(glyph: a.glyph, size: 30, radius: 9, glyphSize: 16)
                        Text(a.name).geist(20, .semibold, tracking: -0.015, lineHeight: 24).foregroundStyle(.black)
                    }
                    Text(Fmt.hms(elapsed)).geistPixel(62).foregroundStyle(.black)
                    Text("Clocked in · \(Fmt.time(store.activeSession?.start ?? now)) · \(Fmt.hm(store.periodTotal(for: a, now: now))) of \(Fmt.goal(minutes: a.goalMinutes))")
                        .geist(13, .medium, lineHeight: 17).foregroundStyle(CH.onAccentSecondary)
                }
                Spacer(minLength: 0)
                StopButton(accent: a.color.accent) { store.stop() }
            }
            .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 14))
        } footer: {
            SegmentStrip(fraction: store.progress(for: a, now: now), accent: a.color.accent)
        }
        .onTapGesture { router.openDetail(a.id) }
    }

    private func idleSample(_ a: Activity, now: Date) -> some View {
        TrackerBezel(color: a.color) {
            HStack(spacing: 12) {
                IconTile(glyph: a.glyph)
                VStack(alignment: .leading, spacing: 1) {
                    Text(a.name).geist(18, .semibold, tracking: -0.015, lineHeight: 22).foregroundStyle(.black)
                    Text(a.goalLine).geist(13, .medium, lineHeight: 17).foregroundStyle(CH.onAccentSecondary)
                }
                Spacer(minLength: 0)
                Text(Fmt.hm(store.periodTotal(for: a, now: now))).geistMono(26, .medium, tracking: -0.05, lineHeight: 30).foregroundStyle(.black)
                PlayButton { store.clockIn(a) }
            }
            .padding(EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 12))
        } footer: {
            SegmentStrip(fraction: store.progress(for: a, now: now), accent: a.color.accent)
        }
    }
}
