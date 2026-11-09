import SwiftUI

struct CardSchedule: Equatable {
    let date: Date
    var done = false
}

enum CardMotion {
    static let resize = Animation.timingCurve(0.22, 1, 0.36, 1, duration: 0.4)
    static let swap = Animation.easeInOut(duration: 0.25)
    static let textSwap = Animation.easeInOut(duration: 0.15)
    static let check = Animation.easeInOut(duration: 0.5)
    static let checkPop = Animation.timingCurve(0.34, 1.36, 0.64, 1, duration: 0.5)
    static let successLead: TimeInterval = 0.42
}

struct BlurSwap: ViewModifier {
    let active: Bool
    var blur: CGFloat = 2
    var dy: CGFloat = 4

    func body(content: Content) -> some View {
        content
            .opacity(active ? 0 : 1)
            .blur(radius: active ? blur : 0)
            .offset(y: active ? dy : 0)
    }
}

extension AnyTransition {
    static func blurSwap(dy: CGFloat = 4) -> AnyTransition {
        .modifier(active: BlurSwap(active: true, dy: dy), identity: BlurSwap(active: false, dy: dy))
    }

    static var cardContent: AnyTransition {
        .asymmetric(insertion: .blurSwap().animation(.easeInOut(duration: 0.25).delay(0.08)),
                    removal: .blurSwap().animation(.easeInOut(duration: 0.15)))
    }
}

struct ScheduleStripes: View {
    var body: some View {
        Canvas { ctx, size in
            var path = Path()
            let step: CGFloat = 8
            var x: CGFloat = -size.height
            while x < size.width + size.height {
                path.move(to: CGPoint(x: x, y: size.height))
                path.addLine(to: CGPoint(x: x + size.height, y: 0))
                x += step
            }
            ctx.stroke(path, with: .color(.black.opacity(0.15)), lineWidth: 2)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct ScheduleTime: View {
    let date: Date
    var color: Color

    var body: some View {
        let parts = Fmt.clockParts(date)
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(parts.time)
                .geistMono(26, .medium, tracking: -0.05, lineHeight: 30)
            Text(parts.meridiem)
                .geistMono(15, .medium, lineHeight: 18)
        }
        .foregroundStyle(color)
        .lineLimit(1)
        .fixedSize()
    }
}

struct CardActionButton: View {
    enum Mode: Equatable { case play, cancel, done }

    let mode: Mode
    var size: CGFloat = 40
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(.black)
                .frame(width: size, height: size)
                .overlay {
                    ZStack {
                        GlyphView(.play, size: (size * 0.32).rounded(), color: .white)
                            .offset(x: size * 0.03)
                            .modifier(IconSwap(on: mode == .play))
                        GlyphView(.close, size: (size * 0.3).rounded(), color: .white)
                            .modifier(IconSwap(on: mode == .cancel))
                        GlyphView(.check, size: (size * 0.4).rounded(), color: CH.up, strokeWidth: 2.4)
                            .scaleEffect(mode == .done ? 1 : 0.25)
                            .animation(CardMotion.checkPop, value: mode)
                            .blur(radius: mode == .done ? 0 : 8)
                            .opacity(mode == .done ? 1 : 0)
                            .animation(CardMotion.check, value: mode)
                    }
                }
                .contentShape(Circle())
        }
        .buttonStyle(.pressScale)
        .disabled(mode == .done)
        .accessibilityLabel(mode == .play ? "Start" : mode == .cancel ? "Cancel scheduled switch" : "Switched")
    }
}

private struct IconSwap: ViewModifier {
    let on: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(on ? 1 : 0.25)
            .blur(radius: on ? 0 : 2)
            .opacity(on ? 1 : 0)
            .animation(CardMotion.swap, value: on)
    }
}

struct CardBump: ViewModifier {
    let trigger: Int

    func body(content: Content) -> some View {
        content.keyframeAnimator(initialValue: 1.0, trigger: trigger) { view, scale in
            view.scaleEffect(scale)
        } keyframes: { _ in
            CubicKeyframe(0.97, duration: 0.1225)
            CubicKeyframe(1.0105, duration: 0.1225)
            CubicKeyframe(1, duration: 0.105)
        }
    }
}
