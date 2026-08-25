import Foundation

/// Port of `Managers/UserActivityBreakTimerManager.cs`.
///
/// During BREAK the polarity is mirrored: touching the machine pauses the break, and leaving it
/// alone resumes it. This is what makes the break count only while you have actually stepped
/// away, rather than while you keep working through it.
@MainActor
final class UserActivityBreakTimerManager: UserActivityPomodoroTimerManager {
    @ObservationIgnored private var pausedDueToActivity = false

    init(timer: PomodoroTimer, threshold: TimeInterval = IdleMonitor.breakActivityThreshold) {
        super.init(timer: timer, monitor: .forBreak(threshold: threshold))
    }

    override func onUserActive() {
        let paused = timer?.clickActivityPause() ?? false
        pausedDueToActivity = paused || pausedDueToActivity
        if paused { startActivityStopwatch() }
    }

    override func onUserInactive() {
        guard pausedDueToActivity else { return }
        timer?.clickActivityResume()
        pausedDueToActivity = false
        stopActivityStopwatch()
    }
}
