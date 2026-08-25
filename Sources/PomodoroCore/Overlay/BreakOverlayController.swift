import AppKit
import SwiftUI

enum BreakStrictness: String, CaseIterable, Codable, Sendable, Identifiable {
    case gentle   // overlay only; Dock and menu bar stay put
    case firm     // + hideDock, hideMenuBar
    case strict   // + disableProcessSwitching, disableAppleMenu, disableHideApplication

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gentle: "Gentle"
        case .firm: "Firm"
        case .strict: "Strict"
        }
    }

    var explanation: String {
        switch self {
        case .gentle: "Covers the screen, but the Dock and menu bar stay available."
        case .firm: "Hides the Dock and menu bar while the break runs."
        case .strict: "Also blocks Cmd-Tab and the Apple menu. Quitting still works."
        }
    }
}

/// macOS replacement for `AppWindowPresenterKind.FullScreen`.
///
/// Native full screen was the wrong tool: it creates a new Space with a ~700 ms animation, it
/// cannot cover other apps' full-screen Spaces, and it traps the app there. A borderless
/// `.screenSaver`-level window per display appears instantly and follows the user everywhere.
///
/// Honest about the limits — this is *best-effort*, not kiosk mode:
/// - `presentationOptions` apply only while this app is active; lose focus and the Dock returns.
/// - Mission Control, Spotlight and Notification Center draw above `.screenSaver` and cannot be
///   blocked without entitlements we do not have.
/// - `.disableForceQuit` / `.disableSessionTermination` are deliberately NOT used: a
///   productivity timer that stops you shutting down your Mac is a bug, not a feature.
@MainActor
final class BreakOverlayController {
    private var windows: [BreakOverlayWindow] = []
    private var savedPresentationOptions: NSApplication.PresentationOptions = []
    private var observers: [any NSObjectProtocol] = []
    private var lastReassertAt: ContinuousClock.Instant?
    private(set) var isShowing = false

    private var strictness: BreakStrictness = .firm
    private var makeContent: ((Bool) -> AnyView)?
    var onSkip: (@MainActor () -> Void)?

    func show(strictness: BreakStrictness, content: @escaping (Bool) -> AnyView) {
        guard !isShowing else { return }
        isShowing = true
        self.strictness = strictness
        self.makeContent = content

        savedPresentationOptions = NSApp.presentationOptions
        buildWindows()
        applyPresentationOptions()

        NSApp.setActivationPolicy(.regular)
        NSApp.activate()

        let center = NotificationCenter.default
        observers.append(center.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main
        ) { _ in
            MainActor.assumeIsolated { self.rebuildWindows() }
        })
        observers.append(center.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil, queue: .main
        ) { _ in
            MainActor.assumeIsolated { self.reassert() }
        })

        Log.overlay.info("overlay shown on \(self.windows.count) screen(s), \(strictness.rawValue)")
    }

    func hide() {
        guard isShowing else { return }
        isShowing = false

        for observer in observers { NotificationCenter.default.removeObserver(observer) }
        observers.removeAll()

        // Restore what was actually there, never assume `.default`.
        NSApp.presentationOptions = savedPresentationOptions
        tearDownWindows()
        makeContent = nil
        Log.overlay.info("overlay hidden")
    }

    // MARK: - Windows

    private func buildWindows() {
        guard let makeContent else { return }
        // The screen with the mouse gets the interactive UI; the rest get a passive backdrop.
        let mouse = NSEvent.mouseLocation
        let primary = NSScreen.screens.firstIndex { NSMouseInRect(mouse, $0.frame, false) } ?? 0

        for (index, screen) in NSScreen.screens.enumerated() {
            let isPrimary = index == primary
            let hosting = NSHostingView(rootView: makeContent(isPrimary))
            hosting.frame = CGRect(origin: .zero, size: screen.frame.size)
            let window = BreakOverlayWindow(screen: screen, content: hosting)
            window.onCancel = { [weak self] in self?.onSkip?() }
            if isPrimary {
                window.makeKeyAndOrderFront(nil)
            } else {
                window.orderFrontRegardless()
            }
            windows.append(window)
        }
    }

    private func tearDownWindows() {
        for window in windows {
            window.orderOut(nil)
            window.close()
        }
        windows.removeAll()
    }

    private func rebuildWindows() {
        guard isShowing else { return }
        Log.overlay.info("screen parameters changed — rebuilding overlay")
        tearDownWindows()
        buildWindows()
        applyPresentationOptions()
    }

    // MARK: - Presentation options

    private func applyPresentationOptions() {
        var options: NSApplication.PresentationOptions = []
        if strictness != .gentle {
            // `.hideMenuBar` WITHOUT `.hideDock` makes setPresentationOptions: raise. They must
            // always be inserted as a pair.
            options.insert([.hideDock, .hideMenuBar])
        }
        if strictness == .strict {
            options.insert([.disableProcessSwitching, .disableAppleMenu, .disableHideApplication])
        }
        NSApp.presentationOptions = options
    }

    /// Re-assert focus when something steals it — rate limited to once a second.
    ///
    /// The rate limit is load-bearing, not a nicety. Without it a genuine system-modal alert
    /// that takes focus produces an infinite activate/resign spin that pegs a core and locks the
    /// user out for real.
    private func reassert() {
        guard isShowing, strictness != .gentle else { return }
        guard NSApp.modalWindow == nil else { return }

        let now = ContinuousClock().now
        if let last = lastReassertAt, last.duration(to: now) < .seconds(1) { return }
        lastReassertAt = now

        NSApp.activate()
        for window in windows { window.orderFrontRegardless() }
        applyPresentationOptions()
    }
}
