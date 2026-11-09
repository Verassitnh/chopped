import SwiftUI
import UIKit

struct SwitchWheel: View {
    let base: Date
    let now: Date
    let range: ClosedRange<Int>
    @Binding var offset: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var position: Double = 0
    @State private var dragStart: Double?
    @State private var lastDetent = 0
    @State private var motion: Task<Void, Never>?
    @State private var width: CGFloat = 0

    static let height: CGFloat = 84
    private static let step = Double.pi / 50
    private static let selection = UISelectionFeedbackGenerator()
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)

    private var pointsPerMinute: Double { max(1, Double(width) / 2 * 1.02 * Self.step) }

    var body: some View {
        Canvas { ctx, size in draw(&ctx, size: size) }
            .frame(height: Self.height)
            .onGeometryChange(for: CGFloat.self, of: \.size.width) { width = $0 }
            .contentShape(Rectangle())
            .gesture(drag)
            .onAppear {
                position = Double(offset)
                lastDetent = offset
            }
            .onChange(of: offset) { _, new in
                guard dragStart == nil, motion == nil, Int(position.rounded()) != new else { return }
                settle(to: new)
            }
            .onDisappear { motion?.cancel() }
            .accessibilityElement()
            .accessibilityLabel("Switch time")
            .accessibilityValue(accessibilityValue)
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: offset = clamp(offset + 1)
                case .decrement: offset = clamp(offset - 1)
                @unknown default: break
                }
            }
    }

    private var accessibilityValue: String {
        let time = Fmt.clock(base.addingTimeInterval(TimeInterval(offset * 60)))
        switch offset {
        case 0: return "Now"
        case 1...: return "\(time), in \(offset) minutes"
        default: return "\(time), \(-offset) minutes ago"
        }
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if dragStart == nil {
                    motion?.cancel()
                    motion = nil
                    dragStart = position
                    Self.selection.prepare()
                }
                let raw = (dragStart ?? position) - Double(value.translation.width) / pointsPerMinute
                setPosition(rubberBand(raw))
            }
            .onEnded { value in
                dragStart = nil
                let velocity = -Double(value.velocity.width) / pointsPerMinute
                if reduceMotion || !range.contains(Int(position.rounded())) {
                    settle(to: clamp(Int(position.rounded())))
                } else {
                    coast(velocity: velocity)
                }
            }
    }

    private func clamp(_ m: Int) -> Int { min(max(m, range.lowerBound), range.upperBound) }

    private func rubberBand(_ p: Double) -> Double {
        let lo = Double(range.lowerBound), hi = Double(range.upperBound)
        if p < lo { return lo - (lo - p) * 0.25 }
        if p > hi { return hi + (p - hi) * 0.25 }
        return p
    }

    private func setPosition(_ p: Double) {
        position = p
        let detent = clamp(Int(p.rounded()))
        guard detent != lastDetent else { return }
        lastDetent = detent
        offset = detent
        if detent == 0 {
            Self.medium.impactOccurred()
        } else if Self.minuteOfDay(base, plus: detent) % 5 == 0 {
            Self.light.impactOccurred(intensity: 0.8)
        } else {
            Self.selection.selectionChanged()
        }
    }

    private func coast(velocity: Double) {
        motion?.cancel()
        motion = Task { @MainActor in
            var p = position
            var v = min(max(velocity, -90), 90)
            let lo = Double(range.lowerBound), hi = Double(range.upperBound)
            var last = Date()
            while !Task.isCancelled, abs(v) > 3 {
                try? await Task.sleep(nanoseconds: 8_000_000)
                let t = Date()
                let dt = t.timeIntervalSince(last)
                last = t
                p += v * dt
                v *= pow(0.12, dt)
                if p <= lo || p >= hi {
                    p = min(max(p, lo), hi)
                    v = 0
                }
                setPosition(p)
            }
            guard !Task.isCancelled else { return }
            await glide(to: clamp(Int(p.rounded())))
            motion = nil
        }
    }

    private func settle(to target: Int) {
        motion?.cancel()
        if reduceMotion {
            setPosition(Double(target))
            motion = nil
            return
        }
        motion = Task { @MainActor in
            await glide(to: target)
            motion = nil
        }
    }

    @MainActor private func glide(to target: Int) async {
        var last = Date()
        let goal = Double(target)
        while !Task.isCancelled, abs(position - goal) > 0.004 {
            try? await Task.sleep(nanoseconds: 8_000_000)
            let t = Date()
            let dt = t.timeIntervalSince(last)
            last = t
            setPosition(goal + (position - goal) * exp(-16 * dt))
        }
        guard !Task.isCancelled else { return }
        setPosition(goal)
    }

    private static func minuteOfDay(_ date: Date, plus minutes: Int = 0) -> Int {
        let c = Calendar.chopped.dateComponents([.hour, .minute], from: date)
        let m = (c.hour ?? 0) * 60 + (c.minute ?? 0) + minutes
        return (m % 1440 + 1440) % 1440
    }

    private static func label(minuteOfDay m: Int) -> String {
        let h = m / 60, h12 = h % 12 == 0 ? 12 : h % 12
        return m % 60 == 0 ? "\(h12) \(h < 12 ? "AM" : "PM")" : "\(h12):\(String(format: "%02d", m % 60))"
    }

    private static let tickMajor = Color(hex: "#8E8E93")
    private static let tickMinor = Color(hex: "#55555A")

    private func draw(_ ctx: inout GraphicsContext, size: CGSize) {
        let w = size.width, h = size.height, cx = w / 2
        let radius = Double(w) / 2 * 1.02
        let rect = CGRect(origin: .zero, size: size)
        let body = RoundedRectangle(cornerRadius: 22, style: .continuous).path(in: rect)
        ctx.fill(body, with: .linearGradient(
            Gradient(colors: [Color(hex: "#232326"), Color(hex: "#1A1A1D"), Color(hex: "#121214")]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))

        var ticks = ctx
        ticks.clip(to: body)
        let lit = offset == 0 ? nil : min(0, offset)...max(0, offset)
        let baseMinute = Self.minuteOfDay(base)
        func project(_ minutes: Double) -> (x: CGFloat, c: Double)? {
            let theta = (minutes - position) * Self.step
            guard abs(theta) < .pi / 2 * 0.97 else { return nil }
            return (cx + CGFloat(radius * sin(theta)), cos(theta))
        }
        for k in (range.lowerBound - 25)...(range.upperBound + 25) {
            guard let (x, c) = project(Double(k)) else { continue }
            let m = ((baseMinute + k) % 1440 + 1440) % 1440
            let quarter = m % 15 == 0, major = m % 5 == 0
            let isLit = lit?.contains(k) ?? false
            let dim = range.contains(k) ? 1.0 : 0.35
            let th = CGFloat((quarter ? 26.0 : major ? 18.0 : 11.0) * (0.75 + 0.25 * c))
            let tw = CGFloat(max(0.7, 2.4 * c))
            let color = isLit ? CH.text : major ? Self.tickMajor : Self.tickMinor
            let tick = RoundedRectangle(cornerRadius: tw / 2)
                .path(in: CGRect(x: x - tw / 2, y: 34 - th / 2, width: tw, height: th))
            ticks.fill(tick, with: .color(color.opacity(pow(c, 1.6) * dim)))
            if quarter {
                var text = ticks
                text.opacity = min(1, pow(c, 1.4)) * dim
                text.draw(Text(Self.label(minuteOfDay: m))
                            .font(.geistMono(11 * (0.7 + 0.3 * c), .medium))
                            .foregroundColor(isLit ? CH.text : Self.tickMajor),
                          at: CGPoint(x: x, y: 68), anchor: .center)
            }
        }
        if offset != 0, let (x, c) = project(now.timeIntervalSince(base) / 60) {
            ticks.fill(Circle().path(in: CGRect(x: x - 2.5, y: 10.5, width: 5, height: 5)),
                       with: .color(CH.up.opacity(pow(c, 1.4))))
        }

        ctx.fill(body, with: .linearGradient(
            Gradient(stops: [.init(color: CH.sheet, location: 0), .init(color: CH.sheet.opacity(0), location: 0.2),
                             .init(color: CH.sheet.opacity(0), location: 0.8), .init(color: CH.sheet, location: 1)]),
            startPoint: .zero, endPoint: CGPoint(x: w, y: 0)))
        ctx.stroke(RoundedRectangle(cornerRadius: 21.5, style: .continuous).path(in: rect.insetBy(dx: 0.5, dy: 0.5)),
                   with: .color(.white.opacity(0.08)), lineWidth: 1)

        var top = Path()
        top.move(to: CGPoint(x: cx - 6, y: 0))
        top.addLine(to: CGPoint(x: cx + 6, y: 0))
        top.addLine(to: CGPoint(x: cx, y: 7))
        top.closeSubpath()
        ctx.fill(top, with: .color(offset == 0 ? CH.up : CH.text))
        ctx.fill(RoundedRectangle(cornerRadius: 1.5).path(in: CGRect(x: cx - 1.5, y: 9, width: 3, height: 50)),
                 with: .color(CH.text))
        var bottom = Path()
        bottom.move(to: CGPoint(x: cx - 6, y: h))
        bottom.addLine(to: CGPoint(x: cx + 6, y: h))
        bottom.addLine(to: CGPoint(x: cx, y: h - 7))
        bottom.closeSubpath()
        ctx.fill(bottom, with: .color(CH.text))
    }
}
