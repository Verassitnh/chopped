import SwiftUI

struct SettingsSheet: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @AppStorage(BreakSettings.minutesKey) private var breakMinutes = BreakSettings.defaultMinutes
    @AppStorage(BreakSettings.autoResumeKey) private var autoResume = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Text("Settings")
                    .geist(17, .semibold, tracking: -0.01, lineHeight: 22)
                    .foregroundStyle(CH.text)
                HStack {
                    Spacer()
                    CircleIconButton(glyph: .close, background: Color.white.opacity(0.08)) { dismiss() }
                        .accessibilityLabel("Close")
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            SectionLabelText("Breaks")
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 10)

            VStack(spacing: 0) {
                row("Default break") { lengthStepper }
                CH.pastMid.opacity(0.5).frame(height: 1)
                row("Resume tracker after") {
                    Toggle("Resume tracker after", isOn: $autoResume).labelsHidden()
                }
            }
            .padding(.horizontal, 16)
            .background(CH.raised, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, 20)

            Text(autoResume
                 ? "Breaks end after \(Fmt.goal(minutes: breakMinutes)) and the tracker picks up where it left off. Break time is logged per tracker and doesn't count toward goals."
                 : "Breaks end after \(Fmt.goal(minutes: breakMinutes)) and the tracker stays stopped. Break time is logged per tracker and doesn't count toward goals.")
                .geist(13, .medium, lineHeight: 18)
                .foregroundStyle(CH.textSecondary)
                .padding(.horizontal, 24)
                .padding(.top, 12)
            Spacer(minLength: 0)
        }
        .background(CH.sheet)
        .presentationBackground(CH.sheet)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(30)
        .tint(CH.up)
        .onChange(of: breakMinutes) { store.refresh(silent: true) }
        .onChange(of: autoResume) { store.refresh(silent: true) }
    }

    private func row<Trailing: View>(_ title: String, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .geist(16, .medium, lineHeight: 20)
                .foregroundStyle(Color(hex: "#BDBDBD"))
                .frame(maxWidth: .infinity, alignment: .leading)
            trailing()
        }
        .frame(minHeight: 58)
    }

    private var lengthStepper: some View {
        let choices = BreakSettings.choices
        let index = choices.firstIndex { $0 >= breakMinutes } ?? choices.count - 1
        return HStack(spacing: 10) {
            CircleIconButton(glyph: .minus, size: 34, glyphSize: 12, background: Color.white.opacity(0.08)) {
                breakMinutes = choices[max(0, index - 1)]
            }
            .disabled(index == 0)
            .opacity(index == 0 ? 0.35 : 1)
            .accessibilityLabel("Shorter")
            Text(Fmt.goal(minutes: breakMinutes))
                .geistMono(17, .medium, tracking: -0.03, lineHeight: 22)
                .foregroundStyle(CH.text)
                .contentTransition(.numericText())
                .animation(.snappy, value: breakMinutes)
                .frame(minWidth: 52)
            CircleIconButton(glyph: .plus, size: 34, glyphSize: 12, background: Color.white.opacity(0.08)) {
                breakMinutes = choices[min(choices.count - 1, index + 1)]
            }
            .disabled(index == choices.count - 1)
            .opacity(index == choices.count - 1 ? 0.35 : 1)
            .accessibilityLabel("Longer")
        }
        .accessibilityElement(children: .contain)
        .accessibilityValue(Fmt.goal(minutes: breakMinutes))
    }
}
