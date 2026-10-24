import SwiftUI

/// Stroke glyphs ported verbatim from design/gen/c3/gen.py ICONS (+ `music` from f/gen.py)
/// and the few UI glyphs used in the Paper file. Drawn in their SVG viewBox and scaled to fit.
enum Glyph: String, CaseIterable, Identifiable {
    // Tracker icons (24×24, stroke 2, round caps/joins). Order = New Tracker picker order.
    case target, people, pulse, mail, book, music
    // UI glyphs
    case clock      // tab bar "Track" (24×24)
    case bars       // tab bar "Stats" (24×24)
    case plus       // header "+" (16×16, stroke 2.2)
    case close      // sheet X (14×14, stroke 2.2)
    case check      // sheet ✓ (16×12, stroke 2.4)
    case minus      // goal stepper (14×14, stroke 2)
    case chevronRight // row chevron (24×24)
    case chevronLeft  // back (24×24)
    case arrowUp    // "↑ 4:15" delta (24×24)
    case arrowRight // entries "→" (24×24)
    case play       // filled triangle (16×18, fill)

    var id: String { rawValue }

    /// Icons a user can pick for a tracker.
    static let trackerIcons: [Glyph] = [.target, .people, .pulse, .mail, .book, .music]

    /// Tracker icon by stored key, falling back to `.target`.
    static func tracker(_ key: String?) -> Glyph {
        key.flatMap(Glyph.init(rawValue:)).flatMap { trackerIcons.contains($0) ? $0 : nil } ?? .target
    }

    var spec: GlyphSpec {
        switch self {
        case .target: GlyphSpec([.circle(12, 12, 9), .circle(12, 12, 5), .dot(12, 12, 1.2)])
        case .people: GlyphSpec([.circle(9, 8, 3.2), .path("M3 19c0-3.3 2.7-5.5 6-5.5s6 2.2 6 5.5"),
                                 .circle(16.5, 9, 2.6), .path("M16.8 13.6c2.5.2 4.2 2 4.2 4.4")])
        case .pulse: GlyphSpec([.path("M2.5 12h4l2.5-6.5 4.5 13 2.5-6.5h5.5")])
        case .mail: GlyphSpec([.rect(3, 5, 18, 14, 2.5), .path("M3.8 6.6 12 12.8l8.2-6.2")])
        case .book: GlyphSpec([.path("M12 6.5C10 5 7 4.5 3.5 5v13c3.5-.5 6.5 0 8.5 1.5 2-1.5 5-2 8.5-1.5V5C17 4.5 14 5 12 6.5Z"),
                               .path("M12 6.5v13")])
        case .music: GlyphSpec([.path("M9 18V6l11-2v12"), .circle(6, 18, 3), .circle(17, 16, 3)])
        case .clock: GlyphSpec([.circle(12, 12, 9), .path("M12 7v5l3 2")])
        case .bars: GlyphSpec([.path("M5 20v-6M12 20V5M19 20v-9")])
        case .plus: GlyphSpec(viewBox: CGSize(width: 16, height: 16), strokeWidth: 2.2, [.path("M8 1.5v13M1.5 8h13")])
        case .close: GlyphSpec(viewBox: CGSize(width: 14, height: 14), strokeWidth: 2.2, [.path("M2 2l10 10M12 2 2 12")])
        case .check: GlyphSpec(viewBox: CGSize(width: 16, height: 12), strokeWidth: 2.4, [.path("M1.5 6.5 6 11 14.5 1.5")])
        case .minus: GlyphSpec(viewBox: CGSize(width: 14, height: 14), [.path("M1 7h12")])
        case .chevronRight: GlyphSpec([.path("M9 5l7 7-7 7")])
        case .chevronLeft: GlyphSpec([.path("M15 5l-7 7 7 7")])
        case .arrowUp: GlyphSpec([.path("M12 19V5M5 12l7-7 7 7")])
        case .arrowRight: GlyphSpec([.path("M5 12h14M12 5l7 7-7 7")])
        case .play: GlyphSpec(viewBox: CGSize(width: 16, height: 18), fill: true,
                              [.path("M2 1.8c0-1 1.1-1.6 2-1.1l10.7 6.9c.8.5.8 1.7 0 2.2L4 16.7c-.9.5-2-.1-2-1.1z")])
        }
    }
}

struct GlyphSpec {
    enum Element {
        case path(String)
        case circle(CGFloat, CGFloat, CGFloat)            // cx, cy, r (stroked)
        case dot(CGFloat, CGFloat, CGFloat)               // cx, cy, r (filled + stroked, like the target centre)
        case rect(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat) // x, y, w, h, rx
    }

    var viewBox = CGSize(width: 24, height: 24)
    var strokeWidth: CGFloat = 2
    var fill = false
    let elements: [Element]

    init(viewBox: CGSize = CGSize(width: 24, height: 24), strokeWidth: CGFloat = 2, fill: Bool = false, _ elements: [Element]) {
        self.viewBox = viewBox
        self.strokeWidth = strokeWidth
        self.fill = fill
        self.elements = elements
    }

    /// Outline in viewBox coordinates. `filledOnly` returns just the filled parts.
    func path(filledOnly: Bool = false) -> Path {
        var p = Path()
        for element in elements {
            switch element {
            case .path(let d) where !filledOnly || fill: p.addPath(SVGPath.parse(d))
            case .circle(let cx, let cy, let r) where !filledOnly:
                p.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r))
            case .dot(let cx, let cy, let r):
                p.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r))
            case .rect(let x, let y, let w, let h, let rx) where !filledOnly:
                p.addRoundedRect(in: CGRect(x: x, y: y, width: w, height: h), cornerSize: CGSize(width: rx, height: rx))
            default: break
            }
        }
        return p
    }
}

/// Shape for a glyph, scaled uniformly (aspect-fit, centred) into the proposed rect.
/// Use `GlyphView` for the stroked rendering; this is exposed for custom effects.
struct GlyphShape: Shape {
    let glyph: Glyph
    var filledOnly = false

    func path(in rect: CGRect) -> Path {
        let spec = glyph.spec
        let s = min(rect.width / spec.viewBox.width, rect.height / spec.viewBox.height)
        let dx = rect.minX + (rect.width - spec.viewBox.width * s) / 2
        let dy = rect.minY + (rect.height - spec.viewBox.height * s) / 2
        return spec.path(filledOnly: filledOnly)
            .applying(CGAffineTransform(a: s, b: 0, c: 0, d: s, tx: dx, ty: dy))
    }
}

/// Renders a glyph at `size` (width of the SVG box in points; height follows the viewBox aspect).
/// Stroke width scales with size (2 in a 24 box → 1.5pt at 18pt), matching the SVG.
struct GlyphView: View {
    let glyph: Glyph
    var size: CGFloat = 18
    var color: Color = .black
    /// Override the SVG stroke width (in viewBox units).
    var strokeWidth: CGFloat? = nil

    init(_ glyph: Glyph, size: CGFloat = 18, color: Color = .black, strokeWidth: CGFloat? = nil) {
        self.glyph = glyph
        self.size = size
        self.color = color
        self.strokeWidth = strokeWidth
    }

    var body: some View {
        let spec = glyph.spec
        let scale = size / spec.viewBox.width
        let height = spec.viewBox.height * scale
        ZStack {
            if spec.fill {
                GlyphShape(glyph: glyph).fill(color)
            } else {
                GlyphShape(glyph: glyph)
                    .stroke(color, style: StrokeStyle(lineWidth: (strokeWidth ?? spec.strokeWidth) * scale,
                                                      lineCap: .round, lineJoin: .round))
                GlyphShape(glyph: glyph, filledOnly: true).fill(color)
            }
        }
        .frame(width: size, height: height)
    }
}

/// Minimal SVG path-data parser (M L H V C S Q T Z, absolute + relative, implicit repeats).
enum SVGPath {
    static func parse(_ d: String) -> Path {
        var path = Path()
        var tokens = Tokenizer(d)
        var current = CGPoint.zero, start = CGPoint.zero
        var lastControl: CGPoint?
        var command: Character = "M"

        while let next = tokens.peekCommand() ?? (tokens.hasNumber ? command : nil) {
            if tokens.peekCommand() != nil { tokens.consumeCommand() }
            let rel = next.isLowercase
            let c = Character(next.uppercased())
            func pt() -> CGPoint {
                let x = tokens.number(), y = tokens.number()
                return rel ? CGPoint(x: current.x + x, y: current.y + y) : CGPoint(x: x, y: y)
            }
            switch c {
            case "M":
                current = pt(); start = current; path.move(to: current)
                command = rel ? "l" : "L"  // subsequent pairs are line-tos
                lastControl = nil
                continue
            case "L": current = pt(); path.addLine(to: current); lastControl = nil
            case "H":
                let x = tokens.number(); current.x = rel ? current.x + x : x
                path.addLine(to: current); lastControl = nil
            case "V":
                let y = tokens.number(); current.y = rel ? current.y + y : y
                path.addLine(to: current); lastControl = nil
            case "C":
                let c1 = pt(), c2 = pt(), end = pt()
                path.addCurve(to: end, control1: c1, control2: c2)
                lastControl = c2; current = end
            case "S":
                let c1 = lastControl.map { CGPoint(x: 2 * current.x - $0.x, y: 2 * current.y - $0.y) } ?? current
                let c2 = pt(), end = pt()
                path.addCurve(to: end, control1: c1, control2: c2)
                lastControl = c2; current = end
            case "Q":
                let c1 = pt(), end = pt()
                path.addQuadCurve(to: end, control: c1)
                lastControl = c1; current = end
            case "T":
                let c1 = lastControl.map { CGPoint(x: 2 * current.x - $0.x, y: 2 * current.y - $0.y) } ?? current
                let end = pt()
                path.addQuadCurve(to: end, control: c1)
                lastControl = c1; current = end
            case "Z":
                path.closeSubpath(); current = start; lastControl = nil
            default:
                return path
            }
            command = next
        }
        return path
    }

    private struct Tokenizer {
        let chars: [Character]
        var i = 0
        init(_ s: String) { chars = Array(s) }

        mutating func skipSeparators() {
            while i < chars.count, chars[i] == " " || chars[i] == "," || chars[i] == "\n" { i += 1 }
        }

        mutating func peekCommand() -> Character? {
            skipSeparators()
            guard i < chars.count, chars[i].isLetter, chars[i] != "e", chars[i] != "E" else { return nil }
            return chars[i]
        }

        mutating func consumeCommand() { i += 1 }

        var hasNumber: Bool {
            mutating get {
                skipSeparators()
                guard i < chars.count else { return false }
                return chars[i].isNumber || chars[i] == "-" || chars[i] == "." || chars[i] == "+"
            }
        }

        mutating func number() -> CGFloat {
            skipSeparators()
            var s = ""
            var seenDot = false, seenExp = false
            if i < chars.count, chars[i] == "-" || chars[i] == "+" { s.append(chars[i]); i += 1 }
            while i < chars.count {
                let ch = chars[i]
                if ch.isNumber { s.append(ch) }
                else if ch == "." && !seenDot && !seenExp { seenDot = true; s.append(ch) }
                else if (ch == "e" || ch == "E") && !seenExp {
                    seenExp = true; s.append(ch)
                    if i + 1 < chars.count, chars[i + 1] == "-" || chars[i + 1] == "+" { i += 1; s.append(chars[i]) }
                } else { break }
                i += 1
            }
            return CGFloat(Double(s) ?? 0)
        }
    }
}
