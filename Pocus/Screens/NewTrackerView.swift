import SwiftUI

/// 05 New tracker sheet (Paper B2U-0). PLACEHOLDER — replace with the real screen.
struct NewTrackerView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                CircleIconButton(glyph: .close, background: Color.white.opacity(0.08)) { dismiss() }
                Spacer()
                Text("New tracker").geist(17, .semibold, tracking: -0.01, lineHeight: 22).foregroundStyle(CH.text)
                Spacer()
                CircleIconButton(glyph: .check, glyphSize: 16, background: TrackerColor.pink.accent, foreground: .black) { dismiss() }
            }
            Text("Placeholder — NewTrackerView").geistMono(12).foregroundStyle(CH.textTertiary)
            Spacer()
        }
        .padding(16)
        .background(CH.sheet)
        .presentationDragIndicator(.visible)
    }
}
