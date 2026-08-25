import SwiftUI

/// The unignorable break screen. `isPrimary` is false on secondary displays, which get the same
/// backdrop and countdown but no controls.
struct BreakOverlayView: View {
    let model: AppModel
    let isPrimary: Bool

    var body: some View {
        ZStack {
            VisualEffectBackground(material: .fullScreenUI, blending: .behindWindow)
                .overlay(Color.black.opacity(0.35))
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Label(model.phase.title, systemImage: model.phase.symbolName)
                    .labelStyle(.titleAndIcon)
                    .font(.title2.weight(.medium))
                    .foregroundStyle(.secondary)

                Text(model.timerText)
                    .font(.system(size: 140, weight: .thin, design: .rounded).monospacedDigit())
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.default, value: model.timerText)

                Text(model.stopwatchText)
                    .font(.system(size: 28, design: .rounded).monospacedDigit())
                    .foregroundStyle(Color(nsColor: .systemGreen))
                    .opacity(model.isStopwatchVisible ? 1 : 0)
                    .accessibilityHidden(!model.isStopwatchVisible)

                if isPrimary {
                    Button("Skip break") { model.stopButtonTapped() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .keyboardShortcut(.cancelAction)
                        .padding(.top, 12)

                    Text("Press Esc to end the break")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(48)
        }
        .transition(.opacity)
    }
}
