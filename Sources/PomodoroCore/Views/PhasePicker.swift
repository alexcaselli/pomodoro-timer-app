import SwiftUI

/// A segmented Work/Break control, hand-built.
///
/// AppKit's segmented control — which `Picker(.segmented)` wraps — will not render an icon
/// alongside a title here: `Label` collapses to title-only, and interpolating an `Image` into
/// the `Text` is dropped too. Building the control out of buttons is the only way to get the
/// glyph to draw, and it also lets the selection slide between segments.
///
/// On macOS 26 the track is a Liquid Glass surface and the selection is a tinted glass pill that
/// morphs across, sharing a `GlassGroup` so the two blend rather than stacking.
struct PhasePicker: View {
    let selection: TimerPhase
    let select: (TimerPhase) -> Void

    @Namespace private var namespace

    private var trackShape: some Shape { RoundedRectangle(cornerRadius: 11, style: .continuous) }
    private var pillShape: some Shape { RoundedRectangle(cornerRadius: 9, style: .continuous) }

    var body: some View {
        GlassGroup(spacing: 6) {
            HStack(spacing: 2) {
                ForEach(TimerPhase.allCases) { phase in
                    segment(phase)
                }
            }
            .padding(3)
            .glassSurface(in: trackShape, fallback: .quaternary)
        }
        .animation(.snappy(duration: 0.28), value: selection)
    }

    private func segment(_ phase: TimerPhase) -> some View {
        let isSelected = phase == selection
        return Button {
            select(phase)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: phase.symbolName)
                    .imageScale(.medium)
                Text(phase.title)
            }
            .fontWeight(isSelected ? .semibold : .regular)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background {
                if isSelected {
                    selectionPill
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(phase.title)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    /// One pill, shared across segments, so it travels instead of cross-fading.
    @ViewBuilder
    private var selectionPill: some View {
        if #available(macOS 26.0, *), GlassStyling.isEnabled {
            Color.clear
                .glassEffect(Glass.configured(tint: .accentColor, interactive: true), in: pillShape)
                .glassEffectID("selection", in: namespace)
        } else {
            pillShape
                .fill(Color.accentColor)
                .matchedGeometryEffect(id: "selection", in: namespace)
        }
    }
}
