import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()
    private var statusItem: StatusItemController?
    private var wakeObserver: (any NSObjectProtocol)?

    var onShowWindow: (@MainActor () -> Void)?
    var onOpenSettings: (@MainActor () -> Void)?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        // Heal after a crash mid-break: without this the user would be left with no Dock and no
        // menu bar until logout.
        NSApp.presentationOptions = []

        model.notifications.bootstrap()

        let status = StatusItemController(model: model)
        status.onShowWindow = { [weak self] in self?.onShowWindow?() }
        status.onOpenSettings = { [weak self] in self?.onOpenSettings?() }
        statusItem = status

        LaunchAtLoginService.syncOnLaunch(desired: model.settings.launchAtLogin)

        // Belt and braces: every timer mechanism fires once on wake rather than replaying the
        // missed interval, and the deadline is authoritative anyway — this just avoids waiting
        // up to a second before noticing the timer already expired.
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.model.forceRecompute() }
        }

        Log.app.info("launched")
    }

    /// Clicking the Dock icon with no visible window reopens the main window.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { onShowWindow?() }
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver)
        }
        model.tearDown()
        NSApp.presentationOptions = []
        Log.app.info("terminated")
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }
}
