import AppKit
import SwiftUI

/// Makes the window itself translucent.
///
/// This is the missing half of the Mica replacement. An `NSVisualEffectView` with
/// `.behindWindow` blending can only blur what is *behind* the window — and a SwiftUI window is
/// opaque by default, with its own solid background painted underneath. The effect view then has
/// nothing to sample and renders as flat grey, which is exactly what it looked like.
///
/// Clearing `isOpaque` and the window background lets the desktop show through, so the material
/// finally does its job.
///
/// Re-applied from `updateNSView` as well as at setup: SwiftUI repaints the window background on
/// some layout passes, and re-asserting is cheap and idempotent.
struct WindowTranslucency: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async { apply(to: view.window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        apply(to: nsView.window)
    }

    private func apply(to window: NSWindow?) {
        guard let window else { return }
        window.isOpaque = false
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        window.appearance = NSAppearance(named: .darkAqua)
    }
}
