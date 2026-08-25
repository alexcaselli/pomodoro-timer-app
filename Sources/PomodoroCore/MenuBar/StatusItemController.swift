import AppKit
import Observation

/// Menu bar extra showing the live countdown.
///
/// AppKit `NSStatusItem` rather than SwiftUI `MenuBarExtra`: `MenuBarExtra` re-renders a whole
/// SwiftUI hierarchy and re-rasterises the item once per second, and its width visibly jitters
/// as the digits change. `NSStatusItem` takes an `NSAttributedString` with a
/// monospaced-digit font — fixed advance width, one string assignment per tick.
@MainActor
final class StatusItemController: NSObject {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let model: AppModel
    private let menu = NSMenu()

    private let startPauseItem = NSMenuItem(title: "Start", action: nil, keyEquivalent: "")
    private let stopItem = NSMenuItem(title: "Stop", action: nil, keyEquivalent: "")
    private let workItem = NSMenuItem(title: "Work", action: nil, keyEquivalent: "")
    private let breakItem = NSMenuItem(title: "Break", action: nil, keyEquivalent: "")

    var onShowWindow: (@MainActor () -> Void)?
    var onOpenSettings: (@MainActor () -> Void)?

    init(model: AppModel) {
        self.model = model
        super.init()
        buildMenu()
        observeModel()
        refresh()
    }

    private func buildMenu() {
        menu.delegate = self

        for menuItem in [startPauseItem, stopItem] {
            menuItem.target = self
            menu.addItem(menuItem)
        }
        startPauseItem.action = #selector(togglePlay)
        stopItem.action = #selector(stop)

        menu.addItem(.separator())

        workItem.target = self
        workItem.action = #selector(selectWork)
        breakItem.target = self
        breakItem.action = #selector(selectBreak)
        menu.addItem(workItem)
        menu.addItem(breakItem)

        menu.addItem(.separator())

        let show = NSMenuItem(title: "Show Window", action: #selector(showWindow), keyEquivalent: "")
        show.target = self
        menu.addItem(show)

        let settings = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "Quit Pomodoro Timer",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        item.menu = menu
    }

    private func refresh() {
        guard let button = item.button else { return }
        button.image = NSImage(
            systemSymbolName: model.phase == .work ? "hammer.fill" : "cup.and.saucer.fill",
            accessibilityDescription: model.phase.title
        )
        button.image?.isTemplate = true
        button.imagePosition = .imageLeading
        button.attributedTitle = NSAttributedString(
            string: " \(model.timerText)",
            attributes: [.font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)]
        )
        button.toolTip = "\(model.phase.title) — \(stateDescription)"
    }

    private var stateDescription: String {
        switch model.stateKind {
        case .ready: "ready"
        case .running: "running"
        case .paused: "paused"
        }
    }

    /// `withObservationTracking` is one-shot and its `onChange` fires *willSet*, so the closure
    /// must hop to read the new value and then RE-ARM. Forgetting the re-arm is the classic bug
    /// with this pattern: updates stop silently after the first change.
    private func observeModel() {
        withObservationTracking {
            _ = model.timerText
            _ = model.phase
            _ = model.stateKind
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.refresh()
                self.observeModel()
            }
        }
    }

    // MARK: - Actions

    @objc private func togglePlay() { model.primaryButtonTapped() }
    @objc private func stop() { model.stopButtonTapped() }
    @objc private func selectWork() { model.select(phase: .work) }
    @objc private func selectBreak() { model.select(phase: .rest) }
    @objc private func showWindow() { onShowWindow?() }
    @objc private func openSettings() { onOpenSettings?() }
}

extension StatusItemController: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        startPauseItem.title = model.stateKind == .running ? "Pause" : "Start"
        stopItem.isEnabled = model.isStopEnabled
        workItem.state = model.phase == .work ? .on : .off
        breakItem.state = model.phase == .rest ? .on : .off
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        menuItem === stopItem ? model.isStopEnabled : true
    }
}
