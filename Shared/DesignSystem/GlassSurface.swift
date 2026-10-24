import SwiftUI
import UIKit

/// Paper "glass": `backdrop-filter: blur(20–24px)` + a white fill (`#FFFFFF14`–`17`) + 1pt white border
/// + a 1pt inset top highlight. SwiftUI materials add their own grey tint (+~27 levels over #0C0C0E, so the
/// glass read ~2× brighter than the design); `BackdropBlur` is the blur alone, so over the flat background
/// the surface is exactly bg + fill, like Paper.
struct GlassSurface<S: InsettableShape>: View {
    let shape: S
    var fill: Color = CH.glassFill
    var stroke: Color = CH.glassStroke
    var highlight: Color = CH.glassHighlight

    var body: some View {
        BackdropBlur()
            .clipShape(shape)
            .overlay(shape.fill(fill))
            .overlay(shape.strokeBorder(stroke, lineWidth: 1))
            .overlay(InsetTopHighlight(shape: shape.inset(by: 1), color: highlight))
    }
}

/// CSS `box-shadow: <color> 0 1px 0 inset`: the part of `shape` not covered by itself moved 1pt down.
private struct InsetTopHighlight<S: Shape>: View {
    let shape: S
    let color: Color

    var body: some View {
        shape.fill(color)
            .mask {
                Rectangle()
                    .overlay(shape.offset(y: 1).blendMode(.destinationOut))
                    .compositingGroup()
            }
            .clipShape(shape)
            .allowsHitTesting(false)
    }
}

/// Untinted backdrop blur (UIVisualEffectView with the material's tint layers cleared).
struct BackdropBlur: UIViewRepresentable {
    func makeUIView(context: Context) -> UntintedBlurView { UntintedBlurView() }
    func updateUIView(_ uiView: UntintedBlurView, context: Context) {}

    final class UntintedBlurView: UIVisualEffectView {
        init() {
            super.init(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
            isUserInteractionEnabled = false
        }
        required init?(coder: NSCoder) { fatalError() }

        override func layoutSubviews() {
            super.layoutSubviews()
            // The material's backdrop runs [luminanceCurveMap, colorSaturate, gaussianBlur]: the curve map lifts
            // near-blacks by ~27 levels. Keep only the blur, and clear any tint subviews.
            for v in subviews {
                let name = String(describing: type(of: v))
                if name.contains("Backdrop"), let filters = v.layer.filters, filters.count > 1 {
                    v.layer.filters = filters.filter { String(describing: $0).contains("gaussianBlur") }
                } else if name.contains("VisualEffectSubview") {
                    v.backgroundColor = .clear
                }
            }
        }
    }
}
