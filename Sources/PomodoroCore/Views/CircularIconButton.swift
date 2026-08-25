import SwiftUI

/// Port of the inline WinUI `ControlTemplate { Grid { Ellipse + ContentPresenter } }` that made
/// the transport buttons round: 64x64 circle, 32x32 glyph.
///
/// The Windows original used four white-on-transparent PNGs, including a separate
/// `stop_icon__disabled.png`. SF Symbols replace them: identical shapes, but they adapt to light
/// and dark appearance (the source PNGs are pure white and would vanish on a light window), and
/// the disabled look comes from `foregroundStyle` rather than a second asset.
struct CircularIconButton: View {
    let icon: ControlIcon
    var isEnabled: Bool = true
    var accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(.regularMaterial)
                Circle().stroke(.separator, lineWidth: 1)
                Image(systemName: icon.symbolName)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(isEnabled ? Color.primary : Color.secondary.opacity(0.4))
                    .frame(width: 32, height: 32)
            }
            .frame(width: 64, height: 64)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(accessibilityLabel)
    }
}
