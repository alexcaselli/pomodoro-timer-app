import Foundation

/// Port of `Managers/UserActivityPomodoroTimerManager.cs`.
///
/// Owns the idle monitor and the count-up "you've been away" stopwatch that the Windows app
/// showed in green while a timer was auto-paused.
@MainActor
@Observable
class UserActivityPomodoroTimerManager: ActivityObserver {
    @ObservationIgnored private(set) weak var timer: PomodoroTimer?
    @ObservationIgnored private let monitor: IdleMonitor
    @ObservationIgnored private let stopwatch = TickDriver()
    @ObservationIgnored private var startedAt: ContinuousClock.Instant?

    private(set) var idleElapsed: TimeInterval = 0
    private(set) var isStopwatchVisible = false

    var stopwatchText: String { TimeFormatting.mmss(idleElapsed) }

    init(timer: PomodoroTimer, monitor: IdleMonitor) {
        self.timer = timer
        self.monitor = monitor
        monitor.add(self)
        monitor.start()
    }

    func onUserActive() { preconditionFailure("abstract") }
    func onUserInactive() { preconditionFailure("abstract") }

    func startActivityStopwatch() {
        startedAt = ContinuousClock().now
        idleElapsed = 0
        isStopwatchVisible = true
        // Derived from an instant rather than `+= 1` per tick: the C# accumulated and drifted.
        stopwatch.start { [weak self] in
            guard let self, let startedAt else { return }
            idleElapsed = startedAt.duration(to: ContinuousClock().now).seconds
        }
    }

    /// Stops counting but deliberately leaves the label on screen, exactly as the Windows app
    /// did — after an auto-resume you still see how long you were away. Only an explicit Stop
    /// (`hideActivityStopwatch`) clears it.
    func stopActivityStopwatch() {
        stopwatch.stop()
    }

    func hideActivityStopwatch() {
        stopwatch.stop()
        isStopwatchVisible = false
    }

    func tearDown() {
        monitor.remove(self)
        monitor.stop()
        stopwatch.stop()
    }
}
