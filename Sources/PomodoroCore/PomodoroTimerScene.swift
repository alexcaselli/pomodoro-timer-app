import SwiftUI

/// The SwiftUI scene graph. Not `@main`: the entry points live in the thin `pomodoro-app` and
/// `pomodoro-selfcheck` executable targets, so the self-check can exercise this module's types
/// without ever building a window.
struct PomodoroTimerScene: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        // `Window`, not `WindowGroup`: this is a single-instance app and Cmd-N must not be able
        // to spawn a second, independent timer.
        Window("Pomodoro Timer", id: "main") {
            ContentView(model: delegate.model)
                .task { wireSceneActions() }
        }
        .defaultSize(width: 720, height: 560)   // the Windows SizeInt32(720, 560)
        .windowResizability(.contentMinSize)

        Settings {
            SettingsView(model: delegate.model)
        }
    }

    /// AppKit (the status item) cannot call SwiftUI scene actions directly, so capture them here.
    /// Avoids `NSApp.sendAction(Selector(("showSettingsWindow:")))`, whose selector name changed
    /// at macOS 14 and is a private string that will break again.
    @MainActor
    private func wireSceneActions() {
        delegate.onShowWindow = {
            openWindow(id: "main")
            NSApp.activate()
        }
        delegate.onOpenSettings = {
            NSApp.activate()
            if #available(macOS 14, *) {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
        }
    }
}
