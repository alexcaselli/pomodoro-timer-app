import AppKit
import SwiftUI

/// Port of `MainWindow.xaml.cs` — the orchestrator.
///
/// The Windows original passed live `TextBlock` and `Button` instances into the timer and
/// manager classes, which mutated them directly. Here the model owns state only and the views
/// observe it.
@MainActor
@Observable
final class AppModel {
    let settings: SettingsStore
    let notifications = NotificationService()
    let overlay = BreakOverlayController()

    private(set) var phase: TimerPhase = .work
    private(set) var timer: PomodoroTimer
    private(set) var manager: UserActivityPomodoroTimerManager

    var debugText: String = ""

    // Derived state, read by ContentView / StatusItemController / BreakOverlayView.
    var timerText: String { timer.displayText }
    var stateKind: TimerStateKind { timer.stateKind }
    var isStopEnabled: Bool { timer.isStopEnabled }
    var primaryIcon: ControlIcon { timer.primaryIcon }
    var stopwatchText: String { manager.stopwatchText }
    var isStopwatchVisible: Bool { manager.isStopwatchVisible }

    init(settings: SettingsStore = SettingsStore()) {
        self.settings = settings
        let t = PomodoroTimer(phase: .work, durationMinutes: settings.effectiveDuration(for: .work))
        self.timer = t
        self.manager = UserActivityWorkTimerManager(
            timer: t, threshold: settings.workInactivityThreshold
        )
        t.onCompleted = { [weak self] phase in self?.onTimerCompleted(phase) }

        notifications.onOpenRequested = { [weak self] in self?.bringToFrontAndShowOverlay() }
    }

    // MARK: - Timer lifecycle

    /// `InitializeWorkTimer()` / `InitializeBreakTimer()`: build a fresh timer and manager for
    /// `phase` WITHOUT starting it.
    private func makeTimer(for phase: TimerPhase) {
        // The leak fix. The C# only did `_currentTimer.TimerCompleted -= OnTimerElapsed` and
        // left the old timer and its monitor running forever.
        timer.tearDown()
        manager.tearDown()

        self.phase = phase
        let t = PomodoroTimer(phase: phase, durationMinutes: settings.effectiveDuration(for: phase))
        timer = t
        manager = switch phase {
        case .work:
            UserActivityWorkTimerManager(timer: t, threshold: settings.workInactivityThreshold)
        case .rest:
            UserActivityBreakTimerManager(timer: t, threshold: settings.breakActivityThreshold)
        }
        t.onCompleted = { [weak self] phase in self?.onTimerCompleted(phase) }
    }

    /// `StartPomodoroTimer(TimerType)`: fresh timer for `phase`, then start it immediately.
    private func startPomodoroTimer(_ phase: TimerPhase) {
        makeTimer(for: phase)
        timer.clickStartPauseResume()
    }

    /// `StopAndResetTimer()`.
    private func stopAndResetTimer() {
        timer.clickStop()
        manager.hideActivityStopwatch()
    }

    // MARK: - User actions

    func primaryButtonTapped() {
        timer.clickStartPauseResume()
    }

    func stopButtonTapped() {
        timer.clickStop()
        manager.hideActivityStopwatch()
        overlay.hide()
    }

    /// `SelectorBarTimer_SelectionChanged`: switching tabs stops and resets, but does NOT start.
    func select(phase newPhase: TimerPhase) {
        guard newPhase != phase else { return }
        stopAndResetTimer()
        makeTimer(for: newPhase)
        overlay.hide()
    }

    /// Settings changed: stop, reset, and rebuild the current phase's timer with the new
    /// duration — the same thing the Save button of the WinUI ContentDialog did.
    func settingsChanged() {
        stopAndResetTimer()
        makeTimer(for: phase)
    }

    // MARK: - Cycle transition (OnTimerElapsed)

    private func onTimerCompleted(_ completed: TimerPhase) {
        notifications.notifyCompleted(phase: completed, enabled: settings.notificationsEnabled)

        switch completed {
        case .work:
            bringToFront()
            presentOverlay()
            startPomodoroTimer(.rest)
        case .rest:
            overlay.hide()
            startPomodoroTimer(.work)
        }
    }

    private func presentOverlay() {
        overlay.onSkip = { [weak self] in self?.stopButtonTapped() }
        overlay.show(strictness: settings.strictness) { [weak self] isPrimary in
            guard let self else { return AnyView(EmptyView()) }
            return AnyView(BreakOverlayView(model: self, isPrimary: isPrimary))
        }
    }

    private func bringToFront() {
        NSApp.activate()
        for window in NSApp.windows where window.canBecomeMain {
            window.makeKeyAndOrderFront(nil)
            break
        }
    }

    func bringToFrontAndShowOverlay() {
        bringToFront()
        if phase == .rest { presentOverlay() }
    }

    // MARK: - System events

    /// Called on wake. Recompute once; never replay missed ticks.
    func forceRecompute() {
        timer.forceRecompute()
    }

    func tearDown() {
        overlay.hide()
        timer.tearDown()
        manager.tearDown()
    }
}
