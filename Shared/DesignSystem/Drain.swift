import SwiftUI

enum Drained {
    static let bezelHex = "#18181A"
    static let innerHex = "#2C2C30"
    static let tickHex = "#3A3A3E"

    static let bezel = Color(hex: bezelHex)
    static let inner = Color(hex: innerHex)
    static let tick = Color(hex: tickHex)
    static let text = Color(hex: "#C7C7CC")
    static let icon = CH.textMuted
    static let iconTile = Color.white.opacity(0.08)
    static let meta = CH.textSecondary
    static let metaStrong = CH.text

    static func overflowTicks(progress: Double, count: Int = 20) -> Int {
        guard progress > 1 else { return 0 }
        return min(count, Int(((progress - 1) * Double(count)).rounded(.down)) + 1)
    }

    static func overLabel(_ seconds: TimeInterval) -> String {
        seconds < 60 ? "just over" : "\(Fmt.words(seconds)) over"
    }
}

extension Color {
    static func mix(_ a: String, _ b: String, _ t: Double) -> Color {
        func rgb(_ hex: String) -> (Double, Double, Double) {
            let v = UInt64(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0
            return (Double((v >> 16) & 0xFF) / 255, Double((v >> 8) & 0xFF) / 255, Double(v & 0xFF) / 255)
        }
        let x = rgb(a), y = rgb(b), p = min(1, max(0, t))
        return Color(.sRGB, red: x.0 + (y.0 - x.0) * p, green: x.1 + (y.1 - x.1) * p, blue: x.2 + (y.2 - x.2) * p)
    }
}

struct PourShape: Shape {
    var level: Double
    var amplitude: Double
    var phase: Double

    func path(in rect: CGRect) -> Path {
        let surface = -amplitude + (rect.height + 2 * amplitude) * level
        let swell = amplitude * sin(.pi * min(1, level * 1.15))
        var path = Path()
        let steps = 32
        for i in 0...steps {
            let x = rect.width * Double(i) / Double(steps)
            let y = surface + swell * (0.7 * sin(x / 38 + phase) + 0.3 * sin(x / 17 - phase * 1.3))
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

struct DrainFrame {
    static let pourDuration = 1.8
    static let pourCurve = UnitCurve.bezier(startControlPoint: UnitPoint(x: 0.7, y: 0),
                                            endControlPoint: UnitPoint(x: 0.84, y: 0))
    static let waveHeight = 24.0
    static let waveSpeed = 14.5
    static let tickStagger = 0.015
    static let tickFade = 0.12
    static let overflowDelay = 0.35
    static let overflowStagger = 0.18
    static let overflowPop = 2.25
    static let reducedDuration = 0.2

    var level: Double
    var wavePhase: Double
    var bezel: Double
    var squash: Double
    let elapsed: Double
    let reduceMotion: Bool

    static let settled = DrainFrame(level: 1, wavePhase: 0, bezel: 1, squash: 0, elapsed: .infinity, reduceMotion: true)

    init(level: Double, wavePhase: Double, bezel: Double, squash: Double, elapsed: Double, reduceMotion: Bool) {
        self.level = level; self.wavePhase = wavePhase; self.bezel = bezel; self.squash = squash
        self.elapsed = elapsed; self.reduceMotion = reduceMotion
    }

    init(elapsed: Double, reduceMotion: Bool) {
        self.elapsed = elapsed
        self.reduceMotion = reduceMotion
        if reduceMotion {
            let p = min(1, max(0, elapsed / Self.reducedDuration))
            level = p; bezel = p; wavePhase = 0; squash = 0
            return
        }
        let raw = min(1, max(0, elapsed / Self.pourDuration))
        level = Self.pourCurve.value(at: raw)
        bezel = min(1, level * 1.1)
        wavePhase = elapsed * Self.waveSpeed
        let landed = elapsed - Self.pourDuration
        squash = landed > 0 ? 0.045 * exp(-7 * landed) * sin(2 * .pi * 3.2 * landed) : 0
    }

    static func duration(overflow: Int, reduceMotion: Bool) -> Double {
        if reduceMotion { return reducedDuration }
        return sweepEnd + overflowDelay + Double(max(0, overflow - 1)) * overflowStagger + 1.1
    }

    private static var sweepEnd: Double { pourDuration + 19 * tickStagger + tickFade }

    func tick(_ index: Int, overflow: Int, accentHex: String) -> (color: Color, scaleY: Double) {
        if reduceMotion {
            let lit = index < overflow
            return (lit ? Color(hex: accentHex) : Color.mix(accentHex, Drained.tickHex, level), 1)
        }
        let startOver = Self.sweepEnd + Self.overflowDelay + Double(index) * Self.overflowStagger
        if index < overflow, elapsed >= startOver {
            let tau = elapsed - startOver
            return (Color(hex: accentHex), 1 + (Self.overflowPop - 1) * exp(-5.5 * tau) * abs(sin(12 * tau)))
        }
        let tau = elapsed - Self.pourDuration - Double(index) * Self.tickStagger
        guard tau > 0 else { return (Color(hex: accentHex), 1) }
        let hop = 0.8 * exp(-10 * tau) * abs(sin(16 * tau))
        return (Color.mix(accentHex, Drained.tickHex, tau / Self.tickFade), 1 + hop)
    }
}

struct DrainStrip: View {
    let frame: DrainFrame
    let overflow: Int
    let accentHex: String
    var count = 20
    var height: CGFloat = 6
    var gap: CGFloat = 3

    var body: some View {
        HStack(spacing: gap) {
            ForEach(0..<count, id: \.self) { i in
                let tick = frame.tick(i, overflow: overflow, accentHex: accentHex)
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(tick.color)
                    .frame(height: height)
                    .frame(maxWidth: .infinity)
                    .scaleEffect(x: 1, y: tick.scaleY)
            }
        }
        .accessibilityElement()
        .accessibilityValue("Over goal")
    }
}
