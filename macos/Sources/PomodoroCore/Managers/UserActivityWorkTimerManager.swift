import Foundation

/// Port of `Managers/UserActivityWorkTimerManager.cs`.
///
/// During WORK: going idle past the threshold auto-pauses; coming back auto-resumes.
@MainActor
final class UserActivityWorkTimerManager: UserActivityPomodoroTimerManager {
    @ObservationIgnored private var pausedDueToInactivity = false

    init(timer: PomodoroTimer, threshold: TimeInterval = IdleMonitor.workInactivityThreshold) {
        super.init(timer: timer, monitor: .forWork(threshold: threshold))
    }

    override func onUserInactive() {
        let paused = timer?.clickActivityPause() ?? false
        pausedDueToInactivity = paused || pausedDueToInactivity
        if paused { startActivityStopwatch() }
    }

    override func onUserActive() {
        // Guarded by the flag so a pause the user made by hand is never auto-resumed.
        guard pausedDueToInactivity else { return }
        timer?.clickActivityResume()
        pausedDueToInactivity = false
        stopActivityStopwatch()
    }
}
