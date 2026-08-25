import Foundation

struct PausedState: TimerState {
    let kind: TimerStateKind = .paused

    func startPauseResume(_ timer: PomodoroTimer) {
        timer.resume()
        timer.change(to: RunningState())
    }

    func stop(_ timer: PomodoroTimer) {
        timer.stop()
        timer.change(to: ReadyState())
    }

    func completed(_ timer: PomodoroTimer) {}
    func activityPause(_ timer: PomodoroTimer) -> Bool { false }

    func activityResume(_ timer: PomodoroTimer) -> Bool {
        timer.resume()
        timer.change(to: RunningState())
        return true
    }
}
