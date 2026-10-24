import SwiftUI

/// 05 New tracker sheet (Paper B2U-0). Also the tracker editor: `NewTrackerView(editing: activity)`.
/// Accent header (follows the selected colour live) with X / ✓, big name field + live icon, then
/// ICON grid, COLOR dots, TRACK PER segmented control and GOAL PER <period> steppers.
struct NewTrackerView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let editing: Activity?
    /// Set when shown by `.newTrackerOverlay` (home "+", detail EDIT TRACKER); nil as a system sheet.
    private let onClose: (() -> Void)?
    @State private var dragOffset: CGFloat = 0

    @State private var name: String
    @State private var icon: Glyph
    @State private var color: TrackerColor
    @State private var period: GoalPeriod
    @State private var goalMinutes: Int
    @FocusState private var nameFocused: Bool
    @Namespace private var segment

    init(editing: Activity? = nil, onClose: (() -> Void)? = nil) {
        self.editing = editing
        self.onClose = onClose
        if let a = editing {
            _name = State(initialValue: a.name)
            _icon = State(initialValue: a.glyph)
            _color = State(initialValue: a.color)
            _period = State(initialValue: a.period)
            _goalMinutes = State(initialValue: a.goalMinutes)
        } else if QC.demo && QC.screen == .newTracker {
            // Matches the design (Guitar · music · pink · daily 30m).
            _name = State(initialValue: "Guitar")
            _icon = State(initialValue: .music)
            _color = State(initialValue: .pink)
            _period = State(initialValue: .day)
            _goalMinutes = State(initialValue: 30)
        } else {
            _name = State(initialValue: "")
            _icon = State(initialValue: .target)
            _color = State(initialValue: .blue)
            _period = State(initialValue: .day)
            _goalMinutes = State(initialValue: Self.defaultGoal(.day))
        }
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedName.isEmpty }
    private var anim: Animation? { reduceMotion ? nil : .smooth(duration: 0.3) }

    /// Paper: the sheet's top edge sits at y=250 on a 956pt screen → a 706pt-tall surface.
    static let sheetHeight: CGFloat = 706

    var body: some View {
        Group {
            if onClose != nil {
                // Overlay mode (home "+"): edge-to-edge 706pt surface pinned to the bottom, drag down to close.
                // (iOS 26 floats/insets partial-height system sheets, which the design doesn't.)
                GeometryReader { geo in
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        surface
                            .frame(height: min(Self.sheetHeight, geo.size.height))
                            .offset(y: dragOffset)
                    }
                }
                .ignoresSafeArea(.container, edges: .bottom)
            } else {
                // Editor (from the detail sheet): a normal large sheet.
                surface
                    .ignoresSafeArea(.container, edges: .bottom)
                    .presentationBackground(CH.sheet)
                    .presentationDragIndicator(.hidden)
                    .presentationCornerRadius(30)
            }
        }
        .onAppear {
            if editing == nil && !AppClock.isFrozen { nameFocused = true }
        }
    }

    private func close() {
        nameFocused = false
        if let onClose { onClose() } else { dismiss() }
    }

    /// Drag the header down to dismiss (overlay mode).
    private var dismissDrag: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { v in dragOffset = max(0, v.translation.height) }
            .onEnded { v in
                if v.translation.height > 120 || v.predictedEndTranslation.height > 320 {
                    close()
                } else {
                    withAnimation(Motion.spring) { dragOffset = 0 }
                }
            }
    }

    private var surface: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    iconSection.padding(.top, 24)
                    colorSection.padding(.top, 24)
                    periodSection.padding(.top, 24)
                    goalSection.padding(.top, 24)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(CH.sheet)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30, style: .continuous))
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 0) {
            Capsule().fill(Color.black.opacity(0.25)).frame(width: 40, height: 5)
                .padding(.top, 8)

            HStack {
                CircleIconButton(glyph: .close, glyphSize: 13, background: Color.black.opacity(0.12), foreground: .black) {
                    close()
                }
                .accessibilityLabel("Cancel")
                Spacer()
                CircleIconButton(glyph: .check, glyphSize: 16, background: .black, foreground: .white) { save() }
                    .opacity(canSave ? 1 : 0.4)
                    .disabled(!canSave)
                    .accessibilityLabel(editing == nil ? "Create tracker" : "Save tracker")
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(CH.iconTileFill)
                    .frame(width: 52, height: 52)
                    .overlay {
                        GlyphView(icon, size: 26, color: .black)
                            .id(icon)
                            .transition(.scale(scale: 0.6).combined(with: .opacity))
                    }
                VStack(alignment: .leading, spacing: 2) {
                    nameField
                    Text("\(period.adjective) · \(Fmt.goal(minutes: goalMinutes)) goal")
                        .geist(14, .medium, lineHeight: 18)
                        .foregroundStyle(Color.black.opacity(0.6))
                        .contentTransition(.numericText())
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 22)
        }
        .padding(.bottom, 22)
        .background(color.accent, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .gesture(dismissDrag, including: onClose == nil ? .subviews : .all)
    }

    private var nameField: some View {
        ZStack(alignment: .leading) {
            // Static caret for QC snapshots (the design shows the field mid-typing).
            if AppClock.isFrozen && !nameFocused {
                HStack(spacing: 3) {
                    Text(name).geist(32, .semibold, tracking: -0.025, lineHeight: 38).hidden()
                    Rectangle().fill(.black).frame(width: 2, height: 32)
                }
                .allowsHitTesting(false)
            }
            TextField("", text: $name, prompt: Text("Name").foregroundStyle(Color.black.opacity(0.3)))
                .geist(32, .semibold, tracking: -0.025, lineHeight: 38)
                .foregroundStyle(.black)
                .tint(.black)
                .focused($nameFocused)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .onSubmit { if canSave { save() } }
                .frame(height: 38)
        }
    }

    // MARK: Sections

    private var iconSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabelText("Icon")
            HStack(spacing: 0) {
                ForEach(Array(Glyph.trackerIcons.enumerated()), id: \.element) { i, g in
                    if i > 0 { Spacer(minLength: 4) }
                    let selected = g == icon
                    Button { withAnimation(anim) { icon = g } } label: {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(selected ? color.accent : CH.raised)
                            .frame(width: 52, height: 52)
                            .overlay { GlyphView(g, size: 20, color: selected ? .black : CH.textSecondary) }
                    }
                    .buttonStyle(.pressScale)
                    .accessibilityLabel(g.rawValue.capitalized)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
        }
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabelText("Color")
            HStack(spacing: 0) {
                ForEach(Array(TrackerColor.picker.enumerated()), id: \.element.id) { i, c in
                    if i > 0 { Spacer(minLength: 2) }
                    let selected = c.accentHex == color.accentHex
                    Button { withAnimation(anim) { color = c } } label: {
                        ZStack {
                            Circle().strokeBorder(CH.text, lineWidth: 2)
                                .opacity(selected ? 1 : 0)
                                .scaleEffect(selected ? 1 : 0.8)
                            Circle().fill(c.accent)
                                .frame(width: selected ? 24 : 28, height: selected ? 24 : 28)
                        }
                        .frame(width: 34, height: 34)
                        .contentShape(Circle())
                    }
                    .buttonStyle(.pressScale)
                    .accessibilityLabel(c.key.capitalized)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
        }
    }

    private var periodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabelText("Track per")
            HStack(spacing: 4) {
                ForEach(GoalPeriod.allCases) { p in
                    let selected = p == period
                    Button {
                        guard p != period else { return }
                        withAnimation(anim) {
                            goalMinutes = Self.convert(goalMinutes, from: period, to: p)
                            period = p
                        }
                    } label: {
                        Text(p.segmentLabel)
                            .geistMono(12, selected ? .semibold : .medium, tracking: 0.06, lineHeight: 16)
                            .foregroundStyle(selected ? Color.black : CH.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background {
                                if selected {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(CH.text)
                                        .matchedGeometryEffect(id: "segment", in: segment)
                                }
                            }
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.pressScale)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            .padding(4)
            .background(CH.raised, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var goalSection: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                SectionLabelText("Goal per \(period.rawValue)")
                Text(Fmt.hm(TimeInterval(goalMinutes * 60)))
                    .geistMono(36, .medium, tracking: -0.04, lineHeight: 40)
                    .foregroundStyle(CH.text)
                    .contentTransition(.numericText())
            }
            Spacer()
            HStack(spacing: 10) {
                CircleIconButton(glyph: .minus, glyphSize: 14) { step(-1) }
                    .disabled(goalMinutes <= Self.step(period))
                    .accessibilityLabel("Decrease goal")
                CircleIconButton(glyph: .plus, glyphSize: 14) { step(1) }
                    .disabled(goalMinutes >= Self.maxGoal(period))
                    .accessibilityLabel("Increase goal")
            }
        }
    }

    // MARK: Goal maths

    private func step(_ direction: Int) {
        let s = Self.step(period)
        // Snap to the step grid, then move one step.
        let snapped = (goalMinutes / s) * s
        let next = direction > 0 ? snapped + s : (snapped == goalMinutes ? snapped - s : snapped)
        withAnimation(anim) { goalMinutes = min(Self.maxGoal(period), max(s, next)) }
    }

    /// Stepper increment in minutes per period.
    static func step(_ p: GoalPeriod) -> Int {
        switch p {
        case .day: 15
        case .week: 60
        case .month: 300
        case .year: 600
        }
    }

    static func maxGoal(_ p: GoalPeriod) -> Int {
        switch p {
        case .day: 24 * 60
        case .week: 7 * 24 * 60
        case .month: 31 * 24 * 60
        case .year: 365 * 24 * 60
        }
    }

    static func defaultGoal(_ p: GoalPeriod) -> Int {
        switch p {
        case .day: 30
        case .week: 10 * 60
        case .month: 40 * 60
        case .year: 150 * 60
        }
    }

    /// Keeps the same daily pace when switching period, rounded to the new step.
    static func convert(_ minutes: Int, from: GoalPeriod, to: GoalPeriod) -> Int {
        let days: [GoalPeriod: Double] = [.day: 1, .week: 7, .month: 30, .year: 365]
        let perDay = Double(minutes) / days[from]!
        let s = step(to)
        let raw = perDay * days[to]!
        let rounded = Int((raw / Double(s)).rounded()) * s
        return min(maxGoal(to), max(s, rounded))
    }

    // MARK: Save

    private func save() {
        guard canSave else { return }
        if var a = editing {
            a.name = trimmedName
            a.icon = icon.rawValue
            a.colorHex = color.accentHex
            a.period = period
            a.goalMinutes = goalMinutes
            store.updateActivity(a)
        } else {
            store.addActivity(name: trimmedName, colorHex: color.accentHex, icon: icon,
                              goalMinutes: goalMinutes, period: period)
        }
        close()
    }
}

// MARK: - Overlay presentation (home "+")

extension View {
    /// Presents `NewTrackerView` over everything as the design's edge-to-edge sheet: the screen behind
    /// fades to 35% (scrim = #0C0C0E @ 65%) and the 706pt surface slides up from the bottom.
    /// Pass `editing` to open it as the editor for that tracker (from the detail sheet).
    func newTrackerOverlay(isPresented: Binding<Bool>, editing: Activity? = nil) -> some View {
        modifier(NewTrackerOverlay(isPresented: isPresented, editing: editing))
    }
}

private struct NewTrackerOverlay: ViewModifier {
    @Binding var isPresented: Bool
    var editing: Activity?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay {
                ZStack {
                    if isPresented {
                        CH.bg.opacity(0.65)
                            .ignoresSafeArea()
                            .onTapGesture { isPresented = false }
                            .accessibilityHidden(true)
                            .transition(.opacity)
                        NewTrackerView(editing: editing, onClose: { isPresented = false })
                            .accessibilityAddTraits(.isModal)
                            .transition(reduceMotion ? .opacity : .move(edge: .bottom))
                            .zIndex(1)
                    }
                }
                .animation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.4, dampingFraction: 0.9),
                           value: isPresented)
            }
    }
}
