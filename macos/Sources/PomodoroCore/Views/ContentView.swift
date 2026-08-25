import SwiftUI

/// Port of the `MainWindow.xaml` layout: a centred vertical stack of
/// selector / debug label / idle stopwatch / countdown / transport buttons.
struct ContentView: View {
    @Bindable var model: AppModel
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(spacing: 16) {
            PhasePicker(selection: model.phase) { model.select(phase: $0) }
                .frame(width: 260)

            // debugTextBlock: FontSize 18, red, Collapsed at runtime.
            if !model.debugText.isEmpty {
                Text(model.debugText)
                    .font(.system(size: 18))
                    .foregroundStyle(.red)
            }

            // inactivityStopwatchTextBlock: FontSize 24, LightGreen, hidden until auto-paused.
            // Kept in the layout with opacity rather than `if`, so nothing jumps when it appears.
            Text(model.stopwatchText)
                .font(.system(size: 24, design: .rounded).monospacedDigit())
                .foregroundStyle(Color(nsColor: .systemGreen))
                .opacity(model.isStopwatchVisible ? 1 : 0)
                .accessibilityHidden(!model.isStopwatchVisible)

            // timerTextBlock: FontSize 64.
            Text(model.timerText)
                .font(.system(size: 64, weight: .light, design: .rounded).monospacedDigit())
                .contentTransition(.numericText(countsDown: true))
                .animation(.default, value: model.timerText)

            HStack(spacing: 20) {
                CircularIconButton(
                    icon: model.primaryIcon,
                    accessibilityLabel: model.primaryIcon == .play ? "Start" : "Pause"
                ) {
                    model.primaryButtonTapped()
                }

                CircularIconButton(
                    icon: .stop,
                    isEnabled: model.isStopEnabled,
                    accessibilityLabel: "Stop"
                ) {
                    model.stopButtonTapped()
                }
            }
            .padding(.top, 8)
        }
        .frame(minWidth: 480, idealWidth: 720, maxWidth: .infinity,
               minHeight: 420, idealHeight: 560, maxHeight: .infinity)
        .background {
            // Order matters: the translucency helper clears the window's own opaque
            // background so the material below it has something to blur.
            ZStack {
                VisualEffectBackground(material: SettingsStore.windowMaterial(), blending: .behindWindow)
                WindowSetup()
            }
            .ignoresSafeArea()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    openSettings()
                } label: {
                    Image(systemName: "gearshape")
                }
                .help("Settings")
            }
        }
    }
}
