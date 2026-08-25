import AppKit
import SwiftUI

/// Two things SwiftUI will not do for this window, done through AppKit.
///
/// **Translucency.** The window keeps a clear background so the `NSVisualEffectView` behind the
/// content can blur the desktop, and the dark appearance is pinned because the material only
/// reads as dark and see-through in `darkAqua`.
///
/// `isOpaque` is deliberately left alone. Clearing it is not needed for behind-window vibrancy —
/// that is how a standard translucent sidebar works in an ordinary opaque window — and it breaks
/// Liquid Glass: glass refracts whatever sits behind it, and in a non-opaque window the backdrop
/// is the desktop, which the process cannot sample, so every glass surface degrades to a flat
/// neutral fill.
///
/// **Initial size.** `.defaultSize(width:height:)` has no effect on this scene — verified by
/// changing the value and measuring, and `idealWidth`/`idealHeight` on the content are ignored
/// too. With `.windowResizability(.contentMinSize)` the window simply adopts the content's
/// *minimum*, coming up at 480x472 instead of the Windows app's 720x560. Setting the size here
/// is the only thing that works.
///
/// The size is applied only when SwiftUI has no frame persisted for the scene, so it runs on
/// first launch and never fights a size the user chose afterwards. SwiftUI owns that key —
/// `setFrameAutosaveName` is deliberately not used, as a second autosave key would compete
/// with it.
struct WindowSetup: NSViewRepresentable {
    /// The Windows app's `AppWindow.Resize(720, 560)`.
    static let defaultContentSize = NSSize(width: 720, height: 560)
    /// SwiftUI persists the frame of the `Window(id: "main")` scene under this key.
    static let savedFrameKey = "NSWindow Frame main"

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async { context.coordinator.configure(view.window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // Re-asserted on layout passes: SwiftUI repaints the window background, and
        // re-applying is cheap and idempotent. Sizing is one-shot, guarded in the coordinator.
        context.coordinator.configure(nsView.window)
    }

    @MainActor
    final class Coordinator {
        private var didSize = false

        func configure(_ window: NSWindow?) {
            guard let window else { return }
            // `.fullSizeContentView` extends the content view over the whole window frame, so
            // the background — which ignores safe areas to reach the edges — sits on top of the
            // margins that carry the resize cursors, and the window stops offering to resize.
            // Nothing here needs content under the titlebar, so drop it.
            window.styleMask.remove(.fullSizeContentView)
            // No `backgroundColor = .clear`: the visual effect view already covers the window,
            // and a clear background on an opaque window is a contradictory state.
            window.titlebarAppearsTransparent = true
            window.appearance = NSAppearance(named: .darkAqua)

            guard !didSize else { return }
            didSize = true
            guard UserDefaults.standard.string(forKey: WindowSetup.savedFrameKey) == nil else { return }
            window.setContentSize(WindowSetup.defaultContentSize)
            window.center()
        }
    }
}
