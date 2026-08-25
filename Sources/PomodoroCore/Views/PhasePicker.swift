import SwiftUI

/// A segmented Work/Break control, hand-built.
///
/// AppKit's segmented control — which `Picker(.segmented)` wraps — will not render an icon
/// alongside a title here: `Label` collapses to title-only, and interpolating an `Image` into
/// the `Text` is dropped too. Building the control out of buttons is the only way to get the
/// glyph to draw, and it also lets the selection slide between segments.
struct PhasePicker: View {
    let selection: TimerPhase
    let select: (TimerPhase) -> Void

    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 2) {
            ForEach(TimerPhase.allCases) { phase in
                segment(phase)
            }
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(.quaternary)
        )
        .animation(.snappy(duration: 0.22), value: selection)
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
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.accentColor)
                        .matchedGeometryEffect(id: "selection", in: namespace)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(phase.title)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}
