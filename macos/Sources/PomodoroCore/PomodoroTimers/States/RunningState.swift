import Foundation

struct RunningState: TimerState {
    let kind: TimerStateKind = .running

    func startPauseResume(_ timer: PomodoroTimer) {
        timer.pause()
        timer.change(to: PausedState())
    }

    func stop(_ timer: PomodoroTimer) {
        timer.stop()
        timer.change(to: ReadyState())
    }

    /// Order matters and matches the C#: transition to Ready FIRST, then fire completion.
    /// `handleTimerCompletion` synchronously drives the work->break cycle transition, which
    /// tears this timer down; firing it while still marked Running would be observably wrong.
    func completed(_ timer: PomodoroTimer) {
        timer.change(to: ReadyState())
        timer.handleTimerCompletion()
    }

    func activityPause(_ timer: PomodoroTimer) -> Bool {
        timer.pause()
        timer.change(to: PausedState())
        return true
    }

    func activityResume(_ timer: PomodoroTimer) -> Bool { false }
}
