import AppKit

/// A borderless `NSWindow` returns `false` from `canBecomeKey` by default, which means keyboard
/// events never reach the SwiftUI content — Esc and the Skip button would both be dead. This
/// subclass exists for those two overrides.
final class BreakOverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    init(screen: NSScreen, content: NSView) {
        // The `screen:` overload is a convenience initializer, so a subclass must go through
        // the designated one and position itself afterwards.
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        level = .screenSaver
        collectionBehavior = [
            .canJoinAllSpaces,        // follow the user across Spaces
            .stationary,              // unaffected by Mission Control
            .fullScreenAuxiliary,     // may sit alongside a full-screen window
            .ignoresCycle,            // stay out of Cmd-` cycling
            .canJoinAllApplications,  // macOS 13+: THE flag that lets us cover *another app's*
                                      // full-screen Space. Without it the overlay works in
                                      // testing and silently fails over full-screened Safari.
        ]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = false    // swallow every click inside our frame
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        animationBehavior = .none
        // `screen.frame`, not `visibleFrame` — we want to cover the menu bar strip too.
        contentView = content
        setFrame(screen.frame, display: true)
    }

    /// Esc / Cmd-. — one of the escape hatches that must always work.
    override func cancelOperation(_ sender: Any?) {
        onCancel?()
    }

    var onCancel: (() -> Void)?
}
